# Voyager Lab — Laravel 9 + Voyager 1.6

Web app cố tình để lỗi: **Voyager 1.6** (default credentials + media-upload RCE) trên
Laravel 9 + PHP 8.1 (Apache), DB MySQL 8.0.

## Thành phần
```
voyager-lab/
├── docker-compose.yml          # app build từ Dockerfile, db mysql:8.0 (pull từ Hub)
├── Dockerfile                  # build image app (Laravel + Voyager)
├── entrypoint.sh               # tự cấu hình .env + migrate + cài Voyager khi boot
└── RUN.md                      # file này
```

## Yêu cầu
- Docker + Docker Compose (Docker Desktop), **có internet** (build app tải Laravel/Voyager + pull mysql).
- Mac Apple Silicon: compose để `platform: linux/amd64` → app build/chạy qua emulation (chậm hơn).
  Lần build đầu khá lâu (composer create-project + require voyager).

## Chạy
```bash
cd voyager-lab

# Build image app từ Dockerfile + pull mysql, rồi khởi động
docker compose up -d --build

# Theo dõi khởi tạo lần đầu (chờ MySQL + migrate + cài Voyager — vài phút)
docker compose logs -f app
#   chờ tới khi Apache start xong rồi Ctrl-C
```

## Truy cập
- App:         http://localhost:8080
- Admin panel: http://localhost:8080/admin
- Tài khoản mặc định Voyager: **admin@admin.com** / **password**
  (nếu sai, xem `entrypoint.sh` phần seed admin để biết creds chính xác)

## Lỗi để khai thác
- Đăng nhập bằng default credentials ở trên.
- Voyager 1.6 **Media/file upload → RCE**: upload file PHP qua Media Manager rồi truy cập trực tiếp.

## Dừng / dọn
```bash
docker compose down          # dừng, giữ DB (volume voyager_db)
docker compose down -v       # dừng và XOÁ DB → lần sau khởi tạo lại từ đầu
```
