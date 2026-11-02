# PRM393 Final · Quick Attend · SE190533

Hệ thống điểm danh bằng mã QR trên Firebase: **giảng viên FPTU điểm danh** trên app Android, **sinh viên quét mã và xem chuyên cần** trên web, **giáo vụ duyệt lớp, quản lý môn và đăng thông báo** trên web admin. Không có server riêng; Security Rules và App Check quyết định mỗi client được làm gì.

| Mục | Nội dung |
|---|---|
| Sinh viên | Trần Ngọc Thiên · SE190533 |
| Web admin | `https://<project-id>.web.app/admin/` _(điền sau khi deploy)_ |
| Cổng sinh viên | `https://<project-id>.web.app/` _(điền sau khi deploy)_ |
| Video demo | _(dán link sau khi quay)_ |
| Thiết kế Lab 2 | Figma [PRM323 Lab 2 v2](https://www.figma.com/design/1qIZVpL0Q7bD9UzT5TVBRy) · repo [prm323-lab2-SE190533](https://github.com/thiengthb/prm323-lab2-SE190533) |
| Bản Lab 3 | Nhánh `main`, tag `lab3-submission` |

> **Trạng thái:** mã xong trên nhánh `final-system`, đã phân tích tĩnh. Chưa chạy trên Firebase thật; các bước còn lại ở [`docs/gap-review.md`](docs/gap-review.md) mục 2.

## Vai trò

| Vai trò | Client | Làm gì | Tài khoản demo |
|---|---|---|---|
| `lecturer` | App Android (`mobile/`) | Nhập lớp, điểm danh, chăm sóc sinh viên, duyệt báo sai | _(điền)_ |
| `student` | Cổng web (`mobile/` build web) | Quét mã, xem chuyên cần, báo sai | _(điền)_ |
| `staff` | Web admin (`web/`) | Duyệt lớp, quản lý môn, đăng thông báo | _(điền)_ |
| `admin` | Web admin | Như staff, thêm cấp vai trò. **Admin đầu tiên:** _(điền email)_ | _(điền)_ |
| `user` | Web admin | Tài khoản mới, bị từ chối cho tới khi Admin cấp quyền | |

## Bản đồ sản phẩm nộp

| Sản phẩm | Ở đâu |
|---|---|
| Khoảng trống Lab 2, Lab 3 và cách đóng | [docs/gap-review.md](docs/gap-review.md) |
| Mô hình dữ liệu, quyền, chuyển trạng thái | [docs/data-model.md](docs/data-model.md) |
| Luồng liên vai trò | [docs/cross-role-flow.md](docs/cross-role-flow.md) |
| Tính năng AI | [docs/ai-feature.md](docs/ai-feature.md) |
| Kết quả kiểm thử | [docs/test-report.md](docs/test-report.md) |
| Truy vết thiết kế, khác biệt | [docs/design-traceability.md](docs/design-traceability.md) |
| Kiến trúc | [docs/architecture.md](docs/architecture.md) |
| Sự kiện Analytics | [docs/analytics-plan.md](docs/analytics-plan.md) |
| Test plan ARTEMIS | [docs/test-plan.md](docs/test-plan.md), [e2e_test/](e2e_test/) |
| AI code review | [docs/code-review.md](docs/code-review.md) |
| Rules, chỉ mục, Remote Config, test Rules | [firebase/](firebase/) |
| Bằng chứng | [evidence/](evidence/) |
| Báo cáo, slide | `report/Final_SE190533.pdf`, `slides/Final_SE190533_slides.pdf` |

## Cài đặt

Cần: Flutter stable 3.47, Node 22, Java 21 (Emulator), Firebase CLI, FlutterFire CLI.

```bash
git clone -b final-system https://github.com/thiengthb/PRM393_Lab03_SE190533 && cd PRM393_Lab03_SE190533
npm i -g firebase-tools && firebase login
dart pub global activate flutterfire_cli

# Nối Firebase cho từng client (ghi đè firebase_options.dart, tạo google-services.json)
(cd mobile && flutter pub get && flutterfire configure --project=<project-id> --platforms=android,web)
(cd web && flutter pub get && flutterfire configure --project=<project-id> --platforms=web)

# Đẩy Rules, chỉ mục, Remote Config (firebase.json nằm trong firebase/)
cd firebase && firebase use <project-id> && firebase deploy --only firestore,remoteconfig && cd ..
```

Trên console bật: Authentication (Email/Password, Google), Firestore, Remote Config, Crashlytics, Messaging, AI Logic (Gemini Developer API), App Check. Thêm SHA-1 cho Android (`cd mobile/android && ./gradlew signingReport`). App Check: đăng ký Play Integrity và reCAPTCHA v3; chạy thử xong mới bật Enforce, nếu không bản debug sẽ bị từ chối (debug token in ra Logcat, dán vào console).

**Admin đầu tiên:** đăng nhập web admin một lần, màn báo chưa có quyền và hiện UID; sửa `users/<uid>.role` thành `admin` trên console.

## Chạy

```bash
# App giảng viên
cd mobile && flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com

# Cổng sinh viên
cd mobile && flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=<key>

# Web admin
cd web && flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=<key>

# Deploy cả hai web: sinh viên ở /, quản trị ở /admin/
RECAPTCHA_SITE_KEY=<key> ./tool/build_hosting.sh && (cd firebase && firebase deploy --only hosting)
```

Dữ liệu mẫu để nhập: `mobile/sample-data/`. Cloud Storage là tùy chọn của Lab 3, cần gói Blaze: bật cờ `report_cloud_upload` và `firebase deploy --only storage`.

## Chạy test

```bash
cd mobile && flutter test                     # unit test ViewModel, logic
cd web && flutter test
cd firebase/tests && npm ci && npm test        # Security Rules trên Emulator, sinh evidence/rules/
cd e2e_test && uv sync && cp .env.example .env # điền .env, khởi động daemon ARTEMIS
uv run pytest --count=3 && uv run python report.py > ../evidence/artemis/results.md
```

`.github/workflows/ci.yml` chạy analyze, unit test, build web và test Rules mỗi lần push.

## Phiên bản

Ràng buộc ở các `pubspec.yaml` là khoảng; bản dùng thật nằm trong `pubspec.lock` sau `flutter pub get`.

| Thành phần | Phiên bản |
|---|---|
| Flutter / Dart | 3.47.3 stable / 3.13 |
| firebase_core · auth · cloud_firestore · storage | 5.1.0 · 7.0.1 · 7.1.0 · 14.0.1 |
| firebase_messaging · analytics · crashlytics · remote_config | 17.0.1 · 13.0.1 · 6.0.1 · 7.0.1 |
| firebase_ai · firebase_app_check | ^5.1.0 · ^0.5.1 |
| flutter_riverpod · go_router · google_sign_in · google_fonts | 3.4.3 · 18.1.2 · 7.2.0 · 8.2.1 |
| mobile_scanner · qr_flutter · file_selector · excel · pdf · printing | 7.4.2 · 4.1.0 · 1.1.0 · 4.0.6 · 3.12.0 · 5.14.3 |
| @firebase/rules-unit-testing · firebase-tools | ^6.0.0 · ^15.0.0 |
| Google ARTEMIS | commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` |
| Model Gemini mặc định | `gemini-3.5-flash-lite`, đổi được bằng Remote Config `ai_model` |

## Công cụ AI đã dùng

| Công cụ | Dùng vào việc gì |
|---|---|
| Claude (Anthropic), kèm Figma MCP | Đọc Figma; viết tài liệu Lab 2; sinh mã Flutter, Security Rules, test, tài liệu `docs/`; tách monorepo; dựng web admin, hộp thư, tính năng AI; review mã (CR-01..CR-14) |
| Google Gemini qua Firebase AI Logic | Tính năng gợi ý lời nhắc trong app |
| Google ARTEMIS | Test E2E trên Android, phiên khám phá Pro |
| CodeRabbit hoặc GitHub Copilot | Review pull request _(điền khi chạy)_ |
