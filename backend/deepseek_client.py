# backend/deepseek_client.py

import os
from datetime import date

import requests

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
DEEPSEEK_MODEL = os.getenv("DEEPSEEK_MODEL", "deepseek-chat")

DEEPSEEK_API_URL = os.getenv(
    "DEEPSEEK_API_URL",
    "https://api.deepseek.com/v1/chat/completions"
)

if not DEEPSEEK_API_KEY:
    raise RuntimeError("DEEPSEEK_API_KEY is not set in environment variables")


HOROSCOPE_SYSTEM_PROMPT_RU = """
Ты астролог, который пишет ежедневные гороскопы на РУССКОМ языке.

Требования к стилю:
- Пиши с лёгкой ноткой юмора и позитива, но без клоунады.
- Не используй негатив, не запугивай, не упоминай болезни, политику, деньги напрямую.
- Тон дружелюбный, поддерживающий, как хороший знакомый, который вдохновляет.

Формат:
- 2–3 абзаца по 2–3 предложения.
- В первом абзаце — общий настрой и главная идея дня.
- Во втором — короткие советы по делам, общению и настроению.
- Можно добавить одну лёгкую шутку или ироничное наблюдение.

Ограничения:
- Не давай медицинских, юридических или финансовых рекомендаций.
- Не используй агрессивные формулировки.
- Не упоминай, что текст сгенерирован ИИ.
""".strip()


def _call_deepseek_chat(system_prompt: str, messages: list[dict]) -> str:
    """
    Базовый вызов DeepSeek Chat API (OpenAI‑совместимый).
    Возвращает content из первого choice.
    """
    headers = {
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": DEEPSEEK_MODEL,
        "messages": [{"role": "system", "content": system_prompt}] + messages,
        "temperature": 0.7,
    }

    resp = requests.post(DEEPSEEK_API_URL, json=payload, headers=headers, timeout=40)
    resp.raise_for_status()
    data = resp.json()
    return data["choices"][0]["message"]["content"]


def generate_daily(sign: str, lang: str, for_date: date) -> str:
    """
    Генерация текста гороскопа для конкретного знака, языка и даты.
    Пока реализуем только 'ru', но lang оставляем на будущее.
    """
    if lang != "ru":
        # На первом этапе поддерживаем только русские тексты
        raise ValueError(f"Only 'ru' is supported for now, got lang={lang!r}")

    user_prompt = (
        f"Сегодняшняя дата: {for_date.isoformat()}.\n"
        f"Знак зодиака: {sign}.\n\n"
        "Сгенерируй гороскоп на сегодняшний день по указанным правилам. "
        "Не дублируй название знака в начале, просто сразу переходи к тексту."
    )

    messages = [
        {"role": "user", "content": user_prompt}
    ]

    return _call_deepseek_chat(HOROSCOPE_SYSTEM_PROMPT_RU, messages)
