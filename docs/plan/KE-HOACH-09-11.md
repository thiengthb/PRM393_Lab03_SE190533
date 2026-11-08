# Kế hoạch hoàn thiện Attendo, 09/11 đến 13/11/2026

Viết 09/11/2026, 03:30 · Claude, đọc từ git, API GitHub, đề Lab 3, đề Final, guideline slide V11, tài liệu "Workflow là gì" và lời nhắn của thầy thien gửi.

File này là kế hoạch tổng. Tiến độ từng ngày vẫn ghi ở `docs/STATUS.md`. Ba quyết định khó sửa nằm ở `docs/decisions/001` đến `003`, thien chọn trước khi Claude làm phần liên quan.

## 1. Tình hình lúc lập kế hoạch

[Fact] `docs/STATUS.md` đã cũ: còn ghi PR #19 chờ gộp, trong khi `final-system` đã gộp tới PR #26 (`8d963e8`). Firebase thật đã được deploy (workflow `Demo: Firebase thật` chạy xanh lúc 02:59 ngày 09/11). Lỗi còn mở trong `docs/demo/loi.md`: LOI-05, LOI-06, LOI-07, LOI-14 (chờ ảnh Console), LOI-15 (chờ câu lỗi AI).

[Fact] Thời gian một vòng sửa lỗi hiện nay, đo từ các lần chạy ngày 08/11:

| Bước | Thời gian |
|---|---|
| CI trên nhánh sửa | 5 đến 6 phút |
| Demo: dựng bản cài trên nhánh sửa | 6 đến 11 phút |
| E2E builds trên nhánh sửa | 17 đến 22 phút |
| Gộp PR, CI và dựng bản cài lại trên `final-system` | 6 đến 7 phút |
| Demo: Firebase thật | 1 phút (chỉ nạp dữ liệu) đến 10 phút (đẩy Rules, Hosting) |
| thien tải APK hoặc zip, cài đè, đăng nhập lại | 5 đến 10 phút |

Cộng lại 40 đến 60 phút, khớp với điều thien thấy. Ba job chạy song song nhưng thien phải chờ job chậm nhất (E2E), rồi chờ thêm một lượt nữa sau khi gộp.

[Fact] Ảnh chụp giao diện hiện tại ở khổ laptop 1440 px (Emulator, bản `7f4dea2`): bản Windows và web admin đã có thanh bên, nhưng phần thân vẫn là giao diện điện thoại kéo rộng ra.

- Tab Điểm danh: dải tuần chỉ chiếm nửa trái, thẻ slot to như trên điện thoại, nửa màn trống.
- Tab Lớp: thẻ lớp xếp lưới, không có bảng, bấm vào mới mở màn khác thay vì xem ngay bên cạnh.
- Tài khoản: một cột hẹp ở giữa, hai bên trống.
- Web sinh viên trên laptop: một cột 640 px ở giữa màn 1440 px.
- Web admin Duyệt lớp: ô "Đã xử lý hết" kéo hết ngang, không có bảng, không tìm kiếm, không lọc.

## 2. Đề và lời thầy đòi gì, đang ở đâu

| Yêu cầu | Nguồn | Đang có | Còn thiếu |
|---|---|---|---|
| Chạy trên máy thật khi chấm | Thầy | APK, bản Windows | Thử trọn vẹn trên điện thoại thật |
| Upload file: Cloudinary hoặc S3 thay Cloud Storage | Thầy | PDF lên Cloudinary (D-L3-18) | Bằng chứng trên console Cloudinary |
| Crashlytics: nút làm app crash, admin xem kết quả trên web | Thầy | Nút "Test crash" ở Khu demo, màn Sự cố trên web admin đọc `crashReports` | Thử thật: crash, mở lại app, Crashlytics console và web admin cùng thấy |
| Web chỉ cần phục vụ Admin; team dev xem trên Firebase console | Thầy | Web admin + web sinh viên cùng một Hosting | Chốt phạm vi web ở quyết định 002 |
| Slide giải thích nguyên lý (FCM token là gì, cấp ở đâu, client có lưu không, gửi tin thế nào, code ở đâu) | Thầy | `docs/fcm.md` | Bộ slide công nghệ cho Lab 3 |
| Slide theo guideline V11 (Problem, Design, Demo theo workflow, Proof) | Thầy | Chưa có | Bộ slide Final |
| Lab 3: 6 dịch vụ Firebase có bằng chứng, ARTEMIS 3 lần mỗi ca, code review 5 phát hiện | Đề Lab 3 | Code đủ, test plan, code-review | Bằng chứng console, DebugView, ARTEMIS chạy thật |
| Final: web admin 4 màn + thông báo, Rules có test, luồng liên vai trò đo thời gian, AI mức 2 | Đề Final | Code đủ, 118 ca test Rules | Đo thời gian thật, 3 cặp vào/ra AI, checklist web có ảnh |
| Không mã số sinh viên trong sản phẩm, một tên Attendo | thien | Logo Attendo; chữ Hereby còn ở app Windows (hereby.exe), Firebase project `hereby-se190533`, gói Dart `quick_attend_core`, mã app Android `vn.edu.fpt.quick_attend` | Đổi tên toàn bộ, Firebase project mới (quyết định 001) |

## 3. Vòng sửa nhanh: từ 40 đến 60 phút xuống dưới 1 phút

Ý chính: test tay không chờ CI nữa. CI chỉ còn để giữ chất lượng và dựng bản nộp.

### 3.1. Laptop của thien chạy bản dev, tự nạp lại khi code đổi

[Fact] Laptop có Flutter (`~/flutter`, `~/develop/flutter`), có bản clone `~/develop/PRM393_Lab03_SE190533`, có thư mục `~/develop/artemis`.

1. thien cấp cho phiên này quyền thư mục `~/develop` (một lần bấm Cho phép).
2. Claude viết `tool/dev/watch.mjs`: chạy `flutter run` cho từng đích (điện thoại, Windows, Chrome), theo dõi thư mục `lib/` và tự gửi lệnh hot reload khi file đổi. thien chạy một lệnh duy nhất trong PowerShell rồi để đó.
3. Mỗi lần sửa: Claude sửa code trên máy cloud, đẩy lên nhánh, rồi kéo về bản clone trên laptop qua công cụ thư mục. Lệnh `watch` thấy file đổi và nạp lại app trên điện thoại trong vài giây. thien không phải cài lại gì.
4. Web admin và web sinh viên cũng chạy bằng `flutter run -d chrome` trỏ vào Firebase thật, nên sửa web cũng không cần deploy để thử. Chỉ deploy khi gom xong một đợt.

Điều kiện [Chưa kiểm]: phiên bản Flutter trên laptop phải chạy được code hiện tại (CI dùng 3.47.3). Claude kiểm ở bước đầu và đưa lệnh cập nhật nếu lệch.

### 3.2. Claude tự xem và tự bấm trên điện thoại

- Điện thoại cắm USB, bật gỡ lỗi USB. Màn điện thoại hiện trên laptop bằng scrcpy (có sẵn trong bộ cài ARTEMIS).
- Claude dùng tính năng điều khiển máy tính của app Claude để chụp và bấm vào cửa sổ scrcpy và cửa sổ app Windows. Terminal và VS Code chỉ cho Claude bấm, không cho gõ, nên lệnh dài vẫn do thien dán một lần.
- Web admin, web sinh viên: Claude dùng trình duyệt có sẵn trong app Claude.

### 3.3. CI gọn lại

| Thay đổi | Lợi ích |
|---|---|
| Lọc theo đường dẫn: đổi Dart thì không chạy job extension, Rules; đổi extension thì không chạy Flutter | Nhánh sửa nhỏ còn 3 đến 5 phút |
| Build Windows, dựng bản cài, E2E 31 ca chỉ chạy trên `final-system`, khi bấm tay, hoặc khi PR có nhãn `e2e` | Nhánh sửa không còn chờ 20 phút |
| `concurrency` huỷ lần chạy cũ khi đẩy commit mới lên cùng nhánh | Không xếp hàng |
| Cache pub, Gradle (đã có một phần) | Giảm 1 đến 2 phút mỗi job |
| Một workflow `Bản nộp` dựng APK, zip Windows, extension và deploy Hosting một lần khi gom đợt | Cài bản mới 1 lần mỗi đợt thay vì mỗi lỗi |

## 4. Giao diện riêng cho từng thiết bị

Nguyên tắc: một ViewModel, nhiều View. Logic, trạng thái tải, rỗng, lỗi giữ nguyên ở ViewModel (đúng luật MVVM của đề); chỉ phần dựng giao diện tách theo thiết bị. Đây cũng là điểm để giải thích trong slide kiến trúc.

Thiết bị được chọn theo nền tảng trước, độ rộng sau:

| Bản | Thiết bị | Khung |
|---|---|---|
| App Android | Điện thoại | Mobile: thanh tab đáy, một cột, nút cao 36 |
| App Windows | Desktop | Desktop luôn, kể cả khi thu nhỏ cửa sổ (đặt cỡ tối thiểu 1024 × 680): thanh bên, thanh lệnh trên, bảng, hai khung, nút cao 30, phím tắt, hover |
| Web admin | Web trên laptop | Bảng quản trị: thanh bên, breadcrumb, bảng có tìm kiếm, lọc, sắp xếp, phân trang, khung chi tiết trượt bên phải |
| Web sinh viên | Web, chủ yếu trên điện thoại | Mobile web; trên laptop là bố cục web hai cột thật sự (tuỳ quyết định 002) |
| Extension | Side panel Chrome 360 đến 420 px | Bước 1-2-3 gọn, nút hành động dính đáy, không chữ thừa |

Việc cụ thể theo màn, chi tiết ở `docs/plan/UI-THIET-BI.md` (viết ở bước 4):

- Desktop: Tổng quan thành bảng điều khiển hai cột (việc cần làm bên trái, lịch tuần dạng lưới giờ × ngày bên phải); Điểm danh thành lịch tuần kiểu Outlook; Lớp thành danh sách bên trái + chi tiết lớp bên phải có bảng sinh viên (tìm, sắp xếp theo số buổi vắng); màn phiên chia đôi: QR to bên trái, danh sách có mặt dạng bảng bên phải, phím tắt Space đóng/mở mã, Ctrl+Enter chốt; Tài khoản thành trang cài đặt hai cột (mục bên trái, nội dung bên phải).
- Web admin: mọi danh sách thành bảng dữ liệu; Duyệt lớp có khung chi tiết và hộp lý do từ chối; Tổng quan có biểu đồ và số liệu tổng hợp; Sự cố hiện bảng crash từ app kèm khoá tuỳ chỉnh và link mở Crashlytics.
- Điện thoại: giữ khung hiện tại, sửa LOI-05 (chỉ máy mở mã đầu tiên được đổi mã, máy sau chỉ xem và có nút Lấy quyền đổi mã), LOI-06 (số đã có mặt dính đầu màn khi cuộn), LOI-07.
- Theo thienui: mỗi màn chính đưa 3 hướng bố cục ở dạng ảnh để thien chọn trước khi làm, rồi chụp cả màn ở cỡ thiết bị để tự soát.

## 5. Đổi tên và Firebase project mới

- Một tên: Attendo. Bỏ Hereby, Quick Attend, `quick_attend`, mã số sinh viên khỏi mọi thứ người dùng thấy: tên app, tên file exe (`attendo.exe`), tiêu đề web, manifest, extension, kênh thông báo, link Hosting, README phần giới thiệu.
- Gói Dart `quick_attend_core` → `attendo_core`; mã app Android và Firebase project theo quyết định 001.
- Firebase project mới: Claude viết hướng dẫn theo `GUIDES.md` (link bấm được, nút in đậm, bảng điền sẵn), thien làm khoảng 40 phút. Không mất bằng chứng nào vì project cũ chưa có bằng chứng.
- Tên file nộp mà đề bắt có mã số (repo, `report/Final_<ID>.pdf`, `slides/...`) theo quyết định 003.

## 6. Test: AI tự test phần lớn, thien test tay 6 ca chính

Bốn workflow lõi (theo tài liệu "Workflow là gì": trigger, các bước, rẽ nhánh theo luật, kết quả):

| Mã | Workflow | Actor | Đối tượng đổi trạng thái |
|---|---|---|---|
| WF-01 | Điểm danh một buổi học | Giảng viên, sinh viên, extension | Slot: chưa mở → đang mở mã → đã đóng mã → đã chốt |
| WF-02 | Xử lý báo sai điểm danh | Sinh viên, giảng viên | Yêu cầu: chờ → duyệt / từ chối |
| WF-03 | Duyệt lớp mới của giảng viên (liên vai trò) | Giảng viên, quản trị | Lớp: chờ duyệt → đã duyệt / bị từ chối |
| WF-04 | Nhắc sinh viên sắp vượt ngưỡng vắng | Hệ thống, giảng viên, AI | Sinh viên: bình thường → sắp chạm → đã nhắc |

Phân công:

| Ai | Làm gì | Bao lâu |
|---|---|---|
| Claude, tự động | 31 ca E2E web trên Emulator (cập nhật theo giao diện mới), 118 ca Rules, unit test | Mỗi đợt |
| Claude, trên điện thoại qua scrcpy | Mọi nhánh rẽ, trạng thái rỗng, lỗi, mất mạng, đăng xuất, đổi giao diện, Khu demo | Mỗi đợt |
| thien, test tay | 6 ca chính trên máy thật, đúng như lúc demo: T1 điểm danh bằng camera + TV + chốt + điền FAP (WF-01); T2 báo sai và duyệt (WF-02); T3 duyệt lớp liên vai trò, đo thời gian (WF-03); T4 nhắc nhở có AI, tắt AI bằng Remote Config (WF-04); T5 FCM ở 3 trạng thái app, bấm thông báo mở đúng màn; T6 nút crash → Crashlytics console và web admin | Khoảng 35 phút |
| thien, một lệnh | ARTEMIS chạy cả bộ 3 lần, tự lưu bằng chứng vào `evidence/artemis/` | Để máy chạy, khoảng 1 giờ |

Ca nào Claude đã tự chạy thì tài liệu test tay ghi rõ; ca nào chưa chạy được ghi `(chưa thử)`.

## 7. Slide, báo cáo, video

- Slide Lab 3 (12 đến 15 slide, PDF): ưu tiên công nghệ như thầy nhắn. Mỗi dịch vụ một slide theo cùng khung: nó là gì, cấp ở đâu, lưu ở đâu, code nằm ở file nào, lỗi thì xử lý ra sao, bằng chứng. FCM trả lời đúng 5 câu thầy hỏi. Thêm Crashlytics, Remote Config, Analytics, App Check, AI Logic, Security Rules, Cloudinary.
- Slide Final (theo guideline V11, rút về 15 slide + phụ lục): Problem (bối cảnh FAP, 3 pain point, actor), Design (business flow có swimlane, state machine Slot và Yêu cầu, kiến trúc, stack, UI theo thiết bị, traceability), Demo WF-01 đến WF-03, Proof (test, đạt được, giới hạn).
- thien thích PPTX: làm bằng Slides của Claude (xuất PPTX và PDF), nếu thien muốn file .pptx ngay thì làm PPTX.
- Báo cáo PDF 8 đến 12 trang (Lab 3) và 10 đến 15 trang (Final): Claude soạn từ `docs/`, mọi câu "chạy được" gắn ảnh trong `evidence/`.
- Kịch bản video: theo thứ tự 4 workflow, cùng dữ liệu demo, có mốc thời gian.

## 8. Lịch

| Khi | Việc | Ai |
|---|---|---|
| Thứ Hai 09/11 sáng | Chốt 3 quyết định; cấp quyền thư mục, bật điều khiển máy tính, cắm điện thoại; Claude dựng vòng sửa nhanh và gọn CI | thien 15 phút, Claude |
| Thứ Hai 09/11 | Đổi tên Attendo; thien tạo Firebase project mới theo hướng dẫn; chạy thử app trên điện thoại bằng vòng sửa nhanh | thien 40 phút, Claude |
| Thứ Hai tối đến thứ Tư sáng | Giao diện theo thiết bị: desktop, web admin, web sinh viên, extension, sửa lỗi mở. Mỗi màn: 3 hướng → thien chọn → làm → Claude tự chụp và soát | Claude, thien chọn hướng |
| Thứ Tư 11/11 trưa | Đóng băng giao diện | |
| Thứ Tư chiều | Claude tự test toàn bộ; thien test tay 6 ca (35 phút); thien chạy ARTEMIS một lệnh | Cả hai |
| Thứ Tư tối đến thứ Năm | Bằng chứng console, code review trên PR, báo cáo, slide hai bộ, kịch bản video | Claude soạn, thien chụp console |
| Thứ Năm tối | thien quay video | thien |
| Thứ Sáu 13/11 | Dự phòng, soát checklist, mở mọi link ở cửa sổ ẩn danh, nộp | Cả hai |

Nếu thiếu giờ, cắt theo thứ tự: (1) 3 hướng bố cục cho màn phụ, chỉ làm cho màn chính; (2) desktop cho các màn ít dùng (Nhập lớp, Hộp thư) giữ bố cục hiện tại đặt giữa; (3) web sinh viên trên laptop; (4) đẹp thêm cho extension. Không cắt: vòng sửa nhanh, đổi tên, desktop cho màn phiên và Lớp, web admin dạng bảng, bằng chứng, slide.

## 9. Cần thien quyết

- 001: Firebase project mới và mã app Android.
- 002: Web phục vụ ai (thầy nhắn "web chỉ cần phục vụ cho Admin").
- 003: Tên repo khi nộp (đề bắt `PRM393_Final_<ID>`, thien không muốn mã số trong sản phẩm).
- LOI-05: Claude làm theo cách trong mục 4 nếu thien không chọn khác.
