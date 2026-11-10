# 001. Firebase project mới và mã app Android

Ngày: 09/11/2026 · Trạng thái: Đã chọn · Người quyết: thien

## Cần quyết gì
thien muốn bỏ hẳn tên Hereby và mã số sinh viên, "kể cả project trên Google". Mã Firebase project (`hereby-se190533`) không đổi được sau khi tạo, và nó hiện ở link web, ảnh chụp console, `google-services.json`. Phải quyết trước khi đổi tên trong code, vì mã app và cấu hình Firebase đi cùng nhau.

## Các phương án đã xét
| Phương án | Lúc nào nó là lựa chọn tốt | Lý do mạnh nhất để không chọn |
|---|---|---|
| A. Project mới `attendo-app` (nếu bị trùng thì `attendo-app-<4 số>`), mã app Android `app.attendo` | Muốn sản phẩm sạch tên; project cũ chưa có bằng chứng nào nên không mất gì | Tốn khoảng 40 phút cài lại (bật dịch vụ, khoá service account, SHA-1, cấu hình), và mọi link cũ trong tài liệu phải đổi |
| B. Giữ `hereby-se190533`, chỉ đổi tên hiển thị trong console thành Attendo | Hết giờ, cần chắc chắn không vỡ gì | Mã `hereby-se190533` vẫn nằm trong link web, ảnh console và file cấu hình: đúng thứ thien không muốn |
| C. Project mới nhưng giữ mã app `vn.edu.fpt.quick_attend` | Muốn ít sửa code nhất | Đằng nào cũng phải đăng ký app lại với project mới, đổi mã lúc này gần như không tốn thêm; giữ thì tên cũ còn trong thông tin app |
| D. Giữ project, thêm một site Hosting mới tên attendo | Chỉ cần link web đẹp | Mới sửa một nửa: console, cấu hình, ảnh bằng chứng vẫn mang mã cũ |

## thien chọn
A (09/11, 03:40, trả lời trong chat).

## AI chọn
A. Project cũ chưa có bằng chứng Analytics, Crashlytics hay FCM nào, nên đổi bây giờ là rẻ nhất; để sau khi đã chụp bằng chứng thì phải chụp lại toàn bộ.

## Kết luận
A: project mới, mã project bắt đầu bằng `attendo-app`, mã app Android `app.attendo`. Trùng với lựa chọn của AI. Claude viết hướng dẫn tạo project theo `GUIDES.md`; mọi link, tài liệu, workflow đổi theo.
