# PRM393 Lab 3 · Quick Attend · SE190533

App Flutter trên Firebase dựng từ thiết kế Lab 2: **giảng viên FPTU điểm danh bằng mã QR** (app Android), **sinh viên quét mã và xem chuyên cần** (Flutter Web, điện thoại và laptop). Kiến trúc MVVM + Riverpod, 6 dịch vụ Firebase, test E2E bằng Google ARTEMIS, review mã bằng AI.

| Mục | Nội dung |
|---|---|
| Sinh viên | Trần Ngọc Thiên · SE190533 |
| Thiết kế Lab 2 | Figma [PRM323 Lab 2 v2](https://www.figma.com/design/1qIZVpL0Q7bD9UzT5TVBRy) (trang 01–06) · repo [prm323-lab2-SE190533](https://github.com/thiengthb/prm323-lab2-SE190533) (`design/DESIGN.md`, `handoff/flutter-handoff.md`) |
| Persona, tiêu chí | P-01 giảng viên 3–4 slot/ngày; TC-1 chốt một slot ≤ 20 giây, TC-2 không slot nào chưa chốt mà không được nhắc, TC-3 tìm em cần chú ý ≤ 10 giây |
| Nguồn dữ liệu | **Cloud Firestore** (dữ liệu của chính giảng viên: lớp, lịch, sinh viên nhập từ file Excel/CSV; phiên điểm danh; yêu cầu sửa). Không dùng dữ liệu mẫu cứng trong app; file mẫu để nhập ở `sample-data/` |
| Video demo | _(dán link sau khi quay)_ |

## Bản đồ sản phẩm nộp

| Sản phẩm | Ở đâu |
|---|---|
| Truy vết thiết kế → mã, mọi khác biệt và lý do | [docs/design-traceability.md](docs/design-traceability.md) |
| Kiến trúc: thư mục, sơ đồ lớp, sơ đồ tuần tự, bảng ViewModel | [docs/architecture.md](docs/architecture.md) |
| Kế hoạch sự kiện Analytics | [docs/analytics-plan.md](docs/analytics-plan.md) |
| Test plan, kết quả ARTEMIS, phiên khám phá | [docs/test-plan.md](docs/test-plan.md), [e2e_test/](e2e_test/) |
| AI code review, quyết định, commit sửa | [docs/code-review.md](docs/code-review.md) |
| Security Rules, Remote Config mặc định | [firebase/](firebase/) |
| Bằng chứng (console, DebugView, Crashlytics, ARTEMIS) | [evidence/](evidence/) |
| Báo cáo, slide | `report/Lab03_SE190533.pdf`, `slides/Lab03_SE190533_slides.pdf` |

## Cài đặt và chạy app

Cần: Flutter stable **≥ 3.38**, tài khoản Firebase (gói Spark), Node (cho Firebase CLI), Android 13+ hoặc emulator có Google Play.

```bash
git clone https://github.com/thiengthb/PRM393_Lab03_SE190533 && cd PRM393_Lab03_SE190533

# 1. Sinh thư mục nền tảng (không ghi đè lib/), rồi sửa android/ cho đúng yêu cầu plugin
flutter create . --org vn.edu.fpt --project-name quick_attend --platforms=android,web
python tool/patch_android.py
flutter pub get

# 2. Nối Firebase (tạo lib/firebase_options.dart và android/app/google-services.json)
npm i -g firebase-tools && firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=<project-id> --platforms=android,web

# 3. Bật dịch vụ trên console: Authentication (Email/Password, Google), Firestore,
#    Storage, Remote Config, Crashlytics, Messaging. Thêm SHA-1 debug cho Google Sign-In:
#    cd android && ./gradlew signingReport
# 4. Đẩy Security Rules, chỉ mục, Remote Config mặc định
firebase use <project-id>
firebase deploy --only firestore:rules,firestore:indexes,storage,remoteconfig

# 5. Chạy
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com   # app giảng viên
flutter run -d chrome                                                                          # web sinh viên
flutter run --dart-define=PORTAL=student                                                       # bản sinh viên trên Android (test FL-4)
flutter test                                                                                   # unit test ViewModel, logic
```

`GOOGLE_SERVER_CLIENT_ID` là Web client ID (Firebase console → Authentication → Sign-in method → Google). Có thể giới hạn email theo vai trò bằng `--dart-define=LECTURER_DOMAIN=fe.edu.vn --dart-define=STUDENT_DOMAIN=fpt.edu.vn` (để trống khi dùng tài khoản test).

Web sinh viên lên Hosting: `flutter build web && firebase deploy --only hosting`.

### Demo nhanh

1. Đăng ký giảng viên → xác nhận email → “Nhập lớp ngay” → chọn `sample-data/lop-fall-2026.csv` (chép vào máy qua `adb push sample-data/lop-fall-2026.csv /sdcard/Download/`).
2. Đăng ký sinh viên trên web với MSSV có trong file (ví dụ `SE190101`).
3. Giảng viên mở slot đang diễn ra → **Điểm danh** → sinh viên **Quét mã** → bộ đếm tăng thời gian thực → **Chốt**.
4. Khu demo Firebase: Tài khoản → Firebase → Khu demo (FCM token, xuất PDF lên Storage, Remote Config, Crashlytics).

## Chạy test E2E (ARTEMIS)

Xem [docs/test-plan.md](docs/test-plan.md) mục 3. Tóm tắt: khởi động daemon ARTEMIS (repo `google/artemis`, commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`), rồi

```bash
cd e2e_test && uv sync && cp .env.example .env
uv run pytest --count=3
uv run python report.py > ../evidence/artemis/results.md
```

## Phiên bản

Ràng buộc trong `pubspec.yaml` là khoảng; bản thật sự dùng được ghi trong `pubspec.lock` sau `flutter pub get` và chép vào bảng này trước khi nộp.

| Thành phần | Phiên bản |
|---|---|
| Flutter / Dart | _(flutter --version)_ |
| firebase_core / auth / cloud_firestore / storage / messaging / analytics / crashlytics / remote_config | ^5 / ^7 / ^7 / ^14 / ^17 / ^13 / ^6 / ^7 |
| flutter_riverpod · go_router · google_sign_in | ^3 · 16–18 · ^7.2 |
| mobile_scanner · qr_flutter · file_selector · excel · pdf · printing | ^7 · ^4.1 · ^1.0.3 · ^4.0.6 · ^3.11 · ^5.14 |
| Google ARTEMIS | commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` |
| Python | ≥ 3.12, uv |

## Công cụ AI đã dùng

| Công cụ | Dùng vào việc gì |
|---|---|
| Claude (Anthropic), kèm Figma MCP | Đọc Figma Final UI/Prototype; viết tài liệu Lab 2 còn thiếu; sinh mã Flutter, Security Rules, unit test, bộ test ARTEMIS, tài liệu `docs/`; review mã lượt 1 và sửa 5 phát hiện ([code-review](docs/code-review.md)) |
| Google ARTEMIS | Test E2E trên Android (Flash), phiên khám phá (Pro) |
| CodeRabbit hoặc GitHub Copilot code review | Review pull request (lượt 2) |
