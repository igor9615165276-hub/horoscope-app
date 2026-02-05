import uuid
from datetime import date, datetime, time
from typing import List, Optional
from uuid import UUID

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from .database import SessionLocal
from .models import User, UserDevice, UserSign, Horoscope

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ---------- Pydantic-схемы ----------

class RegisterDeviceRequest(BaseModel):
    user_id: Optional[UUID] = Field(None, description="UUID пользователя или null")
    fcm_token: str
    lang: str = "ru"
    push_time: str = "09:00"
    signs: List[str]


class RegisterDeviceResponse(BaseModel):
    user_id: UUID


class HoroscopeItem(BaseModel):
    sign: str
    title: Optional[str] = None
    text: str


# ---------- Вспомогательные функции ----------

def parse_push_time(push_time_str: str) -> time:
    try:
        return datetime.strptime(push_time_str, "%H:%M").time()
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid push_time format, expected HH:MM",
        )


# ---------- Эндпоинты ----------

@app.post("/register_device", response_model=RegisterDeviceResponse)
def register_device(payload: RegisterDeviceRequest, db: Session = Depends(get_db)):
    """
    Регистрирует пользователя и устройство, принимает FCM токен, язык, push_time и знаки.
    - Если user_id не передан или не найден, создаётся новый User.
    - Обновляется/создаётся UserDevice с указанным fcm_token.
    - Обновляются UserSign под пользователя.
    """
    user: Optional[User] = None

    if payload.user_id is not None:
        user = db.query(User).filter(User.id == payload.user_id).first()

    if user is None:
        user = User()
        db.add(user)
        db.flush()  # появляется user.id (UUID)

    push_time_value = parse_push_time(payload.push_time)

    device = (
        db.query(UserDevice)
        .filter(
            UserDevice.user_id == user.id,
            UserDevice.fcm_token == payload.fcm_token,
        )
        .first()
    )

    if device is None:
        device = UserDevice(
            user_id=user.id,
            fcm_token=payload.fcm_token,
            lang=payload.lang,
            push_time=push_time_value,
            last_push_date=None,
        )
        db.add(device)
    else:
        device.lang = payload.lang
        device.push_time = push_time_value

    db.query(UserSign).filter(UserSign.user_id == user.id).delete()
    for sign in payload.signs:
        db.add(UserSign(user_id=user.id, sign=sign))

    db.commit()
    db.refresh(user)

    return RegisterDeviceResponse(user_id=user.id)


@app.get("/horoscope/today", response_model=List[HoroscopeItem])
def get_today(
    user_id: UUID,
    lang: str = "ru",
    db: Session = Depends(get_db),
):
    """
    Возвращает список гороскопов на сегодня по выбранным знакам пользователя.
    user_id — UUID (как в users.id).
    Формат ответа: список объектов [{sign, title, text}, ...].
    """
    signs = db.query(UserSign).filter(UserSign.user_id == user_id).all()
    if not signs:
        return []

    today = date.today()
    sign_list = [s.sign for s in signs]

    horoscopes = (
        db.query(Horoscope)
        .filter(
            Horoscope.date == today,
            Horoscope.lang == lang,
            Horoscope.sign.in_(sign_list),
        )
        .all()
    )

    return [
        HoroscopeItem(
            sign=h.sign,
            title=h.title,
            text=h.text,
        )
        for h in horoscopes
    ]


@app.get("/ping")
def ping():
    return {"status": "ok"}
