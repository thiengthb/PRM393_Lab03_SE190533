# Analytics event plan · Quick Attend

> Viết trước khi gắn mã (đề Lab 3 mục 6, Appendix A). Mã ở `lib/firebase/analytics_service.dart`; mọi sự kiện gọi từ ViewModel.
> **Không dữ liệu cá nhân:** không email, tên, MSSV. `class_id` là id tài liệu Firestore (chuỗi ngẫu nhiên theo giảng viên), `subject` là mã môn (PRM393).
> User ID đặt sau đăng nhập (`setUserId(uid)`), user property `role` = lecturer | student.

## 1. Câu hỏi sản phẩm

Tiêu chí thành công Lab 2 ([persona](https://github.com/thiengthb/prm323-lab2-SE190533/blob/main/ux/persona.md)):
- **TC-1** mở app tới chốt một slot ≤ 20 giây khi lớp đã quét xong.
- **TC-2** cuối ngày dạy 0 slot chưa chốt mà thầy không được nhắc.
- **TC-3** từ Tổng quan chỉ ra sinh viên cần chú ý ≤ 10 giây.
- **TC-5** sinh viên đọc được số buổi còn được vắng ngay sau khi quét.

## 2. Sự kiện

| # | Event | Trigger (ViewModel) | Parameters (type) | Câu hỏi trả lời | Bước flow Lab 2 |
|---|---|---|---|---|---|
| 1 | `login` (recommended) | Đăng nhập thành công (`LoginViewModel`) | `method` (string: password, google) | Bao nhiêu người quay lại mỗi tuần; Google hay email được dùng nhiều hơn? | FL-0 GV-090 |
| 2 | `sign_up` (recommended) | Tạo tài khoản (`SignUpViewModel`) | `method` (string), `role` (string) | Tỉ lệ đăng ký → nhập lớp lần đầu (ghép với #4) | FL-0 GV-091 |
| 3 | `logout` | Đăng xuất (`AccountViewModel`) | — | Phiên dài bao lâu trước khi đăng xuất; có ai đăng xuất ngay sau khi nhập lớp lỗi không? | GV-004 .C |
| 4 | `import_classes` | Ghi lớp thành công (`ImportViewModel`) | `class_count` (int), `student_count` (int), `row_errors` (int) | File phòng đào tạo có hay lỗi không; bao nhiêu người phải “Bỏ qua” dòng lỗi? | FL-0, FL-0b GV-100 |
| 5 | `attendance_session_open` | Mở mã QR (`SessionViewModel`) | `class_id` (string), `subject` (string), `slot_no` (int) | Slot nào được mở điểm danh; slot nào không bao giờ mở (so với lịch)? | FL-1 GV-102 .D1 |
| 6 | `attendance_close` | Chốt xong hoặc lưu trên máy (`SessionViewModel`) | `class_id` (string), `present_count` (int), `absent_count` (int), `manual_count` (int), `duration_sec` (int), `offline` (int 0/1) | **TC-1**: thời gian từ mở mã tới chốt; bao nhiêu em phải bật tay (mã QR có đủ không); chốt lúc mất mạng bao nhiêu lần | FL-1, FL-2 GV-102 .S, .X |
| 7 | `view_class` | Mở GV-103 (`ClassDetailViewModel`) | `class_id` (string), `subject` (string) | Lớp nào được xem nhiều; giảng viên có xem lớp trước khi xuất báo cáo không? | FL-3 GV-103 |
| 8 | `view_student` | Mở GV-201 (`StudentProfileViewModel`) | `class_id` (string), `absent_count` (int), `absence_limit` (int) | **TC-3**: hồ sơ mở ra có đúng là em sắp chạm / vượt ngưỡng không? | FL-3 GV-201 |
| 9 | `reminder_send` | Gửi nhắc (`StudentProfileViewModel`) | `class_id` (string), `absent_count` (int) | Nhắc ở mức vắng nào (3/4 hay 5/4)? Nhắc sớm có giảm số em vượt ngưỡng không? | FL-3 GV-OV3 |
| 10 | `qr_scan` | Sinh viên quét (`ScanViewModel`) | `result` (string: success, expired, invalid, notInClass, network, alreadyClosed) | Bao nhiêu lần quét thất bại vì mã hết hạn → chu kỳ `qr_rotate_seconds` có quá ngắn không? | FL-4 SV-101 |
| 11 | `correction_submit` | Gửi báo sai (`ReportViewModel`) | `subject` (string), `reason` (string) | Lý do báo sai phổ biến nhất (mạng, quên quét)? | FL-4 SV-102 |
| 12 | `correction_review` | Duyệt / từ chối (`RequestsViewModel`) | `decision` (string), `reason` (string, khi từ chối) | Tỉ lệ duyệt; lý do từ chối nào hay gặp? | FL-4b GV-105 |
| 13 | `export_report` | PDF tải lên Storage xong (`ClassDetailViewModel`) | `class_id` (string), `file_size_kb` (int) | Lớp nào được xuất báo cáo; xem lớp (#7) dẫn tới xuất bao nhiêu lần? | Khu demo, GV-103 |

13 sự kiện (đề yêu cầu ≥ 7): đủ đăng nhập, đăng xuất, hành động chính (#5, #6), mỗi loại màn chi tiết (#7 lớp, #8 sinh viên), xuất và tải file (#13).

## 3. Phễu theo flow

| Flow | Phễu | Rơi ở đâu thì thấy |
|---|---|---|
| FL-0 | `sign_up` → `import_classes` → `attendance_session_open` | đăng ký nhưng không nhập lớp; nhập lớp có `row_errors` > 0 |
| FL-1 | `attendance_session_open` → `attendance_close` | mở mã mà không chốt; `duration_sec` > 20 giây (TC-1) |
| FL-3 | `view_student` → `reminder_send` | xem hồ sơ nhưng không nhắc |
| FL-4 | `qr_scan` (success) / (expired) → `correction_submit` → `correction_review` | quét thất bại nhiều → báo sai nhiều |

## 4. Bằng chứng

Bật debug: `adb shell setprop debug.firebase.analytics.app vn.edu.fpt.quick_attend`, mở Firebase console → Analytics → DebugView, làm từng flow theo `docs/test-plan.md`. Ảnh chụp từng sự kiện lưu ở `evidence/analytics/<event>.png`.

| Event | Ảnh DebugView |
|---|---|
| login | `evidence/analytics/login.png` |
| sign_up | `evidence/analytics/sign_up.png` |
| logout | `evidence/analytics/logout.png` |
| import_classes | `evidence/analytics/import_classes.png` |
| attendance_session_open | `evidence/analytics/attendance_session_open.png` |
| attendance_close | `evidence/analytics/attendance_close.png` |
| view_class | `evidence/analytics/view_class.png` |
| view_student | `evidence/analytics/view_student.png` |
| reminder_send | `evidence/analytics/reminder_send.png` |
| qr_scan | `evidence/analytics/qr_scan.png` |
| correction_submit | `evidence/analytics/correction_submit.png` |
| correction_review | `evidence/analytics/correction_review.png` |
| export_report | `evidence/analytics/export_report.png` |
