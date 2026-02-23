"""
주식 목록 API
GET /api/stocks/       - 코스피200 전체 목록 + 곡소리 지수
GET /api/stocks/{code} - 특정 종목 상세 (댓글, 공시, 차트)
"""
from fastapi import APIRouter, Query
from typing import Optional
import random
from datetime import datetime
from app.sentiment.analyzer import GoksoriIndexCalculator

router = APIRouter()


def _mock_sentiment_data(stock_code: str, stock_name: str) -> dict:
    """
    개발용 목업 데이터 (실제 DB 연결 전까지 사용)
    종목코드 기반 일관된 랜덤값으로 곡소리 지수 계산
    """
    # 종목코드를 시드로 사용해 일관된 랜덤값 생성
    random.seed(hash(stock_code) % 10000)

    # 댓글 수 생성
    pos = random.randint(10, 80)
    neg = random.randint(5, 60)
    neu = random.randint(5, 40)
    total = pos + neg + neu

    # 변동성 (0~100)
    volatility = random.uniform(5, 40)

    # 추세
    trend_rand = random.random()
    trend = "down" if trend_rand < 0.4 else "up" if trend_rand > 0.6 else "neutral"

    # 곡소리 지수 계산
    goksori_data = GoksoriIndexCalculator.calculate(
        negative_count=neg,
        total_count=total,
        volatility=volatility,
        recent_trend=trend
    )

    # 최근 7일 점수 변동
    score_history = []
    base_goksori = goksori_data["goksori_score"]
    for i in range(7, 0, -1):
        score_history.append({
            "date": f"2026-02-{20-i:02d}",
            "goksori_score": round(max(0, min(100, base_goksori + random.uniform(-15, 15))), 1),
        })

    return {
        "code": stock_code,
        "name": stock_name,
        "goksori_score": goksori_data["goksori_score"],  # 곡소리 지수 (높을수록 위험)
        "goksori_grade": goksori_data["goksori_grade"],  # 위험 등급
        "goksori_components": goksori_data["components"],  # 상세 구성요소
        "trend": trend,
        "positive_count": pos,
        "negative_count": neg,
        "neutral_count": neu,
        "total_count": total,
        "volatility": round(volatility, 1),
        "score_history": score_history,
        "updated_at": datetime.now().isoformat(),
    }


# 코스피200 샘플 목록
SAMPLE_STOCKS = [
    ("005930", "삼성전자"), ("000660", "SK하이닉스"), ("207940", "삼성바이오로직스"),
    ("005380", "현대차"), ("068270", "셀트리온"), ("035420", "NAVER"),
    ("051910", "LG화학"), ("006400", "삼성SDI"), ("003550", "LG"),
    ("028260", "삼성물산"), ("012330", "현대모비스"), ("035720", "카카오"),
    ("055550", "신한지주"), ("373220", "LG에너지솔루션"), ("096770", "SK이노베이션"),
    ("003490", "대한항공"), ("034730", "SK"), ("105560", "KB금융"),
    ("086790", "하나금융지주"), ("030200", "KT"), ("017670", "SK텔레콤"),
    ("032830", "삼성생명"), ("009150", "삼성전기"), ("018260", "삼성에스디에스"),
    ("066570", "LG전자"), ("000270", "기아"), ("011200", "HMM"),
    ("316140", "우리금융지주"), ("015760", "한국전력"), ("032640", "LG유플러스"),
    ("000100", "유한양행"), ("011170", "롯데케미칼"), ("024110", "기업은행"),
    ("078930", "GS"), ("036570", "엔씨소프트"), ("010950", "S-Oil"),
    ("000810", "삼성화재"), ("011790", "SKC"), ("009540", "한국조선해양"),
    ("042660", "한화오션"), ("047050", "포스코인터내셔널"), ("000120", "CJ대한통운"),
    ("010140", "삼성중공업"), ("021240", "코웨이"), ("161390", "한국타이어앤테크놀로지"),
    ("004020", "현대제철"), ("005945", "NH투자증권"), ("034020", "두산에너빌리티"),
    ("009900", "OCI"), ("029780", "삼성카드"),
]


@router.get("/")
async def get_stocks(
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
    sort: str = Query("goksori_desc", pattern="^(goksori_desc|goksori_asc|name)$"),
    search: Optional[str] = None,
):
    """
    코스피200 종목 목록 + 곡소리 지수
    - page/size: 페이지네이션
    - sort: 정렬 기준 (기본값: goksori_desc - 곡소리 높은 순)
      * goksori_desc: 곡소리 지수 높은 순 (위험한 종목 우선)
      * goksori_asc: 곡소리 지수 낮은 순 (안전한 종목 우선)
      * name: 종목명 가나다순
      * trend_up: 상승 추세 우선
      * trend_down: 하락 추세 우선
    - search: 종목명/코드 검색
    """
    stocks = [_mock_sentiment_data(code, name) for code, name in SAMPLE_STOCKS]

    # 검색 필터
    if search:
        search = search.strip().lower()
        stocks = [s for s in stocks if search in s["name"].lower() or search in s["code"]]

    # 정렬 (기본값: 곡소리 지수 높은 순 = 부정 여론 많은 순)
    if sort == "goksori_desc":
        stocks.sort(key=lambda x: x["goksori_score"], reverse=True)  # 곡소리 높은 순 (1위 = 가장 위험)
    elif sort == "goksori_asc":
        stocks.sort(key=lambda x: x["goksori_score"])  # 곡소리 낮은 순 (안전한 순)
    elif sort == "name":
        stocks.sort(key=lambda x: x["name"])
    elif sort == "trend_up":
        stocks = [s for s in stocks if s["trend"] == "up"] + \
                 [s for s in stocks if s["trend"] != "up"]
    elif sort == "trend_down":
        stocks = [s for s in stocks if s["trend"] == "down"] + \
                 [s for s in stocks if s["trend"] != "down"]

    # 페이지네이션
    total = len(stocks)
    start = (page - 1) * size
    end = start + size
    paginated = stocks[start:end]

    return {
        "total": total,
        "page": page,
        "size": size,
        "stocks": paginated,
    }


@router.get("/{stock_code}")
async def get_stock_detail(stock_code: str):
    """특정 종목 상세 정보 (곡소리 지수 포함)"""
    # 종목명 찾기
    stock_name = next((name for code, name in SAMPLE_STOCKS if code == stock_code), stock_code)

    base_data = _mock_sentiment_data(stock_code, stock_name)

    # 최근 댓글 목업 (곡소리 지수에 기반한 감성)
    random.seed(hash(stock_code) % 10000 + 1)
    goksori_score = base_data["goksori_score"]

    # 곡소리 점수가 높을수록 부정 댓글이 많도록
    neg_ratio = goksori_score / 100
    mock_comments = [
        {
            "id": i,
            "content": f"{'부정 의견: 조심해야함' if random.random() < neg_ratio else '긍정 의견: 이 종목 좋아보임' if random.random() < 0.5 else '중립: 지켜봐야할듯'}",
            "author": f"투자자{i:03d}",
            "likes": random.randint(0, 50),
            "sentiment": "negative" if random.random() < neg_ratio else "positive" if random.random() < 0.5 else "neutral",
            "source": "naver_discuss",
            "crawled_at": datetime.now().isoformat(),
        }
        for i in range(1, 21)
    ]

    return {
        **base_data,
        "comments": mock_comments,
        "sources": ["naver_discuss"],
        "dart_url": f"https://dart.fss.or.kr/dsearch/main.do?rcpNo=&textCrpCik={stock_code}",
    }
