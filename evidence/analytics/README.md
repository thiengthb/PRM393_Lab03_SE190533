# Analytics: DebugView (E3)

Chạy thật ngày 10/11/2026, project `attendo-app-2611`, điện thoại Oppo CPH1931 (app `app.attendo` bản dev, chế độ debug bật bằng `adb shell setprop debug.firebase.analytics.app app.attendo`). Ảnh do thien chụp trên DebugView, làm theo `docs/manual-test/lab3-evidence.md` mục E3.

| Ảnh | Sự kiện thấy trên ảnh |
|---|---|
| `04-sign-up.png` | `sign_up` (11:41), kèm `app_exception` và `user_engagement` |
| `05-import-logout.png` | `import_classes` (11:48:23), `logout` (11:48:34) |
| `06-login.png` | `login` (11:48:48), user property `role = lecturer` |
| `03-attendance-close.png` | `attendance_close` với tham số `absent_count`, `class_id`, `duration_sec` |
| `07-view-class-export.png` | `view_class` (11:50:35), `export_report` (11:50:44) |
| `01-debugview.png` | `reminder_send` (12:09:41), `correction_review` (12:09:54) |
| `08-view-student.png` | `view_student` (12:09:35), cột Top events: `view_student` 3 lần |
| `09-session-open.png` | `attendance_session_open` (21:08:02) với tham số `class_id`; chụp 21:09 cùng ngày |
| `analytics-04-web-student.png` | Web sinh viên, 11/11/2026: `page_view` (6:35:09), `qr_scan` (6:35:10, mã sai `000000`), `correction_submit` (6:35:48); Debug device **Microsoft** (trình duyệt Edge, bật debug bằng Tag Assistant) |

Đủ 13 trên 13 sự kiện trong `docs/analytics-plan.md` đã thấy trên DebugView. Ảnh web: chụp màn hình thật trên laptop của thien qua Remote Control, che avatar tài khoản Google và avatar trình duyệt. URL trên ảnh có `app/android:app.attendo` vì đó là app đang chọn ở đầu console; sự kiện vẫn đến từ thiết bị web Microsoft.
