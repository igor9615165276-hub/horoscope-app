import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./test.db")
FCM_CREDENTIALS_FILE = os.getenv("FCM_CREDENTIALS_FILE", "serviceAccountKey.json")
BASE_URL = os.getenv("BASE_URL", "http://localhost:8000")
