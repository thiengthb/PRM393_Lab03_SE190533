# Tiến độ

Cập nhật lần cuối: 09/11/2026 05:00 · Claude (phiên kế hoạch 09-13/11, giao diện theo thiết bị), đọc từ git và API GitHub

File này để bất kỳ ai (thành viên khác, AI khác, thien sau một tuần) mở ra là biết project đang ở đâu.
Lịch sử nằm trong git và PR, không ghi ở đây. Cả file dưới 40 dòng.

## Đang ở đâu
Hạn nộp Lab 3 + Final: thứ Sáu 13/11; đóng băng giao diện trưa thứ Tư 11/11. Kế hoạch: `docs/plan/KE-HOACH-09-11.md`. Việc đang làm nằm trên nhánh `claude/attendo-dev`, PR nháp #27 vào `final-system`. Quyết định 001-003 đã chốt (Firebase mới `attendo-app-2611`, 4 trang web riêng, tên repo `attendo`).

## Vừa xong (09/11, trên `claude/attendo-dev`)
- Vòng sửa nhanh: `tool/dev/dev.ps1` trên laptop của thien (điện thoại tự nạp lại vài giây sau mỗi lần đẩy code, đã chạy thật); CI lọc theo đường dẫn, E2E và bản cài chỉ chạy khi gom đợt.
- Đổi tên toàn bộ thành Attendo; chuyển sang Firebase `attendo-app-2611`, mã app `app.attendo`; Hosting 4 trang.
- Giao diện desktop: khung `FormFactor`, bộ widget `Desk*`, bản desktop cho Tổng quan, Phiên, Lớp, Điểm danh, Yêu cầu sửa, Vắng nhiều, web admin (bảng + khung chi tiết), web sinh viên laptop. Sửa LOI-05.

## Việc tiếp theo
1. thien xong `docs/setup/FIREBASE-MOI.md` bước 6-10 (chạy workflow trên nhánh `claude/attendo-dev`).
2. Claude tự kiểm trên điện thoại (scrcpy) và web; chạy E2E 31 ca trên nhánh; sửa lỗi.
3. Rút test tay còn 6 ca chính (`docs/demo/`), lệnh ARTEMIS một dòng.
4. Bằng chứng console, review AI trên PR, báo cáo, slide Lab 3 (công nghệ) và Final (guideline V11), kịch bản video.

## Đang chờ thien
- Firebase mới bước 6-10; khởi động lại cửa sổ dev bản windows, lecturer, admin; cài scrcpy.
- Nhắn thầy: tên repo `attendo` (quyết định 003) và web sinh viên giữ lại (quyết định 002).

## Đang vướng
- Bản Windows chế độ debug không dựng được (Firebase C++ SDK thiếu thư viện Debug của App Check); dev chạy bản release.
- Máy cloud của Claude không có Flutter; biên dịch nhờ bản dev trên điện thoại, analyze nhờ CI.
