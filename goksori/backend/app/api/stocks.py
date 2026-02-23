"""
주식 목록 API
GET /api/stocks/       - 코스피200 전체 목록 + 곡소리 지수
GET /api/stocks/{code} - 특정 종목 상세 (댓글, 공시, 차트)
"""
from fastapi import APIRouter, Query, Depends
from typing import Optional, List
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.sentiment.analyzer import GoksoriIndexCalculator
from app.db.session import get_db
from app.models.stock import Stock, SentimentScore, Comment

router = APIRouter()


def _transform_stock_data(stock: Stock, score: Optional[SentimentScore]) -> dict:
    """DB 모델 데이터를 API 응답 포맷으로 변환"""
    
    # 점수가 없는 경우 기본값
    if not score:
        return {
            "code": stock.code,
            "name": stock.name,
            "goksori_score": 0.0,
            "goksori_grade": "데이터 없음",
            "goksori_components": {},
            "trend": "neutral",
            "positive_count": 0,
            "negative_count": 0,
            "neutral_count": 0,
            "total_count": 0,
            "volatility": 0.0,
            "score_history": [],
            "updated_at": stock.updated_at.isoformat() if stock.updated_at else None,
        }

    # 곡소리급 평점/지수 재계산 (표시용)
    # 실제 등급 판정은 모델 대신 계산기 재사용
    goksori_data = GoksoriIndexCalculator.calculate(
        negative_count=score.negative_count,
        total_count=score.total_count,
        volatility=20.0, # 서버측 변동성 로직 고도화 전까지 고정값
        recent_trend=score.trend
    )

    return {
        "code": stock.code,
        "name": stock.name,
        "goksori_score": score.score,
        "goksori_grade": goksori_data["goksori_grade"],
        "goksori_components": goksori_data["components"],
        "trend": score.trend,
        "positive_count": score.positive_count,
        "negative_count": score.negative_count,
        "neutral_count": score.neutral_count,
        "total_count": score.total_count,
        "volatility": 0.0, # TODO: 실데이터 반영
        "score_history": [], # TODO: 이력 쿼리 추가
        "updated_at": score.created_at.isoformat() if score.created_at else None,
    }


@router.get("/")
async def get_stocks(
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
    sort: str = Query("goksori_desc", pattern="^(goksori_desc|goksori_asc|name)$"),
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    코스피200 종목 목록 + 곡소리 지수 (실시간 DB 데이터)
    """
    # 기본 쿼리: 종목과 최신 점수를 조인
    query = db.query(Stock)
    
    if search:
        search_filter = f"%{search}%"
        query = query.filter((Stock.name.ilike(search_filter)) | (Stock.code.ilike(search_filter)))

    # 전체 개수 확인
    total = query.count()

    # 정렬 및 페이징 (성능을 위해 스코어 테이블과 아우터 조인)
    from sqlalchemy import select, outerjoin
    
    # 최신 점수만 가져오기 위한 서브쿼리 (Stock별 최신 SentimentScore ID)
    from sqlalchemy import func
    subq = db.query(
        SentimentScore.stock_id,
        func.max(SentimentScore.id).label("max_id")
    ).group_by(SentimentScore.stock_id).subquery()

    # 메인 쿼리 재정의
    query = db.query(Stock, SentimentScore).outerjoin(
        subq, Stock.id == subq.c.stock_id
    ).outerjoin(
        SentimentScore, SentimentScore.id == subq.c.max_id
    )

    if search:
        query = query.filter((Stock.name.ilike(f"%{search}%")) | (Stock.code.ilike(f"%{search}%")))

    # 정렬 적용
    if sort == "goksori_desc":
        query = query.order_by(desc(SentimentScore.score))
    elif sort == "goksori_asc":
        query = query.order_by(SentimentScore.score)
    elif sort == "name":
        query = query.order_by(Stock.name)

    # 페이징 적용
    results = query.offset((page - 1) * size).limit(size).all()

    stocks_data = [_transform_stock_data(s, sc) for s, sc in results]

    return {
        "total": total,
        "page": page,
        "size": size,
        "stocks": stocks_data,
    }


@router.get("/{stock_code}")
async def get_stock_detail(stock_code: str, db: Session = Depends(get_db)):
    """특정 종목 상세 정보 (DB 데이터)"""
    stock = db.query(Stock).filter(Stock.code == stock_code).first()
    if not stock:
        return {"error": "Stock not found"}

    # 최신 점수
    latest_score = db.query(SentimentScore).filter(
        SentimentScore.stock_id == stock.id
    ).order_by(desc(SentimentScore.id)).first()

    base_data = _transform_stock_data(stock, latest_score)

    # 최근 댓글 (최신 30개)
    recent_comments = db.query(Comment).filter(
        Comment.stock_id == stock.id
    ).order_by(desc(Comment.id)).limit(30).all()

    formatted_comments = [
        {
            "id": c.id,
            "content": c.content,
            "author": c.author,
            "likes": c.likes,
            "sentiment": "unknown", # TODO: CommentSentiment 조인
            "source": c.source,
            "crawled_at": c.crawled_at.isoformat() if c.crawled_at else None,
        }
        for c in recent_comments
    ]

    # 최근 7일 이력
    history = db.query(SentimentScore).filter(
        SentimentScore.stock_id == stock.id
    ).order_by(desc(SentimentScore.id)).limit(20).all()
    
    score_history = [
        {
            "date": s.created_at.strftime("%Y-%m-%d %H:%M") if s.created_at else "",
            "goksori_score": s.score
        }
        for s in history
    ][::-1] # 시간순 정렬

    return {
        **base_data,
        "comments": formatted_comments,
        "score_history": score_history,
        "sources": ["naver_discuss"],
        "dart_url": f"https://dart.fss.or.kr/dsearch/main.do?rcpNo=&textCrpCik={stock_code}",
    }
