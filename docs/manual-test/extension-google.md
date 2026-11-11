# Bật và test "Đăng nhập bằng Google" trên extension

Claude đã thử ngày 11/11/2026 trên Firebase Emulator (Google giả lập, bằng Playwright): nút Google vào đúng giảng viên mẫu và thấy danh sách slot đã chốt; Gmail không có hồ sơ giảng viên bị chặn với câu "Tài khoản không có quyền giảng viên."; đăng nhập mật khẩu vẫn chạy. Bước 1 và các ca test trên Google thật cần tài khoản của bạn nên mình **chưa thử**; bước 1 viết theo giao diện Google Cloud Console mình biết, chưa mở được trang vì cần đăng nhập.

Cần làm một lần: thêm một địa chỉ chuyển hướng vào OAuth client Web của Firebase (bước 1), rồi cài lại extension (bước 2, 3). ID extension giờ cố định là `cdommjocjfpplaaclgdcdhnkckidhjei` nên địa chỉ này không đổi giữa các máy.

## Bước 1. Thêm redirect URI cho OAuth client (chưa thử)

1. Mở https://console.cloud.google.com/apis/credentials?project=attendo-app-2611 bằng nick Google sở hữu project `attendo-app-2611` (nick bạn dùng mở Firebase console).
2. Mục **OAuth 2.0 Client IDs**, bấm tên **Web client (auto created by Google Service)**. Client ID của nó bắt đầu bằng `469635173870-kd2qljn0a3`.
3. Kéo xuống mục **Authorized redirect URIs**, bấm **+ ADD URI** (hoặc **+ Add URI**), dán:
   ```
   https://cdommjocjfpplaaclgdcdhnkckidhjei.chromiumapp.org/
   ```
4. Bấm **SAVE** (cuối trang).

Đúng khi: quay lại trang client thấy dòng mới trong **Authorized redirect URIs**, các dòng cũ (`https://attendo-app-2611.firebaseapp.com/__/auth/handler`...) vẫn còn.

Dễ nhầm: đừng xoá hay sửa các URI cũ, web sinh viên và web admin đang dùng chúng. Phải có dấu `/` ở cuối. Google ghi chú thay đổi có thể mất từ 5 phút đến vài giờ mới có hiệu lực.

## Bước 2. Tải bản extension mới

1. Mở https://github.com/thiengthb/PRM393_Lab03_SE190533/actions/workflows/ci.yml?query=branch%3Aclaude%2Fproject-thread-qkughb (sau khi gộp PR thì đổi `claude%2Fproject-thread-qkughb` thành `final-system`).
2. Bấm lần chạy trên cùng có tick xanh.
3. Kéo xuống cuối trang, mục **Artifacts**, bấm **attendo-extension** để tải file zip.
4. Chuột phải file zip, **Extract All...**, giải nén vào:
   ```
   C:\Attendo-extension-google
   ```

Đúng khi: trong `C:\Attendo-extension-google` có file `manifest.json`.

## Bước 3. Thay extension cũ trong Chrome

1. Gõ vào thanh địa chỉ Chrome: `chrome://extensions`
2. Ở thẻ **Attendo cho FAP** cũ bấm **Remove**, hộp thoại bấm **Remove**.
3. Bật **Developer mode** (góc phải trên) nếu chưa bật, bấm **Load unpacked**, chọn thư mục `C:\Attendo-extension-google`, bấm **Select Folder**.

Đúng khi: thẻ **Attendo cho FAP** hiện dòng **ID: cdommjocjfpplaaclgdcdhnkckidhjei**.

Dễ nhầm: phải Remove bản cũ chứ không bấm Reload. Bản cũ có ID khác, Google sẽ từ chối địa chỉ chuyển hướng của nó.

## Các ca test

| Mã | Làm | Mong đợi |
|---|---|---|
| TC01 | Mở [FAP giả lập](https://attendo-app-2611-fap.web.app/fap/), chọn ngày và lớp có slot đã chốt, mở extension, **Đọc trang**, tab **Attendo**, bấm **Đăng nhập bằng Google**, chọn nick giảng viên 024 | Cửa sổ Google hiện danh sách tài khoản; chọn xong cửa sổ tự đóng, khung extension hiện tên giảng viên "Nguyễn Minh Quân", email 024 và ô **Slot đã chốt** |
| TC02 | Từ TC01 bấm **Lấy bản đã chốt** | Ô **3 Kiểm tra bản nháp** hiện số Sĩ số, Có mặt, Vắng giống như khi đăng nhập bằng mật khẩu |
| TC03 | Bấm **Đăng xuất**, đăng nhập lại bằng email 024 và mật khẩu `Demo@123` | Vào được như TC01 (đăng nhập mật khẩu vẫn chạy) |
| TC04 | Bấm **Đăng xuất**, bấm **Đăng nhập bằng Google**, rồi đóng cửa sổ Google không chọn tài khoản | Khung báo "Chưa đăng nhập được Google (cửa sổ bị đóng hoặc bị Google chặn)." |
| TC05 | Bấm **Đăng nhập bằng Google**, chọn nick sinh viên 697 | Khung báo "Tài khoản không có quyền giảng viên.", không vào được |

Nếu lỗi: cửa sổ Google hiện **Error 400: redirect_uri_mismatch** thì bước 1 chưa lưu, chưa có hiệu lực, hoặc extension vẫn là bản cũ (xem ID ở bước 3).

## Bảng kết quả

| Mã | Đạt / Sai | Ghi chú |
|---|---|---|
| TC01 | | |
| TC02 | | |
| TC03 | | |
| TC04 | | |
| TC05 | | |
