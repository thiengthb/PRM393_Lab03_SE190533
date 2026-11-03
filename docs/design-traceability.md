# Design traceability · Lab 2 → Flutter

> Nguồn thiết kế: Figma [PRM323 Lab 2 v2 · SE190533](https://www.figma.com/design/1qIZVpL0Q7bD9UzT5TVBRy) (trang 03 Final UI, 05 Components, 06 Prototype) và repo Lab 2 [thiengthb/prm323-lab2-SE190533](https://github.com/thiengthb/prm323-lab2-SE190533) (`design/DESIGN.md` v3.1, `design/screen-spec.md` v2.0, `handoff/flutter-handoff.md` v2.0, `ux/user-flow.md` v1.0).
>
> Trạng thái: **Done** đã dựng và chạy; **Changed** dựng có thay đổi so với Figma (lý do ở mục 4); **Added** màn hoặc phần đề Lab 3 bắt buộc mà Lab 2 chưa có.

## 1. Màn hình → route, widget, nguồn dữ liệu

Portal: app Android build mặc định là **giảng viên**; build web (và Android với `--dart-define=PORTAL=student`) là **sinh viên** (D-L3-01).

| Mã Lab 2 | Màn | Route | Screen widget | ViewModel | Nguồn dữ liệu | Trạng thái |
|---|---|---|---|---|---|---|
| GV-090 | Đăng nhập | `/login` | `LoginScreen` | `LoginViewModel` | Firebase Auth | Done |
| GV-091 | Đăng ký | `/signup` | `SignUpScreen` | `SignUpViewModel` | Firebase Auth, Firestore `users` | Done |
| GV-092 | Xác nhận email | `/verify` | `VerifyEmailScreen` | `VerifyEmailViewModel` | Firebase Auth | Changed (D-L3-02) |
| GV-093 | Bắt đầu | `/start` | `StartScreen` | — | — | Done |
| GV-094 | Quên mật khẩu | `/forgot` | `ForgotPasswordScreen` | `ForgotPasswordViewModel` | Firebase Auth | Done |
| GV-001 | Tổng quan | `/overview` | `OverviewScreen` | `OverviewViewModel` | Firestore `classes`, `slots`, `attendance` (collection group), `requests` | Done v2 (`239:4209`): ô số v2, dải quên chốt .D3 và .D4, lịch tháng có chấm; .X dải Mất mạng theo `isFromCache` của lịch, hiện sau 4 giây (`LecturerOfflineViewModel`) |
| GV-002 | Điểm danh (tab 2, trước là Lịch) | `/schedule` | `ScheduleScreen` | `ScheduleViewModel` | Firestore `slots` | Done v2 (`266:4364`): chuyển tuần, dải T2 đến CN |
| GV-003 | Lớp | `/classes` | `ClassesScreen` | `ClassesViewModel` | Firestore `classes` | Done v2 (`278:5118`, `280:4844`, `302:4442`): chọn kỳ bằng nút nền xám mở danh sách, ô icon lớp xanh nhạt, .E Chưa nhập lịch |
| GV-004 | Tài khoản | `/account` | `AccountScreen` | `AccountViewModel`, `PaletteViewModel` | Firestore `users`, Firebase Auth, shared_preferences (màu) | Changed v2 (`308:5155`, `301:4751`): hồ sơ thẻ chìm, nhóm hàng trong một thẻ, nhóm Giao diện và khung Chọn màu (D-L3-12), Đăng xuất tách riêng; D-L3-04 nhóm Firebase |
| GV-100 | Nhập lớp | `/import` | `ImportScreen` | `ImportViewModel` | File Excel/CSV → Firestore `classes`, `students`, `slots` | Done v2 (`303:4571`, `298:4232`, `298:4371`, `298:4434`): khung nét đứt thấp, chọn lớp cần nhập, .X nút chính Chọn file khác và Bỏ n dòng lỗi |
| GV-101 | Chi tiết slot | `/slot/:slotId` → `/schedule` | — | — | — | Bỏ ở v2: bấm thẻ slot mở thẳng GV-102 (.D2 nếu chưa chốt, .S nếu đã chốt); slot sắp tới không bấm được |
| GV-OV6 | Slot chưa chốt | `/unclosed` | `UnclosedSlotsScreen` | `OverviewViewModel` | Firestore `slots` | Done v2 (`307:4982`) |
| GV-102 | Phiên điểm danh (+ OV1, OV2) | `/session/:slotId` | `SessionScreen` | `SessionViewModel` | Firestore `slots/{id}`, `attendance` (thời gian thực); mỗi lần đổi mã ghi một batch: slot, `qrCodes/{mã}`, xoá mã cũ, `tv/{khoá}` | Done v2 (`256:2550`): mã số 6 chữ dưới QR, nút Chiếu lên TV mở sheet link |
| TV-001 | Màn chiếu (web, không đăng nhập) | `/tv/:key` | `TvScreen` | `TvViewModel` | Firestore `tv/{key}` (chỉ get, hết hạn sau giờ slot) | Done v2 (`256:2890`, `307:4538`, `259:2954`) |
| GV-103 | Chi tiết lớp | `/class/:classId` | `ClassDetailScreen` | `ClassDetailViewModel` | Firestore `classes/{id}/students`, `slots`, `attendance`, `reports` | Changed v2 (`308:5285`, `302:4308`): ô số có icon, tab Buổi học thẻ chìm vẫn mở được buổi đã chốt để sửa; D-L3-05 nút Xuất PDF, D-L3-10 lưu trên máy |
| GV-104 | Vắng nhiều (trước là Chú ý) | `/attention` | `AttentionScreen` | `AttentionViewModel` | Firestore `attendance` (collection group) | Done v2 (`265:3903`) |
| GV-105 | Yêu cầu sửa (+ OV5) | `/requests` | `RequestsScreen` | `RequestsViewModel` | Firestore `requests` | Done v2 (`289:3337`, `289:3478`, `289:3724`): lời sinh viên trong ô xám, .E căn giữa |
| GV-201 | Hồ sơ sinh viên (+ OV3) | `/student/:classId/:code` | `StudentProfileScreen` | `StudentProfileViewModel` | Firestore `attendance`, `reminders` | Done v2 (`278:5269`, `278:5335`, `289:3922`, `289:3819`): chip Đã fail và không có nút Nhắc nhở khi đã fail, lời nhắc nói còn bao nhiêu buổi thì fail, nút Đã nhắc · ngày |
| SV-090 | Đăng nhập (web) | `/login` | `LoginScreen` (portal sinh viên) | `LoginViewModel` | Firebase Auth | Done |
| SV-091 | Đăng ký (web) | `/signup` | `SignUpScreen` (có ô MSSV) | `SignUpViewModel` | Firebase Auth, Firestore `users` | Done |
| SV-001 | Buổi vắng của tôi (.D, .D1, .D2, .D3, .W) | `/me` | `MyAttendanceScreen` | `MyAttendanceViewModel` | Firestore `attendance` (collection group theo MSSV) | Done v2 (`262:3321`, `262:3417`, `262:3517`, `294:3675`): đếm buổi vắng trên số được vắng, dải hổ phách hoặc đỏ, bỏ nút Báo sai ở danh sách |
| SV-002 | Chi tiết môn (.D, .D1, .W) | `/me/subject/:classId` | `SubjectDetailScreen` | `MyAttendanceViewModel` (dùng chung) | như trên, thêm Firestore `requests` của sinh viên | Done v2 (`295:3703`, `295:3837`): tick và x đầu hàng, buổi vắng chưa báo là thẻ nổi có Báo sai, .D1 ghi kết quả báo sai |
| SV-101 | Quét mã | `/me/scan` | `ScanScreen` | `ScanViewModel` | camera → Firestore `attendance` (rule kiểm mã) | Done v2 (`259:3190`, `256:2460`, `260:2724`, `260:2772`, `296:3931`, `296:3992`): nền camera, nút Nhập mã, dải còn vắng ở .S theo ba mức |
| SV-101 | Nhập mã | `/me/scan/code` | `CodeEntryScreen` | `ScanViewModel.submitCode` | Firestore `qrCodes/{mã}` (get) → `attendance` như khi quét | Done (`259:3108`) |
| SV-102 | Gửi báo sai | `/me/report?slot=` | `ReportScreen` | `ReportViewModel` | Firestore `requests` | Done v2 (`296:3808`, `296:3887`): thẻ chìm, nút Gửi ở thanh đáy, màn Đã gửi có dòng buổi |
| — | Tài khoản sinh viên | `/me/account` | `StudentAccountScreen` | `AccountViewModel` | Firebase Auth | Added (D-L3-06) |
| — | Khu demo Firebase | `/demo` | `FirebaseDemoScreen` | `FirebaseDemoViewModel` | FCM, xuất PDF (lưu trên máy), Remote Config, Crashlytics | Added (đề Lab 3 mục 3) |
| — | Trung tâm thông báo | `/notifications` | `NotificationsScreen` | `NotificationsViewModel` | FCM (lưu trên máy) | Added (đề Lab 3 mục 6) |

Lớp phủ: GV-OV1, GV-OV2 → `AppDialog` trong `SessionScreen`; GV-OV3 → `AppSheet` trong `StudentProfileScreen`; GV-OV5 → `AppSheet` trong `RequestsScreen`; GV-004 .C → `AppDialog` trong `AccountScreen`.

## 2. Luồng → route, test

| Luồng Lab 2 | Đường đi trong app | Nhánh lỗi, phục hồi | Test E2E |
|---|---|---|---|
| FL-0 Đăng nhập, đăng ký, nhập lớp lần đầu | `/login` → `/signup` → `/verify` → `/start` → `/import` → `/overview` | sai mật khẩu; file có dòng lỗi | TC-01, TC-02, TC-03, TC-04 |
| FL-0b Sang kỳ mới | `/overview` (.E2) → `/import` | file sai định dạng | TC-04 |
| FL-1 Điểm danh một slot | `/overview` → `/slot/:id` → `/session/:id` → OV1 → .S | mất mạng → OV2 Thử lại; Hoàn tác | TC-05, TC-06 |
| FL-2 Không quên chốt | `/overview` (.D1) hoặc thông báo → `/session/:id` | như FL-1 | TC-07 |
| FL-3 Chăm sóc sinh viên | `/overview` → `/attention` → `/student/...` → OV3 | Chú ý trống (.E) | TC-08 |
| FL-4 Sinh viên quét mã, báo sai | `/login` → `/me` → `/me/scan` → `/me/subject/:id` → `/me/report` | mã hết hạn, chặn camera | TC-09, TC-10 |
| FL-4b Giảng viên duyệt báo sai | `/overview` → `/requests` → OV5 | Hoàn tác | TC-11 |
| FL-5 Sinh viên trên laptop | build web, bề rộng ≥ 900 → bố cục .W | — | kiểm tay (checklist web) |

## 3. Component → widget

| Component Figma (trang 05) | Widget (`lib/widgets/`) | Biến thể, trạng thái |
|---|---|---|
| Button 3:42 | `AppButton` | primary, outline, ghost, destructive, onPrimary × default, pressed, disabled, loading; size 48 / 40 / 36; icon trái, mũi tên phải |
| Text field | `AppTextField` | default, focused, error, disabled, password |
| Card | `QaCard` | default, pressed, tone warning |
| Stat tile | `StatTile` | có số, “—”, bấm được |
| Status chip 3:74 | `StatusChip` | present, absent |
| Status badge 96:3177 | `StatusBadge` | closed, upcoming, unclosed, error |
| Slot card 4:165 | `SlotCard` | upcoming, live, unclosed, closed |
| Segmented control 5:242 | `AppSegmented` | mỗi mục được chọn |
| Chip 91:156 | `AppChip` | on, off |
| Empty state 5:274 | `EmptyState` | có / không có nút |
| Error state | `ErrorState` | có nút Thử lại |
| Skeleton | `SkeletonList` | — |
| Dialog 5:259 | `AppDialog` | confirmation, error |
| Sheet | `AppSheet` | tay nắm 32×4 |
| Snackbar 5:260 | `AppToast` | có / không Hoàn tác |
| Date header 91:189 | `DateHeader` | — |
| App bar 5:95 | `QaAppBar` | top, nested |
| Bottom navigation 5:220 | `QaBottomNav` | 4 tab |
| Student row | `StudentRow` | có công tắc, chỉ xem |
| Attention row | `AttentionRow` | near, over |
| Số dạng “5/4” | `RatioText` | màu theo mức |
| Avatar | `InitialsAvatar` | — |

## 4. Khác biệt so với thiết kế (deviation)

| ID | Ở đâu | Thay đổi | Lý do | Cập nhật Figma |
|---|---|---|---|---|
| D-L3-01 | Toàn app | Một codebase Flutter cho cả hai phía; phía sinh viên chạy bằng Flutter Web (và Android khi build `PORTAL=student`) thay vì web riêng | Đề Lab 3 yêu cầu dựng mọi màn Final UI bằng Flutter; dùng chung theme và widget giữ đúng design system | Khung ghi chú `206:4505` trên trang 03 |
| D-L3-02 | GV-092 | Thay 6 ô mã số bằng hướng dẫn mở link xác nhận + nút “Xác nhận” kiểm lại trạng thái | Firebase Auth gửi link xác nhận email, không có mã 6 số khi không dùng Cloud Functions (ràng buộc nền tảng, gói Spark) | Đã thêm `GV-092 · Xác nhận email .D (Lab 3)` (206:4165) |
| D-L3-03 | Icon | Dùng Material Symbols (bản nét `outlined` và bản đặc) thay cho Lucide + bộ “Icon đặc” tự vẽ | Giữ đúng luật đặc / nét mà không phải tự vẽ lại 30 icon; Material có sẵn cả hai dạng cho cùng một hình | Khung ghi chú `206:4505` (trang 03) |
| D-L3-04 | GV-004 | Thêm nhóm “Firebase”: Thông báo, Xuất báo cáo, Remote Config, Crashlytics | Đề Lab 3 mục 3 bắt buộc khu demo Firebase trên màn Tài khoản | Đã thêm `GV-004 · Tài khoản .D (Lab 3)` (206:4064) |
| D-L3-05 | GV-103 | Thêm nút icon “Xuất PDF” ở app bar | Đề Lab 3: sinh ít nhất 1 file phản ánh nội dung người dùng đang xem và tải lên cloud | Đã thêm `GV-103 · Chi tiết lớp .D (Lab 3)` (206:4207) |
| D-L3-06 | Web sinh viên | Thêm màn Tài khoản (mở khi chạm dòng avatar ở SV-001): tên, MSSV, khu demo, Đăng xuất | Đề Lab 3: phải có đăng xuất và màn hồ sơ; thiết kế sinh viên chưa có | Đã thêm `SV-003 · Tài khoản .D (Lab 3)` (206:4365) |
| D-L3-07 | GV-001 .D | Nút “Xem tất cả” và hàng Chú ý dùng ngưỡng vắng lấy từ Remote Config (mặc định 20%) | Đề Lab 3: Remote Config phải đổi hành vi thấy được | Ghi trong khung ghi chú `206:4505` |
| D-L3-08 | GV-102 .D1 | Chu kỳ đổi mã QR lấy từ Remote Config (mặc định 12 giây, chip “Đổi mã 12s” theo giá trị) | như trên | Ghi trong khung ghi chú `206:4505` |
| D-L3-09 | Nhập lớp | Định dạng file cố định (cột `mon, lop, mssv, ho_ten, email, lich, bat_dau`), có file mẫu trong `sample-data/` | Thiết kế chưa chốt cột; cần định dạng để kiểm lỗi dòng như GV-100 .X | Khung ghi chú `206:4505` trên trang 03 |
| D-L3-10 | GV-103, khu demo | Xuất PDF lưu file trên máy rồi mở hộp chia sẻ của hệ thống; Firestore `reports` chỉ giữ metadata (tên file, lớp, KB, thời điểm). Không tải lên Cloud Storage, không có link chép | Project ở gói Spark, Firebase yêu cầu gói Blaze để tạo bucket Storage; đề mục 3 cho xin dùng cách tương đương khi dịch vụ không có sẵn (cần thầy đồng ý) | Chưa cập nhật: khung ghi chú `308:5554` trên trang v2, cần quyền ghi |
| D-L3-11 | Nút 40 và 36 | Hình nút giữ như Figma, nhưng ô bố cục của nút cao 48 (vùng bấm vô hình), nên khoảng cách quanh nút trong thẻ và hộp thoại rộng hơn Figma 4 đến 6 | Đề Lab 3 yêu cầu vùng chạm ít nhất 48; Flutter chỉ nhận chạm trong ô bố cục của widget | Chưa cập nhật: khung ghi chú `308:5554`, cần quyền ghi |
| D-L3-12 | Toàn app | Bảng màu đổi được: Biển sâu (mặc định) và Cam FPT. Khung Chọn màu chỉ hiện hai màu này, sáu màu còn lại của Figma chưa làm | Ô màu bấm mà không đổi gì là lỗi; làm thêm khi còn giờ (kế hoạch v2, câu 7) | Chưa cập nhật: khung ghi chú `308:5554`, cần quyền ghi |
| D-L3-13 | GV-102, SV-101 Nhập mã | Mã số 6 chữ nằm ở `qrCodes/{mã}`, app giảng viên ghi mỗi lần đổi mã. Sinh viên chỉ đọc được đúng một mã còn hạn của lớp có tên mình, không liệt kê được. Rủi ro còn lại: bạn cùng lớp thử nhiều mã | Không có Cloud Functions ở gói Spark để đổi mã số sang token phía máy chủ (kế hoạch v2, câu 5) | Chưa cập nhật: khung ghi chú `308:5554`, cần quyền ghi |
| D-L3-14 | TV-001 | Màn chiếu mở bằng link có khoá 10 ký tự (`/tv/<khoá>`), không đăng nhập; nút Chiếu lên TV mở sheet hiện link và nút Chép link. Link dùng tới hết giờ slot cộng 15 phút | Máy chiếu phòng học không đăng nhập tài khoản giảng viên; Figma chưa có khung sheet này | Chưa cập nhật: cần thêm sheet Chiếu lên TV, cần quyền ghi |
| D-L3-15 | TV-001 .E | Chỉ ghi "Chưa mở điểm danh" và "Link chưa đúng hoặc đã hết hạn", không có "Slot kế tiếp" và tên lớp | Máy chiếu không đăng nhập nên không đọc được lịch | Chưa cập nhật: khung ghi chú `308:5554`, cần quyền ghi |
| D-L3-16 | TV-001 .D | Số đã quét trên TV cập nhật mỗi lần đổi mã nên trễ tối đa 1 chu kỳ (12 giây); đếm ngược Đổi mã và Còn chạy trên máy chiếu | Giữ khoảng 5 lần ghi mỗi phút mở mã, thấp hơn nhiều hạn gói Spark | Chưa cập nhật: khung ghi chú `308:5554`, cần quyền ghi |
| D-L3-17 | SV-101 .D, Nhập mã | Bỏ dòng "PRM393 · SE1801 · Slot 1" trên màn quét và màn nhập mã; môn và slot chỉ hiện ở .S sau khi ghi nhận | Sinh viên không đọc được slot (luật CR-01), nên trước khi quét chưa biết lớp nào | Chưa cập nhật: khung ghi chú `308:5554`, cần quyền ghi |

D-L3-01 đến D-L3-09 đã cập nhật vào Figma ngày 30/10/2026 (cột cuối: id khung trên trang 03 Final UI). Từ D-L3-10, cột cuối ghi rõ đã hay chưa cập nhật. Khác biệt chưa có trong bảng là lỗi.
