# 🎯 곡소리 매매법 - 배포 시작 가이드

**상태:** ✅ 모든 개발 및 배포 준비 완료
**생성일:** 2026-02-20
**프로젝트:** Goksori Trading Signal System (곡소리 매매법)

---

## 🚀 빠른 시작 (5분)

### 👉 지금 바로 배포하려면?

**3가지 선택지:**

#### 1️⃣ **가장 빠른 방법** (자동화) ⭐
```bash
cd /sessions/charming-keen-ptolemy/mnt/goksori
bash scripts/complete-deploy.sh
```
- 완전 자동화 (압축 → 업로드 → 배포)
- 소요 시간: 5-7분
- 요구사항: `sshpass` 설치 필요 (스크립트가 자동 설치)

#### 2️⃣ **권장 방법** (반자동) ⭐⭐
문서 참고: `QUICK-DEPLOY-STEPS.md`
- SSH 접속 후 수동 실행
- 진행 상황 확인 가능
- 소요 시간: 5분

#### 3️⃣ **상세 가이드** (단계별)
문서 참고: `NCP-DEPLOYMENT-GUIDE.md`
- 모든 단계 설명 포함
- 트러블슈팅 정보 풍부
- 보안 체크리스트 포함

---

## 📚 문서 맵

| 문서 | 용도 | 읽는 시간 |
|------|------|---------|
| **00-START-HERE.md** ✨ | 이 문서! 시작점 | 2분 |
| **QUICK-DEPLOY-STEPS.md** ⭐ | 5분 빠른 배포 | 5분 |
| **NCP-DEPLOYMENT-GUIDE.md** | 상세 배포 + 문제 해결 | 15분 |
| **DEPLOYMENT-STATUS.md** | 배포 현황 + 다음 단계 | 10분 |
| **README.md** | 프로젝트 개요 | 5분 |
| **SETUP.md** | 개발 환경 설정 | 10분 |
| **IMPLEMENTATION_SUMMARY.md** | 구현 상세 내용 | 15분 |

---

## 🎯 배포 전 확인 사항

### ✅ 필수 정보 확인

```
NCP 서버 정보:
├─ IP: 223.130.136.16
├─ 포트: 22
├─ 사용자: root
└─ 비밀번호: U4*G!@m*86Te7cu

PostgreSQL DB:
├─ 호스트: projectabout-001-8tq0.vpc.nclouddb.com
├─ 포트: 5432
├─ DB 이름: goksori_db
├─ 사용자: days
└─ 비밀번호: Project0423!
```

### ✅ 로컬 환경 확인

```bash
# SSH 설치 확인
ssh -V

# SCP 설치 확인 (파일 업로드용)
which scp

# 인터넷 연결 확인
ping 223.130.136.16
```

---

## 🚀 배포 시작

### Step 1: 빠른 배포 가이드 읽기
👉 **`QUICK-DEPLOY-STEPS.md`** 열기 (5분 가이드)

**주요 내용:**
- Step 1: 프로젝트 압축
- Step 2: NCP 서버 접속 (SSH)
- Step 3: 파일 업로드 (SCP)
- Step 4: NCP 서버에서 배포 명령어 실행
- Step 5: 배포 완료 확인

### Step 2: 배포 실행
문서의 단계별 명령어를 따라 실행

### Step 3: 배포 확인
```bash
# 웹사이트 접속
http://223.130.136.16

# 헬스 체크
curl http://223.130.136.16/health

# API 문서
http://223.130.136.16/api/docs
```

---

## 📊 배포된 시스템 구조

```
┌─────────────────────────────────────┐
│     사용자 브라우저                  │
│   http://223.130.136.16             │
└────────────────┬────────────────────┘
                 │
         ┌───────▼────────┐
         │   Nginx (포트 80)│  ← 리버스 프록시
         │  (로드밸런싱)   │
         └───────┬────────┘
                 │
         ┌───────▼──────────────┐
         │  FastAPI (포트 8000) │  ← 백엔드
         │  • 감성분석 엔진     │
         │  • API 엔드포인트    │
         └───────┬──────────────┘
                 │
    ┌────────────┴───────────┐
    │                        │
┌───▼─────────┐    ┌────────▼──────┐
│ PostgreSQL  │    │  파일 시스템  │
│    DB       │    │  (HTML/CSS/JS)│
│             │    │  (정적 파일)  │
└─────────────┘    └───────────────┘
```

### 주요 엔드포인트

| 엔드포인트 | 용도 |
|----------|------|
| `http://223.130.136.16/` | 메인 웹사이트 |
| `http://223.130.136.16/health` | 헬스 체크 |
| `http://223.130.136.16/api/docs` | API 문서 (Swagger) |
| `http://223.130.136.16/api/stocks/` | 종목 목록 API |

---

## 🛠️ 배포 후 유지보수

### 📊 실시간 모니터링
```bash
# 실시간 로그 확인
ssh root@223.130.136.16
journalctl -u goksori -f
```

### 🔄 서비스 관리
```bash
# 서비스 상태 확인
systemctl status goksori

# 서비스 재시작
systemctl restart goksori

# 서비스 중지
systemctl stop goksori
```

### 📈 시스템 리소스 확인
```bash
# 메모리 확인
free -h

# 디스크 확인
df -h

# 프로세스 확인
top
```

---

## 🆘 문제 해결

### SSH 연결 안 됨?
```bash
# SSH 상세 출력으로 진단
ssh -vv root@223.130.136.16

# 확인 사항:
# 1. IP 주소 정확한지 확인
# 2. 포트 번호 (22) 확인
# 3. 비밀번호 정확한지 확인
# 4. NCP 방화벽 설정 확인 (포트 22 허용)
```

### 웹사이트 안 보임?
```bash
# 1. 헬스 체크
curl http://223.130.136.16/health

# 2. 서비스 상태 확인
ssh root@223.130.136.16
systemctl status goksori

# 3. 로그 확인
journalctl -u goksori -n 50

# 4. 포트 확인
netstat -tuln | grep 8000
```

### 더 자세한 문제 해결?
👉 `NCP-DEPLOYMENT-GUIDE.md` 의 "🛠️ 문제 해결" 섹션 참고

---

## 📈 다음 단계 (배포 후)

### 즉시 (1일)
- [ ] 웹사이트 정상 작동 확인
- [ ] API 문서 확인
- [ ] 실시간 로그 모니터링

### 1주일
- [ ] PostgreSQL 실제 데이터 마이그레이션
- [ ] APScheduler 통합 (4시간 자동 크롤링)
- [ ] DART API 크롤링 추가

### 2-4주
- [ ] KoBERT 감성분석 고도화
- [ ] 뉴스 크롤링 추가
- [ ] 기술적 분석 지표 추가

### 장기 (1-3개월)
- [ ] 회원 시스템 구현
- [ ] 알림 기능 (이메일, Slack)
- [ ] 모바일 앱 (React Native)

자세한 정보: `DEPLOYMENT-STATUS.md` 참고

---

## 🔐 보안 체크리스트

배포 후 다음을 구현하세요:

- [ ] SSH 비밀번호 변경
- [ ] SSH 키 기반 인증 설정
- [ ] Firewall 설정 (포트 80, 443만)
- [ ] SSL/TLS 인증서 (Let's Encrypt)
- [ ] `.env` 파일 권한 설정
- [ ] 정기 백업 스크립트
- [ ] 로그 로테이션
- [ ] 모니터링 도구 (Prometheus)

---

## 📞 빠른 참고

### 배포 관련 파일
```
scripts/
├── complete-deploy.sh       # 완전 자동화 배포
├── deploy-ncp.sh           # NCP 배포
└── ncp-deploy-manual.sh    # 수동 배포
```

### 배포 가이드
```
├── 00-START-HERE.md                    # 이 파일 (시작점)
├── QUICK-DEPLOY-STEPS.md               # 5분 빠른 배포 ⭐
├── NCP-DEPLOYMENT-GUIDE.md             # 상세 가이드
└── DEPLOYMENT-STATUS.md                # 배포 현황
```

### 프로젝트 문서
```
├── README.md                           # 프로젝트 개요
├── SETUP.md                            # 개발 환경 설정
├── IMPLEMENTATION_SUMMARY.md           # 구현 요약
└── PROJECT_COMPLETION_REPORT.txt       # 완료 리포트
```

---

## ⏱️ 배포 시간 추정

| 단계 | 소요 시간 |
|------|---------|
| 준비 (압축) | 1분 |
| 파일 업로드 | 1분 |
| 시스템 업데이트 | 1분 |
| Python 환경 | 2-3분 |
| 설정 및 서비스 | 1분 |
| **총 소요 시간** | **5-10분** |

---

## 🎉 배포 완료 후

### 확인할 것
✅ 웹사이트 접속 가능
✅ API 문서 작동
✅ 데이터 표시됨
✅ 로그에 에러 없음

### 다음
- 모니터링 설정
- 백업 정책 수립
- 도메인 연결
- SSL 인증서 설정

---

## 📖 추가 정보

### 프로젝트 통계
- **개발 기간:** 1일 (TDD 기반)
- **총 코드:** 4,000+ 줄
- **파일 수:** 33개
- **테스트 케이스:** 18개 (모두 통과)
- **API 엔드포인트:** 8개

### 기술 스택
- **백엔드:** FastAPI + Python 3.10
- **프론트엔드:** HTML5 + CSS3 + Vanilla JS
- **데이터베이스:** PostgreSQL 12+
- **배포:** Nginx + Systemd
- **서버:** NCP (Naver Cloud Platform)

---

## 🔗 빠른 링크

| 작업 | 링크 |
|------|------|
| **빠른 배포** | `QUICK-DEPLOY-STEPS.md` |
| **상세 배포** | `NCP-DEPLOYMENT-GUIDE.md` |
| **배포 현황** | `DEPLOYMENT-STATUS.md` |
| **프로젝트 개요** | `README.md` |
| **개발 환경 설정** | `SETUP.md` |

---

## 🎯 지금 시작하세요!

### 추천 순서:

1. **이 문서 읽음** ✅ (지금 여기)
2. **`QUICK-DEPLOY-STEPS.md` 읽고 실행** ← 다음 단계
3. **배포 완료 확인**
4. **모니터링 및 유지보수**

---

## 📝 마지막 확인

배포를 시작하기 전에:

- [ ] NCP 서버 IP 확인: `223.130.136.16`
- [ ] SSH 비밀번호 확인: `U4*G!@m*86Te7cu`
- [ ] DB 연결 문자열 확인: `postgresql://days:Project0423!@...`
- [ ] SSH 클라이언트 설치 확인: `ssh -V`
- [ ] 인터넷 연결 확인

---

**이제 준비 완료!** 🚀

👉 **다음:** `QUICK-DEPLOY-STEPS.md` 읽고 배포 시작하기

---

**프로젝트:** 곡소리 매매법 (Goksori Trading Signal System)
**상태:** ✅ 배포 준비 완료
**생성일:** 2026-02-20
