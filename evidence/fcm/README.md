# FCM: thông báo ở 3 trạng thái app (T5)

Chạy thật ngày 11/11/2026, 21:21 đến 21:35 (giờ Việt Nam), project `attendo-app-2611`, điện thoại Oppo CPH1931
(Android, app Attendo 1.0.0 bản giao diện "Bản vẽ" cobalt, đăng nhập tài khoản giảng viên demo). Mỗi lần gửi
chạy workflow GitHub Actions **"Demo: gửi FCM thử"**, workflow này dùng `tool/fcm/send.mjs` (Firebase Admin SDK,
key nằm trong secret của repo) gửi tới mọi thiết bị của tài khoản đó. Ảnh chụp bằng
`adb exec-out screencap` trên chính điện thoại, chụp liên tục khoảng 1 giây một khung và giữ khung có thông báo.

| Ảnh | Trạng thái app | Thấy gì |
|---|---|---|
| `01-app-dang-mo.png` | Đang mở (foreground) | Thông báo "Lần 1 - app đang mở" hiện đè lên Tổng quan, 21:21:41 (workflow chạy 21:21:27) |
| `02-app-o-nen-banner.png` | Ở nền (bấm Home) | Thông báo "Lần 2 - ở Home" hiện trên màn hình chính, biểu tượng Attendo có chấm đỏ, 21:26:33 (workflow chạy 21:26:17) |
| `03-app-o-nen-thanh-thong-bao.png` | Ở nền | Tin "Lần 1" và "Lần 2" trong thanh thông báo, 21:30 |
| `04-app-da-tat.png` | Đã tắt (vuốt khỏi đa nhiệm, tiến trình app không còn chạy) | Tin "Lần 3 - app đã tắt" trong thanh thông báo, đến lúc 21:31:30 (workflow chạy 21:31:15), chụp 21:35 |
| `05-console-soan-thong-bao.png` | | Ảnh từ lần chạy 09/11/2026 (gửi bằng Firebase console): màn soạn thông báo trên console của project attendo-app-2611 (nội dung Lần 3) |

Trong ảnh 03 và 04, một thông báo hệ thống của Google (có địa chỉ email cá nhân) đã được làm mờ.
Không có chỉnh sửa nào khác.
