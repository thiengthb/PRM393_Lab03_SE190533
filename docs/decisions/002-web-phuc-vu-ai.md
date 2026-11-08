# 002. Web phục vụ ai

Ngày: 09/11/2026 · Trạng thái: Đã chọn · Người quyết: thien

## Cần quyết gì
Thầy nhắn: "Team Dev xem trên Firebase, admin phải dùng web; web chỉ cần phục vụ cho Admin". Hiện Hosting có web admin và web sinh viên (thiết kế Lab 2 cho sinh viên quét mã bằng trình duyệt, không cài app). Cần biết web sinh viên có giữ không, vì nó quyết định luồng của sinh viên, test ARTEMIS và slide.

## Các phương án đã xét
| Phương án | Lúc nào nó là lựa chọn tốt | Lý do mạnh nhất để không chọn |
|---|---|---|
| A. Web chỉ còn web admin; sinh viên dùng app Android (bản sinh viên đã có trong code, dựng với PORTAL=student) | Thầy muốn đúng nghĩa đen: mọi người dùng cuối trên app | Đổi luồng sinh viên của Lab 2 (quét bằng web, không cài app), phải sửa luồng, test, tài liệu; sinh viên phải cài APK |
| B. Web = web admin + web sinh viên (web cho điện thoại); giảng viên chỉ dùng app Android và Windows | Hiểu câu của thầy là "phần web của bài Final chỉ cần cho Admin, không phải dựng web cho vai trò khác" | Nếu thầy hiểu theo nghĩa A thì bị hỏi; nên nhắn thầy một câu để chắc |
| C. Như B, thêm: một app Android cho cả giảng viên và sinh viên, vào đúng giao diện theo vai trò khi đăng nhập | Muốn có cả hai cách cho sinh viên, để chấm theo nghĩa nào cũng đạt | Thêm một bản phải test và giữ đồng bộ; tốn khoảng nửa ngày trong lúc còn 4 ngày |

## thien chọn
Phương án khác cả ba (09/11, 03:40): "1 web riêng cho admin, 1 web riêng cho sinh viên, giảng viên dùng app Android và Windows, có trang FAP giả và extension, thêm web để hiện ra QR quét mã".

## AI chọn
B, kèm một tin nhắn hỏi thầy. Câu của thầy nằm cạnh chuyện Crashlytics (dev xem console, admin xem web), nên nhiều khả năng là nói về phần web admin. Giữ web sinh viên thì không đổi luồng Lab 2 đã duyệt.

## Kết luận
Tách Hosting thành nhiều site trong cùng project (gói Spark cho phép nhiều site): web sinh viên, web admin, màn chiếu QR (TV), FAP giả, mỗi cái một địa chỉ riêng. Giảng viên chỉ dùng app Android và Windows; bản web giảng viên chỉ còn để test E2E, không deploy.

So với AI (chọn B): giống ở chỗ giữ web sinh viên và giảng viên chỉ dùng app; thien tách hẳn thành web riêng. Cách của thien còn sửa luôn LOI-09 (web sinh viên và web admin chung địa chỉ nên chung phiên đăng nhập), điều AI đã bỏ sót khi chọn.
