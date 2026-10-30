# Bản ghi review của AI · Claude (Claude Code) · 30/10/2026

Phạm vi: toàn bộ thay đổi từ commit `c155368` tới `aef9fa3` (nhánh `main`, trước khi mở PR). Cách làm: đọc lại từng file trong `lib/`, `firebase/`, `test/`, đối chiếu luật mục 5 của đề và kiểm bằng `grep`.

```
$ grep -rln "providers.dart\|firebase_\|cloud_firestore" lib/screens lib/widgets
(không có kết quả: không màn hình nào import SDK hay provider service)
$ grep -n "isStudent();" firebase/firestore.rules
48:        || isStudent();
$ grep -n "openRoutes" lib/app.dart
25:    _routes = ref.read(messagingServiceProvider).openRoutes.listen((route) {
```

## Phát hiện

**R1 · Security · `firebase/firestore.rules:48`**
`match /slots/{slotId}` cho mọi sinh viên đã đăng nhập đọc slot bất kỳ, gồm cả `qrToken`. Một sinh viên ở nhà có thể đọc token hiện tại (đổi mỗi 12 giây) rồi tự ghi “có mặt”: mã QR mất tác dụng chống điểm danh hộ. Đề xuất: không cho sinh viên đọc slot; đưa thông tin slot cần thiết vào nội dung mã QR, để Security Rules đối chiếu với slot bằng `get()`.

**R2 · Performance · `lib/viewmodels/account_viewmodels.dart:56-66`**
`reminderSchedulerProvider` watch cả `lecturerFeedProvider`. Feed đổi mỗi khi có bản ghi điểm danh mới (mỗi lần một sinh viên quét), nên trong một phiên 35 em app hủy và đặt lại toàn bộ báo thức ~35 lần. Đề xuất: chỉ watch phần ảnh hưởng tới lịch nhắc (id, giờ, trạng thái chốt của slot và 2 công tắc).

**R3 · Architecture · `lib/app.dart:25`**
Widget `QuickAttendApp` gọi thẳng `messagingServiceProvider` (một service). Luật mục 5: View chỉ nói chuyện với ViewModel. Đề xuất: chuyển việc nghe “chạm thông báo → mở route” vào một provider ở `viewmodels/`.

**R4 · Maintainability · `lib/firebase/messaging_service.dart:37`**
Kiểm trùng tin bằng `s.contains('"id":"${n.id}"')` trên chuỗi JSON: phụ thuộc cách `jsonEncode` đặt dấu cách và thứ tự khóa; id có ký tự đặc biệt sẽ không khớp. Đề xuất: giải mã và so trường `id`.

**R5 · Test gap · `lib/services/import_service.dart:206`**
Nhánh đọc `.xlsx` (`_readXlsx`) không có test; chỉ CSV được test. Thiết kế GV-100 nói “Excel hoặc CSV”. Đề xuất: test tạo file xlsx bằng gói `excel` rồi đọc lại.

**R6 · Performance · `lib/services/slot_repository.dart:73`**
`watchLecturerRecords` nghe mọi bản ghi điểm danh của giảng viên ở mọi kỳ. Sau vài kỳ số lần đọc khi mở app tăng tuyến tính. Đề xuất: lọc theo kỳ (cần chỉ mục ghép `lecturerId + term` cho collection group).

**R7 · Bug · `lib/services/student_attendance_repository.dart:78`**
Sinh viên tự đọc `classes/{id}/students/{mssv}` để kiểm mình có trong lớp trước khi ghi. Luật đã kiểm bằng `exists()`, nên lần đọc này thừa và mở thêm một quyền đọc cho sinh viên. Gộp với R1.
