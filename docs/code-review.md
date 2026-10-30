# AI code review · quyết định và sửa

> Đề Lab 3 mục 8, Appendix C. AI tìm, người quyết định. Bản ghi gốc của lượt review: [`evidence/code-review/claude-review-2026-10-30.md`](../evidence/code-review/claude-review-2026-10-30.md).
>
> **Lượt 1** (30/10/2026): Claude (Claude Code) review toàn bộ thay đổi `c155368..aef9fa3`.
> **Lượt 2** (cần làm): mở pull request trên GitHub và chạy thêm CodeRabbit hoặc GitHub Copilot code review để có phát hiện gắn dòng ngay trên PR; chép kết quả vào bảng dưới (CR-08 trở đi) và lưu ảnh ở `evidence/code-review/`.

## Phát hiện và quyết định

| ID | Tool | File:line | Loại | Phát hiện (tóm tắt) | Quyết định | Lý do | Fix commit |
|---|---|---|---|---|---|---|---|
| CR-01 | Claude | `firebase/firestore.rules:48` (+ `lib/services/student_attendance_repository.dart:78`) | Security | Mọi sinh viên đọc được slot bất kỳ, gồm `qrToken`: có thể điểm danh từ xa bằng cách đọc token đang dùng | **Accepted** | Phá mục tiêu chính của mã QR (chống điểm danh hộ); đề mục 6 yêu cầu luật chỉ cho quyền cần thiết. Sửa: bỏ quyền đọc slot của sinh viên, thông tin slot đi kèm mã QR (`qa2|…`), Rules đối chiếu từng trường với slot thật bằng `get()` và kiểm MSSV có trong lớp bằng `exists()` | [`5c03f09`](https://github.com/thiengthb/PRM393_Lab03_SE190533/commit/5c03f09) |
| CR-02 | Claude | `lib/viewmodels/account_viewmodels.dart:56` | Performance | Lịch nhắc bị hủy và đặt lại toàn bộ mỗi khi có một bản ghi điểm danh mới | **Accepted** | Đo được: phiên 35 sinh viên → ~35 lần `cancelAllPendingNotifications` + đặt lại; nay chỉ chạy khi giờ / trạng thái slot hoặc công tắc nhắc đổi (key so sánh bằng `select`) | [`992e2d9`](https://github.com/thiengthb/PRM393_Lab03_SE190533/commit/992e2d9) |
| CR-03 | Claude | `lib/app.dart:25` | Architecture | Widget gốc gọi thẳng `MessagingService` | **Accepted** | Vi phạm luật mục 5 “View chỉ nói chuyện với ViewModel”. Sửa: `NotificationRouteViewModel` giữ route cần mở, widget chỉ `ref.listen` | [`3865239`](https://github.com/thiengthb/PRM393_Lab03_SE190533/commit/3865239) |
| CR-04 | Claude | `lib/firebase/messaging_service.dart:37` | Maintainability | Kiểm trùng thông báo bằng so chuỗi JSON | **Accepted** | FCM có thể giao lại cùng một tin (đã mở từ khay rồi app nhận lại qua `getInitialMessage`); so chuỗi sẽ lọt nếu định dạng JSON đổi. Giữ `shared_preferences` (không thêm thư viện), giải mã rồi so trường `id` | [`8e2e575`](https://github.com/thiengthb/PRM393_Lab03_SE190533/commit/8e2e575) |
| CR-05 | Claude | `lib/services/import_service.dart:206` | Test gap | Nhánh đọc `.xlsx` không có test | **Accepted** | GV-100 hứa “Excel hoặc CSV”; viết test đã lộ thêm lỗi thật: ô ngày Excel đọc thành `2026-09-07T00:00:00` thay vì `07/09/2026` → thêm `cellText` | [`c4452ea`](https://github.com/thiengthb/PRM393_Lab03_SE190533/commit/c4452ea) |
| CR-06 | Claude | `lib/services/slot_repository.dart:73` | Performance | Nghe mọi bản ghi điểm danh ở mọi kỳ | **Rejected** | Ràng buộc thật: một kỳ ≈ 4 lớp × 35 em × 20 buổi = 2.800 bản ghi, dưới hạn 50.000 lần đọc/ngày của gói Spark; lọc theo kỳ cần chỉ mục ghép collection group và làm GV-003 kỳ cũ mất số Chú ý. Xem lại ở bài Final khi có dữ liệu nhiều kỳ | — |
| CR-07 | Claude | `lib/services/student_attendance_repository.dart:78` | Bug | Đọc thừa danh sách lớp phía sinh viên trước khi ghi | **Accepted** (gộp CR-01) | Luật đã kiểm bằng `exists()`; bỏ lần đọc giảm 1 read mỗi lần quét và bớt một quyền đọc của sinh viên | [`5c03f09`](https://github.com/thiengthb/PRM393_Lab03_SE190533/commit/5c03f09) |

Đủ yêu cầu: 7 phát hiện gắn file và dòng, 5 loại (security, performance, architecture, maintainability, test gap, bug); 5 phát hiện được sửa, mỗi phát hiện một commit có tên ID.

## Kiểm luật kiến trúc (lặp lại trước khi nộp)

```bash
# Không màn hình hay widget nào import SDK hoặc provider service
grep -rln "providers.dart\|firebase_\|cloud_firestore\|FirebaseAuth.instance" lib/screens lib/widgets lib/app.dart
# Không có lời gọi SDK ngoài services/, firebase/, main.dart, providers.dart
grep -rln "\.instance" lib | grep -v "lib/services\|lib/firebase\|lib/main.dart\|lib/providers.dart"
```

## Công cụ AI đã dùng trong Lab 3

| Công cụ | Dùng vào việc gì |
|---|---|
| Claude (Anthropic) qua Claude, có công cụ Figma MCP | Đọc Final UI và Prototype từ Figma; viết tài liệu Lab 2 còn thiếu; sinh mã Flutter (theme, widget, service, ViewModel, màn hình), Security Rules, test Dart, bộ test ARTEMIS, các file `docs/`; review mã (lượt 1) và sửa 5 phát hiện. Sinh viên đọc lại, chạy và chịu trách nhiệm từng phần |
| Google ARTEMIS (model đa phương thức cấu hình trong ARTEMIS) | Chạy test E2E trên Android, phiên khám phá Pro |
| (Lượt 2) CodeRabbit hoặc GitHub Copilot code review | Review pull request |
