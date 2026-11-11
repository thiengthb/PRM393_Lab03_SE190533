# Báo cáo dựng video (bản nháp 12/11/2026)

Claude dựng tiếp từ bàn giao của Codex (`docs/demo/BAN-GIAO-VIDEO-CODEX.md`). Hai bản nháp **chưa nộp được**: còn 4 cảnh chưa quay (ô đỏ "CHƯA QUAY" trong video). Mỗi cảnh có nhãn góc dưới trái nói rõ là quay thật (kèm giờ quay), ảnh chụp (kèm ngày) hay slide.

| Video | Độ dài | Đề yêu cầu | File |
|---|---|---|---|
| Lab 3 | 6:02 | 5 đến 10 phút | `Lab03_SE190533_video-ban-nhap.mp4` + `.srt` |
| Final | 10:36 | 8 đến 12 phút | `Final_SE190533_video-ban-nhap.mp4` + `.srt` |

File nằm ở thư mục `outputs` của bàn giao Codex trên laptop và trong Project files (`video-attendo/`). H.264 1080p 30 fps, phụ đề tiếng Việt ghi cứng, loudnorm (đo được −15,9 LUFS), góc dưới phải "Giọng đọc: Microsoft Edge TTS".

## Lab 3
| Cảnh | Nguồn | Ghi chú |
|---|---|---|
| 1 Giới thiệu | Slide 1 đến 5 | |
| 2 Đăng nhập Google | **Chưa quay** | Codex ghi Google trên Android báo huỷ, chưa rõ nguyên nhân |
| 3 Mở phiên | Quay thật 11/11 13:01 | |
| 4-5 Sinh viên nhập mã, 24 lên 25/35 | Quay thật 11/11 13:02 | |
| 6 Firestore | Slide 7 + ảnh console 10/11 | Lời đọc mới, không nói "bản ghi đó" vì ảnh là ngày khác |
| 7 Đóng mã, chốt 26/9 | Quay thật 11/11 13:04 | |
| 8 Analytics | Ảnh DebugView 10/11 | Lời đọc mới |
| 9-11 Báo sai, duyệt, 3/4 xuống 2/4 | Quay thật 11/11 13:06 | Cắt đoạn chờ giây 42 đến 66; bỏ câu 11 (không có ảnh console yêu cầu đã duyệt) |
| 12-13 FCM | Slide 8 + ảnh điện thoại 11/11 | Lời đọc mới, không nói "mở đúng màn" |
| 14-16 Crashlytics | Ảnh web admin 11/11, ảnh console 09/11 | Lời đọc mới cho 14, 16 |
| 17 Remote Config | Ảnh 10/11 | Lời đọc mới (nói rõ tối 10/11) |
| 18 Xuất PDF | Quay thật 11/11 13:10 | Giây 30 của clip có "Đã tải lên Cloudinary" kèm link `res.cloudinary.com` |
| 19 ARTEMIS | Slide 13 | Số đọc từ `evidence/artemis/results.md` |
| 20 Code review | Slide 14 | |
| 21 Kết | Slide 15 | |

## Final
| Cảnh | Nguồn | Ghi chú |
|---|---|---|
| 1-3 | Slide 1 đến 8, 10 | |
| 4-5 Điện thoại và Windows cùng phiên | Quay thật 11/11 18:03 | |
| 6 Chiếu TV | Quay thật 11/11 18:04 | |
| 7 Quét QR bằng điện thoại | **Chưa quay** | |
| 8 Nhập mã, 25/35 trên điện thoại, TV, Windows | Quay thật 11/11 18:06 | |
| 9 Đóng mã, bật tay, chốt 26/9 | Quay thật 11/11 18:07 | Làm mờ thông báo ChatGPT giây 37 đến 46 |
| 11 rồi 10 Extension FAP | Quay thật 11/11 23:59 | Buổi SE1802 ngày 09/11, khác buổi SE1801 ở trên; lời đọc và nhãn nói rõ. Cắt khung vào cửa sổ Chrome (bỏ cửa sổ Codex), làm mờ Gmail và avatar. Đổi thứ tự: báo sai ngày trước, điền sau, đúng thứ tự đã quay |
| 12 Báo sai | Dùng lại clip Lab 3 quay 11/11 13:06 | Lời đọc mới nói rõ quay lúc 13 giờ |
| 13-14 Duyệt lớp liên vai trò | Quay thật 11/11 23:24 | Chưa đo 3 lần WF-03 |
| 15 Lướt web admin | **Chưa quay** | |
| 16-17 Nhắc, Gợi ý AI | Quay thật 11/11 13:08 | Lời đọc 17 mới: không nói "em sửa một chữ" vì clip không có thao tác sửa |
| 18-19 Tắt AI bằng Remote Config | **Chưa quay** | |
| 20 Test Rules 196/196 | Chạy thật 11/11 23:10 | Cắt khung vào cửa sổ PowerShell, bỏ 26 giây đầu có cửa sổ chat |
| 21-22 | Slide 14, 15 | |

## Không dùng
`final-11.mp4` (cửa sổ Codex có mật khẩu demo, đã có cảnh tương đương trong `final-fap-fill.mp4`), `final-17.mp4`, `final-20.mp4`, `final-20-retake.mp4`, `lab3-01*.mp4` (slide chưa toàn màn hình; dùng ảnh slide dựng từ `slides/`).

## Dựng lại
Script ở `docs/demo/video-build/` (`build.py`, `scenes.py`; lời đọc mới ở `voice-v2.json`, tạo bằng `make_voice_v2.py` trên laptop vì máy cloud không gọi được Edge TTS; đặt cùng biến `MEDIA` thì file mp3 nằm ngay ở `work/voice-v2/voice-v2`, chỗ `build.py` đọc, không cần chép). Khi có clip mới: chép vào `work/clips`, thay ô `card(...)` trong `scenes.py` bằng `clip(...)`, đặt biến `MEDIA` (thư mục bàn giao Codex) và `WORK` (thư mục có `slides/` ảnh slide, `fonts/` Onest TTF), rồi chạy `python3 build.py lab3` và `python3 build.py final` (bỏ `--draft` cho bản nộp).

## Việc của thien
1. Xem hai bản nháp, nhất là các chỗ làm mờ.
2. Quay 4 cảnh còn thiếu (hoặc chọn bỏ cảnh nào và ghi vào giới hạn).
3. Sau bản cuối: tải YouTube Không công khai, kiểm bằng cửa sổ ẩn danh, dán link vào README, slide cuối, báo cáo Final mục 1; thêm "Codex, Claude, Edge TTS: dựng video" vào bảng công cụ AI.
