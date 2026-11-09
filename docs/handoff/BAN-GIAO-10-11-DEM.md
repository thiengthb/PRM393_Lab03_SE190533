# Bàn giao 10/11 đêm (00:50) · cho phiên Claude tiếp theo

Đọc theo thứ tự: `AGENTS.md`, `docs/STATUS.md`, file này, rồi `docs/handoff/BAN-GIAO-09-11-CHIEU.md` (cách vận hành vòng dev trên laptop, tài khoản mẫu, toạ độ điện thoại vẫn đúng). Mọi việc nằm trên nhánh `claude/attendo-dev` (PR nháp #27 vào `final-system`), commit cuối của phiên trước: xem `git log`.

## Việc gấp nhất: ổ C laptop đầy
- 00:40 ngày 10/11: ổ C còn **91,7 MB trống / 453 GB**. Trang Storage của Windows cho bốn mục lớn nhất 248 GB, 110 GB, 26 GB, 1,6 GB (chưa đọc được tên mục: một cửa sổ không chụp được che giữa màn).
- Hệ quả: `device_bash` của phiên trước hỏng hẳn (`listen EIO ... srt-mux ... .sock`), không tự hồi; phiên mới sẽ có máy ảo mới. Flutter/Gradle trên laptop không dựng được cho tới khi dọn.
- thien sẽ dọn (Settings → System → Storage → Show more categories, Temporary files). Phiên mới: hỏi thien đã dọn chưa, còn trống bao nhiêu; nếu cần, đọc ảnh trang Storage thien gửi và chỉ chỗ xoá. Không xoá gì ngoài thứ thien đồng ý.
- Thứ xoá được ngay: `C:\Users\trann\develop\attendo-ban-moi` (bản tải tạm; 2 file đã cắt về 0 byte), `C:\attendo\desktop\hereby.exe|.exp|.lib` (bản cũ), các thư mục `build` của Flutter (dựng lại được).
- Bài học: đừng giải nén file lớn vào thư mục tạm của máy ảo `device_bash`; ghi thẳng bằng `device_commit_files` (ghi đè được, không cần quyền xoá).

## Đã xong trong phiên 09/11 tối
- Màu mặc định toàn hệ thống: **Bản vẽ** (cobalt #1D4ED8, chữ trắng trên nút; tối #6F93F3 chữ mực). Một hằng `AppPalette.fallback` cho app, web, `tool/tokens/gen_css.mjs` → `design/tokens/attendo.css`; extension `globals.css` chép tay theo `AppPalette.banVe` (extension D-011). Khoá lưu lựa chọn `palette_id_v3`. Bảng Tím thêm vào khung Chọn màu. Ghi ở D-T-09.
- Chấm giữa chữ o (logo chữ và icon app) màu cam FPT #F26F21 = `AppColors.brandDot` (D-T-10). Icon sinh lại bằng `python3 tool/brand/gen_icons.py`.
- Slide: biến `--teal*` đổi thành `--brand*`, màu Bản vẽ; ảnh app trong `slides/assets/img/app/` chụp lại từ E2E (map tên ảnh ↔ ảnh E2E: admin-cho-duyet=w61_admin_cho_duyet, gv-da-chot=w03_da_chot, gv-da-duyet=w61_gv_da_duyet, gv-nhac-nho=w05_soan_nhac, gv-phien-dien-thoai=w03_phien_mo, gv-phien-laptop=l4_laptop_phien, gv-tong-quan-laptop=w46_gv_laptop, gv-yeu-cau=w11_gv_yeu_cau, sv-bao-sai=w11_sv_bao_sai, sv-da-ghi-nhan=w03_sv_da_ghi_nhan, tv=w03_tv).
- Kiểm: CI xanh trên `e14c1a8`; E2E 33/33 trên `9daa0d4` (run 42644368921); thien deploy Hosting 23:11 (bản `9daa0d4`: màu mới, chưa có favicon chấm cam). Release `demo-preview` dựng 23:49 từ `e14c1a8`.
- Laptop: `C:\attendo\desktop` đã có `attendo.exe` bản mới (đủ file; `flutter_windows.dll` giữ bản cũ, md5 trùng bản mới). `C:\attendo\extension` đã ghi đè 17 file; thien cần bấm tải lại ở `chrome://extensions`.

## Việc tiếp theo
1. Sau khi dọn ổ: thien đóng/mở lại tab dev `phone` (dựng app có icon mới); kiểm icon trên điện thoại và thanh tác vụ Windows bằng mắt (chưa kiểm).
2. thien chạy `Demo: Firebase thật` trên `claude/attendo-dev`, **chỉ tích deploy, bỏ tích xoá dữ liệu** (mặc định đang bật) để favicon web có chấm cam. Claude không được bấm workflow này (bị chặn, đúng luật).
3. thien bật GitHub Pages (Settings → Pages → `gh-pages` / root), duyệt nội dung slide; T3 đo giây khi quay video.
4. Các việc còn lại giữ như `docs/STATUS.md`: DebugView, ARTEMIS, review AI trên PR, báo cáo Lab 3 và Final, kịch bản video, gộp PR #27, Release `demo`, đổi tên repo cuối cùng. Mốc đóng băng giao diện: trưa 11/11.

## Lưu ý kỹ thuật
- Không có Flutter trên máy cloud; analyze/test nhờ CI. E2E chạy được ở máy cloud: emulator (`firebase/tests`, `npx firebase emulators:start --config ../firebase.json --project attendo-app-2611 --only auth,firestore`) + `e2e_web/serve.py ../../e2e-builds`; test cần FAP giả (W70 phần extension) sẽ đỏ nếu không chạy server FAP ở cổng 4173, đó là thiếu môi trường, không phải lỗi app.
- `E2E builds` không tự chạy trên PR (cần nhãn `e2e`); bấm tay bằng `gh workflow run e2e-builds.yml --ref claude/attendo-dev`.
- `gh release ...` dùng GraphQL nên bị chặn; dùng `gh api repos/thiengthb/PRM393_Lab03_SE190533/releases/tags/demo-preview`.
- Computer use trên laptop: Settings/Explorer xin quyền được nhưng một cửa sổ không chụp được (có thể là chính app Claude) che giữa màn; nhờ thien thu nhỏ trước khi làm.
