# ⚡ 곡소리 매매법 - 빠른 배포 가이드 (5분)

## 🎯 목표
NCP 서버(223.130.136.16)에 곡소리 애플리케이션을 5분 안에 배포하기

---

## 📋 사전 준비

✅ **필요한 것:**
- SSH 클라이언트 (Windows: PuTTY/WSL, Mac/Linux: 기본 터미널)
- NCP 서버 정보:
  - IP: `223.130.136.16`
  - 포트: `22`
  - 사용자: `root`
  - 비밀번호: `U4*G!@m*86Te7cu`

---

## 🚀 배포 단계

### Step 1️⃣: 프로젝트 압축 (로컬)

```bash
cd /sessions/charming-keen-ptolemy/mnt/goksori

# 압축 파일 생성
tar --exclude='__pycache__' --exclude='.pytest_cache' --exclude='venv' \
    -czf goksori-deploy.tar.gz backend frontend docs scripts config

# 파일 확인
ls -lh goksori-deploy.tar.gz
```

**출력 예:**
```
-rw-r--r-- 1 user user 44K Feb 20 goksori-deploy.tar.gz
```

---

### Step 2️⃣: NCP 서버 접속

#### Windows (CMD 또는 PowerShell)
```powershell
ssh -p 22 root@223.130.136.16
# 비밀번호 입력: U4*G!@m*86Te7cu
```

#### Mac/Linux
```bash
ssh -p 22 root@223.130.136.16
# 비밀번호 입력: U4*G!@m*86Te7cu
```

---

### Step 3️⃣: 파일 업로드 (로컬 터미널에서 별도 창)

```bash
# 프로젝트 디렉토리에서 파일 업로드
scp -P 22 goksori-deploy.tar.gz root@223.130.136.16:/tmp/

# 비밀번호 입력: U4*G!@m*86Te7cu
```

---

### Step 4️⃣: NCP 서버에서 배포 (SSH 연결된 터미널)

#### 1. 시스템 업데이트
```bash
apt-get update
apt-get install -y python3.10 python3-pip git nginx curl
```

#### 2. 프로젝트 준비
```bash
rm -rf /home/goksori
mkdir -p /home/goksori
cd /home/goksori
tar -xzf /tmp/goksori-deploy.tar.gz
ls -la
```

**확인:** `backend`, `frontend`, `docs`, `scripts`, `config` 폴더가 보여야 함

#### 3. Python 환경 설정
```bash
cd /home/goksori/backend
python3.10 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

**진행 시간:** 약 2-3분

#### 4. 환경 설정 파일 생성
```bash
cat > config/.env << 'EOF'
DATABASE_URL=postgresql://days:Project0423!@projectabout-001-8tq0.vpc.nclouddb.com:5432/goksori_db
APP_NAME=곡소리매매법
APP_ENV=production
DEBUG=false
SECRET_KEY=goksori-secret-$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
CRAWL_INTERVAL_HOURS=4
MAX_COMMENTS_PER_STOCK=100
REQUEST_DELAY_SECONDS=1
EOF

cat config/.env
```

#### 5. Systemd 서비스 등록
```bash
cat > /etc/systemd/system/goksori.service << 'EOF'
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
EOF

systemctl daemon-reload
systemctl enable goksori
```

#### 6. Nginx 리버스 프록시 설정
```bash
cat > /etc/nginx/sites-available/goksori << 'EOF'
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
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/goksori /etc/nginx/sites-enabled/goksori
nginx -t
systemctl restart nginx
```

#### 7. 서비스 시작
```bash
systemctl start goksori
sleep 3
systemctl status goksori
```

**예상 출력:**
```
● goksori.service - Goksori Trading Signal Service
     Loaded: loaded (/etc/systemd/system/goksori.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2026-02-20 09:15:00 UTC; 2s ago
```

---

## 🔍 배포 확인

### ✅ 방법 1: 로컬에서 헬스 체크

```bash
curl http://223.130.136.16/health
```

**예상 응답:**
```json
{"status":"ok"}
```

### ✅ 방법 2: 웹사이트 접속

브라우저에서 아래 주소로 접속:

```
http://223.130.136.16
```

**보이는 것:**
- 헤더: "곡소리 매매법" 로고
- 통계 바: 5개의 KPI
- 메인 테이블: 50개 코스피200 종목
- 각 종목별: 감성점수, 등급, 업데이트 시간

### ✅ 방법 3: API 문서 확인

```
http://223.130.136.16/api/docs
```

Swagger UI에서 모든 API를 테스트할 수 있습니다.

---

## 📊 실시간 로그 확인

NCP 서버에서:

```bash
# 실시간 로그 보기 (Ctrl+C로 종료)
journalctl -u goksori -f

# 최근 50줄 로그
journalctl -u goksori -n 50

# 에러만 보기
journalctl -u goksori | grep -i error
```

---

## 🛠️ 문제 해결

### 문제 1: 서비스가 시작되지 않음
```bash
systemctl status goksori
journalctl -u goksori -n 20
```

### 문제 2: 포트 8000 이미 사용 중
```bash
lsof -i :8000
kill -9 <PID>
systemctl restart goksori
```

### 문제 3: DB 연결 오류
```bash
# .env 파일 확인
cat config/.env | grep DATABASE_URL

# DB 연결 테스트
psql postgresql://days:Project0423!@projectabout-001-8tq0.vpc.nclouddb.com:5432/goksori_db
```

### 문제 4: Nginx 오류
```bash
nginx -t
systemctl restart nginx
tail -f /var/log/nginx/error.log
```

---

## 📝 배포 완료 체크리스트

배포 후 다음을 확인하세요:

- [ ] 웹사이트 접속 가능 (`http://223.130.136.16`)
- [ ] 헬스 체크 성공 (`curl http://223.130.136.16/health`)
- [ ] API 문서 확인 (`http://223.130.136.16/api/docs`)
- [ ] 종목 데이터 표시됨 (50개 행)
- [ ] 차트/모달 기능 작동함
- [ ] 로그에 에러 없음 (`journalctl -u goksori`)

---

## 🔄 자주 사용하는 명령어

```bash
# 서비스 재시작
systemctl restart goksori

# 서비스 중지
systemctl stop goksori

# 서비스 시작
systemctl start goksori

# 서비스 상태 확인
systemctl status goksori

# 전체 시스템 리소스 확인
top

# 메모리 사용량
free -h

# 디스크 사용량
df -h
```

---

## ⏱️ 시간 예상

| 단계 | 소요 시간 |
|------|---------|
| 압축 | 10초 |
| 파일 업로드 | 10초 |
| 시스템 업데이트 | 30초 |
| Python 환경 | 2-3분 |
| 설정 파일 | 5초 |
| Systemd/Nginx | 5초 |
| 서비스 시작 | 3초 |
| **총 소요 시간** | **약 4-5분** |

---

## 🎉 배포 완료!

축하합니다! 이제 곡소리 매매법이 실시간으로 운영되고 있습니다.

**다음 단계:**

1. **모니터링**: `journalctl -u goksori -f` 로 실시간 로그 확인
2. **백업**: 정기적으로 DB 백업 설정
3. **SSL**: Let's Encrypt로 HTTPS 설정
4. **도메인**: 도메인 연결 (현재는 IP 접속)

---

**생성일:** 2026-02-20
**프로젝트:** 곡소리 매매법
**상태:** ✅ 배포 준비 완료
