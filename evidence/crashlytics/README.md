# Crashlytics và web admin Sự cố (T6)

Chạy thật ngày 09/11/2026, project `attendo-app-2611`, điện thoại Oppo (app Attendo `app.attendo`, đăng nhập
quanm@fe.edu.vn), Khu demo → mục Crashlytics. Ảnh do thien chụp.

| Ảnh | Thấy gì |
|---|---|
| `01-web-admin-non-fatal.png` | 20:25 bấm "Lỗi non-fatal": web admin Sự cố hiện ngay 1 dòng (demo_import_parse, Giảng viên, android) |
| `02-web-admin-test-crash.png` | 20:26 bấm "Test crash": thêm dòng Test crash (demo_test_crash) |
| `03-crashlytics-console.png` | Crashlytics console, app Attendo Android: 2 crash ngày 09/11, 1 người dùng |
| `04-keys.png` | Chụp 11/11. Issue `FlutterFirebaseCrashlyticsPlugin`, sự kiện 09/11 20:26 trên CPH1931, tab **Keys**: `flutter_error_exception`, `flutter_error_reason = thrown demo_import_parse`, `last_error_where = demo_import_parse`. Khoá `role`, `term` nằm dưới khung ảnh, chưa có trên ảnh. Đã che avatar tài khoản |

Vì sao có cả hai nơi: Crashlytics không có API đọc cho app hay web, nên app ghi thêm một bản tóm tắt vào
`crashReports` (Security Rules chỉ cho Admin đọc) để web admin hiện được; stack đầy đủ xem ở console.
Claude cũng kiểm luồng này lúc 18:22 đến 18:23 trước lần nạp lại dữ liệu 19:55 (`docs/STATUS.md`).
