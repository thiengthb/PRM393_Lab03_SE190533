# Tiến độ

Cập nhật lần cuối: 08/11/2026 · Claude (phiên áp quy trình thienai-workflow), đọc từ git và API GitHub

File này để bất kỳ ai (thành viên khác, AI khác, thien sau một tuần) mở ra là biết project đang ở đâu.
Lịch sử nằm trong git và PR, không ghi ở đây. Cả file dưới 40 dòng.

## Đang ở đâu
Bài Final (nộp cùng Lab 3) hạn thứ Sáu 13/11/2026. Mã chính ở `final-system`; giao diện mới nhất (thienui Xanh ngọc, font Onest, thương hiệu Attendo) và test luồng web bằng Playwright nằm trên nhánh `claude/project-thread-uaz0j1`, nhánh này là PR #17, nằm trên cùng chồng PR giao diện #10, #12 đến #16 và đã chứa cả extension #11; chưa PR nào trong chồng được gộp vào `final-system`. App chưa có bằng chứng chạy trên Firebase thật.

## Vừa xong
- 06/11, `claude/project-thread-uaz0j1`: áp thienui và Onest (`c7ac96e`), đổi thương hiệu Attendo (`c0cb08c`), test luồng web trên Emulator (`b3a7980`), chốt lúc mất mạng tự đổi sang Đã chốt (`4d5f326`). PR #17, đang mở.
- 06/11: PR #9 gộp vào `final-system` (toast Hoàn tác, mở lại mã ở slot đã qua).
- 05/11: PR #2 đến #8 gộp vào `final-system` (giao diện v2 từ `ui-v2`, bản Windows, FAP giả lập và extension, FCM, Cloudinary, web admin nối Firebase, `build_hosting.sh` chạy trong Git Bash).

## Việc tiếp theo
1. thien chạy nhánh `claude/project-thread-uaz0j1` trên điện thoại hoặc Windows, báo chỗ giao diện chưa ưng. Hạn: trước mốc đóng băng trưa 11/11.
2. Gộp giao diện vào `final-system`: hoặc gộp chồng PR theo thứ tự #10, #12, #13, #14, #15, #16, #17 (mỗi lần đợi CI xanh; #11 đã nằm trong #17 nên đóng sau cùng), hoặc mở một PR thẳng từ `claude/project-thread-uaz0j1` vào `final-system`. thien chọn cách. PR #1 (Cloudinary vào `ui-v2`) đã có trong `final-system`, đóng được.
3. Trên laptop: `firebase deploy --only firestore,remoteconfig,hosting` trong thư mục `firebase/`, điền link web và tài khoản demo vào README.
4. Chụp bằng chứng vào `evidence/`: đăng nhập, Users, FCM, Crashlytics, Remote Config, DebugView, ARTEMIS chạy 3 lần; mở PR cho CodeRabbit hoặc Copilot review.
5. Báo cáo PDF, slide (thien thích PPTX), video demo; sau đó cân nhắc đổi tên repo thành `PRM393_Final_SE190533`.

## Đang chờ thien
- Xem giao diện Attendo và chọn cách gộp (việc 1, 2).
- Chạy trên máy thật, deploy và chụp bằng chứng (việc 3, 4).
- Xác nhận đã nhắn thầy về việc dùng Cloudinary thay Cloud Storage và về thiết kế mới; repo chưa ghi câu trả lời của thầy.

## Đang vướng
- Máy cloud không chạy được Android và không đẩy được tag; kết quả thật lấy từ CI và máy của thien.
