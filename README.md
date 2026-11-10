# PRM393 Lab 3 + Final · Attendo · SE190533

Attendo là hệ thống điểm danh bằng mã QR trên Firebase cho lớp học FPTU: **giảng viên** điểm danh trên app Android hoặc Windows, **sinh viên** quét mã và xem chuyên cần trên web, **Quản trị** duyệt lớp, quản lý môn, đăng thông báo, cấp vai trò và xem sự cố trên web admin. Không có server riêng: Security Rules và App Check quyết định mỗi client được làm gì; file PDF lên Cloudinary bằng upload preset Unsigned.

Tên cũ: Quick Attend (giao diện cam, nhánh `main`), rồi Hereby (Lab 3 v2). Từ 06/11/2026 app tên Attendo; từ 09/11 dùng Firebase project mới `attendo-app-2611` và mã app Android `app.attendo` (quyết định 001).

| Mục | Nội dung |
|---|---|
| Sinh viên | Trần Ngọc Thiên · SE190533 |
| Web admin | https://attendo-app-2611-admin.web.app |
| Web sinh viên | https://attendo-app-2611.web.app |
| Màn chiếu TV, FAP giả lập | https://attendo-app-2611-tv.web.app (mở bằng link có khoá từ app), https://attendo-app-2611-fap.web.app |
| Bản cài | [Release demo](https://github.com/thiengthb/PRM393_Lab03_SE190533/releases/tag/demo): APK giảng viên, bản Windows, extension |
| Slide | https://thiengthb.github.io/PRM393_Lab03_SE190533/ |
| Video demo | _(dán link sau khi quay)_ |
| Thiết kế Lab 2 | Figma [PRM323 Lab 2 v2](https://www.figma.com/design/1qIZVpL0Q7bD9UzT5TVBRy) · repo [prm323-lab2-SE190533](https://github.com/thiengthb/prm323-lab2-SE190533) |
| Bản Lab 3 | Nhánh `main` (commit `5435678`); phần Final ở nhánh `final-system` |

> **Tiến độ:** [`docs/STATUS.md`](docs/STATUS.md). **Cài và test tay toàn hệ thống:** [`docs/demo/TEST-TAY.md`](docs/demo/TEST-TAY.md); demo bằng tài khoản Google: [`docs/demo/DEMO-GOOGLE.md`](docs/demo/DEMO-GOOGLE.md).

## Vai trò

| Vai trò | Client | Làm gì | Tài khoản demo |
|---|---|---|---|
| `lecturer` | App Android, app Windows (`mobile/`), extension | Nhập lớp, điểm danh, chăm sóc sinh viên, duyệt báo sai | `nam@fe.edu.vn` (có lớp chờ duyệt); tài khoản Google giảng viên có đủ dữ liệu demo gửi riêng cho thầy |
| `student` | Web sinh viên (`mobile/` build web) | Quét mã, xem chuyên cần, báo sai | `tien102@fpt.edu.vn`; tài khoản Google sinh viên gửi riêng |
| `admin` | Web admin (`web/`) | Duyệt lớp, môn học, thông báo, cấp vai trò, sự cố | **Admin đầu tiên:** _(điền)_ |
| `staff` | (bị web admin từ chối) | Có quyền giáo vụ trong Security Rules; bản nộp chỉ mở web admin cho Admin | `giaovu@fe.edu.vn` |
| `user` | Web admin | Tài khoản mới, bị từ chối cho tới khi Admin cấp quyền | |

Tài khoản giảng viên và sinh viên mẫu ở trên dùng mật khẩu `Demo@123` (chỉ có quyền giảng viên, sinh viên). Trên Firebase thật, tài khoản giáo vụ và quản trị mẫu có mật khẩu ngẫu nhiên đổi sau mỗi lần nạp lại dữ liệu; Admin đăng nhập web admin bằng Google. Mỗi client từ chối tài khoản sai vai trò bằng câu rõ ràng. Dữ liệu demo nạp lại bằng workflow [Demo: Firebase thật](https://github.com/thiengthb/PRM393_Lab03_SE190533/actions/workflows/demo-firebase.yml).

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

# Repo đã nối sẵn project attendo-app-2611 (firebase_options.dart của mobile/ và web/, google-services.json).
# Chỉ chạy flutterfire configure khi đổi sang project khác:
# (cd mobile && flutterfire configure --project=<project-id> --platforms=android,web)
# (cd web && flutterfire configure --project=<project-id> --platforms=web)

# Đẩy Rules, chỉ mục, Remote Config (firebase.json nằm trong firebase/)
cd firebase && firebase use attendo-app-2611 && firebase deploy --only firestore,remoteconfig && cd ..
```

Trên console bật: Authentication (Email/Password, Google), Firestore, Remote Config, Crashlytics, Messaging, AI Logic (Gemini Developer API), App Check. Không có Cloud Storage (gói Spark): file PDF lên Cloudinary, xem D-L3-10, D-L3-18. Thêm SHA-1 cho Android (`cd mobile/android && ./gradlew signingReport`). App Check: đăng ký Play Integrity và reCAPTCHA v3; chạy thử xong mới bật Enforce, nếu không bản debug sẽ bị từ chối (debug token in ra Logcat, dán vào console).

**Cloudinary** (tải PDF lên đám mây, D-L3-18): app mặc định dùng cloud `twdfd7sq`, preset Unsigned `attendo_reports` (`packages/core/lib/config/app_config.dart`), nên không cần thêm cờ. Muốn dùng tài khoản khác thì thêm `--dart-define=CLOUDINARY_CLOUD_NAME=<cloud name> --dart-define=CLOUDINARY_UPLOAD_PRESET=<preset>`; truyền cloud name rỗng thì tắt tải lên. Cách tạo tài khoản và preset: đăng ký Cloudinary gói Free → Settings → Upload → Add upload preset → Signing mode **Unsigned**, Allowed formats `pdf`, Max file size 5 MB. Settings → Security: bật "Allow delivery of PDF and ZIP files" để mở được link. Không đưa API secret vào app hay repo. Cloud name rỗng, hoặc Remote Config `report_cloud_upload=false`, thì PDF chỉ lưu trên máy.

`GOOGLE_SERVER_CLIENT_ID` là Web client ID (Firebase console → Authentication → Sign-in method → Google). Có thể giới hạn email theo vai trò bằng `--dart-define=LECTURER_DOMAIN=fe.edu.vn --dart-define=STUDENT_DOMAIN=fpt.edu.vn` (để trống khi dùng tài khoản test).

**Admin đầu tiên:** đăng nhập web admin một lần, màn báo chưa có quyền và hiện UID; sửa `users/<uid>.role` thành `admin` trên console.

## Chạy

```bash
# App giảng viên
cd mobile && flutter run      # Cloudinary và Google client id đã có giá trị mặc định

# Cổng sinh viên
cd mobile && flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=<key>

# Web admin
cd web && flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=<key>

# Deploy bốn site Hosting: sinh viên, admin, TV, FAP giả (quyết định 002)
RECAPTCHA_SITE_KEY=<key> ./tool/build_hosting.sh && (cd firebase && firebase deploy --only hosting)
```

### Desktop giảng viên (Windows)

Cùng mã `mobile/`, build ra `attendo.exe`. Phải build trên máy Windows có Visual Studio 2022 (workload "Desktop development with C++"); Flutter không build Windows từ Linux hay macOS.

```powershell
cd mobile
flutter pub get
flutter run -d windows                      # chạy thử
flutter build windows --release
# File chạy: mobile\build\windows\x64\runner\Release\attendo.exe (chép cả thư mục Release khi mang sang máy khác)
```

CI (job `windows`) cũng build bản này mỗi lần push và đính kèm thư mục Release tên `attendo-windows` trong trang Actions, tải về là chạy được.

Bản Windows và app Android dùng chung tài khoản và Firestore, nên mở slot trên laptop thì điện thoại thấy ngay và ngược lại. Màn rộng có thanh tab dọc bên trái; nút **Chiếu lên TV** mở link màn chiếu như trên điện thoại. FlutterFire trên Windows có Core, Auth, Firestore, Remote Config; không có Crashlytics, FCM, Analytics, Google Sign-In. Vì vậy bản này:

- đăng nhập bằng email (không có nút Google);
- đọc Remote Config như Android, lỗi thì dùng giá trị mặc định trong app; Gợi ý AI luôn tắt;
- không có Crashlytics, FCM, thông báo nhắc slot (các phần này chạy trên Android);
- không bật App Check (Windows chỉ có debug provider). Nếu bật **Enforce** App Check cho Firestore thì bản Windows bị từ chối; chỉ Enforce cho AI Logic, còn Firestore để chế độ theo dõi (Monitor).

### FAP giả lập và extension điền điểm danh

- `fap-mock/`: trang FAP giả lập (`mock-fap-v2`, không phải FAP thật). Lớp và sinh viên lấy từ `mobile/sample-data/lop-fall-2026.csv`, đúng file giảng viên nhập vào Attendo. Chạy ở https://attendo-app-2611-fap.web.app sau khi deploy Hosting, hoặc `cd fap-mock && npm ci && npm run dev` (cổng 4173).
- `extension/`: extension Chrome/Edge (từ Lab 1). Nguồn **Attendo** đăng nhập bằng tài khoản giảng viên Attendo, tìm slot đã chốt cùng môn và lớp với trang FAP, rồi điền hộ; giảng viên tự kiểm và bấm Save. Extension đọc thẳng Firestore qua REST, Security Rules chỉ cho đọc slot của chính mình.

```bash
cd extension && npm ci && npm run build      # rồi chrome://extensions → Load unpacked → extension/dist
```

CI (job `extension`) đính kèm sẵn thư mục `dist` tên `attendo-extension`.

### Demo nhanh

1. Đăng ký giảng viên → xác nhận email → “Nhập lớp ngay” → chọn `mobile/sample-data/lop-fall-2026.csv` (chép vào máy qua `adb push mobile/sample-data/lop-fall-2026.csv /sdcard/Download/`) → màn “Đã gửi 4 lớp · Chờ giáo vụ duyệt”.
2. Admin đăng nhập web admin → **Duyệt lớp** → Duyệt (hoặc Từ chối kèm lý do). App giảng viên đổi ngay, hộp thư có tin kết quả.
3. Đăng ký sinh viên trên web với MSSV có trong file (ví dụ `SE190101`).
4. Giảng viên mở slot đang diễn ra → **Điểm danh** (có thể **Chiếu lên TV**, mở link trên máy chiếu) → sinh viên **Quét mã** hoặc **Nhập mã** 6 số → bộ đếm tăng thời gian thực → **Đóng mã** → bật tay em chưa quét → **Chốt** (một lần, có Hoàn tác).
5. Khu demo Firebase: Tài khoản → Firebase → Khu demo (FCM token, xuất PDF lên Cloudinary, Remote Config, Crashlytics). Bấm **Lỗi non-fatal** hoặc **Test crash**, rồi đăng nhập web admin bằng tài khoản Admin → **Sự cố**: dòng mới hiện ngay; stack đầy đủ xem ở Crashlytics console.
   Gửi thông báo FCM tới máy giảng viên: `tool/fcm/send.mjs`, cách chạy và giải thích token ở [docs/fcm.md](docs/fcm.md).
6. Điền FAP: mở `/fap/`, chọn ngày và buổi trùng slot vừa chốt → mở extension → **Đọc trang** → nguồn **Attendo** → **Lấy bản đã chốt** → xem trước → điền → giảng viên bấm Save (giả lập).

### Chạy trên Firebase Emulator (không đụng dữ liệu thật)

Dùng để xem giao diện, chụp màn, demo khi không có mạng tới Firebase. Mật khẩu chung `Demo@123`: giảng viên `quanm@fe.edu.vn`, sinh viên `dung101@fpt.edu.vn`, quản trị `admin@fe.edu.vn` (giáo vụ `giaovu@fe.edu.vn` có sẵn nhưng web admin chưa mở cho vai trò này). Lớp mẫu đã được duyệt; PRM393 SE1801 được đặt vào slot đang diễn ra lúc tạo dữ liệu.

```bash
cd firebase/tests && npm ci
npx firebase emulators:start --config ../firebase.json --project attendo-app-2611 --only auth,firestore
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
| CodeRabbit | Review PR #28 (lượt 2, CR-15 đến CR-30) |
