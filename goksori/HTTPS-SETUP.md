# HTTPS 설정 기록 (2026-02-23)

## 상황
- **HTTP**: ✅ 정상 작동 (포트 80)
- **HTTPS**: ❌ 미설정 (포트 443)
- **도메인**: goksori.net (DNS → 223.130.136.16 정상 설정됨)
- **SSL 인증서**: Let's Encrypt로 발급 필요

## 실행 명령어

### 1단계: Certbot 설치
```bash
apt-get update
apt-get install -y certbot python3-certbot-nginx
```

### 2단계: SSL 인증서 발급
```bash
certbot certonly --nginx -d goksori.net
```

### 3단계: Nginx 설정 수정
```bash
nano /etc/nginx/sites-available/goksori
```

아래 내용으로 완전히 교체:

```nginx
upstream goksori_backend {
    server 127.0.0.1:8000;
    keepalive 32;
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name goksori.net;

    ssl_certificate /etc/letsencrypt/live/goksori.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/goksori.net/privkey.pem;

    client_max_body_size 10M;

    location / {
        proxy_pass http://goksori_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# HTTP → HTTPS 리다이렉트
server {
    listen 80;
    server_name goksori.net;
    return 301 https://$server_name$request_uri;
}
```

### 4단계: Nginx 재시작
```bash
nginx -t
systemctl restart nginx
```

## 완료 후 확인
```bash
# HTTPS 접속 테스트
curl https://goksori.net/health

# 인증서 만료일 확인
certbot certificates

# SSL 설정 확인
openssl x509 -in /etc/letsencrypt/live/goksori.net/fullchain.pem -text -noout | grep -A 2 "Validity"
```

## 상태 기록
- 작성일: 2026-02-23
- 상태: 재부팅 전 완료된 내용 정리
- 다음 단계: 서버 재부팅 후 위 명령어 실행
