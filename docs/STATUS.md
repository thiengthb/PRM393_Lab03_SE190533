# Tiến độ

Cập nhật lần cuối: 09/11/2026 20:30 · Claude, bàn giao sang phiên mới: đọc `docs/handoff/BAN-GIAO-09-11-CHIEU.md`

File này để bất kỳ ai (thành viên khác, AI khác, thien sau một tuần) mở ra là biết project đang ở đâu.
Lịch sử nằm trong git và PR, không ghi ở đây. Cả file dưới 40 dòng.

## Đang ở đâu
Hạn nộp Lab 3 + Final: thứ Sáu 13/11; đóng băng giao diện trưa thứ Tư 11/11. Kế hoạch: `docs/plan/KE-HOACH-09-11.md`. Việc đang làm nằm trên nhánh `claude/attendo-dev`, PR nháp #27 vào `final-system`. Quyết định 001-004 đã chốt. Firebase `attendo-app-2611` đã có Rules, web 4 trang, dữ liệu demo.

## Vừa xong (09/11)
- thien test tay T3, T5 (FCM 3 trạng thái), T6 (Crashlytics + web admin Sự cố) trên Firebase thật, 20:00 đến 20:27. Ảnh ở `evidence/fcm/`, `evidence/crashlytics/`. Dữ liệu nạp lại lần 5 lúc 19:55 (không nạp thêm hôm nay).
- thien test tay T1 trên Firebase thật (19:20), đạt trọn: TV, quét QR bằng iPhone, extension điền 25/35 có mặt khớp app và chặn sai ngày (ảnh ở `evidence/extension/`). Lỗi trên Oppo do Chrome còn bản web cũ (LOI-25).
- Màn Sự cố kiểm trên Firebase thật (18:23): Lỗi non-fatal và Test crash từ điện thoại hiện ngay trên web admin; thêm E2E W34. Sửa LOI-06 (một phần), LOI-07, LOI-21, LOI-24.
- LOI-20 kiểm trên app Windows (17:51): Ctrl+D, Esc, Space đúng. Dữ liệu nạp lại lần 4 lúc 17:48 (thien chọn); slot 5 PRM393 SE1801 đang diễn ra, mã đã đóng, chưa chốt.
- E2E W70 xanh (32/32, run 42594858960): Esc ở màn phiên laptop không rời phiên khi đang mở mã (thien chọn sửa app).
- LOI-14 đã sửa và kiểm trên Firebase thật (15:35): chỉ mục tổng hợp trên `slots` sai thứ tự trường; web nay hiện đúng câu lỗi theo mã.
- Claude tự test trên Firebase thật: T1 (mở phiên, sinh viên nhập mã, giao quyền đổi mã sang laptop, đóng mã, bật tay, chốt), T2 (báo sai, duyệt, từ chối), T4 Gợi ý AI chạy, PDF lên Cloudinary, non-fatal, Test crash. Lỗi ghi ở `docs/demo/loi.md` LOI-15, 17-23.
- Gợi ý AI: App Check bắt buộc cho AI Logic từ 02/11/2026; quyết định 004 dùng một debug token (GitHub secret + file trên laptop).
- Test tay rút còn 6 ca: `docs/demo/TEST-TAY.md`. Dàn ý slide: `docs/slides/DAN-Y.md`.

## Việc tiếp theo
1. Bằng chứng console, review AI trên PR, báo cáo, slide, kịch bản video.

## Đang chờ thien
- Ghi số giây đo ở T3 (báo cáo Final).
- Deploy lại Hosting để web admin có bản sửa LOI-24 (workflow `Demo: Firebase thật`, chỉ tích deploy).
- Duyệt dàn ý slide; nhắn thầy về tên repo và hai web (quyết định 002, 003).
- Sau khi chấm: xoá debug token `attendo-demo` và secret `APP_CHECK_DEBUG_TOKEN` (quyết định 004).

## Đang vướng
- Bản Windows chế độ debug không dựng được (Firebase C++ SDK thiếu thư viện Debug của App Check); dev chạy bản release.
- Máy cloud của Claude không có Flutter; biên dịch nhờ bản dev trên điện thoại, analyze nhờ CI.
