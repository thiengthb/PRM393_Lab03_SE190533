# Mô hình dữ liệu và quyền

> Đề Final mục 6, Appendix A. Luật: [`firebase/firestore.rules`](../firebase/firestore.rules). Test: [`firebase/tests/rules.test.mjs`](../firebase/tests/rules.test.mjs).

## Vai trò

`users/{uid}.role`: `student`, `lecturer`, `staff` (giáo vụ), `admin`, `user` (tài khoản mới ở web admin, chưa có quyền). Mỗi client từ chối vai trò sai bằng câu rõ ràng: app giảng viên và cổng sinh viên ở `LoginViewModel`, web admin ở màn `/denied`. **Admin đầu tiên đặt trên console**: đăng nhập web admin một lần để có hồ sơ, rồi sửa `role` thành `admin` trong Firestore. Từ đó chỉ Admin đổi vai trò, không ai đổi được của chính mình.

## Collection

| Collection | Trường chính (kiểu) | Tạo | Đọc | Sửa | Xóa | Màn dùng |
|---|---|---|---|---|---|---|
| `users/{uid}` | `role` (string), `displayName`, `email` (string), `studentCode?` (string), `reminderBeforeSlot`, `reminderUnclosed` (bool), `lastImportAt?`, `lastInboxReadAt?` (timestamp) | Chính mình lúc đăng nhập đầu, role ∈ student, lecturer, user | Chính mình; Admin | Chính mình (trừ role, studentCode, email); Admin chỉ sửa `role` người khác | — | GV-004, SV Tài khoản, web Người dùng |
| `studentCodes/{mssv}` | `uid` (string) | Chính sinh viên, cùng batch với `users/{uid}` lúc tạo hồ sơ (CR-15) | Chính chủ | — | — | Mỗi MSSV một tài khoản |
| `users/{uid}/inbox/{id}` | `kind`, `title` (≤ 120), `body` (≤ 500), `route?` (string), `createdBy` (uid), `createdAt` | Staff, Admin | Chủ tài khoản | — | — | Hộp thư |
| `subjects/{code}` | `code` (= id, `^[A-Z0-9]{3,10}$`), `name` (≤ 120), `status` (active, archived), `updatedBy`, `updatedAt` | Staff, Admin | Mọi người đã đăng nhập | Staff, Admin | — (lưu trữ) | Web Môn học; GV-100 kiểm mã môn; web Duyệt lớp cảnh báo |
| `announcements/{id}` | `title` (≤ 120), `body` (≤ 1000), `audience` (all, lecturer, student), `status` (published, archived), `createdBy`, `publishedAt` | Staff, Admin | Staff, Admin; lecturer, student đọc bản published đúng audience | Staff, Admin chỉ đổi `status` | — | Web Thông báo; Hộp thư |
| `classes/{id}` | `lecturerId`, `lecturerName`, `term`, `subject`, `code` (string), `studentCount`, `totalSlots` (int), `status` (pending, approved, rejected), `rejectReason?`, `reviewedBy?`, `reviewedAt?`, `submittedAt` | Lecturer với status = pending | Chủ lớp; Staff, Admin | Xem bảng chuyển trạng thái | — | GV-100, GV-001, GV-003, GV-103; web Duyệt lớp, Tổng quan |
| `classes/{id}/students/{mssv}` | `studentCode`, `name`, `email?`, `lecturerId` | Chủ lớp | Chủ lớp; Staff, Admin | Chủ lớp | — | GV-102, GV-103; web Duyệt lớp |
| `slots/{id}` | `lecturerId`, `classId`, `subject`, `classCode`, `term`, `start`, `end`, `slotNo`, `room`, `studentCount`, `totalSlots`, `closed`, `presentCount`, `absentCount`, `qrOpen`, `qrToken`, `qrExpiresAt` | Chủ lớp | Chủ slot; Staff, Admin. **Sinh viên không đọc** vì có `qrToken` (CR-01) | Chủ slot; mở QR chỉ khi lớp approved | — | GV-001, 002, 101, 102; web Tổng quan |
| `slots/{id}/attendance/{mssv}` | sao chép slot + `studentCode`, `studentName`, `present`, `source`, `final`, `token?`, `scannerUid?`, `at` | Chủ slot khi lớp approved; sinh viên khi mã đúng, còn hạn, có tên trong lớp | Chủ slot; sinh viên đọc bản của mình | Như tạo | — | GV-102, 103, 104, 201; SV-001, 002, 101 |
| `requests/{id}` | `studentUid`, `studentCode`, `studentName`, `lecturerId`, `slotId`, `classId`, `subject`, `slotStart`, `slotNo`, `reason` (≤ 80), `note` (≤ 300), `status`, `rejectReason?`, `rejectNote?`, `reviewedAt?` | Student với status = pending | Sinh viên chủ; giảng viên của lớp; Staff, Admin | Xem bảng | — | SV-102, GV-105 |
| `reminders/{id}` | `lecturerId`, `classId`, `studentCode`, `toEmail`, `message` (≤ 300), `day` | Lecturer | Lecturer chủ | — | — | GV-201, OV3 |
| `reports/{id}` | `ownerUid`, `classId`, `fileName`, `sizeKb` (int), `destination` (device, cloud), `createdAt` | Lecturer chủ | Chủ; Staff, Admin | — | — | GV-103, Khu demo |
| `users/{uid}/fcmTokens/{token}` | `token` (= id, ≤ 1024), `platform` (android, web), `updatedAt` (= giờ máy chủ) | Chủ tài khoản | Chủ tài khoản (cả Admin cũng không đọc token người khác) | Chủ tài khoản | Chủ tài khoản (đăng xuất) | FCM, xem [fcm.md](fcm.md) |
| `crashReports/{id}` | `uid` (= người ghi), `role` (= vai trò thật), `kind` (test_crash, non_fatal, flutter_error), `where` (≤ 80), `message` (≤ 500), `platform` (android, web, windows), `createdAt` (= giờ máy chủ) | Mọi người đã đăng nhập, chỉ ghi cho chính mình | Admin | — | — | Web Sự cố; Khu demo Crashlytics |

Vai trò không có quyền nào trên một collection (ví dụ `user` với `announcements`, `student` với `reminders`) chỉ có ca Denied trong bộ test, vì không tồn tại thao tác Allowed để kiểm.

## Chuyển trạng thái

| Thực thể | Từ | Sang | Ai | Điều kiện |
|---|---|---|---|---|
| Lớp | (chưa có) | pending | Lecturer | `lecturerId` là chính mình |
| Lớp | pending | approved | Staff, Admin | Chỉ sửa `status`, `reviewedBy`, `reviewedAt` |
| Lớp | pending | rejected | Staff, Admin | Có `rejectReason` ≤ 300 |
| Lớp | rejected | pending | Lecturer | Nhập lại file |
| Báo sai | pending | approved, rejected | Lecturer của lớp | Chỉ sửa các trường duyệt |
| Báo sai | approved | pending | Lecturer | Hoàn tác |
| Môn | active ↔ archived | | Staff, Admin | |
| Thông báo | published ↔ archived | | Staff, Admin | Chỉ sửa `status` |

## Chỉ mục

`firebase/firestore.indexes.json`: collection group `attendance` theo `lecturerId` và `studentCode`; các chỉ mục ghép `slots` và `classes` cho aggregation `sum` ở Dashboard.
