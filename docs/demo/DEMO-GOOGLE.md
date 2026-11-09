# Demo bằng nick Google (từ 10/11/2026)

Thầy thích demo bằng Google nên dữ liệu mẫu giờ nạp thẳng vào ba nick Gmail của thien:

| Vai | Nick | Có sẵn sau khi nạp |
|---|---|---|
| Giảng viên | tranngocthien**024**@gmail.com | 4 lớp của "Nguyễn Minh Quân", slot PRM393 SE1801 đang diễn ra, 3 yêu cầu sửa, em vắng nhiều |
| Sinh viên | tranngocthien**697**@gmail.com | Sinh viên SE190101 (Huỳnh Anh Dung) lớp PRM393 SE1801: 1 yêu cầu chờ, 1 bị từ chối |
| Quản trị | tranngocthien**628**@gmail.com | Quyền Quản trị web admin |

Các tài khoản mật khẩu khác giữ nguyên: nam@fe.edu.vn (lớp chờ duyệt), tien102@fpt.edu.vn, giaovu@fe.edu.vn, mật khẩu `Demo@123`. Riêng quanm@fe.edu.vn và dung101@fpt.edu.vn **không còn dữ liệu**: dữ liệu của hai tài khoản này đã chuyển sang 024 và 697.

**Dự phòng khi Google lỗi lúc demo:** nick 024 và 697 vẫn đăng nhập được bằng email + mật khẩu `Demo@123` (gõ đúng địa chỉ Gmail). App Windows và extension FAP dùng cách này (xem mục 4).

## 1. Một lần duy nhất: thêm SHA-1 cho app Android

Không làm bước này thì nút **Đăng nhập với Google** trên điện thoại chọn tài khoản xong sẽ báo "Đã hủy đăng nhập" (Claude thử lúc 02:13 ngày 10/11 bằng nick 628).

1. Mở https://console.firebase.google.com/project/attendo-app-2611/settings/general (đăng nhập nick 628).
2. Kéo xuống **Your apps** → chọn app Android **app.attendo**.
3. Bấm **Add fingerprint**, dán dòng dưới, bấm **Save**:
   `5A:EC:93:0D:F0:9A:EB:82:C8:18:F3:98:C6:BD:E3:1D:9A:73:E6:9F` (bản dev trên laptop, `dev.ps1 -Target phone`)
4. Bấm **Add fingerprint** lần nữa, dán:
   `D0:11:73:C0:79:46:13:B5:88:D8:17:2B:67:AB:C4:0C:2C:84:C1:91` (APK tải từ Release `demo-preview`)
5. Đợi khoảng 5 phút. Không cần dựng lại app.

## 2. Một lần duy nhất: lưu ba nick vào secret

Lưu vào secret thì email không lộ ra repo công khai, và lần nạp sau chỉ cần bấm nút.

1. Mở https://github.com/thiengthb/PRM393_Lab03_SE190533/settings/secrets/actions
2. Bấm **New repository secret** ba lần:

| Name | Secret |
|---|---|
| `DEMO_GOOGLE_LECTURER` | tranngocthien024@gmail.com |
| `DEMO_GOOGLE_STUDENT` | tranngocthien697@gmail.com |
| `DEMO_ADMIN_EMAIL` | tranngocthien628@gmail.com |

Muốn đổi nick cho một lần chạy thì gõ vào ô nhập của workflow, ô nhập thắng secret.

## 3. Mỗi lần trước khi demo: nạp lại dữ liệu

1. Mở https://github.com/thiengthb/PRM393_Lab03_SE190533/actions/workflows/demo-firebase.yml
2. **Run workflow** → Branch: `claude/attendo-dev` (sau khi gộp PR #27 thì chọn `final-system`).
3. Ô **Đẩy Rules, chỉ mục, Remote Config, Hosting**: tick khi Claude báo có bản web mới; nếu không thì bỏ tick cho nhanh.
4. Ô **Xoá sạch dữ liệu và nạp lại**: giữ tick.
5. Ba ô email để trống (đã có secret).
6. **Run workflow**, đợi tick xanh (khoảng 2 phút, có deploy thì khoảng 8 phút).
7. Mở lần chạy → phần Summary ghi "Slot đang diễn ra: N" (email hiện thành `<Gmail>`, là đúng).

Giới hạn ghi miễn phí của Firestore: mỗi lần nạp tốn khá nhiều lượt ghi, nên mỗi ngày chỉ nên nạp 3 đến 4 lần.

## 4. Đăng nhập trên từng máy

| Máy | Mở gì | Đăng nhập |
|---|---|---|
| Điện thoại | App Attendo | **Đăng nhập với Google** → 024. Nếu điện thoại chưa có nick 024: trong hộp chọn bấm **Thêm tài khoản khác** và đăng nhập Google một lần |
| Laptop, Chrome ẩn danh | https://attendo-app-2611.web.app | **Đăng nhập với Google** → 697 |
| Laptop, Chrome thường | https://attendo-app-2611-admin.web.app | Google → 628 |
| Laptop | App Attendo cho Windows | Email `tranngocthien024@gmail.com`, mật khẩu `Demo@123` [Suy luận] nút Google trên Windows không chạy vì thư viện Google của Flutter không hỗ trợ Windows; chưa kiểm |
| Extension FAP | Popup extension | Email 024 + `Demo@123` như trên |

Đúng khi: điện thoại vào thẳng Tổng quan "Chào …, Quân" với 4 lớp; web sinh viên thấy PRM393 SE1801 và các môn khác.

## 5. Claude đã kiểm gì, chưa kiểm gì (10/11, 02:00 đến 02:30)

- [Fact] Trên Auth Emulator: tài khoản do script tạo, đăng nhập Google lần đầu vẫn giữ đúng uid, nên đúng dữ liệu; nạp lại lần hai vẫn giữ; nick đã từng đăng nhập Google trước khi nạp cũng nhận đúng dữ liệu; mật khẩu dự phòng vẫn dùng được; ba nick trùng nhau thì script dừng và báo lỗi.
- [Fact] Trên Firebase thật: app Android bản dev, nick 628, Google báo "Đã hủy đăng nhập" sau khi chọn tài khoản (không ghi gì vào dữ liệu).
- [Suy luận] Lỗi trên do chưa có SHA-1 trong project `attendo-app-2611`: `google-services.json` không có OAuth client Android nào, và SHA-1 debug của laptop chỉ từng thêm vào project cũ.
- [Chưa kiểm] Firebase thật có giữ uid như Emulator không, Google trên điện thoại sau khi thêm SHA-1, nút Google trên app Windows. Claude kiểm ngay sau khi thien làm mục 1 đến 3.
