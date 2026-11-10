---
title: "PRM393 Lab 3 · Attendo"
subtitle: "Ứng dụng điểm danh bằng mã QR trên Flutter và Firebase"
author: "Trần Ngọc Thiên · SE190533"
date: "11/2026"
lang: vi
---

# 1. Thông tin nộp bài

| Mục | Nội dung |
|---|---|
| Sinh viên | Trần Ngọc Thiên · SE190533 |
| Repo | https://github.com/thiengthb/PRM393_Lab03_SE190533 · nhánh `final-system` (bản Lab 3 v2 gộp vào đây, xem mục 9) |
| Bản cài | GitHub Release `demo`: APK giảng viên, bản Windows, extension |
| Web sinh viên | https://attendo-app-2611.web.app |
| Slide | https://thiengthb.github.io/PRM393_Lab03_SE190533/lab3.html |
| Video | _(dán link sau khi quay)_ |
| Firebase project | `attendo-app-2611`, gói Spark |
| Thiết kế gốc | PRM323 Lab 2, repo `thiengthb/prm323-lab2-SE190533`; mọi chỗ khác thiết kế ghi trong `docs/design-traceability.md` |

Mọi kết quả trong báo cáo này đều có nguồn: link lần chạy CI, file trong `evidence/`, hoặc ảnh chụp. Mục nào chưa chạy thì ghi "chưa chạy", không điền số.

# 2. Sản phẩm

Attendo giúp giảng viên FPTU điểm danh một buổi học trong khoảng một phút thay vì gọi tên. Giảng viên mở phiên trên điện thoại, app hiện mã QR và mã 6 số đổi mỗi 12 giây; sinh viên quét mã hoặc gõ mã trên web; giảng viên đóng mã, bật tay cho em quên quét rồi chốt. Sinh viên xem số buổi vắng của từng môn và báo sai khi bị ghi vắng nhầm; giảng viên duyệt hoặc từ chối.

| Vai trò | Client | Việc chính |
|---|---|---|
| Giảng viên | App Android (và Windows) | Nhập lớp, điểm danh, chốt, chăm sóc em vắng nhiều, duyệt báo sai, xuất PDF |
| Sinh viên | Web (Flutter Web) | Quét mã hoặc gõ mã, xem chuyên cần, báo sai |

![Màn điểm danh trên điện thoại: mã QR, mã 6 số, số đã có mặt](../../slides/assets/img/app/gv-phien-dien-thoai.png){width=28%}

# 3. Kiến trúc

App theo MVVM với Riverpod 3. Phụ thuộc chỉ đi một chiều: `screens/` → `viewmodels/` → `services/`, `firebase/` → SDK. Màn hình không import Firebase; lọc, đếm và quyết định trạng thái nằm ở ViewModel, nên test được mà không cần thiết bị.

| Lớp | Ở đâu | Trách nhiệm |
|---|---|---|
| View | `mobile/lib/screens/` | Dựng giao diện từ state, gửi sự kiện người dùng lên ViewModel |
| ViewModel | `mobile/lib/viewmodels/` (một Notifier mỗi màn) | Giữ `ViewState` (đang tải, rỗng, lỗi, có dữ liệu), gọi service, ghi Analytics |
| Service | `packages/core/lib/services/`, `mobile/lib/services/` | Interface + bản Firestore/Auth; đổi sang bản giả khi test |
| Firebase | `packages/core/lib/firebase/`, `mobile/lib/firebase/` | Analytics, Remote Config, App Check, Crashlytics, Messaging |

Luật kiến trúc được kiểm bằng lệnh `grep` trong `docs/code-review.md` (không màn hình nào import SDK hay provider service) trước mỗi lần nộp. Sơ đồ đầy đủ và giao diện theo thiết bị (một ViewModel, nhiều View) ở `docs/architecture.md`.

# 4. Luồng, dữ liệu và trạng thái

## 4.1 Luồng chính

| Mã | Luồng | Màn |
|---|---|---|
| FL-0 | Đăng nhập, đăng ký, nhập lớp lần đầu | GV-090 đến GV-094, GV-100 |
| FL-1 | Điểm danh một slot: mở mã → sinh viên quét → đóng mã → bật tay → chốt | GV-001, GV-102 |
| FL-2 | Không quên chốt: slot đã qua giờ mà chưa chốt hiện cảnh báo và nút Chốt ngay | GV-001, GV-002 |
| FL-3 | Chăm sóc sinh viên vắng nhiều: xem hồ sơ, gửi lời nhắc | GV-104, GV-201, OV3 |
| FL-4 | Sinh viên quét mã hoặc gõ mã, xem chuyên cần, báo sai | SV-001, SV-002, SV-101, SV-102 |
| FL-4b | Giảng viên duyệt hoặc từ chối báo sai | GV-105 |

## 4.2 Dữ liệu

| Collection | Nội dung | Ai ghi |
|---|---|---|
| `users/{uid}` | vai trò, tên, MSSV (sinh viên) | Chính mình lúc đăng nhập đầu |
| `classes/{id}`, `classes/{id}/students/{mssv}` | lớp và danh sách sinh viên | Giảng viên chủ lớp |
| `slots/{id}` | buổi học, trạng thái mã QR (`qrOpen`, `qrToken`, `qrExpiresAt`, mã vừa thay `qrTokenPrev`) | Giảng viên chủ slot |
| `slots/{id}/attendance/{mssv}` | có mặt hay vắng, nguồn (quét, gõ mã, bật tay) | Sinh viên khi mã đúng; giảng viên |
| `requests/{id}` | yêu cầu báo sai | Sinh viên tạo; giảng viên duyệt |
| `reports/{id}` | metadata file PDF đã xuất | Giảng viên |
| `users/{uid}/fcmTokens/{token}` | token FCM của từng máy | Chủ tài khoản |

Bảng đầy đủ (trường, quyền tạo, đọc, sửa, xoá) ở `docs/data-model.md`.

## 4.3 Trạng thái

Mỗi màn có bốn trạng thái tách biệt ở ViewModel: đang tải, rỗng, lỗi (có nút Thử lại), có dữ liệu. Ví dụ màn điểm danh mất mạng khi chốt: app lưu kết quả trên máy, hiện dải vàng "Chưa gửi được · Đã lưu trên máy" và nút Thử lại; có mạng lại thì tự gửi.

| Thực thể | Chuyển trạng thái |
|---|---|
| Slot | chưa mở → đang mở mã → đã đóng mã → đã chốt (hoàn tác được trong vài giây) |
| Báo sai | chờ duyệt → đã duyệt hoặc bị từ chối (có lý do); bị từ chối thì không báo lại buổi đó |

# 5. Dịch vụ Firebase

Mỗi dịch vụ ghi theo cùng một khung: là gì, code ở đâu, bằng chứng.

## 5.1 Authentication

Đăng nhập bằng email và mật khẩu (có xác nhận email) hoặc Google. Vai trò không nằm trong Auth mà ở `users/{uid}.role`; Security Rules đọc `request.auth.uid` rồi tra vai trò. Code: `packages/core/lib/services/auth_service.dart`, `mobile/lib/viewmodels/auth_viewmodels.dart`.

Bằng chứng: đăng nhập Google trên điện thoại vào thẳng Tổng quan có dữ liệu (10/11/2026, `docs/demo/DEMO-GOOGLE.md`). Ảnh console tab Users và Sign-in method: **đang chờ** (`evidence/auth/`).

## 5.2 Cloud Firestore và Security Rules

Mọi dữ liệu ở Firestore, đọc theo thời gian thực: sinh viên quét xong thì số có mặt trên điện thoại giảng viên tăng ngay. Không có server riêng, nên Security Rules là nơi quyết định ai được làm gì. Luật quan trọng nhất là luật quét mã: sinh viên chỉ ghi được bản điểm danh của chính mình khi mã đúng, còn hạn (mã vừa thay vẫn được nhận thêm một chu kỳ) và em có tên trong lớp; sinh viên không đọc được slot nên không lấy được token.

Bằng chứng: bộ test Rules trên Firebase Emulator, **181 ca đạt, 0 lỗi** (CI, commit `63d8cf9`, run 42742315932). Bảng từng ca ở `evidence/rules/rules-test-results.md`. Ảnh dữ liệu trên console: **đang chờ**.

## 5.3 Cloud Messaging (FCM)

Token FCM là định danh một lần cài app trên một máy, do máy chủ FCM cấp khi app gọi `getToken()` (`mobile/lib/firebase/messaging_service.dart`). App ghi token vào `users/{uid}/fcmTokens/{token}` để nhóm phát triển gửi được tin; chạm thông báo thì app mở màn ghi trong `data.route`. Trả lời đủ các câu hỏi về token ở `docs/fcm.md`.

Bằng chứng: nhận thông báo ở cả ba trạng thái app (đang mở, ở nền, đã tắt), điện thoại thật, 09/11/2026.

![FCM khi app đã tắt](../../evidence/fcm/04-app-da-tat.png){width=30%} ![Soạn tin trên console](../../evidence/fcm/05-console-soan-thong-bao.png){width=60%}

## 5.4 Analytics

13 sự kiện, mỗi sự kiện trả lời một câu hỏi cụ thể và gắn với một bước của luồng Lab 2 (`docs/analytics-plan.md`). Ví dụ `attendance_close` có `present_count`, `absent_count`, `manual_count`, `duration_sec` để đo một buổi điểm danh mất bao lâu và bao nhiêu em phải bật tay. Sự kiện ghi ở ViewModel, không ở màn hình.

Bằng chứng DebugView: **đang chờ** (`evidence/analytics/`).

## 5.5 Crashlytics

Khu demo có nút Test crash và nút ghi lỗi non-fatal. Crashlytics không có API cho client đọc, nên app ghi thêm một bản tóm tắt vào `crashReports` để web admin hiện ở màn Sự cố.

Bằng chứng: 09/11/2026, Crashlytics console có issue `FirebaseCrashlyticsTestCrash`; web admin hiện dòng Test crash ngay sau đó.

![Crashlytics console](../../evidence/crashlytics/03-crashlytics-console.png){width=48%} ![Web admin, màn Sự cố](../../evidence/crashlytics/02-web-admin-test-crash.png){width=48%}

## 5.6 Remote Config

Chín tham số có giá trị mặc định trong app (`firebase/remote-config-defaults.json`), gồm ngưỡng vắng `absence_limit_percent`, chu kỳ đổi mã `qr_rotate_seconds`, cờ tắt AI. App nghe cập nhật thời gian thực; Khu demo hiện giá trị đang dùng và nguồn (remote hay mặc định).

Bằng chứng trước và sau (đổi `qr_rotate_seconds` 12 → 15 giây): **đang chờ** (`evidence/remote-config/`).

## 5.7 Lưu file: Cloudinary thay Cloud Storage

Đề yêu cầu sinh ít nhất một file từ nội dung người dùng đang xem và tải lên. Project ở gói Spark, mà Cloud Storage cần gói Blaze, nên PDF báo cáo lớp được tải lên Cloudinary bằng preset unsigned vào thư mục riêng của từng giảng viên; Firestore `reports` giữ metadata (D-L3-18). Code: `mobile/lib/services/cloud_upload_service.dart`, có test ở `mobile/test/cloud_upload_test.dart`.

Bằng chứng: **đang chờ** ảnh Cloudinary (`evidence/storage/`).

# 6. Giao diện và trợ năng

- Giao diện dựng theo thiết kế Lab 2 v2, sau đó đổi tên Attendo và bảng màu Bản vẽ. Mọi chỗ khác thiết kế có mã trong `docs/design-traceability.md` (D-L3-01 đến D-L3-18, D-T-01 đến D-T-11).
- Vùng bấm ít nhất 48 dp: nút 40 và 36 giữ hình như thiết kế nhưng ô bố cục cao 48 (D-L3-11).
- Mọi nút, công tắc, thẻ slot, bộ đếm có nhãn cho trình đọc màn hình (`Semantics`); ARTEMIS và bộ E2E web đều đọc cây này.
- Màu chữ trên nền đạt tương phản 4,5:1 trở lên; dải cảnh báo luôn có chữ, không chỉ dựa vào màu.

# 7. Kiểm thử

| Loại | Công cụ | Kết quả | Nguồn |
|---|---|---|---|
| Unit và widget test | `flutter test` | 59 test app + 11 test web admin đạt | CI run 42742315932, commit `63d8cf9` |
| Phân tích tĩnh | `flutter analyze` | 0 lỗi, 2 gợi ý (info) | như trên |
| Security Rules | Firebase Emulator | 181 ca đạt | như trên |
| E2E web | Playwright + Emulator | 33/33 ca đạt | workflow E2E builds, run 42644368921 |
| Test tay trên Firebase thật | 6 ca T1 đến T6 | Đạt, có ảnh trong `evidence/` | `docs/demo/TEST-TAY.md` |
| ARTEMIS trên điện thoại thật | Google ARTEMIS (Flash), mỗi ca 3 lần | **chưa chạy** | `evidence/artemis/results.md` |

Kế hoạch 16 ca ARTEMIS của Lab 3 (5 đường lỗi, 4 tương tác native) ở `docs/test-plan.md`.

# 8. Review mã bằng AI

| Lượt | Công cụ | Phạm vi | Kết quả |
|---|---|---|---|
| 1 (30/10) | Claude | Mã Lab 3 | CR-01 đến CR-07: 5 nhận, 2 bác; mỗi phát hiện nhận có commit sửa |
| 3 (02/11) | Claude | Mã Final | CR-08 đến CR-14 |
| 2 (10/11) | GitHub Copilot trên PR #28 | ViewModel, service, Security Rules (38 file) | **đang chờ** |

Mỗi phát hiện ghi file, loại, quyết định (nhận, bác, sửa khác) và lý do ở `docs/code-review.md`. Lượt của Claude không độc lập vì chính Claude viết phần lớn mã; vì vậy lượt 2 dùng công cụ khác.

# 9. Công cụ AI và quy trình

| Công cụ | Dùng làm gì |
|---|---|
| Claude (Claude Code) | Viết phần lớn mã, test, tài liệu; tự test trên Firebase thật qua điện thoại và trình duyệt |
| Google ARTEMIS | Test E2E trên điện thoại thật bằng chỉ dẫn ngôn ngữ tự nhiên |
| GitHub Copilot code review | Review lượt 2 trên PR |
| Gemini (Firebase AI Logic) | Tính năng Gợi ý lời nhắc (phần Final) |

Mỗi phiên làm việc với AI có một dòng trong `docs/ai-log.md`: ai yêu cầu, AI làm gì, kết quả, sinh viên kiểm gì và quyết định gì. Quyết định khó sửa lại (Firebase project, tên repo, App Check) ghi ở `docs/decisions/` với bảng phương án.

Về cấu trúc repo: đề Lab 3 đặt mã ở `lib/` gốc repo. Bản Lab 3 đầu tiên (giao diện cam) giữ nguyên ở nhánh `main`; bản Lab 3 v2 làm trên nhánh `ui-v2` rồi gộp vào `final-system`, nơi mã được tách thành `mobile/`, `packages/core/`, `web/` cho bài Final.

# 10. Giới hạn và bài học

- **Không có server riêng.** Vai trò giảng viên và MSSV do người dùng tự khai; giảm rủi ro bằng Security Rules (kiểm có tên trong lớp khi quét) và bước giáo vụ duyệt lớp ở phần Final.
- **Cloud Storage ngoài gói Spark** nên dùng Cloudinary; đã ghi khác biệt D-L3-18.
- **App Windows không có đăng nhập Google** vì thư viện Google của Flutter chưa hỗ trợ Windows; giảng viên dùng email và mật khẩu trên Windows.
- **Bài học:** viết bằng chứng ngay khi chạy thật thay vì để cuối; test luật bảo mật trên Emulator bắt được lỗi mà test giao diện không thấy (CR-14: giảng viên khác ghi được vào danh sách lớp người khác).
