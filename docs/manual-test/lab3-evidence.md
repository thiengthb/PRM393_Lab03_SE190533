# Chụp bằng chứng Firebase cho Lab 3

Hướng dẫn này để chụp các ảnh console mà đề Lab 3 bắt buộc nhưng `evidence/` còn trống: Authentication, Firestore, Analytics (DebugView), Remote Config trước và sau, Cloudinary. FCM và Crashlytics đã có ảnh từ 09/11 nên không chụp lại. Mất khoảng 25 phút. Bản code: nhánh `final-system` (commit `63d8cf9`), app trên điện thoại là bản dev hoặc APK Release `demo`.

Mọi bước trên console cần tài khoản của bạn nên mình chưa thử được, bước nào cũng là `(chưa thử)`. Mình viết theo giao diện Firebase console và Cloudinary đọc ngày 10/11/2026. Nút nào tên khác thì bạn chụp màn hình gửi mình, mình sửa file này.

## Chuẩn bị

**Làm hướng dẫn này trước khi chạy ARTEMIS.** ARTEMIS cài một bản app khác lên điện thoại (nối Firebase Emulator, đăng xuất nick 024), và đọc `qr_rotate_seconds` phải là 12. Nên chụp xong E1 đến E5, trả Remote Config về 12, rồi mới chạy ARTEMIS.

- [ ] Điện thoại đang đăng nhập nick **024** trong app Attendo, mở được Tổng quan có 4 lớp.
- [ ] Laptop mở Chrome bằng nick **628**, vào được https://console.firebase.google.com/project/attendo-app-2611/overview
- [ ] Tạo thư mục để lưu ảnh: mở PowerShell, gõ dòng dưới. Mọi ảnh bạn lưu vào đây, đặt **đúng tên ở cột "Lưu thành"**, mình tự chép vào repo.

```
mkdir $HOME\develop\evidence-inbox
```

Chụp màn hình trên laptop: bấm `Win+Shift+S`, kéo chọn vùng, bấm vào thông báo hiện ra ở góc phải, rồi bấm biểu tượng đĩa mềm (**Save**). Chụp trên điện thoại thì mình lấy ảnh qua cáp, bạn chỉ cần báo "chụp E3.2 rồi".

**Che email cá nhân:** repo đang công khai. Ở ảnh có email Gmail của bạn, mình sẽ làm mờ phần email trước khi commit, bạn không cần tự che.

## E1. Authentication: danh sách tài khoản `(chưa thử)`

1. Mở https://console.firebase.google.com/project/attendo-app-2611/authentication/users
2. Trang **Authentication**, tab **Users** ở hàng tab trên cùng.
3. Không bấm gì thêm.

**Thấy gì là đúng:** bảng có các dòng `nam@fe.edu.vn`, `tien102@fpt.edu.vn`, `giaovu@fe.edu.vn` và các nick Gmail. Cột **Providers** có biểu tượng thư (email) và biểu tượng chữ G (Google).

| Ảnh | Lưu thành |
|---|---|
| Cả bảng Users, thấy cột Providers | `auth-01-users.png` |

4. Bấm tab **Sign-in method** (cạnh tab Users).

**Thấy gì là đúng:** hai dòng **Email/Password** và **Google** đều ghi **Enabled**.

| Ảnh | Lưu thành |
|---|---|
| Danh sách Sign-in providers | `auth-02-providers.png` |

## E2. Firestore: dữ liệu thật `(chưa thử)`

1. Mở https://console.firebase.google.com/project/attendo-app-2611/firestore/databases/-default-/data
2. Cột trái là danh sách collection. Bấm **classes**, rồi bấm document đầu tiên ở cột giữa.

**Thấy gì là đúng:** cột phải có các trường `subject`, `code`, `lecturerId`, `status: "approved"`, `term: "Fall 2026"`.

| Ảnh | Lưu thành |
|---|---|
| Ba cột: collection, document, trường | `firestore-01-classes.png` |

3. Bấm tab **Rules** ở hàng tab trên cùng.

| Ảnh | Lưu thành |
|---|---|
| Nội dung Rules, thấy dòng `rules_version = '2';` | `firestore-02-rules.png` |

## E3. Analytics: DebugView `(chưa thử)`

DebugView chỉ hiện sự kiện từ máy đã bật chế độ debug. Bước 1 bật chế độ đó cho điện thoại.

1. Điện thoại cắm cáp. Trong PowerShell, gõ:

```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell setprop debug.firebase.analytics.app app.attendo
```

**Thấy gì là đúng:** lệnh chạy xong, không in gì.

2. Trên điện thoại: vuốt app Attendo khỏi đa nhiệm rồi mở lại (để app nhận chế độ debug).
3. Trên laptop, mở https://console.firebase.google.com/project/attendo-app-2611/analytics/debugview
   Ở góc trái trên, ô **Debug device** chọn **CPH1931** (nếu chưa thấy thì đợi 1 phút rồi tải lại trang).
4. Trên điện thoại, làm lần lượt (mỗi việc tạo một sự kiện):

| Làm trên điện thoại | Sự kiện |
|---|---|
| Tổng quan, bấm **Điểm danh** ở slot đang diễn ra | `attendance_session_open` |
| Bấm **Đóng mã**, rồi **Chốt** | `attendance_close` |
| Tab **Lớp**, bấm lớp PRM393 · SE1801 | `view_class` |
| Trong lớp đó, bấm biểu tượng **Xuất PDF** ở góc phải trên | `export_report` |
| Quay lại Tổng quan, mục **Vắng nhiều**, bấm em đầu tiên | `view_student` |

Nếu Tổng quan không còn slot đang diễn ra (đã chốt hết hoặc quá giờ), bạn nhắn mình: chạy lại workflow Demo với ô xoá dữ liệu được tick là có slot mới.

**Thấy gì là đúng:** cột giữa của DebugView (dòng thời gian) hiện lần lượt các tên sự kiện trên, chấm xanh.

| Ảnh | Lưu thành |
|---|---|
| Cả trang DebugView, thấy dòng thời gian có các sự kiện | `analytics-01-debugview.png` |
| Bấm vào sự kiện `attendance_close`: khung bên phải hiện tham số `present_count`, `absent_count`, `duration_sec` | `analytics-02-attendance-close.png` |
| Bấm vào sự kiện `export_report`: thấy `file_size_kb` | `analytics-03-export-report.png` |

5. Tắt chế độ debug khi xong:

```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell setprop debug.firebase.analytics.app .none.
```

**Dễ nhầm:** DebugView có thể chậm 10 đến 30 giây sau mỗi thao tác. Chưa thấy thì đợi, đừng làm lại.

## E4. Remote Config: trước và sau `(chưa thử)`

Đổi `qr_rotate_seconds` từ 12 lên 15 giây trên console, rồi xem app nhận giá trị mới, sau đó trả về 12.

1. Điện thoại: tab **Tài khoản** (biểu tượng bánh răng) → kéo xuống → **Khu demo**. Mục **Remote Config** ghi `qr_rotate_seconds 12s`.

| Ảnh | Lưu thành |
|---|---|
| (điện thoại) Khu demo, mục Remote Config, `qr_rotate_seconds 12s` | báo mình "chụp E4.1" |

2. Laptop: mở https://console.firebase.google.com/project/attendo-app-2611/config
3. Ở dòng **qr_rotate_seconds**, bấm biểu tượng bút chì (**Edit**) ở cuối dòng.
4. Ô **Default value** đổi thành:

```
15
```

5. Bấm **Save**. Rồi bấm nút xanh **Publish changes** ở góc phải trên, hộp thoại hiện ra thì bấm **Publish changes** lần nữa.

| Ảnh | Lưu thành |
|---|---|
| Bảng tham số sau khi Publish, dòng `qr_rotate_seconds` là 15 | `remote-config-01-console-15.png` |

6. Điện thoại: ở Khu demo bấm **Tải lại**.

**Thấy gì là đúng:** `qr_rotate_seconds 15s`, dòng **Lần tải** đổi sang giờ hiện tại. App có nghe cập nhật thời gian thực nên có khi chưa bấm đã đổi.

| Ảnh | Lưu thành |
|---|---|
| (điện thoại) Khu demo, `qr_rotate_seconds 15s` | báo mình "chụp E4.6" |

7. Trả lại như cũ: làm lại bước 3 đến 5 với giá trị `12`.

**Dễ nhầm:** bấm **Save** chưa đủ, phải **Publish changes** thì app mới thấy.

## E5. Cloudinary: file PDF đã tải lên `(chưa thử)`

Ở bước E3 bạn đã bấm **Xuất PDF**, nên đã có một file mới trên Cloudinary.

1. Mở https://console.cloudinary.com/ và đăng nhập tài khoản Cloudinary bạn tạo hôm 05/11.
2. Thanh bên trái, bấm **Assets** (giao diện cũ gọi là **Media Library**).
3. Ở ô lọc loại file phía trên, chọn **Raw** hoặc gõ `pdf` vào ô tìm kiếm.

**Thấy gì là đúng:** file PDF mới nhất có giờ tải lên trùng lúc bạn bấm Xuất PDF.

| Ảnh | Lưu thành |
|---|---|
| Danh sách Assets có file PDF mới | `storage-01-cloudinary.png` |

## Xong thì

Nhắn mình "xong E1 đến E5". Mình sẽ chép ảnh từ `evidence-inbox` vào đúng thư mục `evidence/`, làm mờ email, lấy ảnh điện thoại, và ghi README cho từng thư mục.

## Bảng kết quả

| Mục | Đạt / Sai | Ghi chú |
|---|---|---|
| E1 Authentication | | |
| E2 Firestore | | |
| E3 DebugView | | |
| E4 Remote Config | | |
| E5 Cloudinary | | |
