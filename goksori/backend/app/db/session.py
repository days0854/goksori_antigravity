"""DB 세션 관리"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from ..config import get_settings

settings = get_settings()
# SQLite 처리
engine_args = {
    "pool_pre_ping": True,
}

if settings.database_url.startswith("sqlite"):
    engine_args["connect_args"] = {"check_same_thread": False}
else:
    engine_args["pool_size"] = 5
    engine_args["max_overflow"] = 10

engine = create_engine(
    settings.database_url,
    **engine_args
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
