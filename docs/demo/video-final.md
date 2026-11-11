# Kịch bản video Final (khoảng 10 phút, đề cho 8 đến 12)

Video Final phủ đủ các mục đề Final mục 10 yêu cầu: luồng trên mobile, từng màn web, luồng liên vai trò thấy cả hai màn, AI kể cả cảnh tắt bằng Remote Config, và một lần chạy test. Thứ tự đi theo guideline V11 và dàn ý slide Final (`docs/slides/DAN-Y.md`): vấn đề và thiết kế trên slide (2 phút), rồi **demo chạy thật theo thứ tự 4 workflow** (7 phút), cuối cùng bằng chứng (1 phút). Phần từng dịch vụ Firebase đã có ở video Lab 3 nên chỉ nhắc khi workflow chạm tới.

Viết 10/11/2026. Chưa quay thử. Các cảnh dựa trên test tay T1 đến T6 (`docs/demo/TEST-TAY.md`) và hướng dẫn demo bằng nick Google (`docs/demo/DEMO-GOOGLE.md`). Quay sau mốc đóng băng giao diện (trưa 11/11).

## Chuẩn bị (15 phút, ngay trước khi quay)

- [ ] Chạy workflow [Demo: Firebase thật](https://github.com/thiengthb/PRM393_Lab03_SE190533/actions/workflows/demo-firebase.yml): Branch **final-system**, **tick ô xoá dữ liệu**, bỏ tick deploy. Đợi tick xanh. Ghi số **N** ở dòng "Slot đang diễn ra: N" (cần cho FAP giả).
- [ ] Điện thoại (**ĐT**): app Attendo bản Release `demo`, đăng nhập Google nick **024**, ở Tổng quan. Bật **Không làm phiền**.
  - Nếu đã chạy ARTEMIS (`run-e2e.ps1`) trên máy này: app đang là bản nối Emulator, ký bằng khoá debug. Gỡ app Attendo, tải lại **Attendo-GiangVien.apk** ở [Release demo](https://github.com/thiengthb/PRM393_Lab03_SE190533/releases/tag/demo), cài, đăng nhập Google nick **024**. Kiểm: Tổng quan có thẻ Đang diễn ra của dữ liệu vừa nạp.
- [ ] Điện thoại thứ hai hoặc Chrome trên ĐT (**ĐT-web**): https://attendo-app-2611.web.app, đăng nhập `tien102@fpt.edu.vn` / `Demo@123`.
- [ ] Laptop:
  - **WIN**: app Attendo cho Windows, đăng nhập email nick 024 + `Demo@123`.
  - **SV**: Chrome ẩn danh, https://attendo-app-2611.web.app, Google nick **697**.
  - **ADMIN**: Chrome thường, https://attendo-app-2611-admin.web.app, Google nick **628**.
  - **FAP**: Chrome thường, https://attendo-app-2611-fap.web.app, extension Attendo đã tải lại bản mới ở `chrome://extensions`, đăng nhập nick 024.
  - Tab slide Final và tab [Remote Config](https://console.firebase.google.com/project/attendo-app-2611/config).
- [ ] Màn ĐT chiếu lên laptop bằng scrcpy để quay chung một khung. Quay bằng **OBS**, nguồn **Display Capture** (cả màn hình) để thấy cùng lúc cửa sổ scrcpy và trình duyệt. Đừng dùng Win+Alt+R: Xbox Game Bar chỉ quay một cửa sổ.
- [ ] Cảnh 20 cần chạy test trực tiếp. Mở sẵn một cửa sổ PowerShell, mỗi dòng một lệnh:
```
$env:Path = "C:\Program Files\Android\Android Studio\jbr\bin;" + $env:Path
cd $HOME\develop\attendo\firebase\tests
npm ci
npm test
```
  Chạy thử một lần trước khi quay (lần đầu tải Emulator mất vài phút).
- [ ] Đồng hồ hiện giây trên màn (ví dụ trang time.is) đặt ở góc, để đo cảnh 13 từ bản quay.

## Các cảnh

| # | Giờ | Màn | Làm gì | Nói gì (gợi ý, nói bằng lời của bạn) |
|---|---|---|---|---|
| 1 | 0:00 | Slide 1 đến 3 | Bìa; bối cảnh, vấn đề và giải pháp; actor và persona | Điểm danh trên FAP tốn thời gian, dễ quên chốt, sinh viên biết vắng quá muộn, ghi nhầm thì không có kênh sửa. Attendo có bốn actor: giảng viên, sinh viên, Quản trị trên web admin, nhóm phát triển trên Firebase console. |
| 2 | 0:50 | Slide 4 đến 7 | Swimlane, 4 workflow, máy trạng thái, sơ đồ kiến trúc | Không có server riêng: Security Rules quyết định ai ghi được gì, App Check chặn client lạ. Một lõi `packages/core` cho app Android, Windows, web sinh viên và web admin. |
| 3 | 1:50 | Slide 8, 10 | Cùng một màn trên điện thoại, Windows, web; rồi Demo plan | Một ViewModel, nhiều View: logic không lặp lại theo thiết bị. |
| | | | **WF-01 Điểm danh một buổi tới FAP** | |
| 4 | 2:10 | ĐT | Tổng quan → thẻ **Đang diễn ra: PRM393 · SE1801** | Mã QR và mã 6 số đổi mỗi 12 giây. |
| 5 | 2:25 | WIN | Tổng quan → **Ctrl+D** mở cùng phiên | Laptop cùng phiên: một máy giữ quyền đổi mã, máy kia hiện cùng mã, nên sinh viên không bao giờ gõ mã đã bị máy kia thay. |
| 6 | 2:45 | WIN → TV | **Chiếu lên TV** → mở link ở tab mới → F11 | Màn chiếu không cần đăng nhập, link có khoá và hết hạn sau giờ học. |
| 7 | 3:00 | ĐT-web | **Quét mã** → quét QR trên TV | Sinh viên quét bằng web, không cài app. Rules kiểm mã còn hạn và em có tên trong lớp. |
| 8 | 3:15 | SV | **Nhập mã điểm danh** → gõ mã 6 số → Gửi | Em ngồi xa không quét được thì gõ mã. Số có mặt trên ĐT, WIN, TV cùng tăng. |
| 9 | 3:35 | WIN | **Space** đóng mã → bật tay một em ở **Chưa quét** → **Ctrl+Enter** chốt | Chốt một lần, có Hoàn tác; TV báo đã đóng mã. |
| 10 | 3:55 | FAP | Chọn **PRM393 · SE1801 · Slot N** → extension **Đọc trang** → **Lấy bản đã chốt** → tick **Tôi đã kiểm tra danh sách** → **Điền vào trang** | Extension đọc bản đã chốt và điền vào FAP. Giảng viên vẫn tự bấm Save trên FAP. |
| 11 | 4:25 | FAP | Đổi sang slot khác → Đọc lại → Lấy bản đã chốt | Sai buổi thì extension từ chối, không điền nhầm. |
| | | | **WF-02 Báo sai** | |
| 12 | 4:40 | SV → WIN → SV | SV: PRM393 SE1801 → buổi vắng → **Báo sai** → **Quên quét mã** → Gửi. WIN: **Yêu cầu sửa** → **Duyệt**. SV: buổi đó thành có mặt | Luồng thứ hai giữa hai vai trò: sinh viên gửi, giảng viên duyệt, sinh viên thấy ngay, không cần tải lại. |
| | | | **WF-03 Duyệt lớp liên vai trò** (luồng bắt buộc) | |
| 13 | 5:30 | ĐT + ADMIN cùng khung | ĐT: đăng xuất → đăng nhập `nam@fe.edu.vn` → lớp **MMA301 · SE1806** "Chờ giáo vụ duyệt". ADMIN: **Duyệt lớp** → MMA301 · SE1806 → xem danh sách → **Duyệt lớp này** | Giảng viên tự đăng ký được, nên lớp phải được Quản trị duyệt trên web mới mở mã. Trước khi duyệt, Rules từ chối mở mã. Đây là số đo cho báo cáo: từ lúc bấm Duyệt tới lúc app đổi. |
| 14 | 6:10 | ĐT | Chữ chờ duyệt biến mất; nút thư có chấm → Hộp thư → tin "đã được duyệt" | Web ghi một batch: trạng thái lớp và tin hộp thư. App nghe Firestore nên đổi ngay. |
| 15 | 6:30 | ADMIN | Lướt **Tổng quan** (số lớp, tỉ lệ có mặt, biểu đồ theo môn), **Môn học**, **Thông báo** (đăng một tin cho sinh viên → SV thấy trong Hộp thư), **Người dùng**, **Sự cố** | Web admin chỉ mở cho Quản trị; tài khoản vai trò khác bị chặn với câu rõ ràng. Số ở Tổng quan là aggregation chạy trên Firestore. |
| | | | **WF-04 Nhắc sinh viên vắng nhiều, có AI** | |
| 16 | 7:20 | ĐT | Đăng nhập lại nick 024 → Tổng quan → **Vắng nhiều** → **Sắp chạm** → em đầu tiên → **Nhắc nhở** → **Gợi ý AI** | Gemini qua Firebase AI Logic trả JSON đúng schema. Chỉ gửi mã môn và 4 con số, không gửi tên hay MSSV. |
| 17 | 7:45 | ĐT | Sửa một chữ trong ô soạn → **Gửi** | AI chỉ gợi ý, giảng viên đọc và sửa trước khi gửi; nhãn "AI gợi ý" nằm trên ô soạn. |
| 18 | 8:00 | Remote Config → ĐT | `ai_reminder_enabled` → **false** → Publish. ĐT: Khu demo → **Tải lại** → mở sheet nhắc em khác: không còn nút AI | Tắt AI từ xa không cần cập nhật app; luồng nhắc vẫn chạy bằng câu mẫu. |
| 19 | 8:30 | Remote Config | Đổi `ai_reminder_enabled` về **true** → Publish | |
| | | | **Bằng chứng** | |
| 20 | 8:45 | PowerShell | Chạy bộ test Rules trên Emulator (lệnh ở mục Chuẩn bị); để chạy trong lúc nói, quay lại khi in `# pass 196` | Đề yêu cầu một lần chạy test trong video. Mỗi vai trò, mỗi collection có ca được phép và ca bị chặn. |
| 21 | 9:20 | Slide 14 | Bảng test: unit, Rules 196 ca, E2E web, extension, test tay, ARTEMIS (đọc số thật trên slide) | Mọi con số lấy từ CI và `evidence/`. |
| 22 | 9:50 | Slide 15 | Đạt được, giới hạn, hướng tiếp | Giới hạn: không có server nên FCM chưa tự gửi theo sự kiện; vai trò tự khai được giảm rủi ro bằng bước duyệt lớp. |

## Đo thời gian WF-03 (cảnh 13 đến 14)

Báo cáo Final cần 3 lần đo. Quay cảnh 13 ba lần (hoặc quay một lần trong video, hai lần còn lại quay riêng): dùng workflow Demo có tick xoá dữ liệu để lớp MMA301 · SE1806 về lại "Chờ duyệt".

Đọc trên bản quay: khung hình con trỏ bấm **Duyệt lớp này** và khung hình chữ "Chờ giáo vụ duyệt" biến mất trên ĐT. Ghi vào bảng ở `docs/cross-role-flow.md`. Không đo được thì để trống, không ước lượng.

## Dễ nhầm

- Cảnh 5: mở WIN sau ĐT; nếu WIN hiện dòng "máy khác đang đổi mã" là đúng.
- Cảnh 9: đừng bấm **Hoàn tác** trong 5 giây sau khi chốt.
- Cảnh 10: số **N** của slot lấy từ workflow Demo. Extension phải là bản mới (tải lại ở `chrome://extensions`).
- Cảnh 13: ĐT phải là app Attendo bản mới (`app.attendo`); gỡ bản cũ nếu còn (LOI-26).
- Cảnh 16: AI cần APK có debug token App Check (bản Release `demo`). Bản dev tự dựng có thể báo lỗi App Check (LOI-15).
- Cảnh 18: nhớ đổi `ai_reminder_enabled` về **true**.
- Nếu Tổng quan không còn slot đang diễn ra (quá 2 giờ sau khi nạp dữ liệu), chạy lại workflow Demo có tick xoá dữ liệu.

## Sau khi quay

- Tải lên YouTube (Không công khai) hoặc Google Drive (ai có link đều xem được), dán link vào README mục nộp bài, slide cuối và `report/final/report.md` mục 1.
- Điền 3 số đo WF-03 vào `docs/cross-role-flow.md` và báo cáo Final mục 5.
