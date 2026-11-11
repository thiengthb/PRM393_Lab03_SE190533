# Bàn giao hoàn thiện video Attendo cho Claude

Cập nhật 12/11/2026. Người giao: Thiên. Đây là bàn giao tiếp tục thực hiện, không phải xác nhận video đã hoàn thành.

## Yêu cầu và giới hạn

Đọc `docs/demo/video-lab3.md`, `docs/demo/video-final.md`, `docs/demo/loi-thoai-video.md` và bản giao việc đầy đủ tại `C:\Users\trann\.codex\attachments\d31e1b61-f117-4fdd-b7e2-e2793dfd45a8\Pasted text.txt`. Bản giao việc cho phép Edge TTS (ghi rõ trên video) và ảnh evidence đúng trường hợp được nêu, có nhãn ngày chụp. Mọi kết quả khác phải là thao tác chạy thật; không dựng giả hay chèn ảnh thay thao tác. Không tăng tốc thao tác, không che kết quả, không chuyển cảnh hiệu ứng; che email cá nhân, avatar, và loại cửa sổ riêng tư. Không đọc/in/commit secrets, không sửa code app, không push main hoặc final-system. Không xuất video chưa đạt thành phẩm như thể đã hoàn thành.

Đầu ra yêu cầu: hai MP4 H.264 1080p 30 fps, phụ đề tiếng Việt ghi cứng và SRT, tiêu đề đầu cảnh, loudnorm; Lab 3 5–10 phút, Final 8–12 phút. Ghi báo cáo tiếng Việt nêu cảnh chạy thật, evidence, cảnh lỗi, thời lượng và các việc người dùng cần làm để nộp. Xác minh toàn bộ cảnh và nội dung âm thanh tương ứng trước khi xuất. Không tự bịa những cảnh chưa quay hoặc kể các buổi demo khác nhau là cùng một phiên.

## Môi trường và tệp

- Repo hiện tại `work/attendo`, checkout `final-system`, HEAD `05d608e40e3a3f029e440fe995db4968bfcae8af`. Có thay đổi có sẵn ở `evidence/rules/rules-test-results.md`; kiểm tra và giữ nguyên, không tự hoàn tác.
- Thư mục gốc tác vụ: `C:\Users\trann\Documents\Codex\2026-11-11\giao-vi-c-video-cho-codex`.
- Bản quay thô: `work/clips/`; lời đọc đã tạo: `work/voice/`; báo cáo hiện tại và bản xem trước: `outputs/BAO-CAO.md`, `outputs/Final-canh20-xem-truoc.mp4`, `outputs/Final-canh20.srt`. Phần lớn bản thô chưa qua kiểm tra quyền riêng tư và có thể hiện cửa sổ chat hoặc email, tuyệt đối không phát hành trực tiếp. Bản quay lỗi chứa cửa sổ riêng tư vẫn còn; một yêu cầu xóa đã bị cơ chế phê duyệt tự động từ chối, không tìm cách vượt qua từ chối đó.
- Repo có `evidence/` và README của từng mục; chỉ dùng ảnh theo phạm vi giao việc và ghi ngày thực tế xác minh từ nguồn. Không giả vờ ảnh là ghi hình trực tiếp.
- APK demo và bản Windows đã tải trong `work/`; ffmpeg, adb, scrcpy, Node, Python, edge-tts đã được chuẩn bị. Điện thoại từng kết nối USB, cần kiểm tra lại `adb devices -l`, trạng thái ứng dụng và giờ slot trước khi quay.
- Chrome thường profile 7 của Thiên có extension Attendo tại `C:\Attendo-extension-google`. Không cần cài lại. Từng có lệnh mở profile bị cơ chế phê duyệt tự động chặn; người dùng đã tự mở Chrome và extension hoạt động. Không vượt qua chính sách chặn.

## Cảnh thật đã ghi, cần xem lại trước khi dựng

- Lab 3: đã quay mở điểm danh, sinh viên gửi mã, có mặt 24/35 lên 25/35, giảng viên đóng và chốt 26 có mặt/9 vắng, luồng báo sai được duyệt, số vắng 3/4 xuống 2/4. Đối chiếu các file `lab3-01*`, `lab3-03`, `lab3-04-05`, `lab3-07`, `lab3-09-11` với kịch bản. Xuất PDF mới tới màn chia sẻ, chưa chứng minh link Cloudinary. Google Android từng báo hủy đăng nhập; đăng nhập email dự phòng hoạt động. Chưa xác minh nguyên nhân SHA-1 với Firebase Console.
- Final: các file `final-04-05`, `final-06`, `final-08`, `final-09` ghi phiên trên điện thoại/Windows, TV, nhập mã, số tăng 24/35 lên 25/35 và chốt 26/9. Chưa ghi được cảnh quét QR điện thoại thứ hai.
- `final-11.mp4`: extension từ chối do trang ngày 11/11/2026 khác nguồn ngày 09/11/2026. `final-fap-fill.mp4`: FAP giả lập SE1802 slot 2 ngày 09/11, lấy 34 dòng từ bản đã chốt, điền 34 thay đổi và kiểm tra 34/34 dòng, không bấm Save. Đây là buổi khác với SE1801 đã quay; ghi rõ, không kể như cùng phiên. Kiểm toàn bộ khung và che email/avatar trước khi dùng.
- `final-13-14.mp4`: quay duyệt lớp MMA301 SE1806 giữa điện thoại và web quản trị, app đổi và có tin hộp thư. Chưa hoàn thành đủ ba phép đo theo kịch bản.
- `final-16-17.mp4`, `final-17.mp4`: AI tạo lời nhắc và báo đã nhắc; thao tác sửa lời nhắc chưa chứng minh đúng, không nói đã sửa nếu không quay lại được.
- `final-20-take3.mp4`: chạy test Rules thật trên Emulator, 196 pass, 0 fail. Bản xem trước đã cắt cửa sổ riêng tư và có TTS, SRT. Kiểm lại trước ghép.

## Cần làm tiếp

1. Kiểm từng clip theo số cảnh, xác nhận kết quả, thời lượng và mọi thông tin cá nhân; bảo toàn dữ liệu gốc. Cần quay thêm các cảnh thiếu theo kịch bản, hoặc báo không quay được cùng lý do; không tự mô phỏng kết quả. Các cảnh console được phép dùng evidence theo yêu cầu, với nhãn ngày chụp. Cảnh FCM, Google sign-in, PDF Cloudinary, quét QR, AI sửa, Remote Config, slide, ARTEMIS/review và các cảnh khác còn phải xác minh; đừng tự cho là đã hoàn tất.
2. Dữ liệu demo có giới hạn thời gian. Nếu cần reset, chạy workflow Demo: Firebase thật trên `final-system`, bỏ chọn deploy và chọn xoá/nạp dữ liệu demo; người dùng trước đây đã cho phép reset để quay. Kiểm trạng thái và tránh làm gián đoạn người dùng. Nếu không có quyền hoặc cần xác thực, yêu cầu người dùng giúp đúng bước bị chặn.
3. Dựng ffmpeg, đồng bộ tiếng với hình, lời thoại chỉ khớp những gì đã được chứng minh. Kiểm phụ đề, thông tin riêng tư, kết quả không bị che, thời lượng và xem toàn bộ hai video. Cập nhật báo cáo với tình trạng thực tế.
4. Người dùng kiểm video, tải YouTube không công khai hoặc Drive cho phép xem bằng link, kiểm link ẩn danh, rồi dán link README và ghi nhận công cụ AI, theo giao việc.

## Sự cố đã báo

Workflow `43007287357` từng chạy sai với deploy bật. Log xác nhận đã deploy Hosting bốn site, Firestore Rules và indexes; lệnh cũng bao gồm Remote Config nhưng chưa xác minh chênh lệch. Bước nạp dữ liệu của lần đó bị bỏ qua. Đã báo người dùng; không tự rollback vì chưa biết trạng thái trước. Workflow reset sau đó đã thành công với deploy bỏ chọn.
