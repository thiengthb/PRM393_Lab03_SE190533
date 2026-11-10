# Tiến độ

Cập nhật lần cuối: 10/11/2026 07:00 · Claude (phiên mới sau `docs/handoff/BAN-GIAO-10-11-DEM.md`)

File này để bất kỳ ai (thành viên khác, AI khác, thien sau một tuần) mở ra là biết project đang ở đâu.
Lịch sử nằm trong git và PR, không ghi ở đây. Cả file dưới 40 dòng.

## Đang ở đâu
Hạn nộp Lab 3 + Final: thứ Sáu 13/11; đóng băng giao diện trưa thứ Tư 11/11. Kế hoạch: `docs/plan/KE-HOACH-09-11.md`. Việc đang làm nằm trên nhánh `claude/attendo-dev`, PR nháp #27 vào `final-system`. Quyết định 001-004 đã chốt. Firebase `attendo-app-2611` đã có Rules, web 4 trang, dữ liệu demo.

## Vừa xong (10/11)
- Demo bằng nick Google (thien chọn: 024 giảng viên, 697 sinh viên, 628 quản trị): `seed-demo.mjs --google-lecturer/--google-student`, workflow Demo có ô nhập và secret. thien thêm 2 SHA-1, 3 secret, chạy workflow Demo có deploy (06:38). Google trên điện thoại (024) vào thẳng Tổng quan có dữ liệu trên Firebase thật (06:55). Web sinh viên (697) và web admin (628) đăng nhập Google đúng (thien chụp 07:03). Hướng dẫn: `docs/demo/DEMO-GOOGLE.md`.
- Ô thứ ba Tổng quan giữ nhãn "có mặt tuần này", chưa có buổi chốt thì "—" (thien chọn cách A, D-T-11).
- thien dọn ổ C (còn 37 GB, 00:55). Mở lại app Claude thì `device_bash` chạy lại. Tab dev `phone` dựng lại lúc 01:03: icon mới (cobalt, chấm cam) đã thấy trên điện thoại, ảnh chụp qua `shot`.
- Slide web đã lên https://thiengthb.github.io/PRM393_Lab03_SE190533/ (02:00). Bản dựng Pages từ nhánh `gh-pages` hỏng lúc khởi động ("Internal server error"), nên chuyển Source sang GitHub Actions: workflow `Slides` tự đăng (`d0e1b43`); môi trường `github-pages` cho phép thêm nhánh `claude/attendo-dev`. Lệnh chạy tay từ phía Claude (`gh workflow run`) đang hỏng lúc khởi động; thien bấm Re-run thì chạy.

## Vừa xong (09/11)
- Màu mặc định đổi sang **Bản vẽ** (xanh cobalt của slide MLN, D-T-09) cho app, web, extension, icon và slide; chấm giữa chữ o của logo chữ màu cam FPT (D-T-10). CI xanh, E2E 33/33 (run 42644368921), thien deploy Hosting 23:11. Ảnh app trong slide chụp lại bằng màu mới.
- Slide web hai bộ (Lab 3, Final) ở `slides/`, theo dàn ý đã duyệt; workflow `Slides` dựng PDF, kiểm từng slide, đăng lên nhánh `gh-pages`. Ảnh app chụp từ E2E 09/11, chụp lại sau mốc đóng băng.
- thien test tay T3, T5 (FCM 3 trạng thái), T6 (Crashlytics + web admin Sự cố) trên Firebase thật, 20:00 đến 20:27. Ảnh ở `evidence/fcm/`, `evidence/crashlytics/`. Dữ liệu nạp lại lần 5 lúc 19:55 (không nạp thêm hôm nay).
- thien test tay T1 trên Firebase thật (19:20), đạt trọn: TV, quét QR bằng iPhone, extension điền 25/35 có mặt khớp app và chặn sai ngày (ảnh ở `evidence/extension/`). Lỗi trên Oppo do Chrome còn bản web cũ (LOI-25).
- Claude tự test trên Firebase thật: T1 (mở phiên, sinh viên nhập mã, giao quyền đổi mã sang laptop, đóng mã, bật tay, chốt), T2 (báo sai, duyệt, từ chối), T4 Gợi ý AI chạy, PDF lên Cloudinary, non-fatal, Test crash. Lỗi ghi ở `docs/demo/loi.md` LOI-15, 17-23.
- Test tay rút còn 6 ca: `docs/demo/TEST-TAY.md`. Dàn ý slide: `docs/slides/DAN-Y.md`.

## Việc tiếp theo
1. Chụp lại ảnh app cho slide sau mốc đóng băng (11/11 trưa); điền DebugView, ARTEMIS, review AI trên PR, số giây T3 khi có.
2. Báo cáo Lab 3 và Final, kịch bản video.

## Đang chờ thien
- Duyệt nội dung slide khi Pages đăng được.
- Ghi số giây đo ở T3 (báo cáo Final), đo khi quay video.
- Mở lại tab dev `windows` và nhìn icon trên thanh tác vụ; tải lại extension ở `chrome://extensions`.
- Duyệt dàn ý slide; nhắn thầy về tên repo và hai web (quyết định 002, 003).
- Sau khi chấm: xoá debug token `attendo-demo` và secret `APP_CHECK_DEBUG_TOKEN` (quyết định 004).

## Đang vướng
- Bản Windows chế độ debug không dựng được (Firebase C++ SDK thiếu thư viện Debug của App Check); dev chạy bản release.
- Máy cloud của Claude không có Flutter; biên dịch nhờ bản dev trên điện thoại, analyze nhờ CI.
