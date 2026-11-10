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

Chưa có trên ảnh: `attendance_session_open` (đã làm trên app nhưng chưa chụp đúng phút), `qr_scan`, `correction_submit` (web sinh viên; đề đòi DebugView nên chụp DebugView theo `docs/manual-test/lab3-evidence.md` E3.4, không thay bằng trang Realtime).
