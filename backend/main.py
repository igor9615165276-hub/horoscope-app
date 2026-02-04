from fastapi import FastAPI
from .database import Base, engine
from .schemas import HealthResponse

Base.metadata.create_all(bind=engine)

app = FastAPI()

@app.get("/health", response_model=HealthResponse)
def health():
    return HealthResponse(status="ok")
