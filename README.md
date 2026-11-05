# PRM393 Lab 3 + Final · Hereby · SE190533

Tên cũ của app là Quick Attend (giao diện cam, nhánh `main`). Từ Lab 3 app đổi tên Hereby và bảng màu Biển sâu theo Figma v2; `applicationId` vẫn là `vn.edu.fpt.quick_attend`. Nhánh `final-system` gộp giao diện v2 với phần Final (web admin, hộp thư, AI, App Check).

Hệ thống điểm danh bằng mã QR trên Firebase: **giảng viên FPTU điểm danh** trên app Android, **sinh viên quét mã và xem chuyên cần** trên web, **giáo vụ duyệt lớp, quản lý môn và đăng thông báo** trên web admin. Không có server riêng; file PDF lên Cloudinary bằng upload preset Unsigned; Security Rules và App Check quyết định mỗi client được làm gì.

| Mục | Nội dung |
|---|---|
| Sinh viên | Trần Ngọc Thiên · SE190533 |
| Web admin | `https://<project-id>.web.app/admin/` _(điền sau khi deploy)_ |
| Cổng sinh viên | `https://<project-id>.web.app/` _(điền sau khi deploy)_ |
| Video demo | _(dán link sau khi quay)_ |
| Thiết kế Lab 2 | Figma [PRM323 Lab 2 v2](https://www.figma.com/design/1qIZVpL0Q7bD9UzT5TVBRy) · repo [prm323-lab2-SE190533](https://github.com/thiengthb/prm323-lab2-SE190533) |
| Bản Lab 3 | Nhánh `main` (commit `5435678`) |

> **Trạng thái:** mã xong trên nhánh `final-system`, CI đạt (analyze, unit test, build web, test Rules trên Emulator). Chưa chạy trên Firebase thật; các bước còn lại ở [`docs/gap-review.md`](docs/gap-review.md) mục 2.

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
| Truy vết thiết kế → mã, mọi khác biệt và lý do | [docs/design-traceability.md](docs/design-traceability.md) |
| Kiến trúc: thư mục, sơ đồ lớp, sơ đồ tuần tự, bảng ViewModel | [docs/architecture.md](docs/architecture.md) |
| Kế hoạch sự kiện Analytics | [docs/analytics-plan.md](docs/analytics-plan.md) |
| Test plan, kết quả ARTEMIS, phiên khám phá | [docs/test-plan.md](docs/test-plan.md), [e2e_test/](e2e_test/) |
| AI code review, quyết định, commit sửa | [docs/code-review.md](docs/code-review.md) |
| Security Rules, chỉ mục, Remote Config mặc định, test Rules trên Emulator | [firebase/](firebase/), [evidence/rules/](evidence/rules/) |
| Bằng chứng (console, DebugView, Crashlytics, ARTEMIS) | [evidence/](evidence/) |
| Báo cáo, slide | `report/Final_SE190533.pdf`, `slides/Final_SE190533_slides.pdf` (Lab 3 nộp cùng) |

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

Trên console bật: Authentication (Email/Password, Google), Firestore, Remote Config, Crashlytics, Messaging, AI Logic (Gemini Developer API), App Check. Không có Cloud Storage (gói Spark): file PDF lên Cloudinary, xem D-L3-10, D-L3-18. Thêm SHA-1 cho Android (`cd mobile/android && ./gradlew signingReport`). App Check: đăng ký Play Integrity và reCAPTCHA v3; chạy thử xong mới bật Enforce, nếu không bản debug sẽ bị từ chối (debug token in ra Logcat, dán vào console).

**Cloudinary** (tải PDF lên đám mây, D-L3-18): thêm `--dart-define=CLOUDINARY_CLOUD_NAME=<cloud name> --dart-define=CLOUDINARY_UPLOAD_PRESET=<preset>` vào lệnh chạy app giảng viên. Cách tạo: đăng ký Cloudinary gói Free → Settings → Upload → Add upload preset → Signing mode **Unsigned**, Allowed formats `pdf`, Max file size 5 MB. Settings → Security: bật "Allow delivery of PDF and ZIP files" để mở được link. Không đưa API secret vào app hay repo. Thiếu hai biến này, hoặc Remote Config `report_cloud_upload=false`, thì PDF chỉ lưu trên máy.

`GOOGLE_SERVER_CLIENT_ID` là Web client ID (Firebase console → Authentication → Sign-in method → Google). Có thể giới hạn email theo vai trò bằng `--dart-define=LECTURER_DOMAIN=fe.edu.vn --dart-define=STUDENT_DOMAIN=fpt.edu.vn` (để trống khi dùng tài khoản test).

**Admin đầu tiên:** đăng nhập web admin một lần, màn báo chưa có quyền và hiện UID; sửa `users/<uid>.role` thành `admin` trên console.

## Chạy

```bash
# App giảng viên
cd mobile && flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com \
  --dart-define=CLOUDINARY_CLOUD_NAME=<cloud> --dart-define=CLOUDINARY_UPLOAD_PRESET=<preset>

# Cổng sinh viên
cd mobile && flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=<key>

# Web admin
cd web && flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=<key>

# Deploy cả hai web: sinh viên ở /, quản trị ở /admin/
RECAPTCHA_SITE_KEY=<key> ./tool/build_hosting.sh && (cd firebase && firebase deploy --only hosting)
```

### Desktop giảng viên (Windows)

Cùng mã `mobile/`, build ra `hereby.exe`. Phải build trên máy Windows có Visual Studio 2022 (workload "Desktop development with C++"); Flutter không build Windows từ Linux hay macOS.

```powershell
cd mobile
flutter pub get
flutter run -d windows                      # chạy thử
flutter build windows --release --dart-define=CLOUDINARY_CLOUD_NAME=<cloud> --dart-define=CLOUDINARY_UPLOAD_PRESET=<preset>
# File chạy: mobile\build\windows\x64\runner\Release\hereby.exe (chép cả thư mục Release khi mang sang máy khác)
```

Bản Windows và app Android dùng chung tài khoản và Firestore, nên mở slot trên laptop thì điện thoại thấy ngay và ngược lại. Màn rộng có thanh tab dọc bên trái; nút **Chiếu lên TV** mở link màn chiếu như trên điện thoại. FlutterFire trên Windows có Core, Auth, Firestore, Remote Config; không có Crashlytics, FCM, Analytics, Google Sign-In. Vì vậy bản này:

- đăng nhập bằng email (không có nút Google);
- đọc Remote Config như Android, lỗi thì dùng giá trị mặc định trong app; Gợi ý AI luôn tắt;
- không có Crashlytics, FCM, thông báo nhắc slot (các phần này chạy trên Android);
- không bật App Check (Windows chỉ có debug provider). Nếu bật **Enforce** App Check cho Firestore thì bản Windows bị từ chối; chỉ Enforce cho AI Logic, còn Firestore để chế độ theo dõi (Monitor).

### Demo nhanh

1. Đăng ký giảng viên → xác nhận email → “Nhập lớp ngay” → chọn `mobile/sample-data/lop-fall-2026.csv` (chép vào máy qua `adb push mobile/sample-data/lop-fall-2026.csv /sdcard/Download/`) → màn “Đã gửi 4 lớp · Chờ giáo vụ duyệt”.
2. Giáo vụ đăng nhập web admin → **Duyệt lớp** → Duyệt (hoặc Từ chối kèm lý do). App giảng viên đổi ngay, hộp thư có tin kết quả.
3. Đăng ký sinh viên trên web với MSSV có trong file (ví dụ `SE190101`).
4. Giảng viên mở slot đang diễn ra → **Điểm danh** (có thể **Chiếu lên TV**, mở link trên máy chiếu) → sinh viên **Quét mã** hoặc **Nhập mã** 6 số → bộ đếm tăng thời gian thực → **Đóng mã** → bật tay em chưa quét → **Chốt** (một lần, có Hoàn tác).
5. Khu demo Firebase: Tài khoản → Firebase → Khu demo (FCM token, xuất PDF lên Cloudinary, Remote Config, Crashlytics).

### Chạy trên Firebase Emulator (không đụng dữ liệu thật)

Dùng để xem giao diện, chụp màn, demo khi không có mạng tới Firebase. Mật khẩu chung `Demo@123`: giảng viên `quanm@fe.edu.vn`, sinh viên `dung101@fpt.edu.vn`, giáo vụ `giaovu@fe.edu.vn`, quản trị `admin@fe.edu.vn`. Lớp mẫu đã được duyệt; PRM393 SE1801 được đặt vào slot đang diễn ra lúc tạo dữ liệu.

```bash
cd firebase/tests && npm ci
npx firebase emulators:start --config ../firebase.json --project hereby-se190533 --only auth,firestore
node seed-demo.mjs                                                         # cửa sổ khác
cd ../../mobile && flutter run -d chrome --dart-define=EMULATOR_HOST=localhost --dart-define=PORTAL=lecturer
```

Dữ liệu mẫu để nhập: `mobile/sample-data/`. File PDF lên Cloudinary (không cần gói Blaze); tắt bằng cờ Remote Config `report_cloud_upload`.

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

| Thành phần | Phiên bản (pubspec.lock) |
|---|---|
| Flutter / Dart | 3.47.3 stable / 3.13.3 |
| firebase_core · auth · cloud_firestore | 5.1.0 · 7.0.1 · 7.1.0 |
| http (tải lên Cloudinary) | ^1.2.0 |
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
| Claude (Anthropic), kèm Figma MCP | Đọc Figma; viết tài liệu Lab 2; sinh mã Flutter, Security Rules, test, tài liệu `docs/`; tách monorepo; dựng giao diện v2, web admin, hộp thư, tính năng AI, tải PDF lên Cloudinary; review mã (CR-01..CR-14); chạy web trên Emulator và chụp màn bằng Playwright để soát với Figma |
| Google Gemini qua Firebase AI Logic | Tính năng gợi ý lời nhắc trong app |
| Google ARTEMIS | Test E2E trên Android (Flash), phiên khám phá (Pro) |
| CodeRabbit hoặc GitHub Copilot | Review pull request _(điền khi chạy)_ |
