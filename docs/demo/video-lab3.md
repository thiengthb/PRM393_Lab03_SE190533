# Kịch bản video Lab 3 (khoảng 8 phút)

Video Lab 3 chứng minh **app chạy thật trên Firebase thật** và mỗi tiêu chí của đề có một cảnh làm bằng chứng. Thứ tự cảnh đi theo bảng điểm Lab 3: luồng chính trước (2,5 điểm), rồi từng dịch vụ Firebase (2,0), ARTEMIS (1,5), review AI (0,5). Slide Lab 3 dùng ở đầu và cuối video.

Viết 10/11/2026. Chưa quay thử. Các cảnh dựa trên test tay T1, T2, T5, T6 đã chạy đạt ngày 09/11 (`docs/demo/TEST-TAY.md`) và lần đăng nhập Google kiểm ngày 10/11 (`docs/demo/DEMO-GOOGLE.md`).

## Chuẩn bị (10 phút, ngay trước khi quay)

- [ ] Chạy workflow [Demo: Firebase thật](https://github.com/thiengthb/PRM393_Lab03_SE190533/actions/workflows/demo-firebase.yml): Branch **final-system**, **tick ô xoá dữ liệu**, bỏ tick deploy. Đợi tick xanh (khoảng 2 phút). Dữ liệu mới có slot PRM393 · SE1801 đang diễn ra. **Xem giờ kết thúc của slot đó** trên Tổng quan: nếu chạy lúc đang trong một slot học thật, dữ liệu dùng luôn slot thật nên có thể chỉ còn vài phút. Còn dưới 30 phút thì đợi slot đó hết rồi chạy lại workflow (ngoài giờ học, dữ liệu tạo slot dài 2 giờ 15 phút).
- [ ] Điện thoại (gọi là **ĐT**): app Attendo bản từ Release `demo` hoặc bản dev, đăng nhập Google nick **024**, ở Tổng quan. Bật **Không làm phiền** để thông báo khác không chen vào.
- [ ] Laptop, Chrome ẩn danh (**SV**): https://attendo-app-2611.web.app đăng nhập Google nick **697**.
- [ ] Laptop, Chrome thường, các tab theo thứ tự:
  1. Slide Lab 3: https://thiengthb.github.io/PRM393_Lab03_SE190533/lab3.html
  2. Web admin (**ADMIN**): https://attendo-app-2611-admin.web.app (Google nick 628)
  3. [Firestore](https://console.firebase.google.com/project/attendo-app-2611/firestore/databases/-default-/data), [DebugView](https://console.firebase.google.com/project/attendo-app-2611/analytics/debugview), [Crashlytics](https://console.firebase.google.com/project/attendo-app-2611/crashlytics), [Remote Config](https://console.firebase.google.com/project/attendo-app-2611/config), [Messaging](https://console.firebase.google.com/project/attendo-app-2611/messaging)
  4. ARTEMIS http://localhost:8000 (mở sẵn một bản phát lại test TC-05) và `evidence/artemis/results.md` trên GitHub
  5. PR #28 tab **Files changed** (nhận xét của CodeRabbit)
- [ ] Bật DebugView cho ĐT (một lần, ĐT cắm cáp):
```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell setprop debug.firebase.analytics.app app.attendo
```
- [ ] Phần mềm quay: OBS hoặc **Win+Alt+R** (Xbox Game Bar). Màn ĐT chiếu lên laptop bằng scrcpy (có trong bộ ARTEMIS) để quay chung một khung.

## Các cảnh

| # | Giờ | Màn | Làm gì | Nói gì (gợi ý, nói bằng lời của bạn) |
|---|---|---|---|---|
| 1 | 0:00 | Slide 1 đến 5 | Lật nhanh bìa, bài toán và persona, Figma và app, MVVM, design system | Attendo điểm danh bằng QR cho lớp FPTU. Flutter MVVM với Riverpod, mọi dữ liệu ở Firebase, không có server riêng. |
| 2 | 0:40 | ĐT | Đăng xuất, bấm **Đăng nhập với Google**, chọn nick 024 | Authentication: đăng nhập Google, vai trò giảng viên đọc từ `users/{uid}`. |
| 3 | 1:00 | ĐT | Tổng quan → bấm **Điểm danh** ở slot đang diễn ra | Mở phiên: mã QR và mã 6 số đổi mỗi 12 giây, lấy từ Remote Config. |
| 4 | 1:20 | SV | **Nhập mã điểm danh** → gõ mã 6 số đang hiện trên ĐT → **Gửi** | Sinh viên gửi mã. Security Rules kiểm mã còn hạn và em có tên trong lớp. |
| 5 | 1:40 | ĐT | Số có mặt tự tăng 1 | Firestore realtime: không cần tải lại. |
| 6 | 1:50 | Firestore | Mở `slots`, document của slot vừa mở, thấy `qrToken` đang đổi | Đây là dữ liệu thật trên console. |
| 7 | 2:10 | ĐT | **Đóng mã** → bật tay một em ở **Chưa quét** → **Chốt** → thấy "Đã chốt" | Chốt một lần, có Hoàn tác. |
| 8 | 2:30 | DebugView | Dòng thời gian có `attendance_session_open`, `attendance_close`; bấm `attendance_close` xem tham số | Analytics: mỗi sự kiện trả lời một câu hỏi trong kế hoạch sự kiện. |
| 9 | 3:00 | SV | Mở PRM393 · SE1801, một buổi vắng → **Báo sai** → chọn lý do → **Gửi** | Luồng thứ hai: sinh viên báo sai. |
| 10 | 3:20 | ĐT | Tổng quan → ô **yêu cầu sửa** → bấm yêu cầu vừa tới → **Duyệt** | Giảng viên duyệt, sinh viên thấy buổi đó thành Có mặt. |
| 11 | 3:40 | SV | Buổi đó đổi thành **Có mặt**, số vắng giảm 1 | Trạng thái yêu cầu: chờ → duyệt. |
| 12 | 3:55 | Messaging | ĐT bấm **Home** cho app xuống nền. Laptop: **New campaign** → **Notifications** → tiêu đề, nội dung; mục **Additional options** → **Custom data** thêm key `route`, value `/requests` → **Send test message** tới token của ĐT (lấy ở Khu demo) | FCM: token là định danh một lần cài app, app lấy bằng `getToken()` và lưu vào Firestore. |
| 13 | 4:25 | ĐT | Thông báo hiện khi app ở nền; bấm vào thì app mở màn **Yêu cầu sửa** (theo `route` trong dữ liệu tin) | Ba trạng thái đã thử đủ, ảnh ở `evidence/fcm/`. |
| 14 | 4:45 | ĐT | Tài khoản → **Khu demo** → **Test crash** → mở lại app | Crashlytics: app gửi báo lỗi khi mở lại. |
| 15 | 5:05 | ADMIN | Mục **Sự cố**: dòng Test crash mới | Web admin đọc bản tóm tắt app ghi vào `crashReports`, vì Crashlytics không cho client đọc. |
| 16 | 5:20 | Crashlytics | Issue `FirebaseCrashlyticsTestCrash` (có thể phải đợi vài phút; dùng ảnh trong `evidence/crashlytics/` nếu chưa lên) | |
| 17 | 5:35 | Remote Config → ĐT | Đổi `qr_rotate_seconds` 12 → 15, **Publish**; ĐT Khu demo thấy 15s; đổi lại 12 | Remote Config đổi hành vi app không cần cập nhật app. |
| 18 | 6:05 | ĐT | Lớp → PRM393 · SE1801 → **Xuất PDF** → link Cloudinary | Upload file: Cloudinary thay Cloud Storage vì project ở gói Spark. |
| 19 | 6:25 | ARTEMIS | Phát lại TC-05 vài giây; mở `results.md` | ARTEMIS: N ca, mỗi ca chạy 3 lần (đọc số thật từ `results.md`). |
| 20 | 7:00 | PR #28 | Cuộn qua 2 nhận xét của CodeRabbit; mở `docs/code-review.md` | Review AI: mỗi nhận xét có quyết định nhận hay bác, nhận thì có commit sửa. |
| 21 | 7:30 | Slide 15 | Khó khăn và bài học, công cụ AI đã dùng | Kết thúc. |

## Dễ nhầm

- Cảnh 4: mã 6 số đổi mỗi 12 giây. Gõ chậm vẫn được thêm một chu kỳ (mã vừa thay còn nhận), nhưng đừng đợi quá 20 giây.
- Cảnh 7: đừng bấm **Hoàn tác** trong 5 giây sau khi chốt.
- Cảnh 12 đến 13: nếu bấm thông báo chỉ mở app ở Tổng quan mà không sang Yêu cầu sửa, nghĩa là tin thử không mang `route`; khi đó chỉ nói "bấm vào thì mở app", đừng nói mở đúng màn. Gửi bằng script thì chắc chắn có `route`: cần khoá service account như [`docs/fcm.md`](../fcm.md), rồi trong `tool/fcm` chạy `node send.mjs --to <email nick 024> --title "Có yêu cầu sửa mới" --body "SE190101 báo sai buổi" --route /requests` (hoặc nhắn Claude chạy).
- Cảnh 12: **Send test message** cần token của ĐT. Token ở Khu demo, mục FCM, có nút chép; gửi qua Zalo hoặc dán vào laptop trước khi quay.
- Cảnh 17: nhớ đổi `qr_rotate_seconds` về **12** sau khi quay.
- Nếu Tổng quan không còn slot đang diễn ra (quay quá 2 giờ sau khi nạp dữ liệu), chạy lại workflow Demo có tick xoá dữ liệu.

## Sau khi quay

- Tải lên YouTube (chế độ Không công khai) hoặc Google Drive (ai có link đều xem được), dán link vào README mục nộp bài và slide cuối.
