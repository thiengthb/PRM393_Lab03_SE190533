# Báo cáo dựng video (bản nộp, dựng 12/11/2026)

Claude dựng tiếp từ bàn giao của Codex (`docs/demo/BAN-GIAO-VIDEO-CODEX.md`). 4 cảnh còn thiếu đã quay bù sáng 12/11, nên hai video đã dựng bản nộp (không còn ô "CHƯA QUAY"); **chờ thien xem và duyệt**. Mỗi cảnh có nhãn góc dưới trái nói rõ là quay thật (kèm giờ quay), ảnh chụp (kèm ngày) hay slide.

| Video | Độ dài | Đề yêu cầu | File |
|---|---|---|---|
| Lab 3 | 6:23 | 5 đến 10 phút | `Lab03_SE190533_video.mp4` + `.srt` |
| Final | 11:46 | 8 đến 12 phút | `Final_SE190533_video.mp4` + `.srt` |

Bản đầy đủ nằm ở thư mục `outputs` của bàn giao Codex trên laptop; Project files (`video-attendo/`) có bản xem nhanh 480p và ảnh lưới khung hình (4 giây một khung) để duyệt. Bản nháp cũ (`*-ban-nhap.mp4`) giữ nguyên để so. H.264 1080p 30 fps, phụ đề tiếng Việt ghi cứng, loudnorm (đo được −15,9 LUFS), góc dưới phải "Giọng đọc: Microsoft Edge TTS".

## Lab 3
| Cảnh | Nguồn | Ghi chú |
|---|---|---|
| 1 Giới thiệu | Slide 1 đến 5 | |
| 2 Đăng nhập Google | Quay thật OPPO 12/11 03:40 | Làm mờ danh sách tài khoản Google trong hộp chọn (giây 17,5 đến 31 của clip) |
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
| 7 Sinh viên quét mã | Quay thật trên Firebase Emulator 12/11 03:42, **camera mô phỏng** | thien cho phép mô phỏng phần quét. Camera giả của Chromium phát ảnh mã QR; cổng sinh viên và lượt điểm danh là thật trên Emulator (24 lên 25). Nhãn và lời đọc nói rõ là mô phỏng |
| 8 Nhập mã, 25/35 trên điện thoại, TV, Windows | Quay thật 11/11 18:06 | |
| 9 Đóng mã, bật tay, chốt 26/9 | Quay thật 11/11 18:07 | Làm mờ thông báo ChatGPT giây 37 đến 46 |
| 11 rồi 10 Extension FAP | Quay thật 11/11 23:59 | Buổi SE1802 ngày 09/11, khác buổi SE1801 ở trên; lời đọc và nhãn nói rõ. Cắt khung vào cửa sổ Chrome (bỏ cửa sổ Codex), làm mờ Gmail và avatar. Đổi thứ tự: báo sai ngày trước, điền sau, đúng thứ tự đã quay |
| 12 Báo sai | Dùng lại clip Lab 3 quay 11/11 13:06 | Lời đọc mới nói rõ quay lúc 13 giờ |
| 13-14 Duyệt lớp liên vai trò | Quay thật 11/11 23:24 | Chưa đo 3 lần WF-03 |
| 15 Lướt web admin | Quay thật trên Firebase Emulator 12/11 03:35 | Dữ liệu demo |
| 16-17 Nhắc, Gợi ý AI | Quay thật 11/11 13:08 | Lời đọc 17 mới: không nói "em sửa một chữ" vì clip không có thao tác sửa |
| 18-19 Tắt AI bằng Remote Config | Quay thật OPPO 12/11 04:04 và 04:07 | thien tự publish trên console: phiên bản 17 (`ai_reminder_enabled` true → false, 04:04:17) và 18 (bật lại, 04:07:42); v18 giống v16 trừ số phiên bản. Hai đoạn publish là chữ dựng (nền xanh, nhãn "Chữ dựng, không phải cảnh quay"), số liệu lấy từ lịch sử phiên bản. Làm mờ vùng FCM token |
| 20 Test Rules 196/196 | Chạy thật 11/11 23:10 | Cắt khung vào cửa sổ PowerShell, bỏ 26 giây đầu có cửa sổ chat |
| 21-22 | Slide 14, 15 | |

## Không dùng
`final-11.mp4` (cửa sổ Codex có mật khẩu demo, đã có cảnh tương đương trong `final-fap-fill.mp4`), `final-17.mp4`, `final-20.mp4`, `final-20-retake.mp4`, `lab3-01*.mp4` (slide chưa toàn màn hình; dùng ảnh slide dựng từ `slides/`).

## Dựng lại
Script ở `docs/demo/video-build/` (`build.py`, `scenes.py`; lời đọc mới ở `voice-v2.json`, tạo bằng `make_voice_v2.py` trên laptop vì máy cloud không gọi được Edge TTS; đặt cùng biến `MEDIA` thì file mp3 nằm ngay ở `work/voice-v2/voice-v2`, chỗ `build.py` đọc, không cần chép). Khi có clip mới: chép vào `work/clips`, thay ô `card(...)` trong `scenes.py` bằng `clip(...)`, đặt biến `MEDIA` (thư mục bàn giao Codex) và `WORK` (thư mục có `slides/` ảnh slide, `fonts/` Onest TTF), rồi từ thư mục gốc của repo chạy `python3 docs/demo/video-build/build.py lab3 --draft` và `python3 docs/demo/video-build/build.py final --draft` để ra bản nháp; bỏ `--draft` khi dựng bản nộp. Ô `card(...)` còn lại trong `scenes.py` là hai thẻ chữ Remote Config có chủ ý, không phải ô "CHƯA QUAY".

## Việc của thien
1. Xem hai bản nộp, nhất là các chỗ làm mờ và cảnh camera mô phỏng.
2. Xoá hay giữ bản nháp cũ trong `outputs` tuỳ thien.
3. Sau bản cuối: tải YouTube Không công khai, kiểm bằng cửa sổ ẩn danh, dán link vào README, slide cuối, báo cáo Final mục 1; thêm "Codex, Claude, Edge TTS: dựng video" vào bảng công cụ AI.
