# Tiến độ

Cập nhật lần cuối: 12/11/2026 04:35 · Claude (nhánh `claude/project-thread-0x1jn2`, video). Phiên sau đọc `docs/handoff/BAN-GIAO-10-11-CHIEU.md`, rồi PR #30.

File này để bất kỳ ai (thành viên khác, AI khác, thien sau một tuần) mở ra là biết project đang ở đâu.
Lịch sử nằm trong git và PR, không ghi ở đây. Cả file dưới 40 dòng.

## Đang ở đâu
Hạn nộp Lab 3 + Final: thứ Sáu 13/11; đóng băng giao diện trưa thứ Tư 11/11. Kế hoạch: `docs/plan/KE-HOACH-09-11.md`. PR #27 đã gộp vào `final-system` (`63d8cf9`, 10/11 09:22); Release `demo` và Firebase (Hosting, Rules) đã lên bản này. Việc mới làm trên `claude/attendo-dev`, chưa mở PR. Mục tiêu 10/11: xong Lab 3. Quyết định 001-004 đã chốt. Firebase `attendo-app-2611` đã có Rules, web 4 trang, dữ liệu demo.

## Vừa xong (10/11)
- Tối 10/11: ảnh E4 Remote Config (12→15, 20→30, app đổi theo, rồi trả về 12/20), E5 Cloudinary, E6 Crashlytics Keys, DebugView `attendance_session_open` trong `evidence/`. Sáng 11/11: web sinh viên `qr_scan`, `correction_submit`, DebugView đủ 13/13; PR #31 đã gộp. Ảnh Keys không có `role`, `term` (chỉ ghi lúc đăng nhập, nhập lớp), thien chọn giữ ảnh và ghi hạn chế.
- Review AI lượt 2: thien không có Copilot nên dùng CodeRabbit trên PR #28; 16 phát hiện, thien quyết định từng cái, 14 cái sửa ở PR #29 (`claude/code-review-fixes` → `final-system`, CI xanh run 42787095197). Ghi ở `docs/code-review.md` CR-15 đến CR-30. CR-15 thêm `studentCodes/{mssv}` vào Rules: sau khi gộp phải chạy workflow Demo có deploy và reset.
- Demo bằng nick Google (thien chọn: 024 giảng viên, 697 sinh viên, 628 quản trị): `seed-demo.mjs --google-lecturer/--google-student`, workflow Demo có ô nhập và secret. thien thêm 2 SHA-1, 3 secret, chạy workflow Demo có deploy (06:38). Google trên điện thoại (024) vào thẳng Tổng quan có dữ liệu trên Firebase thật (06:55). Web sinh viên (697) và web admin (628) đăng nhập Google đúng (thien chụp 07:03). Hướng dẫn: `docs/demo/DEMO-GOOGLE.md`.
- Slide web đã lên https://thiengthb.github.io/PRM393_Lab03_SE190533/ (02:00). Bản dựng Pages từ nhánh `gh-pages` hỏng lúc khởi động ("Internal server error"), nên chuyển Source sang GitHub Actions: workflow `Slides` tự đăng (`d0e1b43`); môi trường `github-pages` cho phép thêm nhánh `claude/attendo-dev`. Lệnh chạy tay từ phía Claude (`gh workflow run`) đang hỏng lúc khởi động; thien bấm Re-run thì chạy.

## Vừa xong (09/11)
- Màu mặc định đổi sang **Bản vẽ** (xanh cobalt của slide MLN, D-T-09) cho app, web, extension, icon và slide; chấm giữa chữ o của logo chữ màu cam FPT (D-T-10). CI xanh, E2E 33/33 (run 42644368921), thien deploy Hosting 23:11. Ảnh app trong slide chụp lại bằng màu mới.
- Slide web hai bộ (Lab 3, Final) ở `slides/`, theo dàn ý đã duyệt; workflow `Slides` dựng PDF, kiểm từng slide, đăng lên nhánh `gh-pages`. Ảnh app chụp từ E2E 09/11, chụp lại sau mốc đóng băng.
- thien test tay T3, T5 (FCM 3 trạng thái), T6 (Crashlytics + web admin Sự cố) trên Firebase thật, 20:00 đến 20:27. Ảnh ở `evidence/fcm/`, `evidence/crashlytics/`. Dữ liệu nạp lại lần 5 lúc 19:55 (không nạp thêm hôm nay).
- thien test tay T1 trên Firebase thật (19:20), đạt trọn: TV, quét QR bằng iPhone, extension điền 25/35 có mặt khớp app và chặn sai ngày (ảnh ở `evidence/extension/`). Lỗi trên Oppo do Chrome còn bản web cũ (LOI-25).
- PR #30 (`claude/project-thread-uaz0j1`, xếp sau PR #29): xử lý 20 góp ý CodeRabbit trên PR #29 (11 sửa tài liệu; CR-31 đến CR-39 về code, thien đồng ý cả 9 quyết định 20:42); báo cáo Lab 3 (ảnh console, 196 ca Rules, CodeRabbit) và Final; slide Lab 3 thêm "Figma và app", "Design system", persona và TC-1, hai slide chuyển phụ lục; README, kịch bản video Final. CodeRabbit review PR #30: 18 ý, sửa cả (CR-40 đến CR-44 về code, CR-40 là mật khẩu mẫu mở được Admin trên Firebase thật), chờ thien duyệt.

## Việc tiếp theo
- **Thứ tự làm và từng bước: `docs/manual-test/VIEC-CON-LAI.md`** (xác nhận review, gộp PR, ảnh console còn thiếu, ARTEMIS, video, nộp).
1. Chụp lại ảnh app cho slide sau mốc đóng băng (11/11 trưa); điền DebugView, ARTEMIS, review AI trên PR, số giây T3 khi có.
2. Final: báo cáo đã cắt các mục chưa làm (số đo WF-03, ba cặp AI, ảnh W-01 đến W-19) sang mục 12 "Giới hạn"; còn video, link video trong báo cáo.

## Đang chờ thien
- Video: bản nộp Lab 3 (6:23) và Final (11:46) dựng 12/11 sau khi quay bù đủ 4 cảnh (Final 7 là camera mô phỏng, có nhãn). Nằm ở `outputs` bàn giao Codex trên laptop; chờ thien xem, rồi tải YouTube Không công khai và dán link. Chi tiết: `docs/demo/video-bao-cao.md`.
- Extension có nút **Đăng nhập bằng Google** (nhánh `claude/project-thread-qkughb`, PR vào `final-system`): redirect URI đã thêm, TC01 trên Google thật đạt (11/11 23:35); còn gộp PR và TC02 đến TC05 ở `docs/manual-test/extension-google.md` nếu muốn.
- PR #29, #30, #31 đã gộp; workflow Demo có deploy và reset chạy xong 11/11 06:14 trên `final-system` (run 42921127944, log có `Xong.` và "mật khẩu ngẫu nhiên" cho giáo vụ, quản trị: CR-40 đã có hiệu lực).
- Duyệt nội dung slide khi Pages đăng được.
- Ghi số giây đo ở T3 (báo cáo Final), đo khi quay video.
- Mở lại tab dev `windows` và nhìn icon trên thanh tác vụ; tải lại extension ở `chrome://extensions`.
- Duyệt dàn ý slide; nhắn thầy về tên repo và hai web (quyết định 002, 003).
- Sau khi chấm: xoá debug token `attendo-demo` và secret `APP_CHECK_DEBUG_TOKEN` (quyết định 004).

## Đang vướng
- ARTEMIS: dừng 11/11 12:18 vì hết credit Gemini, thien quyết định không chạy thêm (quá ngân sách). Kết quả lượt 1: 12 trên 17 ca, mỗi ca 1 lần (`evidence/artemis/results.md`).
- Máy cloud của Claude không có Flutter; biên dịch nhờ bản dev trên điện thoại, analyze nhờ CI.
