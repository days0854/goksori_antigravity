# 곡소리 배포 현황 (2026-02-23)

## 완료된 작업

### ✅ SSH 설정 복구
- PermitRootLogin: yes (활성화)
- PasswordAuthentication: yes (활성화)
- Port 22 정상 작동
- root 계정 SSH 접속 가능

### ✅ 애플리케이션 배포
- 저장소: https://github.com/days0854/goksori
- 배포 경로: `/home/goksori/backend/`
- Python 버전: 3.12
- 가상환경: `/home/goksori/backend/venv`
- 진입점: `app.main:app`

### ✅ 의존성 설치
- transformers
- konlpy
- selenium
- beautifulsoup4
- sqlalchemy, psycopg2-binary
- fastapi, uvicorn
- torch 제거 (797MB, 불필요)

### ✅ 서비스 관리
- Systemd service: `goksori.service`
- 상태: `active (running)`
- 포트: 8000 (내부)

### ✅ HTTP (포트 80) 설정
- Nginx reverse proxy 정상 작동
- `http://223.130.136.16` → 접속 가능
- 헬스 체크: `/health` → `{"status":"ok","service":"곡소리매매법"}`

### ✅ 도메인 DNS
- goksori.net → 223.130.136.16 (설정됨)

## 미완료 작업

### ⏳ HTTPS/SSL 설정 (다음 재부팅 후)
- Certbot 설치 필요
- Let's Encrypt 인증서 발급 필요
- Nginx HTTPS 설정 필요 (443 포트)
- HTTP → HTTPS 리다이렉트 설정 필요

참고: `HTTPS-SETUP.md` 파일 참조

## 현재 서버 상태

| 항목 | 상태 | 비고 |
|------|------|------|
| SSH | ✅ | root 접속 가능 |
| HTTP | ✅ | 포트 80 정상 |
| HTTPS | ❌ | 포트 443 미설정 |
| 애플리케이션 | ✅ | uvicorn 8000 |
| Nginx | ✅ | 포트 80 reverse proxy |
| 데이터베이스 | ✅ | PostgreSQL 연동 (외부) |
| 도메인 | ✅ | DNS A 레코드 설정됨 |

## 접속 정보

### HTTP (임시)
```
http://223.130.136.16
http://223.130.136.16/health
```

### HTTPS (재부팅 후 설정)
```
https://goksori.net
https://goksori.net/health
```

## 파일 위치 정리

```
/home/goksori/
├── backend/
│   ├── app/
│   │   ├── main.py (FastAPI 진입점)
│   │   └── ...
│   ├── backend/ (또 다른 backend 폴더)
│   ├── frontend/
│   ├── config/
│   ├── venv/ (Python 가상환경)
│   └── requirements.txt

/etc/systemd/system/goksori.service
/etc/nginx/sites-available/goksori
/etc/nginx/sites-enabled/goksori (symlink)
/etc/letsencrypt/ (HTTPS 설정 후 추가)
```

## 다음 단계

1. 서버 재부팅 완료
2. HTTPS-SETUP.md 문서 참고하여 Certbot 설치 및 SSL 인증서 발급
3. Nginx 설정 수정 및 재시작
4. `https://goksori.net` 접속 확인

---
작성일: 2026-02-23
상태: 재부팅 예정 중 - 스냅샷 저장 완료
