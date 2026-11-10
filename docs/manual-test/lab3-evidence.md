# Chụp bằng chứng Firebase cho Lab 3

Hướng dẫn này để chụp các ảnh console mà checklist đề Lab 3 bắt buộc nhưng `evidence/` còn thiếu: Authentication, Firestore, đủ 13 sự kiện trên DebugView, hai tham số Remote Config đổi hành vi app, Cloudinary, khoá tuỳ chỉnh Crashlytics. FCM và Crashlytics (lỗi, crash) đã có ảnh từ 09/11. Mất khoảng 45 phút. Bản code: nhánh `final-system` (commit `63d8cf9`), app trên điện thoại là bản dev hoặc APK Release `demo`.

Mọi bước trên console cần tài khoản của bạn nên mình chưa thử được, bước nào cũng là `(chưa thử)`. Mình viết theo giao diện Firebase console và Cloudinary đọc ngày 10/11/2026. Nút nào tên khác thì bạn chụp màn hình gửi mình, mình sửa file này.

**Đọc hết một mục trước khi bấm.** Ảnh cần chụp ghi bằng dòng 📸 ngay tại bước đó. Lỡ đi quá bước chụp cũng không sao: mọi bước ở đây làm lại được (DebugView giữ sự kiện 30 phút, Remote Config đổi qua lại được, trang console mở lại là chụp được).

## Chuẩn bị

**ARTEMIS tạm dừng (10/11 11:17) chờ thầy trả lời.** Khi chạy lại ARTEMIS, Remote Config phải là `qr_rotate_seconds = 12`, `absence_limit_percent = 20` như mặc định, nên nhớ trả về sau E4.

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

## E3. Analytics: đủ 13 sự kiện trên DebugView `(chưa thử)`

Đề ghi "every event seen in DebugView", nên cần thấy đủ 13 sự kiện trong `docs/analytics-plan.md`. Làm theo đúng thứ tự dưới đây thì mỗi sự kiện hiện ra một lần.

**E3.0 Cài lại app thật lên điện thoại.** Sáng nay ARTEMIS cài một bản app nối Firebase Emulator, nên phải thay bằng bản nối Firebase thật. Trong PowerShell gõ lần lượt:

```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell pm clear app.attendo
```

**Thấy gì là đúng:** in ra `Success` (công tắc "Tắt giám sát quyền" bật từ sáng nên lệnh này chạy được).

```
powershell -ExecutionPolicy Bypass -File $HOME\develop\attendo\tool\dev\dev.ps1 -Target phone -Branch final-system
```

**Thấy gì là đúng:** khoảng 3 phút sau app mở ở màn đăng nhập. Để nguyên cửa sổ này.

**E3.1 Bật DebugView cho điện thoại và chép file lớp mẫu** (mở một cửa sổ PowerShell khác):

```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell setprop debug.firebase.analytics.app app.attendo
```

```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" push $HOME\develop\attendo\mobile\sample-data\lop-fall-2026.csv /sdcard/Download/
```

**Thấy gì là đúng:** lệnh thứ hai in ra `1 file pushed`.

**E3.2 Mở DebugView:** https://console.firebase.google.com/project/attendo-app-2611/analytics/debugview , ô **Debug device** ở góc trái trên chọn **CPH1931** (chưa thấy thì đợi 1 phút rồi tải lại trang).

**E3.3 Làm lần lượt trên điện thoại.** Làm hết 11 việc rồi mới chụp ở E3.3b: không cần chụp giữa chừng, vì DebugView giữ mọi sự kiện của 30 phút gần nhất. Thiếu sự kiện nào thì làm lại riêng việc đó (đăng ký lại thì dùng `+demo2`, `+demo3`).

| # | Làm | Sự kiện |
|---|---|---|
| 1 | Màn đăng nhập → **Đăng ký** → điền bảng dưới → **Tạo tài khoản**; mở Gmail nick 697 trên laptop, bấm link xác nhận trong thư Firebase gửi; quay lại app bấm **Xác nhận** | `sign_up` |
| 2 | Tài khoản → **Nhập danh sách lớp** → chọn file `lop-fall-2026.csv` trong Download → **Nhập** | `import_classes` |
| 3 | Tài khoản → **Đăng xuất** | `logout` |
| 4 | **Đăng nhập với Google** → nick 024 | `login` |
| 5 | Tổng quan → **Điểm danh** ở slot đang diễn ra | `attendance_session_open` |
| 6 | **Đóng mã** → **Chốt** | `attendance_close` |
| 7 | Tab **Lớp** → PRM393 · SE1801 | `view_class` |
| 8 | Trong lớp đó, biểu tượng **Xuất PDF** ở góc phải trên | `export_report` |
| 9 | Tổng quan → mục **Vắng nhiều** → em đầu tiên | `view_student` |
| 10 | Trong hồ sơ em đó → **Nhắc nhở** → **Gửi** | `reminder_send` |
| 11 | Tổng quan → ô **yêu cầu sửa** → một yêu cầu → **Duyệt** | `correction_review` |

Bảng điền ở bước 1:

| Ô | Điền |
|---|---|
| Họ tên | `Giảng viên thử` |
| Email | `tranngocthien697+demo1@gmail.com` |
| Mật khẩu | `Demo@123` |

Tài khoản có `+demo` sẽ tự bị xoá ở lần nạp lại dữ liệu sau, nên không làm bẩn dữ liệu demo.

**E3.3b Chụp.** Ô **Debug Device** (mũi tên tam giác nhỏ dưới chữ Debug Device) chọn dòng có **CPH1931** hoặc **OPPO**. **Thấy gì là đúng:** cột giữa DebugView hiện lần lượt 11 sự kiện trên. 📸

| Ảnh | Lưu thành |
|---|---|
| DebugView, dòng thời gian có các sự kiện từ `sign_up` tới `correction_review` (chụp 2 ảnh nếu dài) | `analytics-01-debugview.png`, `analytics-02-debugview.png` |
| Bấm sự kiện `attendance_close`, khung phải hiện `present_count`, `absent_count`, `duration_sec` | `analytics-03-attendance-close.png` |

**E3.4 Hai sự kiện của sinh viên trên web** `(chưa thử)`: `qr_scan` và `correction_submit` xảy ra trên web sinh viên. Web không dùng được lệnh `adb` ở trên, nên bật chế độ debug bằng tiện ích Chrome:

1. Mở https://chromewebstore.google.com/search/Google%20Analytics%20Debugger , cài **Google Analytics Debugger**, ghim biểu tượng lên thanh công cụ.
2. Mở https://attendo-app-2611.web.app , bấm biểu tượng tiện ích cho nó chuyển sang **ON**, tải lại trang, đăng nhập Google nick 697.
3. **Nhập mã điểm danh** → gõ một mã sai bất kỳ, ví dụ `000000` → **Gửi** (sự kiện `qr_scan`, kết quả `wrongCode`).
4. Mở PRM393 · SE1801 → một buổi **Vắng** còn nút **Báo sai** → chọn lý do → **Gửi** (sự kiện `correction_submit`).
5. DebugView: ô **Debug device** chọn thiết bị mới (trình duyệt Chrome).

| Ảnh | Lưu thành |
|---|---|
| DebugView có `qr_scan` và `correction_submit` | `analytics-04-web-student.png` |

**Nếu web không hiện trên DebugView** (đề đòi ảnh DebugView, trang Realtime không thay được), thử lần lượt:
1. Biểu tượng tiện ích phải ghi **ON**. Bấm lại cho ON rồi tải lại trang bằng **Ctrl+Shift+R**.
2. Tắt trình chặn quảng cáo (uBlock, AdBlock, Brave Shields) cho trang `attendo-app-2611.web.app`: chúng chặn luôn Analytics.
3. Dùng cửa sổ Chrome thường, không dùng ẩn danh (tiện ích mặc định không chạy trong ẩn danh).
4. Làm lại bước 3, 4 ở trên, đợi 30 giây. Ô **Debug device** có thêm một dòng mới (tên trình duyệt hoặc một mã ngẫu nhiên): chọn dòng đó.
5. Vẫn không thấy thì báo mình, đừng chụp ảnh khác để thay.

**E3.5 Tắt chế độ debug khi xong:**

```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell setprop debug.firebase.analytics.app .none.
```

**Dễ nhầm:** DebugView chậm 10 đến 30 giây. Chưa thấy thì đợi, đừng làm lại.

## E4. Remote Config: hai tham số đổi hành vi app (đã làm 10/11, ảnh ở `evidence/remote-config/`)

Đề ghi "Two Remote Config values change the app without a rebuild". Đổi hai tham số cùng lúc: `qr_rotate_seconds` 12 → 15 (mã QR đổi chậm hơn) và `absence_limit_percent` 20 → 30 (ngưỡng vắng cao hơn, danh sách Vắng nhiều ngắn lại).

1. 📸 **Chụp trước khi đổi gì trên console.** Điện thoại: Tổng quan, nhìn mục **Vắng nhiều**: số em và mức "3/4", "6/4". Rồi **Tài khoản** → **Khu demo**, mục Remote Config ghi `qr_rotate_seconds 12s`, `absence_limit_percent 20%`. Nếu đã lỡ đổi, trả về `12`, `20`, Publish, bấm Tải lại rồi chụp.

| Ảnh | Lưu thành |
|---|---|
| (điện thoại) Tổng quan, mục Vắng nhiều | báo mình "chụp E4.1a" |
| (điện thoại) Khu demo, mục Remote Config | báo mình "chụp E4.1b" |

2. Laptop: https://console.firebase.google.com/project/attendo-app-2611/config
3. Dòng **qr_rotate_seconds** → biểu tượng bút chì (**Edit**) ở cuối dòng → ô **Default value** điền `15` → **Save**.
4. Dòng **absence_limit_percent** → **Edit** → điền `30` → **Save**.
5. 📸 Bấm nút xanh **Publish changes** ở góc phải trên, hộp thoại hiện ra thì bấm **Publish changes** lần nữa, rồi chụp ngay.

| Ảnh | Lưu thành |
|---|---|
| Bảng tham số sau khi Publish, hai dòng là 15 và 30 | `remote-config-01-console.png` |

6. 📸 Điện thoại: Khu demo bấm **Tải lại**, rồi về Tổng quan.

**Thấy gì là đúng:** Khu demo ghi `15s` và `30%`; mục Vắng nhiều ít em hơn (ngưỡng 30% của 20 buổi là 6 buổi thay vì 4). Ảnh Khu demo ghi `15s` chỉ cho thấy app đã nhận giá trị; bằng chứng hành vi là màn phiên đếm **Đổi mã 15s**. Phiên giữ chu kỳ của lúc mở, nên phải làm E4 **trước** khi bấm Điểm danh ở E3 (và trước việc 6 Chốt); không thì cần một slot đang diễn ra khác (chạy lại workflow Demo có tick xoá dữ liệu). Thứ tự đúng ở `VIEC-CON-LAI.md` phần 4.

| Ảnh | Lưu thành |
|---|---|
| (điện thoại) Khu demo `15s`, `30%` | báo mình "chụp E4.6a" |
| (điện thoại) Tổng quan, mục Vắng nhiều sau khi đổi | báo mình "chụp E4.6b" |

7. 📸 Điện thoại: Tổng quan → bấm **Điểm danh** ở thẻ Đang diễn ra. Dòng dưới mã ghi **Đổi mã 15s** (đếm từ 15 xuống). Nếu làm theo `VIEC-CON-LAI.md` thì đây là phần 4c (chụp kèm DebugView `attendance_session_open`).

| Ảnh | Lưu thành |
|---|---|
| (điện thoại) màn phiên, **Đổi mã 15s** | báo mình "chụp E4 phiên" |

8. Chụp xong bước 7 mới trả lại như cũ: làm lại bước 3 đến 5 với `12` và `20`.

**Dễ nhầm:** bấm **Save** chưa đủ, phải **Publish changes** thì app mới thấy.

## E5. Cloudinary: file PDF đã tải lên (đã làm 10/11, ảnh ở `evidence/storage/`)

Ở bước E3 bạn đã bấm **Xuất PDF**, nên đã có một file mới trên Cloudinary.

1. Mở https://console.cloudinary.com/ và đăng nhập tài khoản Cloudinary bạn tạo hôm 05/11.
2. Thanh bên trái, bấm **Assets** (giao diện cũ gọi là **Media Library**).
3. Ở ô lọc loại file phía trên, chọn **Raw** hoặc gõ `pdf` vào ô tìm kiếm.

**Thấy gì là đúng:** file PDF mới nhất có giờ tải lên trùng lúc bạn bấm Xuất PDF.

| Ảnh | Lưu thành |
|---|---|
| Danh sách Assets có file PDF mới | `storage-01-cloudinary.png` |

## E6. Crashlytics: khoá tuỳ chỉnh (đã làm 11/11, `evidence/crashlytics/04-keys.png`)

Đề ghi "Crashlytics shows a non-fatal error and a test crash with keys". Ảnh 09/11 đã có lỗi và crash, còn thiếu ảnh khoá tuỳ chỉnh (`role`, `term`, `last_error_where`).

1. Mở https://console.firebase.google.com/project/attendo-app-2611/crashlytics
2. Bấm vào issue **FirebaseCrashlyticsTestCrash** (hoặc issue non-fatal `demo_import_parse`).
3. Trong trang issue, tab **Keys** (cạnh tab **Stack trace**, **Logs**).

**Thấy gì là đúng:** bảng khoá có `role = lecturer`, `term = Fall 2026`.

| Ảnh | Lưu thành |
|---|---|
| Tab Keys của issue | `crashlytics-04-keys.png` |

## Xong thì

Nhắn mình "xong E1 đến E6". Mình sẽ chép ảnh từ `evidence-inbox` vào đúng thư mục `evidence/`, làm mờ email, lấy ảnh điện thoại, và ghi README cho từng thư mục.

## Bảng kết quả

| Mục | Đạt / Sai | Ghi chú |
|---|---|---|
| E1 Authentication | | |
| E2 Firestore | | |
| E3 DebugView | | |
| E4 Remote Config | | |
| E5 Cloudinary | | |
| E6 Crashlytics keys | | |
