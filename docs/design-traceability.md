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
| GV-001 | Tổng quan | `/overview` | `OverviewScreen` | `OverviewViewModel` | Firestore `classes`, `slots`, `attendance` (collection group), `requests` | Done |
| GV-002 | Lịch | `/schedule` | `ScheduleScreen` | `ScheduleViewModel` | Firestore `slots` | Done |
| GV-003 | Lớp | `/classes` | `ClassesScreen` | `ClassesViewModel` | Firestore `classes` | Done |
| GV-004 | Tài khoản | `/account` | `AccountScreen` | `AccountViewModel` | Firestore `users`, Firebase Auth | Changed (D-L3-04: nhóm Firebase) |
| GV-100 | Nhập lớp | `/import` | `ImportScreen` | `ImportViewModel` | File Excel/CSV → Firestore `classes`, `students`, `slots` | Done |
| GV-101 | Chi tiết slot | `/slot/:slotId` | `SlotDetailScreen` | `SlotDetailViewModel` | Firestore `slots/{id}`, `attendance` | Done |
| GV-102 | Phiên điểm danh (+ OV1, OV2) | `/session/:slotId` | `SessionScreen` | `SessionViewModel` | Firestore `slots/{id}`, `attendance` (thời gian thực) | Done |
| GV-103 | Chi tiết lớp | `/class/:classId` | `ClassDetailScreen` | `ClassDetailViewModel` | Firestore `classes/{id}/students`, `slots`, `attendance` | Changed (D-L3-05: nút Xuất PDF) |
| GV-104 | Chú ý | `/attention` | `AttentionScreen` | `AttentionViewModel` | Firestore `attendance` (collection group) | Done |
| GV-105 | Yêu cầu sửa (+ OV5) | `/requests` | `RequestsScreen` | `RequestsViewModel` | Firestore `requests` | Done |
| GV-201 | Hồ sơ sinh viên (+ OV3) | `/student/:classId/:code` | `StudentProfileScreen` | `StudentProfileViewModel` | Firestore `attendance`, `reminders` | Done |
| SV-090 | Đăng nhập (web) | `/login` | `LoginScreen` (portal sinh viên) | `LoginViewModel` | Firebase Auth | Done |
| SV-091 | Đăng ký (web) | `/signup` | `SignUpScreen` (có ô MSSV) | `SignUpViewModel` | Firebase Auth, Firestore `users` | Done |
| SV-001 | Buổi vắng của tôi (.D, .D1, .D2, .W) | `/me` | `MyAttendanceScreen` | `MyAttendanceViewModel` | Firestore `attendance` (collection group theo MSSV) | Done |
| SV-002 | Chi tiết môn (.D, .W) | `/me/subject/:classId` | `SubjectDetailScreen` | `MyAttendanceViewModel` (dùng chung) | như trên | Done |
| SV-101 | Quét mã | `/me/scan` | `ScanScreen` | `ScanViewModel` | camera → Firestore `attendance` (rule kiểm mã) | Done |
| SV-102 | Gửi báo sai | `/me/report?slot=` | `ReportScreen` | `ReportViewModel` | Firestore `requests` | Done |
| — | Tài khoản sinh viên | `/me/account` | `StudentAccountScreen` | `AccountViewModel` | Firebase Auth | Added (D-L3-06) |
| — | Khu demo Firebase | `/demo` | `FirebaseDemoScreen` | `FirebaseDemoViewModel` | FCM, Storage, Remote Config, Crashlytics | Added (đề Lab 3 mục 3) |
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
| D-L3-01 | Toàn app | Một codebase Flutter cho cả hai phía; phía sinh viên chạy bằng Flutter Web (và Android khi build `PORTAL=student`) thay vì web riêng | Đề Lab 3 yêu cầu dựng mọi màn Final UI bằng Flutter; dùng chung theme và widget giữ đúng design system | Ghi chú trên trang 03 |
| D-L3-02 | GV-092 | Thay 6 ô mã số bằng hướng dẫn mở link xác nhận + nút “Xác nhận” kiểm lại trạng thái | Firebase Auth gửi link xác nhận email, không có mã 6 số khi không dùng Cloud Functions (ràng buộc nền tảng, gói Spark) | Thêm khung GV-092 .D (Lab 3) |
| D-L3-03 | Icon | Dùng Material Symbols (bản nét `outlined` và bản đặc) thay cho Lucide + bộ “Icon đặc” tự vẽ | Giữ đúng luật đặc / nét mà không phải tự vẽ lại 30 icon; Material có sẵn cả hai dạng cho cùng một hình | Ghi chú trên trang 05 |
| D-L3-04 | GV-004 | Thêm nhóm “Firebase”: Thông báo, Xuất báo cáo, Remote Config, Crashlytics | Đề Lab 3 mục 3 bắt buộc khu demo Firebase trên màn Tài khoản | Thêm khung GV-004 .D (Lab 3) |
| D-L3-05 | GV-103 | Thêm nút icon “Xuất PDF” ở app bar | Đề Lab 3: sinh ít nhất 1 file phản ánh nội dung người dùng đang xem và tải lên cloud | Thêm icon trên khung GV-103 |
| D-L3-06 | Web sinh viên | Thêm màn Tài khoản (mở khi chạm dòng avatar ở SV-001): tên, MSSV, khu demo, Đăng xuất | Đề Lab 3: phải có đăng xuất và màn hồ sơ; thiết kế sinh viên chưa có | Thêm khung SV-003 |
| D-L3-07 | GV-001 .D | Nút “Xem tất cả” và hàng Chú ý dùng ngưỡng vắng lấy từ Remote Config (mặc định 20%) | Đề Lab 3: Remote Config phải đổi hành vi thấy được | — (không đổi giao diện) |
| D-L3-08 | GV-102 .D1 | Chu kỳ đổi mã QR lấy từ Remote Config (mặc định 12 giây, chip “Đổi mã 12s” theo giá trị) | như trên | — |
| D-L3-09 | Nhập lớp | Định dạng file cố định (cột `mon, lop, mssv, ho_ten, email, lich, bat_dau`), có file mẫu trong `sample-data/` | Thiết kế chưa chốt cột; cần định dạng để kiểm lỗi dòng như GV-100 .X | Ghi chú trên trang 03 |

Mọi khác biệt ở trên đều được cập nhật vào Figma trước khi nộp (cột cuối); khác biệt chưa có trong bảng là lỗi.
