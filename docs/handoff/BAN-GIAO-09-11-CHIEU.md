# Bàn giao 09/11 chiều (13:10) · cho phiên Claude tiếp theo

Đọc theo thứ tự: `AGENTS.md`, `docs/STATUS.md`, file này, `docs/demo/loi.md`, `docs/demo/TEST-TAY.md`, `docs/plan/KE-HOACH-09-11.md`. Mọi việc nằm trên nhánh `claude/attendo-dev` (PR nháp #27 vào `final-system`).

## thien đã cho phép
- Thư mục `~/develop` trên laptop (Windows, PowerShell 5), điện thoại cắm cáp, **điều khiển máy tính (computer use)** để tự sửa và test (13:06, 09/11). Firebase thật chỉ đụng qua workflow `Demo: Firebase thật`, và chỉ thien bấm.
- Hôm nay đã nạp lại dữ liệu 3 lần (giới hạn ghi miễn phí): không nạp thêm trong ngày 09/11 trừ khi thien muốn.

## Hệ thống đang chạy
- Firebase `attendo-app-2611`, tài khoản Google **tranngocthien628@gmail.com** (không phải 024). Web: sinh viên `attendo-app-2611.web.app`, admin `-admin.web.app`, TV `-tv.web.app/tv/<key>`, FAP giả `-fap.web.app`. Admin đăng nhập Google bằng nick 628 đã có quyền.
- Tài khoản mẫu, mật khẩu `Demo@123`: quanm@fe.edu.vn, nam@fe.edu.vn (giảng viên), dung101@ và tien102@fpt.edu.vn (sinh viên).
- Bản cài mới (APK, Windows, extension) ở Release `demo-preview` (dựng từ `claude/attendo-dev`). Release `demo` vẫn là bản project cũ.
- App Check: AI Logic bị Firebase bắt buộc từ 02/11/2026; quyết định 004 dùng debug token chung (secret `APP_CHECK_DEBUG_TOKEN`, file `~/develop/attendo-config/app-check-debug-token.txt`). Không in, không commit token.

## Vòng sửa nhanh trên laptop (`tool/dev/dev.ps1`)
4 tab PowerShell: `-Target phone | lecturer (localhost:7303) | admin (localhost:7301) | windows`. Mỗi lần đẩy code lên `claude/attendo-dev`, các tab tự kéo (chung 1 lần mỗi 10 giây) và nạp lại.
- Điều khiển điện thoại: ghi file `~/develop/.attendo-dev/key-phone`, mỗi dòng một lệnh: `shot` (ra `phone.png`, 720×1600), `tap X Y`, `swipe X1 Y1 X2 Y2 MS`, `key back|home|enter`, `text WORD`, `wait N`, `r`/`R`. Ghi bằng `device_bash` (printf); nếu Windows không thấy file thì gửi bằng `device_commit_files`. Máy ảo không xoá được file trong `~/develop`.
- Nhịp từng tab: `beat-<target>.txt` (bước đang làm). Log: `run-<target>.log`.
- Toạ độ điện thoại đã dùng: Tổng quan "Xem tất cả" (Vắng nhiều) 575,1234 → em đầu tiên 265,847 → Nhắc nhở 360,1438 → Gợi ý AI 360,1326. Tab Tài khoản 630,1440 → vuốt lên → Khu demo 360,846. Nút đa nhiệm (Oppo) 188,1555; nút Home 360,1555.
- Không bấm Back ở Tổng quan (thoát app; mở lại qua đa nhiệm).
- Lỗi script đã sửa hôm nay: biến `$key` ghi đè `$Key` (PowerShell không phân biệt hoa thường), adb treo, kéo code tranh khoá. Tab windows cần mở lại để nhận bản đóng `attendo.exe` trước khi dựng (lỗi MSB3073).

## Đã kiểm trên Firebase thật (Claude, 09/11)
T1 phần app (mở phiên, sinh viên nhập mã, giao quyền đổi mã sang laptop, đóng mã, bật tay, chốt, hoàn tác), T2 (báo sai, duyệt, từ chối), T4 Gợi ý AI, PDF lên Cloudinary, Remote Config, non-fatal, Test crash (Crashlytics console có issue `FirebaseCrashlyticsTestCrash`, thien chụp 12:07).

## Việc đang mở, theo thứ tự ưu tiên
1. **LOI-14 Tổng quan web admin "Có lỗi, hãy thử lại"** trên Firebase thật. Truy vấn ở `packages/core/lib/services/dashboard_repository.dart` (aggregation count/sum trên `classes`, `slots`). Lỗi gốc in ra Console trình duyệt dòng `Firestore error:`. Cách lấy: computer use mở Edge (đã đăng nhập admin nick 628) → F12 → Console, hoặc `localhost:7301`.
2. **E2E W70 đỏ** (31/32 đạt): laptop mở phiên ngay sau điện thoại, test đọc mã số ngay và không thấy. Bằng chứng: mã số trên laptop hiện sau 3 đến 12 giây (có lần lâu hơn trên CI). Đã sửa 2 nguyên nhân có thật (nhả quyền sau lần ghi cuối `3584b85`; ghi mã ngay khi slot tải xong `1f60a72`) nhưng chưa hết. Script dựng lỗi: `tool/e2e/debug_takeover.py` (cần emulator và `e2e_web/serve.py` với bản dựng ở nhánh `e2e-builds`). **Chưa sửa test**: nếu kết luận là test đọc mã quá sớm, báo thien lý do, thien quyết (luật "không sửa test cho xanh").
3. **Test tay còn lại cho thien** (hướng dẫn chi tiết đã gửi trong chat 09/11 12:10, bản gọn ở `docs/demo/TEST-TAY.md`): T1 phần TV, quét QR bằng camera, extension điền FAP; T3 duyệt lớp đo giây; T5 FCM 3 trạng thái (trên điện thoại phải bấm "Cho phép" thông báo trong Khu demo trước); T6 trang Sự cố của web admin.
4. LOI-20 (Ctrl+D, Esc trên desktop) kiểm trên app Windows; LOI-19 xem lại bằng mắt.
5. Sau khi ổn: gộp PR #27 vào `final-system` (thien bấm), dựng Release `demo`, cập nhật `docs/demo/TEST-TAY.md`/README sang Attendo, AGENTS.md phần riêng (Firebase mới, tên).
6. Bài nộp 13/11: bằng chứng `evidence/` (chỉ thứ đã chạy thật), review AI trên PR, báo cáo Lab 3 và Final, 2 bộ slide theo `docs/slides/DAN-Y.md` (chờ thien duyệt dàn ý), kịch bản video, tin nhắn cho thầy về tên repo `attendo` và hai web (quyết định 002, 003). Đổi tên repo làm cuối cùng.

## Dọn sau khi chấm
Xoá debug token `attendo-demo` (App Check → Apps → Manage debug tokens) và secret `APP_CHECK_DEBUG_TOKEN`.
