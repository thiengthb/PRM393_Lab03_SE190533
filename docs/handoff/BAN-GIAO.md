# Bàn giao Lab 3 PRM393, 03/11/2026

Tài liệu này để tiếp tục Lab 3 từ một tài khoản Claude khác, không cần chat cũ. Mọi thứ cần biết nằm trong repo này.

**Câu dán để mở chat mới:**

> Gắn repo `thiengthb/PRM393_Lab03_SE190533` với quyền push. Đọc `docs/handoff/BAN-GIAO.md` rồi `docs/handoff/LAB3-ke-hoach-giao-dien-v2.md` trên nhánh `ui-v2`, tóm tắt lại cho mình trong vài câu, rồi làm tiếp từ mục "Việc tiếp theo". Nhắn với mình bằng tiếng Việt.

Đính kèm thêm 3 file PDF: đề Lab 3, đề Final, hướng dẫn chuẩn bị Lab 3. Trong repo không có các file này.

## 1. Bối cảnh

- **Sinh viên:** Trần Ngọc Thiên, SE190533. Thích nhắn bằng tiếng Việt, viết dễ hiểu, giải thích thuật ngữ.
- **App:** điểm danh bằng mã QR cho FPTU. Giảng viên dùng app Android, sinh viên dùng web, cùng một codebase Flutter, MVVM với Riverpod 3.
- **Tên:** đang đổi từ Quick Attend (màu cam) sang Hereby (màu Biển sâu), theo Figma v2.
- **Hạn:** Lab 3 thứ Sáu 06/11/2026; giờ cụ thể bạn chưa xác nhận. Bài Final làm sau.

## 2. Các nhánh

| Nhánh | Là gì | Ghi chú |
|---|---|---|
| `ui-v2` | **Làm Lab 3 ở đây.** Tách từ `main`, đã nối Firebase | `lib/` ở gốc repo, đúng cấu trúc đề Lab 3 |
| `main` | Bản Lab 3 giao diện cam, commit `5435678` | Không sửa trực tiếp |
| `final-system` | Bài Final: monorepo, web admin, AI, duyệt lớp, 118 ca test Rules | **Không đụng tới trước khi nộp Lab 3.** Nộp xong gộp `main` vào đây |

## 3. Đã chốt

- Làm Lab 3 trên `ui-v2`, nộp từ đó.
- **Không nâng gói Blaze.** Vì vậy không có Cloud Storage. Việc này ảnh hưởng 0,25 điểm, bạn cần nhắn thầy xin dùng cách thay thế; đề mục 3 cho phép. Chưa có xác nhận là đã nhắn.
- Giữ `applicationId` là `vn.edu.fpt.quick_attend`, chỉ đổi nhãn hiển thị thành Hereby.
- Firebase project đặt tên `hereby-se190533`.

Các câu 4 đến 7 ở mục 3 của kế hoạch (cách vào màn TV, mã số, lối sửa slot đã chốt, tám bảng màu) **chưa được trả lời**, nên dùng cách mặc định ghi trong kế hoạch và ghi vào bảng khác biệt.

## 4. Firebase đã làm gì

Làm trên console bằng tài khoản `tranngocthien024@gmail.com`. Khi cần vào console phải đăng nhập đúng tài khoản này.

| Mục | Trạng thái |
|---|---|
| Project | `hereby-se190533`, số `267439096687`, gói Spark |
| Analytics | Đã bật, tắt mọi mục chia sẻ dữ liệu. App web chưa nối luồng Analytics: trong Project settings có nút "Create stream" |
| Authentication | Đã bật Email/Password và Google. Tên công khai Hereby |
| Firestore | Đã tạo, `asia-southeast1`, chế độ production |
| App Android | `vn.edu.fpt.quick_attend`, đã thêm SHA-1 debug `5a:ec:93:0d:f0:9a:eb:82:c8:18:f3:98:c6:bd:e3:1d:9a:73:e6:9f` |
| App web | Hereby Web, đã liên kết Hosting site `hereby-se190533` |
| Security Rules, chỉ mục, Remote Config | **Chưa đẩy lên.** Xem mục 6 |
| Hosting | **Chưa deploy** |
| Crashlytics, FCM | Chưa kiểm tra; cần app chạy trước |
| Cloud Storage | Không bật, theo quyết định ở mục 3 |

Trên nhánh `ui-v2` đã có `android/app/google-services.json`, `lib/firebase_options.dart`, `.firebaserc`, plugin Gradle `google-services` 4.4.4 và `crashlytics` 3.0.6, Web client ID đặt mặc định trong `lib/config/app_config.dart`. Các giá trị này không phải bí mật; đề cho phép đưa lên repo.

## 5. Mức độ đã kiểm tra

Đừng coi các mục dưới đây là đã chạy được:

- **App chưa từng chạy với Firebase thật.** Các phiên bản plugin Gradle mới chọn, chưa build thử trên máy.
- `ui-v2` có CI ở `.github/workflows/ci.yml`. Xem kết quả commit mới nhất ở tab Actions, hoặc qua API `commits/ui-v2/check-runs` nếu phiên làm việc đọc được.
- Lỗi `file_picker_service.dart:37` khi phân tích ở máy cloud là lỗi giả, do lấy `cross_file` bản mới thay vì bản trong `pubspec.lock`. Trên CI của `final-system` không có lỗi này.
- Thư mục `evidence/` chỉ có bản review của Claude. **Không điền kết quả chưa chạy**: đề coi là gian lận.

## 6. Việc tiếp theo

**Bạn chạy trên laptop.** Máy Windows, Flutter ở `C:\Users\trann\flutter`. Lệnh trong PowerShell:

```powershell
cd $HOME\develop
git clone -b ui-v2 https://github.com/thiengthb/PRM393_Lab03_SE190533
cd PRM393_Lab03_SE190533
npm i -g firebase-tools
firebase login
firebase deploy --only firestore,remoteconfig
flutter pub get
flutter run
```

`firebase login` phải chọn tài khoản `...024`. Trước `flutter run`, cắm điện thoại Android hoặc mở máy ảo. Đạt khi app mở màn đăng nhập và đăng ký được tài khoản. Sau đó thử trọn một vòng theo Giai đoạn 0: nhập `sample-data/lop-fall-2026.csv`, điểm danh giữa điện thoại và web.

**Phần của Claude: đã xong hết trong ngày 03/11** (kiểm lại ngày 04/11, CI nhánh `ui-v2` xanh tới commit `31d20cd`):

1. Xuất PDF lưu và chia sẻ trên máy, metadata ở Firestore `reports`, có luật và D-L3-10 (`9131dbe`).
2. Giai đoạn 1: Hereby, Biển sâu, logo, thanh tab, hai kiểu thẻ, vùng bấm 48 (`ea62ac9`).
3. Giai đoạn 2 đến 5 của mục 7 kế hoạch: GV-102 kèm `qrTokenPrev`, GV-001, GV-002, mã số, TV-001, test Rules 63/63 trên Emulator, màn sinh viên, các màn giảng viên còn lại, chữ của 16 ca ARTEMIS và TC-17, đủ 8 bảng màu.
4. Mục 8 kế hoạch: truy vết, test plan, kiến trúc, README trên repo này; tài liệu Lab 2 có `design/final-ui-v2.md` (PR #1 repo Lab 2 đã gộp).

**Còn lại, đều cần máy bạn hoặc tài khoản của bạn**, nên Claude không làm thay được:

- Chạy các lệnh ở trên, deploy Rules, Remote Config và Hosting. App vẫn chưa chạy với Firebase thật.
- Chụp bằng chứng vào `evidence/` (đăng nhập, Users, FCM, Crashlytics, Remote Config, DebugView, ARTEMIS chạy 3 lần). Các thư mục này hiện chỉ có `.gitkeep`, trừ `rules/` và `code-review/`.
- Mở PR cho công cụ AI review (CodeRabbit hoặc Copilot), quay video, làm slide.
- Gửi ảnh từng màn để Claude so với Figma và sửa.

## 7. Công cụ và cách làm

- **Figma** file key `1qIZVpL0Q7bD9UzT5TVBRy`, trang chính `03 Final UI · v2` (`239:4208`). **Mặc định chỉ đọc**; muốn ghi phải xin phép từng lần, vì từng có phiên làm hỏng file. Tài khoản mới cần được cấp quyền xem file và kết nối Figma.
- **Máy cloud không tải được pub.dev và Flutter engine**, nên không chạy được app ở đó; kết quả thật lấy từ CI và máy bạn. Có thể tự dựng phân tích tĩnh: lấy `dart-sdk` từ conda-forge, clone mã nguồn package từ GitHub, tự sinh `package_config.json`.
- **Commit** dùng `user.name=thiengthb`, email `tranngocthien697@gmail.com`. Từ phiên cloud không đẩy được tag.
- **Luật kiến trúc:** màn hình không import Firebase; lọc và đếm nằm ở ViewModel. Lệnh kiểm tra ở `docs/code-review.md`.
- Mỗi lần sửa giao diện cần bạn chạy thử và gửi ảnh, vì máy cloud không xem được màn hình app.

## 8. Câu hỏi còn mở với bạn

- Đã nhắn thầy về Cloud Storage và về thiết kế mới tên Hereby chưa? Đề chỉ cho đổi thiết kế khi lúc dựng gặp vấn đề thật.
- Giờ nộp chính xác của Lab 3?
- `lessons/LAB2-ban-giao*.md` (lý do các quyết định v2) chưa có trên GitHub. Cần đẩy lên hoặc đính kèm vào chat mới.
- Tài khoản Google test riêng và khoá API model cho ARTEMIS đã có chưa? Giai đoạn 5 cần.
