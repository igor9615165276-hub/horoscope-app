import os
import json
import logging
from datetime import datetime, date, time, timedelta, timezone

from sqlalchemy.orm import Session

from .database import SessionLocal
from .models import UserDevice, UserSign, Horoscope

import firebase_admin
from firebase_admin import credentials, messaging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MOSCOW_TZ = timezone(timedelta(hours=3))


def init_firebase():
    # Вариант 1: путь к файлу с ключом
    cred_path = os.getenv("FCM_CREDENTIALS_FILE")
    cred_json = os.getenv("FCM_SERVICE_ACCOUNT_JSON")

    if cred_path and os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin initialized from file")
        return

    # Вариант 2: JSON ключа в переменной окружения
    if cred_json:
        data = json.loads(cred_json)
        cred = credentials.Certificate(data)
        firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin initialized from env JSON")
        return

    raise RuntimeError(
        "Firebase credentials not provided (FCM_CREDENTIALS_FILE or FCM_SERVICE_ACCOUNT_JSON)"
    )


def get_moscow_now() -> datetime:
    utc_now = datetime.now(timezone.utc)
    return utc_now.astimezone(MOSCOW_TZ)


def is_within_window(now_ms: datetime, target: time, window_minutes: int = 10) -> bool:
    """Проверяем, что текущее время в окне ±window_minutes от target."""
    target_dt = datetime.combine(now_ms.date(), target, tzinfo=now_ms.tzinfo)
    delta = abs((now_ms - target_dt).total_seconds()) / 60.0
    return delta <= window_minutes


def get_user_signs(db: Session, user_id):
    rows = db.query(UserSign).filter(UserSign.user_id == user_id).all()
    return [r.sign for r in rows]


def get_today_horoscopes_for_signs(db: Session, signs, lang: str):
    today = get_moscow_now().date()
    return (
        db.query(Horoscope)
        .filter(
            Horoscope.date == today,
            Horoscope.lang == lang,
            Horoscope.sign.in_(signs),
        )
        .all()
    )


def build_preview_text(horoscopes):
    if not horoscopes:
        return "Ваш гороскоп на сегодня готов!"
    first = horoscopes[0]
    text = first.text or ""
    short = text.strip().replace("\n", " ")
    if len(short) > 160:
        short = short[:157].rsplit(" ", 1)[0] + "..."
    return short


def send_push_to_device(device: UserDevice, horoscopes, lang: str):
    body = build_preview_text(horoscopes)
    title = "Гороскоп на сегодня" if lang == "ru" else "Today’s horoscope"

    message = messaging.Message(
        token=device.fcm_token,
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data={
            "screen": "today",
        },
    )
    response = messaging.send(message)
    logger.info(f"Sent push to device {device.id}, response: {response}")


def process_pushes():
    moscow_now = get_moscow_now()
    logger.info(f"Moscow time now: {moscow_now.isoformat()}")

    today = moscow_now.date()
    db: Session = SessionLocal()
    try:
        # Берём только активные устройства, которым ещё не слали сегодня
        devices = (
            db.query(UserDevice)
            .filter(
                UserDevice.is_active.is_(True),
                UserDevice.fcm_token != "",
                (UserDevice.last_push_date.is_(None) | (UserDevice.last_push_date != today)),
            )
            .all()
        )
        logger.info(f"Found {len(devices)} devices eligible for push")

        for device in devices:
            if not device.push_time:
                continue

            # ВРЕМЕННО: строгая проверка по часам и минутам
            if (
                moscow_now.hour != device.push_time.hour
                or moscow_now.minute != device.push_time.minute
            ):
                logger.info(
                    "Skip device %s: now=%s, push_time=%s",
                    device.id,
                    moscow_now.time(),
                    device.push_time,
                )
                continue

            try:
                signs = get_user_signs(db, device.user_id)
                if not signs:
                    logger.info(f"No signs for user {device.user_id}, skip")
                    continue

                horoscopes = get_today_horoscopes_for_signs(db, signs, device.lang)
                if not horoscopes:
                    logger.info(f"No horoscopes for user {device.user_id} today, skip")
                    continue

                send_push_to_device(device, horoscopes, device.lang)

                device.last_push_date = today
                db.add(device)
                db.commit()
            except Exception as e:
                db.rollback()
                logger.exception(f"Failed to send push to device {device.id}: {e}")
    finally:
        db.close()


def main():
    logger.info("cron_send_pushes started")
    init_firebase()
    process_pushes()
    logger.info("cron_send_pushes finished")


if __name__ == "__main__":
    main()
