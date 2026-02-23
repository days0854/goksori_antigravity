# 🚀 곡소리 매매법 - NCP 배포 가이드

## 📋 현재 상태

- ✅ 프로젝트 개발 완료 (TDD 기반)
- ✅ 모든 테스트 통과
- ✅ NCP 서버 생성 완료 (IP: `223.130.136.16`)
- ✅ PostgreSQL DB 연결 완료
- 🔄 배포 진행 중...

---

## 📦 배포 파일 정보

| 항목 | 값 |
|------|-----|
| 서버 IP | `223.130.136.16` |
| SSH 포트 | `22` |
| SSH 사용자 | `root` |
| SSH 비밀번호 | `U4*G!@m*86Te7cu` |
| DB 호스트 | `projectabout-001-8tq0.vpc.nclouddb.com` |
| DB 이름 | `goksori_db` |
| DB 사용자 | `days` |
| DB 비밀번호 | `Project0423!` |

---

## 🎯 빠른 배포 (2가지 방법)

### 방법 1️⃣: 자동 배포 (권장)

#### Step 1: 로컬에서 압축 파일 생성
```bash
cd /sessions/charming-keen-ptolemy/mnt/goksori
tar --exclude='__pycache__' --exclude='.pytest_cache' --exclude='venv' \
    -czf goksori-deploy.tar.gz backend frontend docs scripts config
```

#### Step 2: 서버에 파일 업로드
```bash
# scp를 사용하여 파일 업로드
scp -P 22 goksori-deploy.tar.gz root@223.130.136.16:/tmp/

# 또는 SSH 터미널에서 파일 업로드 후 실행
```

#### Step 3: 서버에서 자동 배포 스크립트 실행
```bash
# NCP 서버에 SSH로 접속
ssh -p 22 root@223.130.136.16

# 서버에서:
bash /tmp/deploy-on-server.sh
```

---

### 방법 2️⃣: 수동 배포 (단계별)

NCP 서버에 SSH로 접속 후 아래 명령어를 차례대로 실행하세요.

#### Step 1: 시스템 업데이트
```bash
apt-get update
apt-get install -y python3.10 python3-pip git nginx curl
```

#### Step 2: 프로젝트 디렉토리 준비
```bash
mkdir -p /home/goksori
cd /home/goksori

# 압축 파일 추출 (파일 업로드 후)
tar -xzf /tmp/goksori-deploy.tar.gz
```

#### Step 3: Python 가상환경 설정
```bash
cd /home/goksori/backend
python3.10 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

#### Step 4: 환경 설정 파일 생성
```bash
cat > config/.env << 'EOF'
DATABASE_URL=postgresql://days:Project0423!@projectabout-001-8tq0.vpc.nclouddb.com:5432/goksori_db
APP_NAME=곡소리매매법
APP_ENV=production
DEBUG=false
SECRET_KEY=goksori-secret-key-$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
CRAWL_INTERVAL_HOURS=4
MAX_COMMENTS_PER_STOCK=100
REQUEST_DELAY_SECONDS=1
EOF
```

#### Step 5: Systemd 서비스 등록
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

#### Step 6: Nginx 설정
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

# Nginx 검사 및 재시작
nginx -t
systemctl restart nginx
```

#### Step 7: 서비스 시작
```bash
systemctl start goksori
sleep 3
systemctl status goksori
```

---

## 🔍 배포 완료 확인

### 1. 헬스 체크
```bash
curl http://223.130.136.16/health
```

**예상 응답:**
```json
{"status": "ok", "timestamp": "2026-02-20T09:00:00"}
```

### 2. 웹사이트 접속
```
http://223.130.136.16
```

50개 코스피200 종목이 감성분석 점수와 함께 표시되어야 합니다.

### 3. API 문서 확인
```
http://223.130.136.16/api/docs
```

Swagger UI에서 모든 API 엔드포인트를 확인할 수 있습니다.

---

## 📊 실시간 로그 확인

```bash
# 실시간 로그 보기
journalctl -u goksori -f

# 최근 50줄 로그
journalctl -u goksori -n 50

# Nginx 로그
tail -f /var/log/nginx/access.log
```

---

## 🛠️ 트러블슈팅

### 서비스가 시작되지 않음
```bash
systemctl status goksori
journalctl -u goksori -n 50
```

### Nginx 설정 오류
```bash
nginx -t  # 문법 검사
systemctl restart nginx
```

### DB 연결 오류
```bash
# .env 파일 확인
cat config/.env | grep DATABASE_URL

# DB 연결 테스트 (서버에서)
python3 -c "from sqlalchemy import create_engine; engine = create_engine('postgresql://days:Project0423!@projectabout-001-8tq0.vpc.nclouddb.com:5432/goksori_db'); print(engine.execute('SELECT 1'))"
```

### 포트 이미 사용 중
```bash
# 8000 포트 사용 프로세스 확인
lsof -i :8000

# 프로세스 종료 후 다시 시작
systemctl restart goksori
```

---

## 🔄 유지보수 명령어

### 서비스 재시작
```bash
systemctl restart goksori
```

### 서비스 중지
```bash
systemctl stop goksori
```

### 서비스 활성화/비활성화
```bash
systemctl enable goksori
systemctl disable goksori
```

### 시스템 리소스 확인
```bash
# 메모리/CPU 사용량
top

# 디스크 사용량
df -h

# 네트워크 상태
netstat -tuln
```

---

## 📝 다음 단계

배포 완료 후 다음 작업을 진행할 수 있습니다:

### 즉시 (Day 2)
- [ ] PostgreSQL 실제 데이터 마이그레이션
- [ ] APScheduler 통합 (4시간 자동 크롤링)
- [ ] DART API 크롤링 추가

### 1-2주 (Phase 2)
- [ ] KoBERT 감성분석 고도화
- [ ] 종목별 뉴스 크롤링
- [ ] 기술적 분석 추가 (캔들, 이동평균)

### 3-4주 (Phase 3)
- [ ] 회원 시스템 (로그인, 즐겨찾기)
- [ ] 알림 기능 (이메일, Slack)
- [ ] 모바일 앱 (React Native)

---

## 🔐 보안 체크리스트

배포 후 다음을 확인하세요:

- [ ] SSH 비밀번호 변경: `passwd root`
- [ ] SSH 공개키 인증으로 변경 (비밀번호 비활성화)
- [ ] Firewall 설정 (포트 80, 443만 허용)
- [ ] SSL 인증서 설정 (Let's Encrypt)
- [ ] 정기 백업 스크립트 설정
- [ ] 로그 로테이션 설정

---

## 📞 지원

배포 중 문제가 발생하면:

1. 로그 확인: `journalctl -u goksori -n 50`
2. 헬스 체크: `curl http://223.130.136.16/health`
3. DB 연결 확인: `psql postgresql://days:Project0423!@projectabout-001-8tq0.vpc.nclouddb.com:5432/goksori_db`

---

**배포 가이드 생성일:** 2026-02-20
**프로젝트:** 곡소리 매매법 (Goksori Trading Signal System)
**상태:** ✅ 배포 준비 완료
