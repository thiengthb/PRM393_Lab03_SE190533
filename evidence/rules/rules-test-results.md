# Kết quả test Security Rules

Sinh tự động bởi `firebase/tests/rules.test.mjs` trên Firestore Emulator, 2026-11-03T01:38:26.656Z.

**63/63 ca đạt.**

| ID | Collection | Vai trò | Thao tác | Mong đợi | Kết quả |
|---|---|---|---|---|---|
| R-001 | users | student | đọc hồ sơ của mình | Allowed | Pass |
| R-002 | users | student | tự đổi role thành lecturer | Denied | Pass |
| R-003 | users | student | đổi MSSV | Denied | Pass |
| R-004 | users | lecturer | đổi công tắc nhắc | Allowed | Pass |
| R-005 | users | lecturer | đọc hồ sơ người khác | Denied | Pass |
| R-006 | users | anon | đọc hồ sơ | Denied | Pass |
| R-007 | classes | lecturer | liệt kê lớp của mình | Allowed | Pass |
| R-008 | classes | lecturer | đọc lớp người khác | Denied | Pass |
| R-009 | classes | student | đọc lớp | Denied | Pass |
| R-010 | classes | anon | đọc lớp | Denied | Pass |
| R-011 | students | lecturer | thêm sinh viên vào lớp của mình | Allowed | Pass |
| R-012 | students | lecturer2 | ghi vào lớp người khác | Denied | Pass |
| R-013 | students | student | đọc danh sách lớp | Denied | Pass |
| R-014 | slots | lecturer | mở mã QR slot của mình | Allowed | Pass |
| R-015 | slots | lecturer2 | sửa slot người khác | Denied | Pass |
| R-016 | slots | student | đọc slot (có qrToken) | Denied | Pass |
| R-017 | slots | anon | đọc slot | Denied | Pass |
| R-018 | attendance | student | quét đúng mã trong hạn | Allowed | Pass |
| R-019 | attendance | student | quét mã vừa thay (qrTokenPrev) trong hạn | Allowed | Pass |
| R-020 | attendance | student | quét sai mã | Denied | Pass |
| R-021 | attendance | student | điểm danh hộ MSSV khác | Denied | Pass |
| R-022 | attendance | student | ghi sang lớp khác (classId không khớp) | Denied | Pass |
| R-023 | attendance | student | đọc buổi của mình (collection group) | Allowed | Pass |
| R-024 | attendance | lecturer | đánh dấu tay | Allowed | Pass |
| R-025 | attendance | lecturer2 | đánh dấu ở slot người khác | Denied | Pass |
| R-026 | attendance | anon | quét mã | Denied | Pass |
| R-X1 | attendance | student | quét mã cũ sau 1 chu kỳ | Denied | Pass |
| R-027 | qrCodes | student | đọc đúng mã còn hạn của lớp mình | Allowed | Pass |
| R-028 | qrCodes | student | đọc mã đã hết hạn | Denied | Pass |
| R-029 | qrCodes | student | đọc mã của lớp không có tên | Denied | Pass |
| R-030 | qrCodes | student | liệt kê để dò mã | Denied | Pass |
| R-031 | qrCodes | student | đọc mã không tồn tại | Denied | Pass |
| R-032 | qrCodes | lecturer | ghi mã mới cùng lần đổi mã (batch) | Allowed | Pass |
| R-033 | qrCodes | lecturer | ghi đè mã còn hạn của lớp khác | Denied | Pass |
| R-034 | qrCodes | lecturer | ghi đè mã đã hết hạn của lớp khác | Allowed | Pass |
| R-035 | qrCodes | lecturer | mã không phải 6 chữ số | Denied | Pass |
| R-036 | qrCodes | lecturer2 | ghi mã cho slot người khác | Denied | Pass |
| R-037 | qrCodes | lecturer2 | xoá mã người khác | Denied | Pass |
| R-038 | qrCodes | anon | đọc mã | Denied | Pass |
| R-X2 | qrCodes | student (lớp khác) | đọc mã của lớp không có tên | Denied | Pass |
| R-039 | tv | anon | đọc màn chiếu bằng khoá còn hạn | Allowed | Pass |
| R-040 | tv | anon | đọc link đã hết hạn | Denied | Pass |
| R-041 | tv | anon | liệt kê để dò khoá | Denied | Pass |
| R-042 | tv | anon | ghi màn chiếu | Denied | Pass |
| R-043 | tv | lecturer | tạo màn chiếu và lưu khoá vào slot (batch) | Allowed | Pass |
| R-044 | tv | lecturer | cập nhật khung khi đổi mã | Allowed | Pass |
| R-045 | tv | lecturer | thêm trường lạ | Denied | Pass |
| R-046 | tv | lecturer | chuyển màn chiếu sang slot khác | Denied | Pass |
| R-047 | tv | lecturer2 | sửa màn chiếu người khác | Denied | Pass |
| R-048 | tv | student | sửa số đã quét | Denied | Pass |
| R-049 | tv | student | đọc màn chiếu (như mọi người có link) | Allowed | Pass |
| R-050 | requests | student | gửi báo sai | Allowed | Pass |
| R-051 | requests | student | tự duyệt báo sai | Denied | Pass |
| R-052 | requests | lecturer | duyệt pending → approved | Allowed | Pass |
| R-053 | requests | lecturer | sửa lý do của sinh viên | Denied | Pass |
| R-054 | requests | anon | đọc báo sai | Denied | Pass |
| R-055 | reminders | lecturer | gửi lời nhắc | Allowed | Pass |
| R-056 | reminders | lecturer | sửa lời nhắc đã gửi | Denied | Pass |
| R-057 | reminders | student | đọc lời nhắc | Denied | Pass |
| R-058 | reports | lecturer | ghi metadata báo cáo của mình | Allowed | Pass |
| R-059 | reports | lecturer | ghi metadata tên người khác | Denied | Pass |
| R-060 | reports | lecturer | xoá metadata | Denied | Pass |
| R-061 | reports | student | đọc báo cáo của giảng viên | Denied | Pass |
