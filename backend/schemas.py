from pydantic import BaseModel
from typing import List
from datetime import time, date


class RegisterDeviceRequest(BaseModel):
    user_id: str | None = None
    fcm_token: str
    lang: str = "ru"
    push_time: time
    signs: List[str]


class RegisterDeviceResponse(BaseModel):
    user_id: str


class HoroscopeItem(BaseModel):
    sign: str
    date: date
    lang: str
    title: str | None = None
    text: str


class HoroscopeTodayResponse(BaseModel):
    items: List[HoroscopeItem]


class HealthResponse(BaseModel):
    status: str
