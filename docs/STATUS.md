# Tiến độ

Cập nhật lần cuối: 09/11/2026 12:05 · Claude (tự test trên Firebase thật), đọc từ git, API GitHub và log điện thoại

File này để bất kỳ ai (thành viên khác, AI khác, thien sau một tuần) mở ra là biết project đang ở đâu.
Lịch sử nằm trong git và PR, không ghi ở đây. Cả file dưới 40 dòng.

## Đang ở đâu
Hạn nộp Lab 3 + Final: thứ Sáu 13/11; đóng băng giao diện trưa thứ Tư 11/11. Kế hoạch: `docs/plan/KE-HOACH-09-11.md`. Việc đang làm nằm trên nhánh `claude/attendo-dev`, PR nháp #27 vào `final-system`. Quyết định 001-004 đã chốt. Firebase `attendo-app-2611` đã có Rules, web 4 trang, dữ liệu demo.

## Vừa xong (09/11)
- Claude tự test trên Firebase thật: T1 (mở phiên, sinh viên nhập mã, giao quyền đổi mã sang laptop, đóng mã, bật tay, chốt), T2 (báo sai, duyệt, từ chối), T4 Gợi ý AI chạy, PDF lên Cloudinary, non-fatal, Test crash. Lỗi ghi ở `docs/demo/loi.md` LOI-15, 17-23.
- Gợi ý AI: App Check bắt buộc cho AI Logic từ 02/11/2026; quyết định 004 dùng một debug token (GitHub secret + file trên laptop).
- Test tay rút còn 6 ca: `docs/demo/TEST-TAY.md`. Dàn ý slide: `docs/slides/DAN-Y.md`.

## Việc tiếp theo
1. E2E W70 (laptop vào phiên ngay sau điện thoại) vẫn đỏ, 31/32 đạt; đang tìm nguyên nhân, chưa sửa test.
2. Kiểm Crashlytics console và trang Sự cố của web admin (cần thien đăng nhập Google).
3. Bằng chứng console, review AI trên PR, báo cáo, slide, kịch bản video.

## Đang chờ thien
- Test tay phần cần camera, extension, Google: T1 (TV, quét QR, FAP), T3, T5, T6 trên web admin.
- Duyệt dàn ý slide; nhắn thầy về tên repo và hai web (quyết định 002, 003).
- Sau khi chấm: xoá debug token `attendo-demo` và secret `APP_CHECK_DEBUG_TOKEN` (quyết định 004).

## Đang vướng
- Bản Windows chế độ debug không dựng được (Firebase C++ SDK thiếu thư viện Debug của App Check); dev chạy bản release.
- Máy cloud của Claude không có Flutter; biên dịch nhờ bản dev trên điện thoại, analyze nhờ CI.
