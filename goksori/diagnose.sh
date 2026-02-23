#!/bin/bash

echo "🔍 곡소리 매매법 서버 진단 시작..."
echo ""

# 1. Python 프로세스 확인
echo "1️⃣ Python 프로세스 상태:"
ps aux | grep -i "python\|uvicorn" | grep -v grep || echo "   [프로세스 없음]"

echo ""
echo "2️⃣ 포트 8000 상태:"
netstat -tuln | grep 8000 || echo "   [포트 닫혀있음]"

echo ""
echo "3️⃣ Nginx 상태:"
systemctl status nginx 2>&1 | head -3 || echo "   [Nginx 확인 불가]"

echo ""
echo "4️⃣ 로컬 curl 테스트:"
curl -s http://localhost:8000/ | head -20 || echo "   [연결 실패]"

echo ""
echo "5️⃣ Nginx 설정 확인:"
cat /etc/nginx/sites-enabled/goksori 2>/dev/null || echo "   [설정 파일 없음]"

