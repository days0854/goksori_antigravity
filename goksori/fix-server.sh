#!/bin/bash

# 서버 수정 및 재설정 스크립트
echo "=== GOKSORI SERVER FIX SCRIPT ==="
echo ""

# SSH 설정 복구 및 재설정
echo "Step 1: Fixing SSH Configuration..."
echo "======================================="

# sshd_config 복원 (손상 방지)
echo "Restoring sshd_config from backup..."
sudo cp /etc/ssh/sshd_config.d/50-cloud-init.conf /etc/ssh/sshd_config

# SSH 필수 설정
echo "Applying SSH settings..."
sudo sed -i '/^Port /d' /etc/ssh/sshd_config
sudo sed -i '/^PermitRootLogin /d' /etc/ssh/sshd_config
sudo sed -i '/^PasswordAuthentication /d' /etc/ssh/sshd_config

# 새로운 설정 추가
echo "Port 22" | sudo tee -a /etc/ssh/sshd_config > /dev/null
echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null

# SSH 설정 검증
echo "Validating SSH config..."
sudo sshd -t && echo "SSH config OK" || echo "SSH config ERROR"

# SSH 재시작
echo "Restarting SSH service..."
sudo systemctl restart ssh

echo ""
echo "Step 2: Checking uvicorn and application..."
echo "============================================"

# uvicorn 프로세스 확인
echo "Checking for running uvicorn processes..."
sudo pkill -f uvicorn || echo "No uvicorn process to kill"
sleep 1

# 실제 앱 구조 확인
echo "Checking application structure..."
if [ -f /root/goksori/backend/app/main.py ]; then
    echo "Found app at /root/goksori/backend/app/main.py"
    APP_PATH="/root/goksori/backend"
    APP_MODULE="app.main:app"
elif [ -f /root/goksori/main.py ]; then
    echo "Found temporary app at /root/goksori/main.py"
    APP_PATH="/root/goksori"
    APP_MODULE="main:app"
else
    echo "ERROR: Application not found!"
    exit 1
fi

# uvicorn 시작
echo "Starting uvicorn..."
cd "$APP_PATH"
nohup python3 -m uvicorn $APP_MODULE --host 0.0.0.0 --port 8000 > uvicorn.log 2>&1 &
sleep 2

# uvicorn 프로세스 확인
echo "Checking if uvicorn started..."
ps aux | grep uvicorn | grep -v grep && echo "Uvicorn is running" || echo "Uvicorn failed to start"

echo ""
echo "Step 3: Checking nginx configuration..."
echo "========================================="

# nginx 설정 확인
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "Nginx default config found"

    # proxy_pass 설정 확인
    if grep -q "proxy_pass" /etc/nginx/sites-enabled/default; then
        echo "Proxy pass is configured"
        grep "proxy_pass" /etc/nginx/sites-enabled/default
    else
        echo "WARNING: proxy_pass not found in nginx config"
        echo "This might cause 502 errors"
    fi

    # nginx 설정 테스트
    echo "Testing nginx config..."
    sudo nginx -t
else
    echo "Nginx default config not found"
fi

echo ""
echo "Step 4: Restarting nginx..."
echo "============================"
sudo systemctl restart nginx

echo ""
echo "=== FIX SCRIPT COMPLETE ==="
echo ""
echo "Next steps:"
echo "1. Try accessing https://goksori.net"
echo "2. Try SSH: ssh -v root@your.server.ip"
echo "3. Check logs if issues persist"
