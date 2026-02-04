import asyncio
from datetime import datetime, date
from sqlalchemy.orm import Session

from .database import SessionLocal
from .models import Horoscope
from .celltick_client import fetch_all_signs

LANGS = ["ru", "en"]


def save_items(db: Session, items: list[dict], lang: str):
    today = date.today()
    for item in items:
        # Подстраиваемся под поля Celltick[web:53]
        sign = item.get("sign") or item.get("zodiac") or item.get("sunsign")
        if not sign:
            continue

        title = item.get("title") or item.get("meta") or None
        text = item.get("text") or item.get("horoscope") or item.get("description")
        if not text:
            continue

        h_id = f"{sign}_{lang}_{today.isoformat()}"

        db.merge(
            Horoscope(
                id=h_id,
                sign=sign,
                date=today,
                lang=lang,
                title=title,
                text=text,
            )
        )
    db.commit()


async def run_once():
    db = SessionLocal()
    try:
        today_dt = datetime.utcnow()
        for lang in LANGS:
            items = await fetch_all_signs(lang, today_dt)
            save_items(db, items, lang)
    finally:
        db.close()


if __name__ == "__main__":
    asyncio.run(run_once())
