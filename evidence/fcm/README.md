# FCM: thông báo ở 3 trạng thái app (T5)

Chạy thật ngày 09/11/2026, 20:15 đến 20:20, project `attendo-app-2611`, điện thoại Oppo CPH1931 (app Attendo
đăng nhập quanm@fe.edu.vn). Gửi bằng Firebase console → Cloud Messaging → Compose notification →
**Send test message** tới FCM token chép từ Khu demo của app. Ảnh do thien chụp.

| Ảnh | Trạng thái app | Thấy gì |
|---|---|---|
| `01-app-dang-mo.png` | Đang mở (foreground) | Thông báo "Lần 1 - app đang mở" hiện đè lên Tổng quan |
| `02-app-o-nen-banner.png` | Ở nền (bấm Home) | Thông báo "Lần 2 - ở Home" hiện trên màn hình chính, biểu tượng có chấm đỏ |
| `03-app-o-nen-thanh-thong-bao.png` | Ở nền | Tin "Lần 2" trong thanh thông báo |
| `04-app-da-tat.png` | Đã tắt (vuốt khỏi đa nhiệm) | Tin "Lần 3 - app đã tắt" trong thanh thông báo, 20:20 |
| `05-console-soan-thong-bao.png` | | Màn soạn thông báo trên console của project attendo-app-2611 (nội dung Lần 3) |
