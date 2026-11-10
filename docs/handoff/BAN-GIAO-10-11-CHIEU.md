# Bàn giao 10/11 chiều (18:00) · cho phiên Claude tiếp theo (tài khoản khác)

Đọc theo thứ tự: `AGENTS.md`, `docs/STATUS.md`, file này. Cách vận hành laptop (tab dev, `key-phone`, toạ độ điện thoại, tài khoản mẫu) vẫn như `docs/handoff/BAN-GIAO-09-11-CHIEU.md` và `BAN-GIAO-10-11-DEM.md`. Hạn nộp: thứ Sáu 13/11. Đóng băng giao diện: trưa thứ Tư 11/11. Mục tiêu thien đặt: xong Lab 3 trong 10/11, xong Final nếu kịp, để thứ Sáu chỉ còn sửa lỗi.

## Nhánh và PR lúc bàn giao
- `final-system` = `63d8cf9` (PR #27 đã gộp; production đang chạy bản này, cộng Rules sửa LOI-27 thien deploy 12:27).
- `claude/attendo-dev` (`e581f08`): sửa LOI-27 (`1d0db6d`), ảnh bằng chứng, hướng dẫn. Chưa có PR riêng; toàn bộ đã nằm trong `claude/code-review-fixes`.
- `claude/code-review-fixes`: **PR #29 vào `final-system`, CI xanh** (run 42787095197). Chứa mọi thứ của `claude/attendo-dev` cộng 14 bản sửa CodeRabbit (CR-15 đến CR-29). Chờ thien gộp.
- PR #28 (`review/lab3-head` → `review/lab3-base`): chỉ để CodeRabbit review bản Lab 3. **Không gộp.**

## Đã xong trong phiên này
- Demo bằng Google trên Firebase thật: giảng viên 024 (điện thoại), sinh viên 697 (web), quản trị 628 (web). `docs/demo/DEMO-GOOGLE.md`. Email thật chỉ nằm trong secret, không ghi vào repo.
- Slide web: https://thiengthb.github.io/PRM393_Lab03_SE190533/ (workflow `Slides`, Source = GitHub Actions).
- Review AI lượt 2 (đề Lab 3 mục 8, 0,5 điểm): thien không có Copilot nên dùng CodeRabbit (đã cài vào repo). 16 phát hiện trên PR #28, thien quyết từng cái; ghi ở `docs/code-review.md` mục "Lượt 2"; gốc ở `evidence/code-review/coderabbit-pr28.md`. Rules Emulator 196/196.
- Ảnh console đã có: E1 (`evidence/auth/`), E2 (`evidence/firestore/`), E3 được 10/13 event (`evidence/analytics/`, xem README ở đó).

## Việc còn lại, theo thứ tự
1. **CodeRabbit đã review luôn PR #29: 16 comment + 4 nitpick, chưa ai quyết định.** Gốc: `evidence/code-review/coderabbit-pr29.md`. Phần lớn nói về tài liệu, không phải code. Đáng chú ý:
   - Major: `video-lab3.md:17` vẫn ghi Copilot, phải đổi thành CodeRabbit; `gemini-billing.md:5` hứa "chặn chi tiêu chắc chắn", sai vì Prepay vẫn có thể vượt; `lab3-evidence.md:139` thay DebugView bằng Realtime mà đề đòi DebugView; `lab3-evidence.md:171` E3 bảo chốt buổi đang diễn ra, làm E4 không còn buổi để thử; `run-e2e.ps1:25` không kiểm mã thoát của lệnh ngoài; `import_shots.py:35` (Security & Privacy, chưa đọc kỹ); `session_viewmodel.dart:594` hàng đợi chốt bị từ chối sau đó (Heavy lift, chính là phần CR-20 đã ghi Modified).
   - Minor: số test Rules cũ 183 trong `loi.md:33` và `report/lab3/report.md:102` (giờ là 196); `code-review.md:69` đừng gọi lượt Lab 3 là review độc lập của code Final; `class_repository.dart:220` báo khi import ghi dở vì batch quá 450 thao tác; `report/build.py:49`; ba ý cho `video-lab3.md`.
   - Làm theo luật: AI đề xuất, thien quyết. Ghi vào `docs/code-review.md` thành CR-31 trở đi (Tool = CodeRabbit, PR #29) hoặc sửa thẳng nếu chỉ là tài liệu và thien đồng ý.
2. **thien gộp PR #29**, rồi chạy workflow `Demo: Firebase thật` trên `final-system`, **tick cả deploy và reset**: Rules mới có `studentCodes/{mssv}` (CR-15), reset để seed ghi khoá MSSV cho tài khoản mẫu. Claude không được bấm workflow này.
3. **Ảnh console còn thiếu** (`docs/manual-test/lab3-evidence.md`, 📸 đánh dấu đúng bước): E3 còn 3 event `attendance_session_open`, `qr_scan`, `correction_submit` (cần một buổi đang diễn ra, nên làm ngay sau lần reset ở bước 2; sửa E3 cho khỏi chốt buổi trước khi làm E4, như CodeRabbit chỉ ra); E4 Remote Config hai tham số (`qr_rotate_seconds` 12 → 15, `absence_limit_percent` 20 → 30, làm xong trả về 12 và 20); E5 Cloudinary; E6 Crashlytics tab Keys. Ảnh CodeRabbit: `code-review-01-summary.png`, `code-review-02-inline.png` (PR #28). Nhập ảnh: `python3 tool/evidence/import_shots.py` (tên `<khu>-NN-<việc>.png`, tự làm mờ Gmail).
4. **ARTEMIS** (Lab 3 1,5 điểm, Final cũng cần): đang tạm dừng, thien hỏi thầy (từ 11:17). Vướng: khoá Gemini miễn phí 20 lượt/ngày (lỗi 429). Phương án nạp 10 USD: `docs/manual-test/gemini-billing.md` (sửa câu hứa chặn chi tiêu trước khi đưa thien). Khi có model: `tool/artemis/run-e2e.ps1 -Step lecturer -SkipInstall`, rồi `-Step student`, rồi `-Step report` → `evidence/artemis/results.md`. Config trên laptop: `~/develop/artemis/config/artemis.jsonc` (model mặc định đã đổi sang `gemini-3.7-flash`, bản cũ `.bak-2026-11-10`). Oppo đã bật "Tắt giám sát quyền" để `pm clear` chạy.
5. **Báo cáo Lab 3**: `report/lab3/report.md` (12 mục theo đề mục 9). Chèn ảnh mới, sửa số test Rules thành 196, thêm CodeRabbit; dựng PDF: `python3 report/build.py lab3` → `report/Lab03_SE190533.pdf` (không commit bản nháp).
6. **Slide**: còn thiếu slide "thiết kế so với app" và "design system"; chụp lại ảnh app sau mốc đóng băng (trưa 11/11).
7. **Video Lab 3**: thien quay theo `docs/demo/video-lab3.md` (21 cảnh, khoảng 8 phút; đổi cảnh review sang CodeRabbit trước).
8. README (tên Attendo, link video), rồi tới phần Final.

## Lưu ý cho phiên mới
- thien muốn: test trước, hướng dẫn rất chi tiết với ca test cụ thể, và **dặn chụp ảnh ngay tại bước**, không gom cuối mục (thien đã phàn nàn). Mỗi lệnh PowerShell một dòng, không `&&`.
- Máy cloud không có Flutter: Dart nhờ CI của PR (CI không chạy khi chỉ push nhánh `claude/*`, phải có PR). Rules test chạy được ở cloud: `cd firebase/tests && npm test` (cần Java cho Emulator; máy mới thì kiểm `java -version` trước).
- `gh workflow run` từ cloud hỏng lúc khởi động ("Internal server error"); thien bấm Re-run thì chạy.
- Link dashboard của CodeRabbit chứa token chia sẻ (`scope=ghh_...`): khi lưu output thì bỏ link đó (xem cách làm trong lịch sử commit `evidence/code-review/`).
- Gọi CodeRabbit review lại: comment `@coderabbitai full review` trên PR. PR có base không phải nhánh mặc định thì nó không tự review.
- Đăng ký thử trên app: dùng `tranngocthien697+demoN@gmail.com` (697 gốc đã có tài khoản).
- Analytics: DebugView cần `adb shell setprop debug.firebase.analytics.app app.attendo` rồi mở lại app; Realtime nằm ở analytics.google.com → Reports → Realtime overview.
