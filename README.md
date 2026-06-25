# labs

Bộ lab bảo mật **cố tình chứa lỗ hổng** (vulnerable by design) để học/luyện khai thác.
Mỗi lab chạy bằng Docker Compose, độc lập trong thư mục riêng.

> ⚠️ Đây là ứng dụng có lỗ hổng chủ đích — **chỉ chạy local / môi trường cô lập**, đừng
> expose ra internet.

## Danh sách lab

| Thư mục | Lab | Cổng | Loại lỗi |
|---------|-----|------|----------|
| [`redis-cve-2022-0543/`](redis-cve-2022-0543/RUN.md) | Redis 5.0.7 (+ SSH banner) | 6379, 22 | Lua sandbox escape → RCE (CVE-2022-0543); port 22 chỉ hiện banner, không cho login |
| [`voyager-lab/`](voyager-lab/RUN.md) | Laravel 9 + Voyager 1.6 | 8080 | Default creds + media-upload RCE |

Hướng dẫn chạy + PoC chi tiết nằm trong `RUN.md` của từng lab.

## Chạy nhanh
```bash
# Redis (+ SSH banner)
cd redis-cve-2022-0543 && docker compose up -d --build

# Voyager (build lần đầu mất vài phút)
cd voyager-lab && docker compose up -d --build
```

## Ghi chú
- Repo này là **source-only**: image không kèm trong repo (GitHub giới hạn 100MB/file).
  - `redis` và `mysql` được pull từ Docker Hub.
  - `voyager-lab-app` được build tại chỗ từ `Dockerfile` (cần internet lần đầu).
- Bản đóng gói **kèm image để chạy offline** (`docker load`) được giữ riêng ngoài repo.
- Image gốc là `linux/amd64`; trên Mac Apple Silicon sẽ chạy qua emulation.
