# Giao trọn việc làm video cho Codex

11/11/2026 · Claude viết theo yêu cầu của thien: Codex tự làm từ đầu đến cuối trên laptop của thien, thien không phải bấm. Dán nguyên khối "Chỉ dẫn cho Codex" bên dưới vào Codex (Codex CLI hoặc Codex app, mở trong thư mục repo trên laptop).

## Chỉ dẫn cho Codex
```
Bạn làm hai video demo cho bài PRM393 của sinh viên Trần Ngọc Thiên (app Attendo, repo hiện tại, nhánh final-system). Bạn tự làm toàn bộ trên máy này: điều khiển điện thoại Android qua adb, điều khiển trình duyệt bằng Playwright, quay màn hình, lồng tiếng, dựng video. Không hỏi lại trừ khi bị chặn hẳn.

LUẬT CỨNG (đề chấm, vi phạm là mất điểm):
- Mọi kết quả trong video phải là thao tác chạy thật lúc quay. Không dựng cảnh giả, không chèn ảnh thay cho thao tác trừ đúng trường hợp ghi "dùng ảnh evidence" bên dưới, và khi đó phải có chữ "Ảnh chụp ngày ..." trên khung.
- Không đọc, in hay commit secret (.env, service account, API key).
- Không sửa code app. Không push lên nhánh final-system hay main.
- Che email cá nhân, avatar trên khung hình (làm mờ vùng đó bằng ffmpeg boxblur).

ĐẦU VÀO
- Kịch bản cảnh: docs/demo/video-lab3.md và docs/demo/video-final.md (cột Màn, Làm gì).
- Lời thoại từng cảnh: docs/demo/loi-thoai-video.md (số đoạn = số cảnh). Chỗ [số] ở cảnh ARTEMIS: đọc từ evidence/artemis/results.md; nếu file chưa có thì bỏ câu số liệu, chỉ nói "kết quả ở evidence/artemis".
- Ảnh evidence: thư mục evidence/.

CHUẨN BỊ (làm một lần)
1. Kiểm công cụ: adb (tìm ở $env:LOCALAPPDATA\Android\Sdk\platform-tools), scrcpy, ffmpeg, python, node. Thiếu cái nào thì cài bằng winget hoặc pip/npm. Cài edge-tts: pip install edge-tts.
2. adb devices phải thấy điện thoại. Bật Không làm phiền: adb shell cmd notification set_dnd priority.
3. App Attendo trên điện thoại là bản Release demo nối Firebase thật (attendo-app-2611). Nếu app đang là bản nối Emulator (vừa chạy ARTEMIS) thì tải Attendo-GiangVien.apk ở Release "demo" của repo trên GitHub, adb install -r.
4. Dữ liệu demo: nếu thien đã chạy workflow "Demo: Firebase thật" trong giờ này thì dùng luôn; nếu chưa, ghi vào báo cáo cuối là cần thien chạy, rồi vẫn quay với dữ liệu hiện có.
5. Mở scrcpy (cửa sổ bên trái màn hình) để thấy điện thoại trên laptop. Trình duyệt Chrome do Playwright mở (cửa sổ bên phải), dùng profile riêng, đăng nhập bằng tài khoản email demo trong README mục "Tài khoản demo" (không dùng Google của thien).

QUAY
- Quay cả màn hình: ffmpeg -f gdigrab -framerate 30 -i desktop -c:v libx264 -preset veryfast -crf 23 clips/<video>-<cảnh>.mp4. Mỗi cảnh một file, dừng quay khi cảnh xong.
- Thao tác điện thoại: adb shell input tap/swipe/text, tìm toạ độ bằng adb shell uiautomator dump (các nút có nhãn Semantics). Chờ màn đổi rồi mới bấm tiếp.
- Thao tác web: Playwright, bấm theo chữ trên nút như trong kịch bản.
- Mỗi cảnh xong, xem lại 1 khung cuối (ffmpeg -sseof -1 -frames:v 1) để chắc kết quả hiện trên màn. Sai thì quay lại cảnh đó.
- Cảnh cần Firebase console, Crashlytics console, Remote Config console, DebugView: dùng ảnh evidence tương ứng (evidence/firestore, crashlytics, remote-config, analytics), hiện 5 giây, có chữ "Ảnh chụp console ngày ..." lấy ngày từ README trong thư mục đó.
- Cảnh chạy test (Final cảnh 20): chạy thật trong PowerShell: cd firebase/tests; npm ci; npm test. Quay đến khi in dòng pass.
- Cảnh slide: mở https://thiengthb.github.io/PRM393_Lab03_SE190533/lab3.html (hoặc final.html), bấm F, chuyển slide bằng phím mũi tên.

LỒNG TIẾNG
- Mỗi đoạn lời thoại thành một file mp3: edge-tts --voice vi-VN-NamMinhNeural --rate=+5% --text "<đoạn>" --write-media voice/<video>-<cảnh>.mp3
- Ghép tiếng vào cảnh tương ứng. Nếu tiếng dài hơn hình thì giữ khung cuối của cảnh cho đủ (tpad stop_mode=clone), nếu hình dài hơn thì cắt bớt đoạn chờ không có thao tác, không cắt lúc kết quả hiện.

DỰNG
- Ghép các cảnh theo thứ tự, thêm phụ đề tiếng Việt từ chính lời thoại (ghi cứng), dòng tiêu đề nhỏ góc trên trái 3 giây đầu mỗi cảnh (lấy từ cột Làm gì).
- Góc dưới phải suốt video: "Giọng đọc: Microsoft Edge TTS".
- Chuẩn hoá âm lượng (loudnorm), xuất H.264 1080p 30 fps: out/Lab03_SE190533_video.mp4 (5 đến 10 phút), out/Final_SE190533_video.mp4 (8 đến 12 phút). Quá độ dài thì cắt đoạn chờ, không cắt cảnh.

BÁO CÁO CUỐI (ghi vào out/BAO-CAO.md, viết tiếng Việt)
- Cảnh nào chạy thật, cảnh nào dùng ảnh evidence, cảnh nào lỗi và vì sao.
- Độ dài hai video.
- Việc thien còn phải làm: tải lên YouTube chế độ Không công khai, dán link vào README mục nộp bài.
```

## Việc của thien sau khi Codex xong
1. Xem nhanh hai file trong `out/`.
2. Tải lên YouTube, chế độ **Không công khai**, rồi dán link vào README mục nộp bài. Mở link bằng cửa sổ ẩn danh để kiểm thầy xem được.
3. Thêm "Codex, Edge TTS: làm video" vào bảng công cụ AI trong README.

## Lưu ý
- Lúc Codex quay thì đừng để luồng ARTEMIS chạy cùng điện thoại. Chạy Codex khi ARTEMIS đã xong.
- Giọng đọc là giọng máy. Đề chấm "clear narration", nên giọng máy rõ vẫn ổn hơn video không tiếng; có thời gian thì thien tự đọc lại lời thoại.
