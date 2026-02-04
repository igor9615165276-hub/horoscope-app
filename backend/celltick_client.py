import httpx
from datetime import datetime
from typing import Literal

BASE_URL = "https://contentapi.celltick.com/mediaApi/v1.0/mid/horoscope"

Language = Literal["ru", "en"]


async def fetch_all_signs(lang: Language, date_: datetime) -> list[dict]:
    params = {
        "publishDate": date_.strftime("%m/%d/%Y"),
        "language": lang,
    }
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(BASE_URL, params=params)
        resp.raise_for_status()
        data = resp.json()
        # по доке Celltick результат — объект с полем items[web:53]
        items = data.get("items") or data
        # items должен быть списком объектов со структурами { "sign": ..., "title": ..., "text": ... }
        return items
