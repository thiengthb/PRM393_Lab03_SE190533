# Lời thoại video Attendo

Đọc từng đoạn theo số cảnh trong `docs/demo/video-lab3.md` và `docs/demo/video-final.md`. Đọc chậm, mỗi đoạn một hơi. Chỗ trong ngoặc vuông thì đọc số thật trên màn hình.

## Video Lab 3 (khoảng 8 phút)

1. Em chào thầy. Đây là Attendo, app điểm danh bằng mã QR em làm cho Lab 3. App viết bằng Flutter theo MVVM với Riverpod, dữ liệu nằm hết trên Firebase, không có server riêng.
2. Đầu tiên là đăng nhập. Em đăng nhập bằng Google. Vai trò giảng viên được đọc từ tài liệu người dùng trên Firestore, nên app vào thẳng màn Tổng quan của giảng viên.
3. Em mở phiên điểm danh. Mã QR và mã 6 số đổi mỗi 12 giây, con số 12 này lấy từ Remote Config.
4. Bên trình duyệt, sinh viên gõ mã rồi gửi. Security Rules kiểm tra mã còn hạn và sinh viên có tên trong lớp thì mới cho ghi.
5. Thầy thấy số có mặt bên điện thoại tăng ngay, không cần tải lại. Đó là Firestore đọc theo thời gian thực.
6. Đây là bản ghi đó trên Firebase console, dữ liệu thật chứ không phải giả lập.
7. Giờ em đóng mã và chốt buổi. Chốt xong vẫn có nút Hoàn tác nếu lỡ tay.
8. Mỗi bước vừa rồi đều ghi một sự kiện Analytics. Đây là DebugView, thầy thấy sự kiện chốt điểm danh kèm tham số.
9. Luồng thứ hai là báo sai. Sinh viên thấy buổi này bị ghi vắng nên bấm Báo sai, chọn lý do rồi gửi.
10. Giảng viên mở mục Yêu cầu sửa và bấm Duyệt. Bên sinh viên, buổi đó đổi thành Có mặt.
11. Trên console, yêu cầu đã chuyển từ chờ duyệt sang đã duyệt.
12. Tiếp theo là Cloud Messaging. Token là địa chỉ của một lần cài app trên một máy. App lấy token bằng getToken rồi lưu lên Firestore. Em gửi thử một thông báo từ console.
13. Thông báo hiện khi app đang ở nền, bấm vào thì app mở đúng màn Yêu cầu sửa. Em đã thử đủ ba trạng thái: đang mở, ở nền và đã tắt.
14. Crashlytics: em bấm Test crash trong Khu demo. App tắt, mở lại thì báo lỗi được gửi lên.
15. Crashlytics không cho client đọc lại, nên app ghi thêm một bản tóm tắt. Web admin đọc bản đó và hiện ngay ở mục Sự cố.
16. Còn đây là lỗi đó trên Crashlytics console.
17. Remote Config: em đổi chu kỳ đổi mã từ 12 lên 15 giây rồi Publish. App nhận giá trị mới mà không cần cài lại.
18. Xuất báo cáo: em xuất PDF của lớp. File được tải lên Cloudinary, vì Cloud Storage cần gói Blaze còn project em dùng gói Spark.
19. Phần test tự động em dùng ARTEMIS chạy trên điện thoại thật. Có [số] ca, mỗi ca chạy [số] lần, đạt [số] trên [số] lần.
20. Code review em làm bằng CodeRabbit trên pull request. Mỗi nhận xét em đều ghi nhận hay bác và lý do, cái nào nhận thì có commit sửa.
21. Đó là toàn bộ Lab 3 của em. Em cảm ơn thầy.

## Video Final (khoảng 10 phút)

1. Em chào thầy. Bài Final của em là Attendo, hệ thống điểm danh bằng mã QR. Hiện nay điểm danh trên FAP mất thời gian đầu giờ, dễ quên chốt, còn sinh viên thường biết mình vắng quá nhiều khi đã muộn. Hệ thống có bốn actor: giảng viên, sinh viên, quản trị trên web admin, và nhóm phát triển trên Firebase console.
2. Hệ thống không có server riêng. Security Rules quyết định ai được ghi gì, App Check chặn client lạ. Một package lõi dùng chung cho app Android, app Windows, web sinh viên và web admin.
3. Cùng một màn phiên điểm danh chạy trên điện thoại, laptop và màn chiếu, tất cả dùng chung một ViewModel.
4. Bắt đầu luồng thứ nhất: điểm danh một buổi. Trên điện thoại, em mở slot đang diễn ra. Mã QR và mã 6 số đổi mỗi 12 giây.
5. Em mở cùng phiên trên laptop. Chỉ một máy giữ quyền đổi mã, máy kia hiện cùng mã, nên sinh viên không gõ phải mã đã cũ.
6. Em chiếu mã lên TV. Màn chiếu không cần đăng nhập, link có khoá và hết hạn sau giờ học.
7. Sinh viên quét mã bằng trình duyệt trên điện thoại, không cần cài app.
8. Em nào ngồi xa không quét được thì gõ mã 6 số. Thầy thấy số có mặt trên điện thoại, laptop và TV cùng tăng.
9. Em đóng mã, bật có mặt cho một bạn quên điện thoại, rồi chốt.
10. Sang trang FAP, extension đọc bản đã chốt và điền sẵn. Giảng viên vẫn tự bấm Save trên FAP.
11. Nếu chọn nhầm buổi, extension báo không khớp và không điền.
12. Luồng thứ hai là báo sai. Sinh viên gửi yêu cầu, giảng viên duyệt, sinh viên thấy buổi đó thành có mặt mà không cần tải lại.
13. Luồng thứ ba là luồng liên vai trò. Giảng viên tự đăng ký lớp, nên lớp phải được quản trị duyệt trên web thì mới mở mã được. Em bấm Duyệt bên web admin.
14. Bên điện thoại, chữ chờ duyệt biến mất ngay và hộp thư có tin lớp đã được duyệt.
15. Đây là web admin: tổng quan, môn học, thông báo, người dùng và sự cố. Web admin chỉ mở cho quản trị.
16. Luồng thứ tư là nhắc sinh viên vắng nhiều. Em mở hồ sơ một bạn sắp chạm ngưỡng và bấm Gợi ý AI. Gemini chỉ nhận mã môn và vài con số, không nhận tên hay mã số sinh viên.
17. AI chỉ gợi ý. Em sửa lại một chữ rồi mới gửi.
18. Em tắt cờ AI trên Remote Config. Mở lại thì nút Gợi ý AI không còn nữa, nhưng vẫn nhắc được bằng câu mẫu.
19. Em bật cờ lại như cũ.
20. Giờ em chạy bộ test Security Rules trên Emulator. Mỗi vai trò, mỗi collection đều có ca được phép và ca bị chặn.
21. Đây là bảng kết quả test, các con số đều lấy từ CI và thư mục evidence.
22. Giới hạn hiện tại là chưa có server nên thông báo chưa tự gửi theo sự kiện. Em cảm ơn thầy.
