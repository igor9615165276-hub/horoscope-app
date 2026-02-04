import os
import logging
from datetime import datetime, date, time, timedelta, timezone

from sqlalchemy.orm import Session

from .database import SessionLocal
from .models import UserDevice, UserSign, Horoscope

import firebase_admin
from firebase_admin import credentials, messaging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def init_firebase():
    cred_path = os.getenv("FCM_CREDENTIALS_FILE")
    if not cred_path:
        raise RuntimeError("FCM_CREDENTIALS_FILE is not set")
    if not os.path.exists(cred_path):
        raise RuntimeError(f"FCM credentials file not found: {cred_path}")
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    logger.info("Firebase Admin initialized")


def get_moscow_now():
    utc_now = datetime.now(timezone.utc)
    moscow_tz = timezone(timedelta(hours=3))
    return utc_now.astimezone(moscow_tz)


def is_within_window(now_ms: datetime, target: time, window_minutes: int = 10) -> bool:
    target_dt = datetime.combine(now_ms.date(), target, tzinfo=now_ms.tzinfo)
    delta = abs((now_ms - target_dt).total_seconds()) / 60.0
    return delta <= window_minutes


def get_user_signs(db: Session, user_id):
    rows = db.query(UserSign).filter(UserSign.user_id == user_id).all()
    return [r.sign for r in rows]


def get_today_horoscopes_for_signs(db: Session, signs, lang: str):
    today = date.today()
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
        target_time = time(hour=9, minute=0)

        devices = (
            db.query(UserDevice)
            .filter(
                UserDevice.push_time == target_time,
                (UserDevice.last_push_date.is_(None) | (UserDevice.last_push_date != today)),
            )
            .all()
        )
        logger.info(f"Found {len(devices)} devices eligible for push")

        if not is_within_window(moscow_now, target_time, window_minutes=10):
            logger.info("Now is outside of push window, skipping send")
            return

        for device in devices:
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
