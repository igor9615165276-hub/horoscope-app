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

ZODIAC_SIGNS_RU = [
    "Овен",
    "Телец",
    "Близнецы",
    "Рак",
    "Лев",
    "Дева",
    "Весы",
    "Скорпион",
    "Стрелец",
    "Козерог",
    "Водолей",
    "Рыбы",
]


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def upsert_horoscope(db, sign: str, lang: str, for_date: date, text: str):
    obj = (
        db.query(Horoscope)
        .filter(
            Horoscope.sign == sign,
            Horoscope.date == for_date,
            Horoscope.lang == lang,
        )
        .first()
    )

    title = f"Гороскоп на {for_date.strftime('%d.%m.%Y')}"

    if obj:
        obj.title = title
        obj.text = text
    else:
        obj = Horoscope(
            sign=sign,
            date=for_date,
            lang=lang,
            title=title,
            text=text,
        )
        db.add(obj)

    db.commit()


def generate_all_for_today(lang: str = "ru"):
    today = date.today()
    logger.info("Generating horoscopes for %s, lang=%s", today.isoformat(), lang)

    db_gen = get_db()
    db = next(db_gen)

    try:
        for sign in ZODIAC_SIGNS_RU:
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
