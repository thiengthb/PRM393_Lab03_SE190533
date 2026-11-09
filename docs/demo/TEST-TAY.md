# Test tay rút gọn: 6 ca, khoảng 35 phút

Bản thay cho 18 luồng trong `HUONG-DAN.md` (bản đó vẫn giữ để tra cứu). Từ 09/11, Claude tự test các luồng đủ bước bằng E2E web (32 ca trên Emulator) và bằng cách điều khiển điện thoại và laptop qua cáp. Bạn chỉ làm 6 ca này: đó là những thứ chỉ thấy được trên máy thật, và cũng là những gì sẽ demo cho thầy.

[Chưa kiểm] Toàn bộ ca dưới đây viết cho project mới **attendo-app-2611**, chưa chạy lần nào trên project này. Claude sẽ chạy thử trước rồi mới báo bạn bắt đầu.

## Chuẩn bị (5 phút, trước mỗi buổi)

1. Nạp lại dữ liệu: [Demo: Firebase thật](https://github.com/thiengthb/PRM393_Lab03_SE190533/actions/workflows/demo-firebase.yml) → **Run workflow** → nhánh đang dùng (hiện là `claude/attendo-dev`) → bỏ tick ô Đẩy Rules (trừ khi Claude báo có bản web mới), giữ tick ô Xoá sạch dữ liệu, ô admin_email gõ Gmail quản trị của bạn → đợi tick xanh. Ghi lại số **N** trong dòng "Slot đang diễn ra: N".
2. Mở sẵn:

| Ký hiệu | Máy | Mở gì | Đăng nhập |
|---|---|---|---|
| ĐT | Điện thoại | App Attendo | quanm@fe.edu.vn |
| ĐT-web | Chrome trên điện thoại | [attendo-app-2611.web.app](https://attendo-app-2611.web.app) | tien102@fpt.edu.vn |
| WIN | Laptop | App Attendo cho Windows | quanm@fe.edu.vn |
| SV | Laptop, Chrome ẩn danh | [attendo-app-2611.web.app](https://attendo-app-2611.web.app) | dung101@fpt.edu.vn |
| ADMIN | Laptop, Chrome thường | [attendo-app-2611-admin.web.app](https://attendo-app-2611-admin.web.app) | Gmail quản trị (Google) |
| FAP | Laptop, Chrome thường | [attendo-app-2611-fap.web.app](https://attendo-app-2611-fap.web.app) + extension | |

Mật khẩu mọi tài khoản mẫu: **Demo@123**.

Mỗi ca có dòng **Đúng khi**. Sai thì ghi vào `docs/demo/loi.md` (hoặc nhắn Claude kèm ảnh) rồi làm tiếp ca sau, đừng dừng cả buổi.

## T1. Điểm danh một buổi từ đầu đến FAP (WF-01, 12 phút)

1. ĐT: Tổng quan → bấm thẻ **Đang diễn ra: PRM393 · SE1801**. Đúng khi: có mã QR, mã số 6 chữ số, "24 trên 35 đã có mặt", mã đổi mỗi 12 giây.
2. WIN: Tổng quan → bấm thẻ **Đang diễn ra** (hoặc Ctrl+D). Đúng khi: bố cục laptop (mã bên trái, danh sách bên phải) và dòng báo máy khác đang đổi mã; mã trên hai máy giống nhau.
3. WIN: **Chiếu lên TV** → chép link → mở tab Chrome mới → F11. Đúng khi: trang TV có QR lớn, link dạng `attendo-app-2611-tv.web.app/tv/...`.
4. ĐT-web (tien102): **Quét mã** → cho phép camera → quét QR trên TV. Đúng khi: **Đã ghi nhận**; ĐT, WIN và TV cùng lên 25 trong vài giây.
5. SV (dung101): **Nhập mã điểm danh** → gõ mã số đang hiện → Gửi. Đúng khi: **Đã ghi nhận**, các màn lên 26.
6. ĐT: bấm **Quay lại** về Tổng quan. Đúng khi: trong khoảng 3 giây WIN tự nhận việc đổi mã (dòng báo máy khác biến mất), mã vẫn đổi đều.
7. WIN: **Đóng mã** (hoặc phím Space) → bật tay một em trong nhóm **Chưa quét** → **Chốt** (Ctrl+Enter). Đúng khi: **Đã chốt**, 27 trên 35, trang TV báo đã đóng mã.
8. FAP: ô Buổi chọn **PRM393 · SE1801 · Slot N** → extension **Đọc trang** → đăng nhập quanm → **Lấy bản đã chốt** → tick **Tôi đã kiểm tra danh sách** → **Điền vào trang**. Đúng khi: Có mặt 27, Vắng 8, trên trang đúng 27 em Present.
9. FAP: đổi ô Buổi sang slot khác → Đọc lại → Lấy bản đã chốt. Đúng khi: extension từ chối vì slot không khớp.

Chụp ảnh cho bằng chứng: bước 2 (WIN), 3 (TV), 4 (ĐT-web), 8 (extension).

## T2. Sinh viên báo sai, giảng viên duyệt và từ chối (WF-02, 6 phút)

1. SV: mở môn **PRM393 SE1801**. Đúng khi: bảng buổi học bên phải, đúng một buổi vắng có nút **Báo sai**.
2. **Báo sai** → bấm Gửi khi chưa chọn lý do (không gửi được) → chọn **Quên quét mã** → **Gửi**.
3. WIN: mục **Yêu cầu sửa** bên trái. Đúng khi: yêu cầu vừa gửi tự hiện, không cần tải lại.
4. WIN: chọn yêu cầu đó → **Duyệt**. Đúng khi: SV thấy buổi đó thành "có mặt", số vắng giảm 1.
5. WIN: chọn yêu cầu khác của Huỳnh Anh Dung → **Từ chối** → chọn **Không có mặt** → gửi. Đúng khi: SV (F5) thấy "Bị từ chối: Không có mặt", không còn nút Báo sai ở buổi đó.

## T3. Duyệt lớp liên vai trò, đo thời gian (WF-03, 5 phút)

1. ĐT: Tài khoản → Đăng xuất → đăng nhập **nam@fe.edu.vn**. Đúng khi: lớp **MMA301 · SE1806** ghi Chờ giáo vụ duyệt.
2. ADMIN: **Duyệt lớp** → chọn MMA301 · SE1806 → khung chi tiết bên phải → **Duyệt lớp này**, cùng lúc bấm đồng hồ bấm giờ.
3. Đúng khi: ĐT bỏ chữ chờ duyệt. **Ghi số giây** (báo cáo Final cần số này).
4. ĐT: Hộp thư có tin lớp đã được duyệt. Đăng xuất, đăng nhập lại quanm.

## T4. Nhắc sinh viên vắng nhiều bằng AI, tắt AI bằng Remote Config (WF-04, 5 phút)

1. ĐT: Tổng quan → khối Vắng nhiều → **Xem tất cả** → tab **Sắp chạm** → em đầu tiên → **Nhắc nhở** → **Gợi ý AI**. Đúng khi: vài giây sau ô soạn đổi thành lời nhắc AI viết. Chụp ảnh. Bấm **Gửi** → **Đã nhắc**.
2. Laptop: [Remote Config](https://console.firebase.google.com/project/attendo-app-2611/config) → `ai_reminder_enabled` → **false** → Publish.
3. ĐT: Tài khoản → **Khu demo** → **Tải lại** → quay lại sheet nhắc của một em khác. Đúng khi: không còn nút Gợi ý AI, lời nhắc mẫu vẫn gửi được.
4. Đổi `ai_reminder_enabled` về **true** → Publish.

## T5. Thông báo FCM ở 3 trạng thái app (4 phút)

1. ĐT: Khu demo → **Chép token**, gửi token sang laptop (Zalo hoặc email cho chính mình).
2. Laptop: [Messaging](https://console.firebase.google.com/project/attendo-app-2611/messaging) → tạo thông báo "Attendo test" → **Send test message** → dán token → Test. Làm 3 lần: app đang mở, app ở nền (bấm Home), app đã tắt (vuốt khỏi đa nhiệm).
3. Đúng khi: cả ba lần đều nhận; bấm thông báo thì app mở lên. Chụp cả ba.

Muốn bấm thông báo mở đúng màn (ví dụ Yêu cầu sửa): nhắn Claude chạy `tool/fcm/send.mjs`, script gửi kèm `data.route`.

## T6. Nút crash, Crashlytics, web admin Sự cố (3 phút + đợi)

1. ĐT: Khu demo → **Lỗi non-fatal**. ADMIN: mục **Sự cố**. Đúng khi: có dòng mới ngay.
2. ĐT: Khu demo → **Test crash** → app tắt → mở lại app (Crashlytics gửi báo cáo ở lần mở sau).
3. ADMIN: Sự cố. Đúng khi: có dòng crash mới.
4. Đợi 5 đến 10 phút: [Crashlytics](https://console.firebase.google.com/project/attendo-app-2611/crashlytics). Đúng khi: có sự cố mới. Chụp cả console và web admin (đây là phần thầy dặn demo).

## Phần Claude tự kiểm (bạn không cần làm)

| Nhóm | Claude kiểm bằng gì |
|---|---|
| Đăng nhập, đăng ký, quên mật khẩu, xác nhận email | E2E web W01, W44, W47, W49 |
| Lịch tuần, lớp, buổi học, sửa buổi đã chốt, slot quên chốt | E2E W02, W04, W45; điện thoại qua cáp |
| Mất mạng lúc chốt | E2E W50 (tắt mạng trình duyệt) |
| Nhập file lớp, lỗi file | E2E W20, W40 |
| Web admin: môn học, người dùng, thông báo, người lạ bị chặn | E2E W30 đến W33 |
| Security Rules | 118+ ca test trên Emulator (CI) |
| Extension | 84 ca test (CI), E2E W60 |
| Giao diện từng thiết bị | Ảnh chụp điện thoại, Windows, web ở đúng kích thước máy |

Kết quả thật của phần này lấy từ CI và ghi vào `docs/test-report.md`; chưa chạy thì ghi "chưa kiểm".
