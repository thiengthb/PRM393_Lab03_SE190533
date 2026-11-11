# Giao việc video cho Codex

11/11/2026 · Claude viết. Đọc cùng `video-lab3.md` và `video-final.md` (kịch bản từng cảnh).

## Điều không đổi được
Đề Lab 3 (mục 9) và đề Final (mục 10) chấm video **quay trực tiếp trên máy thật**. Bảng điểm Lab 3 trừ điểm khi có "kết quả dựng vào thay cho lần chạy thật". Vì vậy:

- Codex **không được** tạo cảnh giả, ghép ảnh chụp thay cho thao tác thật, hay dựng video từ slide và giọng đọc máy.
- Codex **được** làm phần hậu kỳ trên bản quay thật: cắt đoạn chờ, ghép các đoạn, thêm phụ đề, chèn tiêu đề cảnh, chuẩn hoá âm lượng.

## Việc của thien
1. Quay theo `video-lab3.md` (5 đến 10 phút) và `video-final.md` (8 đến 12 phút) bằng OBS, nguồn Display Capture, màn điện thoại chiếu lên laptop bằng scrcpy.
2. Mỗi video có thể quay thành nhiều đoạn, đặt tên theo số cảnh: `lab3-01-04.mp4`, `lab3-05-12.mp4`...
3. Đưa các file cho Codex kèm đoạn giao việc bên dưới.

## Đoạn giao việc dán cho Codex
```
Bạn làm hậu kỳ video demo cho bài PRM393 (app Attendo). Đầu vào: các file mp4 tôi quay trực tiếp, tên file ghi số cảnh, và kịch bản docs/demo/video-lab3.md (hoặc video-final.md) trong repo thiengthb/PRM393_Lab03_SE190533.
Dùng ffmpeg. Làm đúng các việc sau, không thêm cảnh nào không có trong bản quay:
1. Ghép các đoạn theo thứ tự số cảnh.
2. Cắt các khoảng chờ dài hơn 3 giây không có thao tác (màn hình đứng yên, đang tải), nhưng giữ nguyên mọi khoảnh khắc kết quả xuất hiện (số có mặt tăng, thông báo hiện, console đổi, test in pass).
3. Chèn một dòng tiêu đề nhỏ góc trên trái ở đầu mỗi cảnh, lấy từ cột "Làm gì" của kịch bản, 3 giây, chữ trắng nền đen mờ, font Onest hoặc sans-serif.
4. Tạo phụ đề tiếng Việt (.srt) từ giọng nói trong video, ghi cứng vào video.
5. Chuẩn hoá âm lượng (loudnorm), xuất mp4 H.264 1080p, 30 fps.
6. Kiểm độ dài: Lab 3 từ 5 đến 10 phút, Final từ 8 đến 12 phút. Nếu dài hơn, báo tôi đoạn nào nên cắt, đừng tự cắt phần có kết quả.
Không tăng tốc đoạn có thao tác, không làm mờ hay che kết quả, không thêm hiệu ứng chuyển cảnh.
Xuất: lab3-video.mp4, final-video.mp4 và file .srt đi kèm.
```

## Sau khi có video
Tải lên YouTube (Không công khai) hoặc Google Drive (ai có link đều xem được), rồi dán link vào README mục nộp bài. Mở link bằng cửa sổ ẩn danh để chắc thầy xem được.
