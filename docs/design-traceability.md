# Design traceability · Lab 2 → Flutter

> Nguồn thiết kế: Figma [PRM323 Lab 2 v2 · SE190533](https://www.figma.com/design/1qIZVpL0Q7bD9UzT5TVBRy) (trang `03 Final UI · v2` `239:4208`, 05 Components, `06 Prototype · v2`); phần v2 thay bản v3.1 ghi ở `design/final-ui-v2.md` của repo Lab 2 và repo Lab 2 [thiengthb/prm323-lab2-SE190533](https://github.com/thiengthb/prm323-lab2-SE190533) (`design/DESIGN.md` v3.1, `design/screen-spec.md` v2.0, `handoff/flutter-handoff.md` v2.0, `ux/user-flow.md` v1.0).
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
| GV-102 | Phiên điểm danh (+ .X, sheet Chiếu lên TV) | `/session/:slotId` | `SessionScreen` | `SessionViewModel` | Firestore `slots/{id}`, `attendance` (thời gian thực); mỗi lần đổi mã ghi một batch: slot, `qrCodes/{mã}`, xoá mã cũ, `tv/{khoá}` | Done v2 (`256:2550`): mã số 6 chữ dưới QR, nút Chiếu lên TV mở sheet link |
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

Lớp phủ: GV-OV1 bỏ ở v2 (chốt một lần, không hỏi lại); GV-OV2 thay bằng dải vàng .X trong `SessionScreen`; sheet Chiếu lên TV (`339:5337`) → `AppSheet` trong `SessionScreen`; GV-OV3 → `AppSheet` trong `StudentProfileScreen`; GV-OV5 → `AppSheet` trong `RequestsScreen`; GV-OV6 → màn `/unclosed`; Chọn màu (`301:4751`) → `AppSheet` trong `AccountScreen`; GV-004 .C → `AppDialog` trong `AccountScreen`.

## 2. Luồng → route, test

| Luồng Lab 2 | Đường đi trong app | Nhánh lỗi, phục hồi | Test E2E |
|---|---|---|---|
| FL-0 Đăng nhập, đăng ký, nhập lớp lần đầu | `/login` → `/signup` → `/verify` → `/start` → `/import` → `/overview` | sai mật khẩu; file có dòng lỗi | TC-01, TC-02, TC-03, TC-04 |
| FL-0b Sang kỳ mới | `/overview` (.E2) → `/import` | file sai định dạng | TC-04 |
| FL-1 Điểm danh một slot | `/overview` → `/session/:id` (.D1 → Đóng mã → .D2 → Chốt) → .S; Chiếu lên TV → `/tv/:key` trên web | mất mạng → dải vàng .X, Thử lại; Hoàn tác | TC-05, TC-06 |
| FL-2 Không quên chốt | `/overview` (dải quên chốt .D3, .D4 → `/unclosed`), tab Điểm danh `/schedule` hoặc thông báo → `/session/:id` | như FL-1 | TC-07 |
| FL-3 Chăm sóc sinh viên | `/overview` → `/attention` → `/student/...` → OV3 | Vắng nhiều trống (.E) | TC-08 |
| FL-4 Sinh viên quét mã, báo sai | `/login` → `/me` → `/me/scan` (hoặc `/me/scan/code` Nhập mã) → `/me/subject/:id` → `/me/report` | mã hết hạn, mã gõ sai, chặn camera | TC-09, TC-10, TC-17 |
| FL-4b Giảng viên duyệt báo sai | `/overview` → `/requests` → OV5 | Hoàn tác | TC-11 |
| FL-5 Sinh viên trên laptop | build web, bề rộng ≥ 900 → bố cục .W | — | kiểm tay (checklist web) |
| Liên vai trò 1 Duyệt lớp (Final) | `/import` → web `/review` → `/overview`, `/inbox` | từ chối có lý do → Nhập lại | TC-17, TC-18, TC-19 |
| Thông báo (Final) | web `/announcements` → `/inbox` | hộp thư trống, lỗi mạng | TC-20 |
| AI gợi ý nhắc (Final) | GV-201 → GV-OV3 | tắt cờ, quota, mất mạng → câu mẫu | TC-21, TC-22 |

## 3. Component → widget

| Component Figma (trang 05, khu 17 của trang v2) | Widget (`packages/core/lib/widgets/`) | Biến thể, trạng thái |
|---|---|---|
| Button 3:42 | `AppButton` | primary, outline, ghost, destructive, onPrimary × default, pressed, disabled, loading; size 48 / 40 / 36; icon trái, mũi tên phải |
| Text field | `AppTextField` | default, focused, error, disabled, password |
| Card (v2: nổi, chìm) | `QaCard` | nổi (bấm được: viền 2 + gờ đáy 2), chìm (chỉ xem: nền muted-surface, không viền), pressed, tone warning |
| Stat card v2 `248:2306` | `StatTile` | Thông tin (chìm), Bấm được (nền primary-soft, mũi tên), có số, “—” |
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
| Date header v2 `243:4251` | `DateHeader` | có slot, không slot |
| App bar 5:95 | `QaAppBar` | top, nested |
| Bottom navigation v2 `266:4185` | `QaBottomNav` | 4 tab: Tổng quan, Điểm danh (QR), Lớp, Tài khoản (bánh răng); cao 72, chỉ icon, nhãn cho trình đọc màn hình |
| Hàng chưa quét v2 `265:3540`, Hàng có mặt v2 `265:3564` | `StudentRow` | có công tắc, chỉ xem |
| Công tắc (Student row `4:72`) | `AppSwitch` | bật, tắt, khoá; rãnh 44×26 bo 8, núm 20 bo 6, vùng bấm 48 |
| Ô ngày v2 `266:4363` | `MonthCalendar` | có chấm slot, hôm nay, ngày khác tháng |
| Icon/rotate `259:2938`, Icon/copy `339:5336` | `RotateCodeIcon`; `Icons.copy_rounded` | — |
| App icon v2 · Hereby `262:2800` | `BrandMark` | — |
| Attention row v2 `250:2345` | `AttentionRow` | near, over (over là đã fail) |
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
| D-L3-10 | GV-103, khu demo | Xuất PDF lưu file trên máy rồi mở hộp chia sẻ của hệ thống; Firestore `reports` chỉ giữ metadata (tên file, lớp, KB, thời điểm). Không tải lên Cloud Storage, không có link chép | Project ở gói Spark, Firebase yêu cầu gói Blaze để tạo bucket Storage; đề mục 3 cho xin dùng cách tương đương khi dịch vụ không có sẵn (cần thầy đồng ý) | Đã thêm vào khung ghi chú `308:5554` (03/11/2026) |
| D-L3-11 | Nút 40 và 36 | Hình nút giữ như Figma, nhưng ô bố cục của nút cao 48 (vùng bấm vô hình), nên khoảng cách quanh nút trong thẻ và hộp thoại rộng hơn Figma 4 đến 6 | Đề Lab 3 yêu cầu vùng chạm ít nhất 48; Flutter chỉ nhận chạm trong ô bố cục của widget | Đã thêm vào khung ghi chú `308:5554` (03/11/2026) |
| D-L3-12 | Toàn app | Bảng màu đổi được, đủ 8 mẫu của khung Chọn màu: Biển sâu (mặc định), Cam FPT, Hải quân, Đại dương, Mòng két, Chàm, Mận, Than. Hải quân và Đại dương lấy đủ giá trị từ mode B, C của bộ biến Color trên Figma. Bốn mẫu Mòng két, Chàm, Mận, Than Figma chỉ cho màu chính; các sắc pressed, soft, on-soft, soft-edge suy theo tỉ lệ HSL của Biển sâu, tương phản chữ đều ≥ 6,6 | Bộ biến Figma chỉ có mode cho Cam FPT, Biển sâu, Hải quân, Đại dương; cách suy bốn mẫu còn lại ghi trong `lib/theme/tokens.dart` | Đã thêm vào khung ghi chú `308:5554` (03/11/2026) |
| D-L3-13 | GV-102, SV-101 Nhập mã | Mã số 6 chữ nằm ở `qrCodes/{mã}`, app giảng viên ghi mỗi lần đổi mã. Sinh viên chỉ đọc được đúng một mã còn hạn của lớp có tên mình, không liệt kê được. Rủi ro còn lại: bạn cùng lớp thử nhiều mã | Không có Cloud Functions ở gói Spark để đổi mã số sang token phía máy chủ (kế hoạch v2, câu 5) | Đã thêm vào khung ghi chú `308:5554` (03/11/2026) |
| D-L3-14 | TV-001 | Màn chiếu mở bằng link có khoá 10 ký tự (`/tv/<khoá>`), không đăng nhập; nút Chiếu lên TV mở sheet hiện link và nút Chép link. Link dùng tới hết giờ slot cộng 15 phút | Máy chiếu phòng học không đăng nhập tài khoản giảng viên; thiết kế v2 chưa có khung sheet này | Đã thêm `GV-102 · Sheet Chiếu lên TV · v2` (`339:5337`) cùng icon `Icon/copy` (`339:5336`, khu 17), ghi trong `308:5554` (03/11/2026) |
| D-L3-15 | TV-001 .E | Chỉ ghi "Chưa mở điểm danh" và "Link chưa đúng hoặc đã hết hạn", không có "Slot kế tiếp" và tên lớp | Máy chiếu không đăng nhập nên không đọc được lịch | Đã thêm vào khung ghi chú `308:5554` (03/11/2026) |
| D-L3-16 | TV-001 .D | Số đã quét trên TV cập nhật mỗi lần đổi mã nên trễ tối đa 1 chu kỳ (12 giây); đếm ngược Đổi mã và Còn chạy trên máy chiếu | Giữ khoảng 5 lần ghi mỗi phút mở mã, thấp hơn nhiều hạn gói Spark | Đã thêm vào khung ghi chú `308:5554` (03/11/2026) |
| D-L3-17 | SV-101 .D, Nhập mã | Bỏ dòng "PRM393 · SE1801 · Slot 1" trên màn quét và màn nhập mã; môn và slot chỉ hiện ở .S sau khi ghi nhận | Sinh viên không đọc được slot (luật CR-01), nên trước khi quét chưa biết lớp nào | Đã thêm vào khung ghi chú `308:5554` (03/11/2026) |
| D-L3-18 | GV-103, khu demo | Bổ sung cho D-L3-10: PDF được tải lên **Cloudinary** vào `hereby/reports/<uid>/` (thanh tiến độ, hiện link, nút chép link), rồi mới lưu trên máy; Firestore `reports` ghi thêm `destination: cloudinary` và `url`. Khu demo đổi tên mục thành "Xuất báo cáo · Cloudinary" | Thầy cho dùng Cloudinary hoặc AWS S3 thay Cloud Storage (04/11/2026). Chọn Cloudinary: gói free không cần thẻ, upload thẳng từ app bằng upload preset loại Unsigned nên không cần server và app không giữ API secret. Đánh đổi: Cloudinary không có Rules theo uid như Storage; preset chỉ nhận PDF, giới hạn dung lượng, và Firestore Rules chỉ nhận link nằm đúng thư mục của người ghi | **Chưa** cập nhật Figma |

D-L3-01 đến D-L3-09 đã cập nhật vào Figma ngày 30/10/2026 (cột cuối: id khung trên trang 03 Final UI). D-L3-10 đến D-L3-17 cập nhật ngày 03/11/2026. Từ D-L3-10, cột cuối ghi rõ đã hay chưa cập nhật. Khác biệt chưa có trong bảng là lỗi.

## 5. Final: màn và khác biệt mới

Màn Lab 2 dùng giao diện v2 (Biển sâu) của Lab 3. Các phần dưới đây là phần đề Final bắt buộc thêm, dựng bằng token và component Lab 2. Với màn mới, bố cục theo các luật trong repo `thiengthb/frontend`: mỗi màn trả lời một câu hỏi (UX-002), nghĩa control đúng hình dạng (CMP-001), trạng thái lỗi nói nguyên nhân và có Thử lại.

| Màn | Route | Screen | ViewModel | Nguồn dữ liệu | Trạng thái |
|---|---|---|---|---|---|
| Hộp thư (app, cổng sinh viên) | `/inbox` | `InboxScreen` | `InboxViewModel` | `announcements`, `users/{uid}/inbox` | Added |
| Web: Đăng nhập | `/login`, `/denied` | `AdminLoginScreen`, `AdminDeniedScreen` | `AdminAuthViewModel` | Firebase Auth, `users` | Added |
| Web: Tổng quan | `/dashboard` | `DashboardScreen` | `DashboardViewModel` | Aggregation `classes`, `slots` | Added |
| Web: Duyệt lớp | `/review` | `ReviewScreen` | `ReviewViewModel` | `classes`, `students`, `subjects` | Added |
| Web: Môn học | `/subjects` | `SubjectsScreen` | `SubjectsViewModel` | `subjects` | Added |
| Web: Thông báo | `/announcements` | `AnnouncementsScreen` | `AnnouncementsViewModel` | `announcements` | Added |
| Web: Người dùng (Admin) | `/users` | `UsersScreen` | `UsersViewModel` | `users` | Added |

| ID | Ở đâu | Thay đổi | Lý do | Cập nhật Figma |
|---|---|---|---|---|
| D-F-01 | GV-100 .S | “Đã nhập N lớp” đổi thành “Đã gửi N lớp · Chờ giáo vụ duyệt” | Đề Final: luồng liên vai trò. Giảng viên tự đăng ký được nên cần bước xác nhận lớp | Chưa |
| D-F-02 | GV-001, GV-003 | Thêm `ClassReviewCard` (chờ duyệt, bị từ chối kèm lý do, nút Nhập lại); lớp chưa duyệt không vào lịch | Như trên; app phải đổi theo thời gian thực | Chưa |
| D-F-03 | GV-001 | Thêm nút thư có chấm đỏ trên app bar (`InboxButton`) | Đề Final: hộp thư thông báo | Chưa |
| D-F-04 | GV-004, SV-003 | Thêm nhóm “Giáo vụ” có mục “Hộp thư” | Cổng sinh viên không có Tổng quan nên cần lối vào | Chưa |
| D-F-05 | GV-OV3 | Thêm nút “Gợi ý AI” và dòng nhãn AI; ô soạn cao hơn | Đề Final mục 8 | Chưa |
| D-F-06 | GV-100 .X | Dòng lỗi mới “Môn X chưa có trong danh mục” | App đọc danh mục do giáo vụ quản lý | Chưa |
| D-F-07 | Khu demo, GV-103 | Nút “Xuất PDF”: tải lên Cloudinary (cờ `report_cloud_upload`, mặc định bật), lưu và mở hộp chia sẻ; không dùng Cloud Storage (D-L3-18) | Đề Final mục 4 đưa Cloud Storage ra ngoài phạm vi | Chưa |
| D-F-08 | Web admin | Toàn bộ 6 màn chưa có khung Figma | Lab 2 chỉ có giảng viên và sinh viên | Chưa |
| D-F-09 | App giảng viên trên Windows | Màn rộng ≥ 840 px: 4 tab thành thanh dọc bên trái (`QaSideNav`) có logo và chữ; nội dung giữ cột 600. Bản Windows bỏ nút Google, Gợi ý AI, nhắc slot | Desktop cho giảng viên (như Lab 1). FlutterFire Windows không có Crashlytics, FCM, Analytics, Google Sign-In | Chưa |
| D-F-10 | Web admin: trang **Sự cố** (chỉ Admin) | Ba ô đếm theo loại (Test crash, Lỗi non-fatal, Lỗi giao diện), chạm để lọc; danh sách 100 sự cố mới nhất: loại, nơi xảy ra, giờ, vai trò, nền tảng, câu lỗi; nút chép link Crashlytics console | Thầy dặn admin xem kết quả Crashlytics trên web, nhưng Crashlytics không có API cho web client: app ghi kèm bản tóm tắt vào `crashReports`, stack đầy đủ vẫn ở console | Chưa |
| D-U-01 | Mọi màn (app, web SV, web admin, Windows) | Font Nunito đóng gói trong `packages/core/fonts` (4 độ đậm), bỏ `google_fonts` tải lúc chạy; PDF báo cáo cũng dùng bản đóng gói | Windows và máy mất mạng từng rơi về font hệ thống; một font cho mọi bề mặt, kể cả extension | Không cần (Figma đã dùng Nunito) |
| D-U-02 | Windows, web admin | Một thanh bên chung `AppSideNav` rộng 240, thu về 72 (chỉ icon) khi cửa sổ < 900; ngưỡng màn rộng của app đổi từ 840 thành 900 cho khớp web | Trước đây hai thanh bên khác bề rộng (220 và 240) và khác ngưỡng | Chưa |
| D-U-03 | Màn rộng ≥ 900 | Chữ lớn hơn một bậc (×1,07: 15 → 16), lề màn 24; màn chiếu TV không đổi | Ngồi xa màn laptop thì cỡ chữ điện thoại nhỏ | Chưa |
| D-U-05 | GV-001, GV-002, GV-003 trên màn rộng | Tổng quan: bốn ô số một hàng, việc hôm nay bên trái và lịch tháng bên phải (`TwoColumns`); Điểm danh: thanh tuần giữ rộng 640, slot xếp lưới (`CardGrid`); Lớp: thẻ lớp xếp lưới. Điện thoại không đổi | Bản Windows từng là cột điện thoại giữa màn trống | Chưa |
| D-U-06 | SV-001, SV-002 trên màn rộng | Trang chủ sinh viên giữ một cột 640 giữa màn (trước đây kéo hết bề ngang); Chi tiết môn: khối đếm bên trái, danh sách buổi bên phải | Sinh viên chỉ có vài môn, hàng kéo dài 1200 khó đọc | Chưa |
| D-U-07 | Web admin: Tổng quan, Sự cố | Ô số Tổng quan có icon như app giảng viên; nhãn ngắn hơn ("có mặt · 68 buổi", "Có mặt theo môn"); trang Sự cố bỏ hai dòng link console, link nằm ở nút chép trên đầu trang | Bớt chữ, cùng kiểu ô số với app | Chưa |
| D-U-08 | Toàn hệ thống (core tokens, theme, widgets) | Thiết kế lại theo Slate Teal của thienui: bảng màu Teal mặc định (primary #04756B, nút #308E84 chữ mực), nền xám lạnh #F5F7FA, thẻ trắng viền 1 + bóng nhẹ thay gờ đáy, bo 8 (nút, ô nhập) / 12 (thẻ, hộp thoại), font Be Vietnam Pro thay Nunito, thanh tab đáy có nhãn, app bar bỏ icon | thien 05/11: giao diện cũ "phèn", lấy màu teal của thienui; bỏ Figma, luật Lab 2 không còn ràng buộc Lab 3/Final | Không (bỏ Figma) |
| D-U-09 | Đăng nhập, đăng ký, quên mật khẩu (app GV, web SV, web admin) | AuthShell: điện thoại có tiêu đề lớn + dòng phụ; màn rộng chia đôi, trái dải teal có logo, câu giới thiệu và 3 điểm chính, phải là form | Màn đăng nhập cũ trống, không có điểm nhấn | Không |
| D-U-10 | Web sinh viên trang chủ | Lời chào "Chào <tên>" + kỳ học; thẻ môn có icon, thanh đếm buổi vắng và dòng "Còn được vắng N buổi" | Trang chủ cũ thưa, chỉ một dòng số | Không |
| D-U-11 | GV-001 Tổng quan, GV-103 Chi tiết lớp, danh sách sinh viên/buổi | Vượt khuôn Lab 2 (thien 05/11): thẻ chào teal chứa slot kế tiếp và nút hành động thay hàng ngày + thẻ slot rời; 4 số gộp một thẻ có đường kẻ; đầu trang lớp có thanh tiến độ buổi đã học; danh sách hàng (CardList) gộp một thẻ thay vì từng thẻ rời | Màn chính rõ việc cần làm trước, bớt khối lặp | Không |
| D-U-12 | TV-001 Màn chiếu, icon app | Dải phải chuyển teal có logo, thanh tiến độ số đã quét, đồng hồ dạng viên thuốc; dòng 'Quét mã để điểm danh' trên QR. Icon app (Android, Windows, web) và SVG đổi sang teal, bỏ gờ dưới | Cùng màu với giao diện mới | Không |
| D-U-13 | Toàn hệ thống (core) | Theo đúng component thienui/shadcn (thien 05/11: bản trước "không ổn"): token Slate Teal chính xác (nền #FAFBFD, --border #DBE0E8, --muted #ECEFF5, chữ một màu mực #131519), bo 6/10, chữ giao diện 14, tiêu đề đậm 600; nút cao 44/36/32 chữ 500, destructive nền đỏ nhạt, tắt mờ 50%; thẻ viền 1 không bóng; ô số kiểu shadcn (nhãn trên, số dưới); avatar xám; tabs/thanh bên/tab đáy chọn nền --accent trung tính; toast trắng kiểu sonner; app bar kẻ dưới; bỏ gradient ở thẻ chào, đăng nhập, TV | Giống hệ thiết kế thienui mà thien chọn | Không |
| D-U-14 | Toàn hệ thống (core, icon) | Bảng màu "Xanh xô thơm" (thien chọn 06/11 từ trang so sánh 3 bảng): primary #386F5F chữ trắng trên nút, nền/viền/mực xám ấm như giấy (#FBFAF8, #F1F0EC, #E1E0DA, #1C1B16); thành công #397949, cảnh báo hổ phách #8D5E00, lỗi #AB413E, cùng độ sáng. Bảng giữ id `teal` để lựa chọn đã lưu vẫn về mặc định, tên hiện "Xô thơm". Logo mới (thien chọn): chấm tròn giữa khung ngắm bốn góc, nền phẳng, cho BrandMark, icon Android/Windows/web, favicon | Dịu mắt, ít tính công nghệ, hài hoà; logo nhỏ vẫn rõ | Không |
| D-U-15 | Toàn hệ thống (core, mobile, web) | Bộ icon đổi từ Material sang Lucide (gói lucide_icons_flutter, export qua quick_attend_core/theme/app_icons.dart), 86 icon | thien 06/11: dùng icon Lucide, cùng bộ với shadcn/thienui | Không |
| D-T-01 | Toàn hệ thống | Bố cục chọn theo thiết bị trước, độ rộng sau (`FormFactor`, `packages/core/lib/widgets/form_factor.dart`): app Windows luôn desktop (kể cả cửa sổ hẹp), app Android luôn điện thoại, web admin luôn desktop, web sinh viên theo độ rộng ≥ 900. Một ViewModel, hai View: màn có bản desktop riêng nằm ở `screens/lecturer/desktop/`, chọn ở đầu `build()` | thien 09/11: "mobile cho ra mobile, desktop cho ra desktop"; bản cũ chọn theo độ rộng nên desktop là giao diện điện thoại kéo rộng | Không (bỏ Figma) |
| D-T-02 | App giảng viên trên Windows và trình duyệt laptop | Thanh bên 6 mục (Tổng quan, Điểm danh, Lớp, Yêu cầu sửa, Hộp thư, Tài khoản) luôn hiện, kể cả ở màn con; màn con không trượt. Tổng quan hướng A: slot đang diễn ra ở trên, Việc cần xử lý và 7 ngày tới ở dưới, Ctrl+D mở điểm danh. Phiên hướng A: QR bên trái, bảng cả lớp bên phải (tab, tìm, sắp xếp), Space đóng mã, Ctrl+Enter chốt, / tìm, Esc quay lại. Lớp: danh sách bên trái, chi tiết lớp bên phải dạng bảng. Điểm danh: lưới tuần slot × thứ. Yêu cầu sửa, Vắng nhiều: bảng | thien chọn hướng A cho Tổng quan và Phiên (09/11, 3 hướng dựng đúng cỡ 1366×768) | Không |
| D-T-03 | Web admin | Mọi danh sách thành bảng có tìm, sắp xếp, hover; Duyệt lớp hướng A: bảng + khung chi tiết bên phải (danh sách sinh viên, Duyệt / Từ chối); Tổng quan mở đầu bằng hàng đợi chờ duyệt rồi mới tới số liệu và biểu đồ; Sự cố có khung chi tiết | thien chọn hướng A (09/11); luật thienui "không mở màn bằng lưới ô số ngang hàng" | Không |
| D-T-04 | Web sinh viên trên laptop | Môn học bên trái, bảng buổi học của môn đang chọn bên phải (Báo sai ngay trên hàng vắng), nút "Nhập mã điểm danh" (laptop không quét được QR trên TV) | Thay cột 640 ở giữa màn (D-U-06) | Không |
| D-T-05 | Nút trên desktop | Bỏ vùng chạm vô hình 48 px của nút 30/36 trên desktop (chuột chính xác hơn ngón tay), giữ trên điện thoại; sheet trượt từ đáy thành hộp thoại giữa màn trên desktop; thanh nút đáy gọn bên phải | Hàng bảng trên desktop cao 44, vùng chạm 48 làm hàng phình và lệch | Không |
| D-T-06 | Hosting | Tách thành 4 trang: web sinh viên `<project>.web.app`, web admin `<project>-admin.web.app`, màn chiếu TV `<project>-tv.web.app/tv/<khoá>`, FAP giả `<project>-fap.web.app/fap/` | Quyết định 002 (thien 09/11); sửa luôn LOI-09 (web sinh viên và web admin chung phiên đăng nhập) | Không |
| D-T-07 | Tên và project | Một tên Attendo (bỏ Hereby, Quick Attend), Firebase project mới `attendo-app-2611`, mã app Android `app.attendo`, file chạy Windows `attendo.exe`, gói Dart `attendo_core` | Quyết định 001 (thien 09/11): không mã số sinh viên trong sản phẩm | Không |
| D-T-08 | GV-102 Phiên, hai máy giảng viên | Máy mở mã trước giữ quyền đổi mã; máy sau chỉ hiện cùng QR (không có mã số) kèm dòng giải thích, tự nhận quyền khi máy kia rời màn phiên (máy kia ghi `qrLeaseUntil` = bây giờ) hoặc khi mã đó hết hạn; máy theo kiểm lại mỗi 3 giây (LOI-05) | Hai máy cùng đổi mã làm mã sinh viên vừa thấy bị thay | Không |
| D-T-09 | Toàn hệ thống (app, web, extension, icon, slide) | Bảng màu mặc định đổi từ Xanh ngọc sang **Bản vẽ** (xanh cobalt của slide MLN122): primary #1D4ED8, nút đặc #1D4ED8 chữ trắng, viền nút #1A3FAE, nền nhạt #E6EDFD; bản tối primary #8FB0FF, nút #6F93F3 chữ mực. Thêm bảng Tím (#6D28D9). Khung Chọn màu: Bản vẽ, Tím, Xanh ngọc rồi các bảng cũ. Khoá lưu lựa chọn lên `palette_id_v3` để mọi máy về Bản vẽ một lần. Mặc định đọc từ một hằng `AppPalette.fallback` (app, web, `gen_css.mjs` → extension) | thien chọn 09/11 sau khi so 3 bảng trên các màn tiêu biểu: nhiều nhóm trong lớp cũng dùng xanh rêu/ngọc, dễ trùng | Không |
| D-T-10 | Logo chữ "attendo" (app, web, extension, slide) | Chấm giữa chữ o màu cam FPT #F26F21 (`AppColors.brandDot`), vòng ngoài giữ màu primary (Bản vẽ). Biểu tượng app (ô xanh, vòng trắng: Android, Windows, web, favicon, extension, `BrandMark`) cũng chấm cam | thien 09/11: chấm cam nổi bật trên vòng xanh, áp cả icon app | Không |
| D-T-11 | GV-001 Tổng quan, ô thứ ba | Nhãn luôn là "có mặt tuần này"; tuần chưa có buổi đã chốt thì số là "—" (trước đây nhãn đổi thành "chưa chốt buổi nào") | thien 10/11 chọn cách A: nhãn cũ đứng cạnh dải "N slot chưa chốt" đọc thành mâu thuẫn | Không |
| D-U-04 | Extension | Token màu, bo góc, bố cục lấy từ `design/tokens/hereby.css` (biến `--hb-*`), sinh bằng `tool/tokens/gen_css.mjs` từ `tokens.dart`; test `mobile/test/tokens_css_test.dart` báo lệch | Extension từng dùng bảng màu cam của dự án khác | Không cần |

“Chưa” là còn nợ: đề Lab 3 coi khác biệt chưa ghi vào Figma là lỗi. Bổ sung khi đã chốt bản frontend mới, để không phải vẽ hai lần.
