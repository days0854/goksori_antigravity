#!/bin/bash
set -e

echo "🚀 NCP 서버 배포 시작..."

# 1. 시스템 업데이트
echo "📦 패키지 설치..."
apt-get update > /dev/null 2>&1 || true
apt-get install -y python3.10 python3-pip git nginx curl > /dev/null 2>&1

# 2. 프로젝트 준비 (이미 /tmp에 있다고 가정)
echo "📂 프로젝트 파일 준비..."
rm -rf /home/goksori
mkdir -p /home/goksori
cd /home/goksori

# 배포 파일이 /tmp에 있으면 추출, 없으면 직접 다운로드
if [ -f /tmp/goksori-deploy.tar.gz ]; then
    tar -xzf /tmp/goksori-deploy.tar.gz
else
    echo "⚠️  파일을 /tmp에서 찾을 수 없습니다. 로컬에서 업로드 필요합니다."
fi

# 3. Python 환경 구성
echo "🐍 Python 환경 설정..."
cd /home/goksori/backend
python3.10 -m venv venv > /dev/null 2>&1
source venv/bin/activate
pip install --upgrade pip setuptools wheel > /dev/null 2>&1
pip install -r requirements.txt > /dev/null 2>&1

# 4. 환경 변수 설정
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

# 5. Systemd 서비스 등록
echo "🔧 Systemd 서비스 등록..."
cat > /etc/systemd/system/goksori.service << 'SVCEOF'
[Unit]
Description=Goksori Trading Signal Service
After=network.target

[Service]
Type=notify
User=root
WorkingDirectory=/home/goksori/backend
Environment="PATH=/home/goksori/backend/venv/bin"
ExecStart=/home/goksori/backend/venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVCEOF
systemctl daemon-reload
systemctl enable goksori > /dev/null 2>&1

# 6. Nginx 설정
echo "🌐 Nginx 리버스 프록시 설정..."
cat > /etc/nginx/sites-available/goksori << 'NGXEOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 10M;

    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
    }
}
NGXEOF
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/goksori /etc/nginx/sites-enabled/goksori
nginx -t > /dev/null 2>&1
systemctl restart nginx

# 7. 서비스 시작
echo "🚀 곡소리 서비스 시작..."
systemctl start goksori
sleep 3

if systemctl is-active --quiet goksori; then
    echo "✅ 서비스 정상 시작!"
else
    echo "❌ 서비스 시작 실패"
    journalctl -u goksori -n 20
    exit 1
fi

echo ""
echo "✅ 배포 완료!"
echo "🌐 웹사이트: http://223.130.136.16"
echo "📊 API 문서: http://223.130.136.16/api/docs"
echo "💊 헬스 체크: curl http://223.130.136.16/health"
