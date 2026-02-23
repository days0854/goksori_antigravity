from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI()

@app.get("/")
def read_root():
    return HTMLResponse("""
    <html>
        <head>
            <title>곡소리 매매법 - 테스트 페이지</title>
            <style>
                body { font-family: Arial; margin: 50px; background: #f0f0f0; }
                .container { background: white; padding: 30px; border-radius: 10px; }
                h1 { color: #333; }
                .success { color: green; font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>✅ 곡소리 매매법 웹사이트</h1>
                <p class="success">FastAPI 앱이 정상 작동 중입니다!</p>
                <hr>
                <p><strong>서버:</strong> 223.130.136.16:8000</p>
                <p><strong>상태:</strong> 🟢 온라인</p>
                <hr>
                <h2>API 테스트</h2>
                <ul>
                    <li><a href="/api/docs">/api/docs - Swagger UI</a></li>
                    <li><a href="/health">/health - 헬스 체크</a></li>
                </ul>
            </div>
        </body>
    </html>
    """)

@app.get("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
