# Kết quả test Security Rules

Sinh tự động bởi `firebase/tests/rules.test.mjs` trên Firestore Emulator, 2026-11-05T02:35:13.956Z.

**157/157 ca đạt.**

| ID | Collection | Vai trò | Thao tác | Mong đợi | Kết quả |
|---|---|---|---|---|---|
| R-001 | users | student | đọc hồ sơ của mình | Allowed | Pass |
| R-002 | users | student | tự đổi role thành admin | Denied | Pass |
| R-003 | users | student | đọc hồ sơ người khác | Denied | Pass |
| R-004 | users | lecturer | tạo hồ sơ giảng viên lần đầu | Allowed | Pass |
| R-005 | users | lecturer | tự đổi role | Denied | Pass |
| R-006 | users | lecturer | đổi công tắc nhắc | Allowed | Pass |
| R-007 | users | staff | đánh dấu đã đọc hộp thư của mình | Allowed | Pass |
| R-008 | users | staff | đổi vai trò người khác | Denied | Pass |
| R-009 | users | staff | liệt kê người dùng | Denied | Pass |
| R-010 | users | admin | cấp quyền staff cho tài khoản mới | Allowed | Pass |
| R-011 | users | admin | liệt kê người dùng | Allowed | Pass |
| R-012 | users | admin | tự đổi vai trò của mình | Denied | Pass |
| R-013 | users | admin | sửa trường khác của người khác | Denied | Pass |
| R-014 | users | user | tạo hồ sơ vai trò user | Allowed | Pass |
| R-015 | users | user | tự tạo hồ sơ vai trò admin | Denied | Pass |
| R-016 | users | user | tạo hồ sơ cho uid khác | Denied | Pass |
| R-017 | users | anon | đọc hồ sơ | Denied | Pass |
| R-018 | inbox | lecturer | đọc tin riêng của mình | Allowed | Pass |
| R-019 | inbox | lecturer | tự ghi tin | Denied | Pass |
| R-020 | inbox | student | đọc tin riêng của mình | Allowed | Pass |
| R-021 | inbox | student | đọc tin của giảng viên | Denied | Pass |
| R-022 | inbox | staff | ghi tin kết quả duyệt | Allowed | Pass |
| R-023 | inbox | staff | ghi tin mạo danh người khác | Denied | Pass |
| R-024 | inbox | admin | ghi tin kết quả duyệt | Allowed | Pass |
| R-025 | inbox | admin | xóa tin | Denied | Pass |
| R-026 | inbox | user | đọc tin riêng của mình | Allowed | Pass |
| R-027 | inbox | user | ghi tin | Denied | Pass |
| R-028 | subjects | student | đọc danh mục | Allowed | Pass |
| R-029 | subjects | student | thêm môn | Denied | Pass |
| R-030 | subjects | lecturer | đọc môn đang dùng | Allowed | Pass |
| R-031 | subjects | lecturer | sửa môn | Denied | Pass |
| R-032 | subjects | staff | thêm môn | Allowed | Pass |
| R-033 | subjects | staff | lưu trữ môn | Allowed | Pass |
| R-034 | subjects | staff | mã môn khác id | Denied | Pass |
| R-035 | subjects | staff | xóa môn | Denied | Pass |
| R-036 | subjects | admin | sửa tên môn | Allowed | Pass |
| R-037 | subjects | admin | trạng thái lạ | Denied | Pass |
| R-038 | subjects | user | đọc danh mục | Allowed | Pass |
| R-039 | subjects | user | thêm môn | Denied | Pass |
| R-040 | subjects | anon | đọc danh mục | Denied | Pass |
| R-041 | announcements | lecturer | truy vấn hộp thư như app | Allowed | Pass |
| R-042 | announcements | lecturer | đọc thông báo dành cho sinh viên | Denied | Pass |
| R-043 | announcements | lecturer | đăng thông báo | Denied | Pass |
| R-044 | announcements | student | truy vấn hộp thư như app | Allowed | Pass |
| R-045 | announcements | student | đọc thông báo đã lưu trữ | Denied | Pass |
| R-046 | announcements | staff | đăng thông báo | Allowed | Pass |
| R-047 | announcements | staff | lưu trữ | Allowed | Pass |
| R-048 | announcements | staff | tiêu đề quá 120 ký tự | Denied | Pass |
| R-049 | announcements | staff | sửa nội dung sau khi đăng | Denied | Pass |
| R-050 | announcements | admin | đọc mọi thông báo | Allowed | Pass |
| R-051 | announcements | admin | xóa thông báo | Denied | Pass |
| R-052 | announcements | user | đọc thông báo | Denied | Pass |
| R-053 | classes | lecturer | gửi lớp mới trạng thái pending | Allowed | Pass |
| R-054 | classes | lecturer | tạo lớp đã approved | Denied | Pass |
| R-055 | classes | lecturer | tự duyệt lớp pending | Denied | Pass |
| R-056 | classes | lecturer | gửi lại lớp bị từ chối | Allowed | Pass |
| R-057 | classes | lecturer | đọc lớp chưa tồn tại trước khi nhập | Allowed | Pass |
| R-058 | classes | lecturer | liệt kê lớp của mình | Allowed | Pass |
| R-059 | classes | staff | duyệt pending → approved | Allowed | Pass |
| R-060 | classes | staff | từ chối có lý do | Allowed | Pass |
| R-061 | classes | staff | từ chối không có lý do | Denied | Pass |
| R-062 | classes | staff | duyệt lại lớp đã approved | Denied | Pass |
| R-063 | classes | staff | sửa dữ liệu lớp khi duyệt | Denied | Pass |
| R-064 | classes | admin | xem hàng đợi | Allowed | Pass |
| R-065 | classes | admin | xóa lớp | Denied | Pass |
| R-066 | classes | student | đọc lớp | Denied | Pass |
| R-067 | classes | user | đọc lớp | Denied | Pass |
| R-068 | students | lecturer | thêm sinh viên vào lớp của mình | Allowed | Pass |
| R-069 | students | student | đọc danh sách lớp | Denied | Pass |
| R-070 | students | staff | đọc danh sách khi duyệt | Allowed | Pass |
| R-071 | students | staff | sửa danh sách | Denied | Pass |
| R-072 | students | admin | đọc danh sách | Allowed | Pass |
| R-073 | students | admin | xóa sinh viên | Denied | Pass |
| R-074 | students | user | đọc danh sách | Denied | Pass |
| R-X1 | students | lecturer (khác) | ghi vào lớp người khác | Denied | Pass |
| R-075 | slots | lecturer | mở mã QR slot của lớp đã duyệt | Allowed | Pass |
| R-076 | slots | lecturer | mở mã QR khi lớp chưa duyệt | Denied | Pass |
| R-077 | slots | student | đọc slot (có qrToken) | Denied | Pass |
| R-078 | slots | staff | đọc slot đã chốt để tổng hợp | Allowed | Pass |
| R-079 | slots | staff | sửa slot | Denied | Pass |
| R-080 | slots | admin | đọc slot | Allowed | Pass |
| R-081 | slots | admin | xóa slot | Denied | Pass |
| R-082 | slots | user | đọc slot | Denied | Pass |
| R-X2 | slots | lecturer | batch tạo lớp + sinh viên + slot | Allowed | Pass |
| R-083 | attendance | student | quét đúng mã trong hạn | Allowed | Pass |
| R-084 | attendance | student | quét mã vừa thay (qrTokenPrev) trong hạn | Allowed | Pass |
| R-085 | attendance | student | ghi sang lớp khác (classId không khớp) | Denied | Pass |
| R-086 | attendance | student | quét sai mã | Denied | Pass |
| R-087 | attendance | student | điểm danh hộ MSSV khác | Denied | Pass |
| R-088 | attendance | student | đọc buổi của mình (collection group) | Allowed | Pass |
| R-089 | attendance | lecturer | đánh dấu tay ở lớp đã duyệt | Allowed | Pass |
| R-090 | attendance | lecturer | đánh dấu ở lớp chưa duyệt | Denied | Pass |
| R-091 | attendance | lecturer | đọc toàn bộ của mình (collection group) | Allowed | Pass |
| R-092 | attendance | staff | đọc điểm danh | Denied | Pass |
| R-093 | attendance | staff | sửa điểm danh | Denied | Pass |
| R-094 | attendance | admin | sửa điểm danh | Denied | Pass |
| R-095 | attendance | user | quét mã | Denied | Pass |
| R-096 | attendance | anon | quét mã | Denied | Pass |
| R-X3 | attendance | student | quét mã cũ sau 1 chu kỳ | Denied | Pass |
| R-097 | qrCodes | student | đọc đúng mã còn hạn của lớp mình | Allowed | Pass |
| R-098 | qrCodes | student | đọc mã đã hết hạn | Denied | Pass |
| R-099 | qrCodes | student | đọc mã của lớp không có tên | Denied | Pass |
| R-100 | qrCodes | student | liệt kê để dò mã | Denied | Pass |
| R-101 | qrCodes | student | đọc mã không tồn tại | Denied | Pass |
| R-102 | qrCodes | lecturer | ghi mã mới cùng lần đổi mã (batch) | Allowed | Pass |
| R-103 | qrCodes | lecturer | ghi đè mã còn hạn của lớp khác | Denied | Pass |
| R-104 | qrCodes | lecturer | ghi đè mã đã hết hạn của lớp khác | Allowed | Pass |
| R-105 | qrCodes | lecturer | mã không phải 6 chữ số | Denied | Pass |
| R-106 | qrCodes | lecturer2 | ghi mã cho slot người khác | Denied | Pass |
| R-107 | qrCodes | lecturer2 | xoá mã người khác | Denied | Pass |
| R-108 | qrCodes | staff | đọc mã | Denied | Pass |
| R-109 | qrCodes | admin | ghi mã | Denied | Pass |
| R-110 | qrCodes | user | đọc mã | Denied | Pass |
| R-111 | qrCodes | anon | đọc mã | Denied | Pass |
| R-X4 | qrCodes | student (lớp khác) | đọc mã của lớp không có tên | Denied | Pass |
| R-112 | tv | anon | đọc màn chiếu bằng khoá còn hạn | Allowed | Pass |
| R-113 | tv | anon | đọc link đã hết hạn | Denied | Pass |
| R-114 | tv | anon | liệt kê để dò khoá | Denied | Pass |
| R-115 | tv | anon | ghi màn chiếu | Denied | Pass |
| R-116 | tv | lecturer | tạo màn chiếu và lưu khoá vào slot (batch) | Allowed | Pass |
| R-117 | tv | lecturer | cập nhật khung khi đổi mã | Allowed | Pass |
| R-118 | tv | lecturer | thêm trường lạ | Denied | Pass |
| R-119 | tv | lecturer | chuyển màn chiếu sang slot khác | Denied | Pass |
| R-120 | tv | lecturer2 | sửa màn chiếu người khác | Denied | Pass |
| R-121 | tv | student | đọc màn chiếu (như mọi người có link) | Allowed | Pass |
| R-122 | tv | student | sửa số đã quét | Denied | Pass |
| R-123 | tv | staff | đọc màn chiếu có link | Allowed | Pass |
| R-124 | tv | staff | ghi màn chiếu | Denied | Pass |
| R-125 | tv | admin | ghi màn chiếu | Denied | Pass |
| R-126 | tv | user | ghi màn chiếu | Denied | Pass |
| R-127 | requests | student | gửi báo sai | Allowed | Pass |
| R-128 | requests | student | tự duyệt báo sai | Denied | Pass |
| R-129 | requests | lecturer | duyệt pending → approved | Allowed | Pass |
| R-130 | requests | lecturer | sửa lý do của sinh viên | Denied | Pass |
| R-131 | requests | staff | đọc để thống kê | Allowed | Pass |
| R-132 | requests | staff | duyệt thay giảng viên | Denied | Pass |
| R-133 | requests | admin | đọc | Allowed | Pass |
| R-134 | requests | admin | xóa | Denied | Pass |
| R-135 | requests | user | gửi báo sai | Denied | Pass |
| R-136 | reminders | lecturer | gửi lời nhắc | Allowed | Pass |
| R-137 | reminders | lecturer | sửa lời nhắc đã gửi | Denied | Pass |
| R-138 | reminders | student | đọc lời nhắc | Denied | Pass |
| R-139 | reminders | staff | đọc lời nhắc | Denied | Pass |
| R-140 | reminders | admin | tạo lời nhắc | Denied | Pass |
| R-141 | reminders | user | đọc lời nhắc | Denied | Pass |
| R-142 | reports | lecturer | ghi metadata báo cáo của mình | Allowed | Pass |
| R-143 | reports | lecturer | ghi metadata tên người khác | Denied | Pass |
| R-144 | reports | lecturer | ghi link Cloudinary trong thư mục của mình | Allowed | Pass |
| R-145 | reports | lecturer | ghi link Cloudinary ở thư mục người khác | Denied | Pass |
| R-146 | reports | lecturer | ghi link không phải Cloudinary | Denied | Pass |
| R-147 | reports | lecturer | lưu trên máy mà kèm link | Denied | Pass |
| R-148 | reports | student | đọc báo cáo của giảng viên | Denied | Pass |
| R-149 | reports | staff | đọc metadata | Allowed | Pass |
| R-150 | reports | staff | sửa metadata | Denied | Pass |
| R-151 | reports | admin | đọc metadata | Allowed | Pass |
| R-152 | reports | admin | xóa metadata | Denied | Pass |
| R-153 | reports | user | ghi metadata | Denied | Pass |
