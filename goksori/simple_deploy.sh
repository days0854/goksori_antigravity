#!/bin/bash
set -e

echo "🚀 곡소리 배포 시작..."

# 1. 파일 준비
cd /tmp
if [ ! -f goksori-deploy.tar.gz ]; then
    echo "[!] 파일을 받을 수 없습니다. wget 재시도..."
    wget -q http://172.16.0.190:8888/goksori-deploy.tar.gz
fi

# 2. 압축 해제
echo "📂 파일 해제 중..."
rm -rf /home/goksori 2>/dev/null || true
mkdir -p /home/goksori
tar -xzf goksori-deploy.tar.gz -C /home/goksori

# 3. 백엔드 디렉토리로 이동
cd /home/goksori/backend

# 4. Python 환경 구성
echo "🐍 Python 환경 설정..."
python3 -m venv venv
source venv/bin/activate
pip install -q --upgrade pip setuptools wheel
pip install -q -r requirements.txt

# 5. 환경 변수 설정
echo "⚙️  환경 설정..."
mkdir -p config
SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

cat > config/.env << ENVEOF
DATABASE_URL=postgresql://days:Project0423!@projectabout-001-8tq0.vpc.nclouddb.com:5432/goksori_db
APP_NAME=곡소리매매법
APP_ENV=production
DEBUG=false
SECRET_KEY=$SECRET
CRAWL_INTERVAL_HOURS=4
MAX_COMMENTS_PER_STOCK=100
REQUEST_DELAY_SECONDS=1
ENVEOF

echo "✅ 배포 스크립트 준비 완료!"
echo "🌐 서비스 시작: python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
