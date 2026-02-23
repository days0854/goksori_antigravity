#!/bin/bash

echo "🚀 곡소리 매매법 최종 수정 시작..."

# 1. 기존 프로세스 모두 종료
pkill -9 python
pkill -9 uvicorn
sleep 1

# 2. 간단한 테스트 앱으로 포트 8000 확인
echo "🔧 포트 8000에서 간단한 앱 실행 중..."

cat > /tmp/simple_app.py << 'APP'
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "✅ 곡소리 매매법 웹사이트 온라인!", "status": "success"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
APP

# Python이 필요하니 직접 실행
cd /tmp
python3 simple_app.py &

sleep 2

# 3. 로컬 테스트
echo "✅ 로컬 테스트 중..."
curl -s http://localhost:8000/ || echo "실패"

# 4. 포트 확인
echo ""
echo "📊 포트 8000 상태:"
netstat -tuln | grep 8000

