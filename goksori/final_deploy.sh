#!/bin/bash

# 배포 디렉토리 생성 및 파일 다운로드
cd /tmp
wget -q http://172.16.0.190:8888/goksori-deploy.tar.gz -O goksori-deploy.tar.gz

# 압축 해제
rm -rf /home/goksori
mkdir -p /home/goksori
tar -xzf goksori-deploy.tar.gz -C /home/goksori

# 환경 설정 및 실행
cd /home/goksori/backend
python3 -m venv venv
source venv/bin/activate
pip install -q --upgrade pip setuptools wheel
pip install -q -r requirements.txt

# .env 파일 생성
mkdir -p config
cat > config/.env << 'ENVEOF'
DATABASE_URL=postgresql://days:Project0423!@projectabout-001-8tq0.vpc.nclouddb.com:5432/goksori_db
APP_NAME=곡소리매매법
APP_ENV=production
DEBUG=false
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
CRAWL_INTERVAL_HOURS=4
MAX_COMMENTS_PER_STOCK=100
REQUEST_DELAY_SECONDS=1
ENVEOF

echo "✅ 배포 준비 완료!"
echo "앱 실행: cd /home/goksori/backend && source venv/bin/activate && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
