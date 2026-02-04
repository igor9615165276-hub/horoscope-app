from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from datetime import date

from .database import Base, engine, SessionLocal
from .models import User, UserDevice, UserSign, Horoscope
from .schemas import (
    HealthResponse,
    RegisterDeviceRequest,
    RegisterDeviceResponse,
    HoroscopeTodayResponse,
    HoroscopeItem,
)

Base.metadata.create_all(bind=engine)

app = FastAPI()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/health", response_model=HealthResponse)
def health():
    return HealthResponse(status="ok")


@app.post("/register_device", response_model=RegisterDeviceResponse)
def register_device(payload: RegisterDeviceRequest, db: Session = Depends(get_db)):
    if payload.user_id:
        user = db.query(User).filter(User.id == payload.user_id).first()
    else:
        user = User()
        db.add(user)
        db.flush()

    device = (
        db.query(UserDevice)
        .filter(UserDevice.user_id == user.id, UserDevice.fcm_token == payload.fcm_token)
        .first()
    )
    if not device:
        device = UserDevice(
            user_id=user.id,
            fcm_token=payload.fcm_token,
            lang=payload.lang,
            push_time=payload.push_time,
        )
        db.add(device)
    else:
        device.lang = payload.lang
        device.push_time = payload.push_time

    db.query(UserSign).filter(UserSign.user_id == user.id).delete()
    for sign in payload.signs:
        db.add(UserSign(user_id=user.id, sign=sign))

    db.commit()
    return RegisterDeviceResponse(user_id=str(user.id))


@app.get("/horoscope/today", response_model=HoroscopeTodayResponse)
def get_today(user_id: str, lang: str = "ru", db: Session = Depends(get_db)):
    signs = db.query(UserSign).filter(UserSign.user_id == user_id).all()
    sign_names = [s.sign for s in signs]
    items_db = (
        db.query(Horoscope)
        .filter(
            Horoscope.sign.in_(sign_names),
            Horoscope.date == date.today(),
            Horoscope.lang == lang,
        )
        .all()
    )
    items = [
        HoroscopeItem(
            sign=it.sign,
            date=it.date,
            lang=it.lang,
            title=it.title,
            text=it.text,
        )
        for it in items_db
    ]
    return HoroscopeTodayResponse(items=items)
