# Crashlytics và web admin Sự cố (T6)

Chạy thật ngày 09/11/2026, project `attendo-app-2611`, điện thoại Oppo (app Attendo `app.attendo`, đăng nhập
quanm@fe.edu.vn), Khu demo → mục Crashlytics. Ảnh 03, 04 do thien chụp; ảnh 01, 02 chụp lại ngày 11/11/2026 (Claude bấm trên điện thoại qua adb, chụp web admin bằng Claude in Chrome).

| Ảnh | Thấy gì |
|---|---|
| `01-web-admin-non-fatal.png` | Chạy lại 11/11/2026 với giao diện cobalt, tài khoản giảng viên demo trên điện thoại. 21:41:09 bấm "Lỗi non-fatal": web admin Sự cố hiện dòng 11/11 21:41 (demo_import_parse, Giảng viên, android). Dòng 21:00 "Lỗi giao diện" (uncaught_async) là lỗi thật có sẵn từ trước, không do bước này tạo |
| `02-web-admin-test-crash.png` | 11/11/2026, 21:49:56 bấm "Test crash" (app thoát), 21:50:01 mở lại app để gửi báo cáo: thêm dòng 11/11 21:49 Test crash (demo_test_crash). Ảnh 01 và 02 chụp vùng trang của Chrome (không có thanh địa chỉ), URL `attendo-app-2611-admin.web.app/#/crashes`; đã làm mờ tên Admin ở góc trái dưới |
| `03-crashlytics-console.png` | Crashlytics console, app Attendo Android: 2 crash ngày 09/11, 1 người dùng |
| `04-keys.png` | Chụp 11/11. Issue `FlutterFirebaseCrashlyticsPlugin`, sự kiện 09/11 20:26 trên CPH1931, tab **Keys**: `flutter_error_exception`, `flutter_error_reason = thrown demo_import_parse`, `last_error_where = demo_import_parse`. Sự kiện này chỉ có 3 khoá trên (thien kiểm lại 11/11 06:43). `role` được ghi lúc đăng nhập hoặc khi nhập lớp thành công, `term` chỉ khi nhập lớp thành công; mở app khi đã đăng nhập sẵn thì hai khoá này không được ghi, nên sự kiện này không có chúng (hạn chế đã biết, thien chọn giữ ảnh 11/11). Đã che avatar tài khoản |

Vì sao có cả hai nơi: Crashlytics không có API đọc cho app hay web, nên app ghi thêm một bản tóm tắt vào
`crashReports` (Security Rules chỉ cho Admin đọc) để web admin hiện được; stack đầy đủ xem ở console.
Claude cũng kiểm luồng này lúc 18:22 đến 18:23 trước lần nạp lại dữ liệu 19:55 (`docs/STATUS.md`).
