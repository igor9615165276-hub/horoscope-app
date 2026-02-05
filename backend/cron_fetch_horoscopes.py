# backend/cron_fetch_horoscopes.py

import logging
from datetime import date

from .database import SessionLocal
from .models import Horoscope
from .deepseek_client import generate_daily

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

# Технические коды знаков, как в UserSign.sign и онбординге
ZODIAC_SIGNS = [
    "aries",
    "taurus",
    "gemini",
    "cancer",
    "leo",
    "virgo",
    "libra",
    "scorpio",
    "sagittarius",
    "capricorn",
    "aquarius",
    "pisces",
]

# Русские названия для заголовков
RUSSIAN_SIGN_NAMES = {
    "aries": "Овен",
    "taurus": "Телец",
    "gemini": "Близнецы",
    "cancer": "Рак",
    "leo": "Лев",
    "virgo": "Дева",
    "libra": "Весы",
    "scorpio": "Скорпион",
    "sagittarius": "Стрелец",
    "capricorn": "Козерог",
    "aquarius": "Водолей",
    "pisces": "Рыбы",
}


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def make_horoscope_id(sign: str, lang: str, for_date: date) -> str:
    """Детерминированный ID: например, 'aries_ru_2026-02-05'."""
    return f"{sign}_{lang}_{for_date.isoformat()}"


def upsert_horoscope(db, sign: str, lang: str, for_date: date, text: str):
    """Создать или обновить гороскоп для знака/даты/языка."""
    obj = (
        db.query(Horoscope)
        .filter(
            Horoscope.sign == sign,
            Horoscope.date == for_date,
            Horoscope.lang == lang,
        )
        .first()
    )

    sign_ru = RUSSIAN_SIGN_NAMES.get(sign, sign)
    title = f"{sign_ru}: гороскоп на {for_date.strftime('%d.%m.%Y')}"
    h_id = make_horoscope_id(sign, lang, for_date)

    if obj:
        obj.title = title
        obj.text = text
    else:
        obj = Horoscope(
            id=h_id,
            sign=sign,
            date=for_date,
            lang=lang,
            title=title,
            text=text,
        )
        db.add(obj)

    db.commit()


def generate_all_for_today(lang: str = "ru"):
    """Сгенерировать гороскопы на сегодняшнюю дату для всех знаков."""
    today = date.today()
    logger.info("Generating horoscopes for %s, lang=%s", today.isoformat(), lang)

    db_gen = get_db()
    db = next(db_gen)

    try:
        for sign in ZODIAC_SIGNS:
            try:
                logger.info("Generating horoscope for sign=%s", sign)
                text = generate_daily(sign=sign, lang=lang, for_date=today)
                upsert_horoscope(db, sign=sign, lang=lang, for_date=today, text=text)
                logger.info("Saved horoscope for %s", sign)
            except Exception as e:
                logger.exception("Failed to generate/save horoscope for %s: %s", sign, e)
    finally:
        db_gen.close()

    logger.info("Done generating horoscopes for %s", today.isoformat())


if __name__ == "__main__":
    generate_all_for_today(lang="ru")
