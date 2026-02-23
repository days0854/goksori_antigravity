"""
주식 데이터 수집 및 감성분석 태스크
- 코스피 200 종목 리스트 업데이트
- 네이버 토론방 크롤링 및 감성분석
- DB 저장
"""
import logging
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
import time

from ..crawler.kospi200 import Kospi200Manager
from ..crawler.naver_crawler import NaverDiscussCrawler
from ..sentiment.analyzer import RuleBasedSentimentAnalyzer, SentimentAggregator, GoksoriIndexCalculator
from ..db.session import SessionLocal
from ..models.stock import Stock, Comment, SentimentScore, CommentSentiment

logger = logging.getLogger(__name__)

class StocksTask:
    def __init__(self, db: Session = None):
        self.db = db or SessionLocal()
        self.crawler_manager = Kospi200Manager()
        self.sentiment_analyzer = RuleBasedSentimentAnalyzer()
        self.aggregator = SentimentAggregator()
        self.goksori_calculator = GoksoriIndexCalculator()

    def update_stocks_and_sentiment(self, max_stocks: int = 200):
        """전체 종목 업데이트 메인 로직"""
        try:
            logger.info("🚀 주식 데이터 업데이트 시작...")
            
            # 1. 코스피 200 목록 가져오기
            stock_list = self.crawler_manager.get_stock_list()
            logger.info(f"📋 코스피200 {len(stock_list)}개 종목 확인됨")

            # 2. DB에 종목 마스터 데이터 싱크
            self._sync_stocks(stock_list)

            # 3. 각 종목별 크롤링 및 점수 계산
            # 서버 부하를 고려하여 순차적으로 진행
            for idx, stock_info in enumerate(stock_list[:max_stocks]):
                try:
                    self._process_single_stock(stock_info)
                    # 각 종목 사이 딜레이 (Naver 차단 방지)
                    time.sleep(1)
                except Exception as e:
                    logger.error(f"❌ {stock_info.name}({stock_info.code}) 처리 실패: {e}")
                    continue

            logger.info("✅ 주식 데이터 업데이트 완료")
        finally:
            self.db.close()

    def _sync_stocks(self, stock_list):
        """DB의 stocks 테이블과 네이버 목록 싱크"""
        for s in stock_list:
            existing = self.db.query(Stock).filter(Stock.code == s.code).first()
            if not existing:
                new_stock = Stock(code=s.code, name=s.name, market=s.market)
                self.db.add(new_stock)
        self.db.commit()

    def _process_single_stock(self, stock_info):
        """개별 종목 크롤링, 분석, 저장"""
        logger.info(f"🔍 {stock_info.name}({stock_info.code}) 분석 중...")
        
        # 1. 댓글 크롤링
        with NaverDiscussCrawler(delay=0.5, max_pages=3) as crawler:
            comments_data = crawler.get_comments(stock_info.code, max_comments=50)

        if not comments_data:
            logger.warning(f"⚠️ {stock_info.name}: 수집된 댓글 없음")
            return

        # 2. 감성 분석
        sentiment_results = []
        db_stock = self.db.query(Stock).filter(Stock.code == stock_info.code).one()
        
        for c_data in comments_data:
            # 2.1 댓글 저장
            new_comment = Comment(
                stock_id=db_stock.id,
                source=c_data.source,
                content=c_data.content,
                author=c_data.author,
                likes=c_data.likes,
                dislikes=c_data.dislikes,
                original_url=c_data.original_url
            )
            self.db.add(new_comment)
            self.db.flush() # ID 생성을 위해 flush

            # 2.2 개별 댓글 감성분석
            result = self.sentiment_analyzer.analyze(c_data.content)
            sentiment_results.append(result)

            # 2.3 분석 결과 저장
            new_sentiment = CommentSentiment(
                comment_id=new_comment.id,
                score=result.score,
                label=result.label,
                confidence=result.confidence
            )
            self.db.add(new_sentiment)

        # 3. 종목 단위 집계
        agg_result = self.aggregator.aggregate(sentiment_results)
        
        # 4. 곡소리 지수 계산
        # 변동성은 단순 목업으로 20~50 사이 랜덤 (실제 구현시 과거 데이터 비교 필요)
        import random
        volatility = random.uniform(20, 50)
        
        goksori_data = self.goksori_calculator.calculate(
            negative_count=agg_result["negative_count"],
            total_count=agg_result["total_count"],
            volatility=volatility,
            recent_trend=agg_result["trend"]
        )

        # 5. 집계 결과 저장
        new_score = SentimentScore(
            stock_id=db_stock.id,
            score=goksori_data["goksori_score"],
            positive_count=agg_result["positive_count"],
            negative_count=agg_result["negative_count"],
            neutral_count=agg_result["neutral_count"],
            total_count=agg_result["total_count"],
            trend=agg_result["trend"],
            period_start=datetime.now() - timedelta(hours=4),
            period_end=datetime.now()
        )
        self.db.add(new_score)
        
        # 6. 커밋
        self.db.commit()
        logger.info(f"✅ {stock_info.name} 업데이트 완료: 지수 {goksori_data['goksori_score']}")

def run_update():
    """스케줄러에서 호출할 함수"""
    task = StocksTask()
    task.update_stocks_and_sentiment()

if __name__ == "__main__":
    # 수동 실행용
    logging.basicConfig(level=logging.INFO)
    run_update()
