# Remote Config: hai tham số đổi hành vi app (E4)

Chạy thật tối 10/11/2026, project `attendo-app-2611`, điện thoại Oppo CPH1931 (app `app.attendo`, giảng viên nick 024). thien đổi giá trị trên console; Claude điều khiển điện thoại qua adb và chụp màn hình (Remote Control trên laptop của thien). Ảnh console đã che avatar tài khoản.

| Ảnh | Lúc | Thấy gì |
|---|---|---|
| `01-before-overview.png` | 21:23 | Trước khi đổi: Tổng quan, mục Vắng nhiều `6/4`, `5/4` (ngưỡng 20% của 20 buổi = 4, màu đỏ) |
| `02-before-khudemo.png` | 21:24 | Khu demo: `absence_limit_percent 20%`, `qr_rotate_seconds 12s`, nguồn `remote` |
| `03-console-published.png` | trước 22:09 | Console sau khi Publish: `absence_limit_percent = 30`. Dòng `qr_rotate_seconds` nằm thấp hơn trong bảng, không vào khung; giá trị 15 thấy ở ảnh 04 và 06 |
| `04-after-khudemo.png` | 22:09 | Sau khi bấm Tải lại: `30%`, `15s`, lần tải 10/11 22:09 |
| `05-after-overview.png` | 22:09 | Vắng nhiều thành `6/6`, `5/6`: ngưỡng lên 6 buổi, hai em chuyển từ đỏ (vượt) sang vàng (sát ngưỡng) |
| `06-session-15s.png` | 22:02 | Mở lại mã sau khi đổi: dòng dưới mã ghi **Đổi mã 15s** (trước đây 12s) |

Không dựng lại app: cùng một bản cài, chỉ đổi giá trị trên console rồi bấm Tải lại (app cũng nghe cập nhật thời gian thực).

Sau khi chụp, Remote Config đã trả về `12` và `20`; Khu demo xác nhận lúc 11/11 05:52.

Ghi chú trung thực: lần Publish đầu tiên `absence_limit_percent` bị gõ nhầm thành `4`; app hiện `4%`, nên chưa chụp ảnh sau. Sửa thành `30`, Publish lại, rồi mới chụp ảnh 03 đến 05.
