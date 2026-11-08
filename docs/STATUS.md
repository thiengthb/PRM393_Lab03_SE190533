# Tiến độ

Cập nhật lần cuối: 08/11/2026 · Claude (phiên chuẩn bị test tay và demo), đọc từ git và API GitHub

File này để bất kỳ ai (thành viên khác, AI khác, thien sau một tuần) mở ra là biết project đang ở đâu.
Lịch sử nằm trong git và PR, không ghi ở đây. Cả file dưới 40 dòng.

## Đang ở đâu
Bài Final (nộp cùng Lab 3) hạn thứ Sáu 13/11/2026, đóng băng giao diện trưa 11/11. Giao diện Attendo đã gộp vào `final-system`. Đã có tài liệu test tay và demo `docs/demo/HUONG-DAN.md` (bản đọc: Doc trên Claude), bản cài dựng sẵn trên Release `demo`, và workflow bấm tay để đẩy lên Firebase thật. App chưa có bằng chứng chạy trên Firebase thật.

## Vừa xong
- 08/11: PR #10, #12 đến #17 gộp vào `final-system` (giao diện Attendo, test luồng web); #11 tự đóng vì đã nằm trong #17.
- 08/11: PR #19 chuẩn bị demo: workflow `Demo: dựng bản cài`, `Demo: Firebase thật`, dữ liệu demo `seed-demo.mjs --demo`, test W60, W61, W70, W71; CI E2E 31 ca đạt.
- 08/11: PR #18 áp quy trình thienai-workflow.

## Việc tiếp theo
1. thien làm phần "Cài đặt một lần" của `docs/demo/HUONG-DAN.md`: đổi nhánh mặc định sang `final-system`, tạo secret `FIREBASE_SERVICE_ACCOUNT`, chạy `Demo: Firebase thật`, cài APK, app Windows, extension.
2. thien chạy kiểm khói 10 phút, rồi test tay L1 đến L18; lỗi ghi theo phần "Ghi lỗi", Claude chuyển vào `docs/demo/loi.md`.
3. Claude sửa lỗi mở trong `docs/demo/loi.md` (LOI-05 chờ thien quyết cách sửa).
4. Chụp bằng chứng vào `evidence/` trong lúc test (FCM, Crashlytics, Remote Config, DebugView, ARTEMIS 3 lần); mở PR cho CodeRabbit hoặc Copilot review.
5. Báo cáo PDF, slide (thien thích PPTX), video theo phần "Kịch bản demo".

## Đang chờ thien
- Làm phần "Cài đặt một lần" (việc 1); Claude chưa chạy được gì trên Firebase thật khi chưa có secret.
- Quyết cách sửa LOI-05 (hai máy giảng viên cùng mở màn phiên thì mã đổi chồng nhau).
- Xác nhận đã nhắn thầy về Cloudinary thay Cloud Storage và về thiết kế mới; repo chưa ghi câu trả lời của thầy.

## Đang vướng
- Máy cloud của Claude không chạy được Flutter, Android, Windows, và không vào được Firebase thật; kết quả lấy từ CI (GitHub Actions) và máy của thien.
- Máy chủ GitHub đôi lúc lỗi mạng khi tải Gradle hay pdfium (504); workflow đã tự thử lại 3 lần.
