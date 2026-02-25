"""
곡소리매매법 FastAPI 메인 앱
"""
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
import logging
from contextlib import asynccontextmanager

from .config import get_settings
from .db.session import engine
from .models.base import Base
# 모든 모델을 임포트하여 Base.metadata에 등록되도록 함
from .models.stock import Stock, Comment, SentimentScore, CommentSentiment
import datetime

settings = get_settings()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ─── 스케줄러 설정 ─────────────────────────────────────────────────────────────
from apscheduler.schedulers.background import BackgroundScheduler
from .tasks.stocks_task import run_update

scheduler = BackgroundScheduler()

from fastapi import BackgroundTasks

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 시작 시 실행
    logger.info("🚀 애플리케이션 시작...")
    
    if settings.app_env == "production" or True: # 테스트를 위해 일단 항상 활성화
        logger.info("🛠️ 데이터베이스 테이블 생성/확인 중...")
        Base.metadata.create_all(bind=engine)
        
        logger.info(f"⏰ 스케줄러 가동: {settings.crawl_interval_hours}시간 간격")
        scheduler.add_job(
            run_update, 
            "interval", 
            hours=settings.crawl_interval_hours,
            id="stocks_update",
            replace_existing=True
        )
        # 서버 시작 시 즉시 한 번 실행 (데이터가 없을 수 있으므로 10초 뒤 실행)
        scheduler.add_job(
            run_update, 
            "date", 
            run_date=datetime.datetime.now() + datetime.timedelta(seconds=10),
            id="stocks_update_initial"
        )
        scheduler.start()
    
    yield
    
    # 종료 시 실행
    logger.info("🛑 애플리케이션 종료...")
    if scheduler.running:
        scheduler.shutdown()

# ─── FastAPI 앱 초기화 ────────────────────────────────────────────────────────
app = FastAPI(
    title=settings.app_name,
    description="코스피200 종목 감성분석 기반 매매 시그널 서비스",
    version="0.1.0",
    docs_url="/api/docs" if settings.debug else None,
    lifespan=lifespan,
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 실무에서는 구체적인 도메인 지정을 권장하지만, 현재 문제를 해결하기 위해 우선 모두 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 정적 파일 / 템플릿
BASE_DIR = Path(__file__).parent.parent.parent
FRONTEND_DIR = BASE_DIR / "frontend"

app.mount(
    "/static",
    StaticFiles(directory=str(FRONTEND_DIR / "static")),
    name="static",
)
templates = Jinja2Templates(directory=str(FRONTEND_DIR / "templates"))

# ─── 라우터 등록 ──────────────────────────────────────────────────────────────
from .api import stocks, sentiment, share  # noqa: E402
app.include_router(stocks.router, prefix="/api/stocks", tags=["주식"])
app.include_router(sentiment.router, prefix="/api/sentiment", tags=["감성분석"])
app.include_router(share.router, prefix="/api/share", tags=["공유"])


# ─── 페이지 라우트 ─────────────────────────────────────────────────────────────
@app.get("/")
async def index(request: Request):
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "title": "곡소리 매매법",
            "adsense_client_id": settings.adsense_client_id,
            "kakao_js_key": settings.kakao_js_key,
        },
    )


@app.get("/en")
async def index_en(request: Request):
    return templates.TemplateResponse(
        "en/index.html",
        {
            "request": request,
            "title": "Goksori Index - Market Sentiment",
            "adsense_client_id": settings.adsense_client_id,
            "kakao_js_key": settings.kakao_js_key,
        },
    )


@app.get("/stock/{stock_code}")
async def stock_detail(request: Request, stock_code: str):
    return templates.TemplateResponse(
        "stock_detail.html",
        {
            "request": request,
            "stock_code": stock_code,
            "title": f"곡소리 매매법 - {stock_code}",
        },
    )


@app.get("/health")
async def health_check():
    return {"status": "ok", "service": settings.app_name}


@app.post("/api/admin/refresh")
async def manual_refresh(background_tasks: BackgroundTasks):
    """데이터 수집 및 분석 태스크 수동 실행"""
    logger.info("📢 수동 업데이트 요청됨")
    background_tasks.add_task(run_update)
    return {"message": "Update task started in background"}
