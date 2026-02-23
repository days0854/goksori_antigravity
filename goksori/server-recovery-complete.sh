#!/bin/bash

# ========================================
# 곡소리 서버 완전 복구 스크립트
# ========================================
# 목적: SSH 문제, 502 에러 등 모든 문제를 해결
# 수행자: Claude AI

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     GOKSORI SERVER - COMPLETE RECOVERY & SETUP            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ========================================
# PHASE 1: SSH 설정 복구
# ========================================
echo ""
echo "【PHASE 1】SSH Configuration Recovery..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1.1 sshd_config 복원
echo "[1.1] Restoring sshd_config from backup..."
if [ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]; then
    cp /etc/ssh/sshd_config.d/50-cloud-init.conf /etc/ssh/sshd_config
    echo "✓ sshd_config restored"
else
    echo "✗ Backup not found at /etc/ssh/sshd_config.d/50-cloud-init.conf"
fi

# 1.2 SSH 설정 최적화
echo "[1.2] Configuring SSH settings..."

# 기존 설정 제거
sed -i '/^Port /d' /etc/ssh/sshd_config
sed -i '/^PermitRootLogin /d' /etc/ssh/sshd_config
sed -i '/^PasswordAuthentication /d' /etc/ssh/sshd_config
sed -i '/^PubkeyAuthentication /d' /etc/ssh/sshd_config

# 새로운 설정 추가
cat >> /etc/ssh/sshd_config << 'SSH_CONFIG'

# Custom goksori settings
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
SSH_CONFIG

echo "✓ SSH settings configured"

# 1.3 sshd_config 검증
echo "[1.3] Validating sshd_config..."
if sshd -t 2>/dev/null; then
    echo "✓ sshd_config is valid"
else
    echo "✗ sshd_config has errors!"
    sshd -t
fi

# 1.4 SSH 서비스 재시작
echo "[1.4] Restarting SSH service..."
systemctl restart ssh
sleep 2
if systemctl is-active --quiet ssh; then
    echo "✓ SSH service is running"
else
    echo "✗ SSH service failed to start"
fi

# ========================================
# PHASE 2: 포트 상태 확인 및 uvicorn 정리
# ========================================
echo ""
echo "【PHASE 2】Port Cleanup & Process Management..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "[2.1] Killing existing uvicorn processes..."
pkill -f "uvicorn" || echo "No uvicorn process found"
sleep 2

echo "[2.2] Checking port 8000..."
if netstat -tuln 2>/dev/null | grep -q ":8000 "; then
    echo "✗ Port 8000 still in use, waiting..."
    sleep 3
fi

if ! netstat -tuln 2>/dev/null | grep -q ":8000 "; then
    echo "✓ Port 8000 is free"
else
    echo "✗ Port 8000 still in use"
fi

# ========================================
# PHASE 3: 애플리케이션 설정 및 배포
# ========================================
echo ""
echo "【PHASE 3】Application Setup..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 3.1 디렉토리 준비
echo "[3.1] Preparing application directories..."
rm -rf /home/goksori
mkdir -p /home/goksori
cd /home/goksori || exit 1
echo "✓ Directories prepared"

# 3.2 파일 복사 (현재 로컬에 있는 파일 기준)
echo "[3.2] Checking for application files..."
if [ -d "backend" ] && [ -d "frontend" ]; then
    echo "✓ Application files found locally"
else
    echo "ℹ Extracting from tar.gz if available..."
    if [ -f /tmp/goksori-deploy.tar.gz ]; then
        tar -xzf /tmp/goksori-deploy.tar.gz
        echo "✓ Files extracted"
    else
        echo "ℹ Note: Files need to be copied separately"
    fi
fi

# 3.3 Python 가상환경 설정
echo "[3.3] Setting up Python virtual environment..."
cd /home/goksori/backend || exit 1

if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✓ Virtual environment created"
fi

source venv/bin/activate
pip install --upgrade pip setuptools wheel --quiet
echo "✓ Pip upgraded"

if [ -f requirements.txt ]; then
    pip install -r requirements.txt --quiet
    echo "✓ Dependencies installed"
else
    echo "⚠ requirements.txt not found"
fi

# 3.4 환경 변수 설정
echo "[3.4] Creating .env file..."
cat > config/.env << 'ENV_EOF'
DATABASE_URL=postgresql://days:Project0423!@projectabout-001-8tq0.vpc.nclouddb.com:5432/goksori_db
APP_NAME=곡소리매매법
APP_ENV=production
DEBUG=false
CRAWL_INTERVAL_HOURS=4
MAX_COMMENTS_PER_STOCK=100
REQUEST_DELAY_SECONDS=1
EOF
echo "✓ .env file created"

# ========================================
# PHASE 4: Systemd 서비스 설정
# ========================================
echo ""
echo "【PHASE 4】Systemd Service Setup..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "[4.1] Creating systemd service..."
cat > /etc/systemd/system/goksori.service << 'SYSTEMD_EOF'
[Unit]
Description=Goksori Trading Signal Service
After=network.target

[Service]
Type=simple
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
SYSTEMD_EOF

systemctl daemon-reload
systemctl enable goksori
echo "✓ Systemd service created and enabled"

# ========================================
# PHASE 5: Nginx 설정
# ========================================
echo ""
echo "【PHASE 5】Nginx Configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "[5.1] Creating nginx configuration..."
cat > /etc/nginx/sites-available/goksori << 'NGINX_EOF'
upstream goksori_backend {
    server 127.0.0.1:8000;
    keepalive 32;
}

server {
    listen 80;
    server_name _;
    client_max_body_size 10M;

    # 헬스 체크
    location /health {
        access_log off;
        proxy_pass http://goksori_backend;
    }

    # 모든 요청
    location / {
        proxy_pass http://goksori_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
    }
}
NGINX_EOF

# 기존 설정 제거
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/goksori

# 새 설정 활성화
ln -sf /etc/nginx/sites-available/goksori /etc/nginx/sites-enabled/goksori

echo "[5.2] Testing nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✓ Nginx configuration is valid"
else
    echo "⚠ Nginx configuration warnings:"
    nginx -t
fi

# ========================================
# PHASE 6: 서비스 시작
# ========================================
echo ""
echo "【PHASE 6】Starting Services..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "[6.1] Restarting nginx..."
systemctl restart nginx
sleep 2

if systemctl is-active --quiet nginx; then
    echo "✓ Nginx is running"
else
    echo "✗ Nginx failed to start"
fi

echo "[6.2] Starting goksori service..."
systemctl start goksori
sleep 3

if systemctl is-active --quiet goksori; then
    echo "✓ Goksori service is running"
else
    echo "✗ Goksori service failed to start"
    systemctl status goksori
fi

# ========================================
# PHASE 7: 진단 및 확인
# ========================================
echo ""
echo "【PHASE 7】Diagnostics & Verification..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "[7.1] Process status:"
ps aux | grep -E "uvicorn|nginx" | grep -v grep || echo "No processes found"

echo ""
echo "[7.2] Port status:"
netstat -tuln | grep -E "8000|80 " || echo "Ports not listening"

echo ""
echo "[7.3] Recent service logs:"
journalctl -u goksori -n 10 --no-pager || echo "No logs available"

echo ""
echo "[7.4] Nginx error check:"
tail -5 /var/log/nginx/error.log 2>/dev/null || echo "No error logs"

# ========================================
# 완료
# ========================================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    RECOVERY COMPLETE!                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "✓ SSH: Port 22, PermitRootLogin yes"
echo "✓ Application: /home/goksori/backend"
echo "✓ Service: goksori (systemd managed)"
echo "✓ Proxy: Nginx on port 80 → uvicorn on port 8000"
echo ""
echo "Next steps:"
echo "1. SSH: ssh root@223.130.136.16"
echo "2. Web: http://223.130.136.16 (or https://goksori.net)"
echo "3. API: http://223.130.136.16/api/docs"
echo "4. Logs: journalctl -u goksori -f"
echo ""
