#!/bin/bash

# 서버 진단 스크립트
echo "=== GOKSORI SERVER DIAGNOSTICS ==="
echo ""

# 1. SSH 설정 확인
echo "1. SSH Configuration Check:"
echo "----"
if [ -f /etc/ssh/sshd_config ]; then
    echo "SSH Config exists"
    echo "Port setting:"
    grep "^Port" /etc/ssh/sshd_config || echo "Port: NOT SET (using default 22)"
    echo "PermitRootLogin:"
    grep "^PermitRootLogin" /etc/ssh/sshd_config || echo "PermitRootLogin: NOT SET"
    echo "PasswordAuthentication:"
    grep "^PasswordAuthentication" /etc/ssh/sshd_config || echo "PasswordAuthentication: NOT SET"
else
    echo "SSH Config NOT FOUND"
fi
echo ""

# 2. SSH 서비스 상태
echo "2. SSH Service Status:"
echo "----"
systemctl status ssh --no-pager || echo "SSH service status check failed"
echo ""

# 3. Uvicorn 프로세스 확인
echo "3. Uvicorn Process Check:"
echo "----"
ps aux | grep uvicorn | grep -v grep || echo "No uvicorn process running"
echo ""

# 4. Port 8000 listening 확인
echo "4. Port 8000 Listening Check:"
echo "----"
netstat -tuln | grep 8000 || echo "Port 8000 not listening"
echo ""

# 5. Nginx 설정 확인
echo "5. Nginx Configuration:"
echo "----"
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "Upstream configuration:"
    grep -A 5 "upstream" /etc/nginx/sites-enabled/default || echo "No upstream found"
    echo ""
    echo "Proxy pass configuration:"
    grep "proxy_pass" /etc/nginx/sites-enabled/default || echo "No proxy_pass found"
else
    echo "Nginx default config NOT FOUND"
fi
echo ""

# 6. Nginx 에러 로그 최근 20줄
echo "6. Nginx Error Log (last 20 lines):"
echo "----"
if [ -f /var/log/nginx/error.log ]; then
    tail -20 /var/log/nginx/error.log
else
    echo "Nginx error log NOT FOUND"
fi
echo ""

# 7. Uvicorn 로그 확인
echo "7. Uvicorn Log Status:"
echo "----"
if [ -f /root/goksori/uvicorn.log ]; then
    echo "Uvicorn log exists. Last 20 lines:"
    tail -20 /root/goksori/uvicorn.log
else
    echo "Uvicorn log NOT FOUND"
fi
echo ""

# 8. /root/goksori 디렉토리 내용
echo "8. /root/goksori Contents:"
echo "----"
ls -la /root/goksori/ 2>/dev/null || echo "Directory not accessible"
echo ""

echo "=== END DIAGNOSTICS ==="
