# Tạo Firebase project mới cho Attendo

09/11/2026 · Claude viết, thien làm · khoảng 40 phút · theo quyết định [001](../decisions/001-firebase-moi-va-ma-app.md)

Các bước trên console Firebase, Google Cloud và Cloudinary cần tài khoản của bạn nên Claude chưa thử được; mỗi bước có ghi `(chưa thử)`. Chữ trên nút lấy theo giao diện tiếng Anh của console tháng 11/2026, kèm chữ tiếng Việt nếu console của bạn hiện tiếng Việt. Bước nào không ra đúng dòng "Đúng khi", chụp màn hình gửi Claude, đừng tự sửa.

Bạn chỉ cần làm trên trình duyệt. Mọi giá trị cấu hình bạn lưu vào một thư mục trên laptop, Claude tự đọc từ đó rồi đưa vào code.

## Tên đã đặt sẵn

| Thứ | Tên |
|---|---|
| Tên project | `Attendo` |
| Mã project | `attendo-app` (nếu bị trùng: `attendo-app-2611`) |
| Mã app Android | `app.attendo` |
| Web app cho sinh viên, màn chiếu TV và app Windows | `Attendo Web` |
| Web app cho quản trị | `Attendo Admin` |
| Thư mục lưu cấu hình trên laptop | `C:\Users\trann\develop\attendo-config` |
| Preset Cloudinary | `attendo_reports` |

Tạo sẵn thư mục cấu hình: mở File Explorer → vào `C:\Users\trann\develop` → chuột phải chỗ trống → **New → Folder** → gõ `attendo-config` → Enter.

## Bước 1. Tạo project (5 phút) (chưa thử)

1. Trình duyệt đăng nhập **tranngocthien024@gmail.com** (tài khoản sở hữu project cũ). Mở [Firebase console](https://console.firebase.google.com/).
2. Bấm **Create a new Firebase project** (**Tạo dự án Firebase mới**).
3. Ô **Project name**: gõ
   ```
   Attendo
   ```
   Ngay dưới ô tên có dòng mã project (dạng `attendo-1a2b3`). Bấm biểu tượng bút cạnh dòng đó, xoá hết, gõ
   ```
   attendo-app
   ```
   Nếu báo đã có người dùng, gõ `attendo-app-2611`. Tick ô đồng ý điều khoản → **Continue**.
4. Màn **AI assistance / Gemini in Firebase**: để mặc định → **Continue**.
5. Màn **Google Analytics**: bật **Enable Google Analytics for this project** → **Continue**. Ô **Analytics location** chọn **Vietnam**, tick các ô đồng ý → **Create project**. Đợi khoảng 30 giây → **Continue**.

Đúng khi: trang tổng quan ghi **Attendo**, và thanh địa chỉ có `console.firebase.google.com/project/attendo-app/...` (hoặc mã bạn đặt). Ghi lại mã project.

## Bước 2. Firestore (2 phút) (chưa thử)

1. Thanh bên trái → **Databases & Storage** (hoặc **Build**) → **Firestore Database** → **Create database**.
2. Chọn **Standard edition** → **Next**. Ô **Location**: chọn **asia-southeast1 (Singapore)** → **Next**.
3. Chọn **Start in production mode** → **Create**.

Đúng khi: trang Firestore hiện tab **Data** trống. Security Rules thật sẽ do workflow đẩy lên ở bước 9.

**Dễ nhầm:** vị trí không đổi được sau khi tạo. Chọn đúng Singapore để điện thoại ở Việt Nam đọc nhanh.

## Bước 3. Đăng nhập (3 phút) (chưa thử)

1. Thanh bên trái → **Security** (hoặc **Build**) → **Authentication** → **Get started**.
2. Tab **Sign-in method** → **Email/Password** → bật công tắc trên cùng (**Enable**), để tắt dòng "Email link" → **Save**.
3. **Add new provider** → **Google** → bật **Enable** → ô **Support email for project** chọn tranngocthien024@gmail.com → **Save**.

Đúng khi: bảng Sign-in providers có hai dòng **Email/Password** và **Google**, cả hai ghi **Enabled**.

4. Bấm lại dòng **Google** → mở mục **Web SDK configuration** → chép ô **Web client ID** (dạng `1234...-abc.apps.googleusercontent.com`) → mở Notepad → Ctrl+V → **Save As** vào `C:\Users\trann\develop\attendo-config` với tên `google-web-client-id.txt`.

Đúng khi: thư mục `attendo-config` có file `google-web-client-id.txt` chứa một dòng kết thúc bằng `.apps.googleusercontent.com`. (App Android cần mã này để đăng nhập Google.)

## Bước 4. App Android (5 phút) (chưa thử)

1. Bấm biểu tượng bánh răng cạnh **Project Overview** (trên cùng thanh bên trái) → **Project settings** → tab **General** → kéo xuống **Your apps** → bấm biểu tượng Android.
2. Điền:

   | Ô | Điền |
   |---|---|
   | Android package name | `app.attendo` |
   | App nickname | `Attendo Android` |
   | Debug signing certificate SHA-1 | để trống (Claude thêm sau, khi có SHA-1 của bản dựng) |

3. **Register app** → **Download google-services.json**. Lưu file vào `C:\Users\trann\develop\attendo-config` (giữ đúng tên `google-services.json`).
4. Bấm **Next** ba lần rồi **Continue to console**, bỏ qua các bước sửa Gradle (code đã có sẵn).

Đúng khi: thư mục `attendo-config` có file `google-services.json`, mở bằng Notepad thấy dòng `"package_name": "app.attendo"`.

## Bước 5. Hai web app (5 phút) (chưa thử)

Làm hai lần, lần một tên `Attendo Web`, lần hai tên `Attendo Admin`:

1. Vẫn ở **Project settings → General → Your apps** → **Add app** → biểu tượng web `</>`.
2. Ô **App nickname**: gõ tên. **Không** tick "Also set up Firebase Hosting" (workflow tự làm) → **Register app**.
3. Màn hiện khối code có `const firebaseConfig = { ... };`. Bôi đen từ `const firebaseConfig` đến dấu `};` → Ctrl+C.
4. Mở Notepad → Ctrl+V → **File → Save As** → vào `C:\Users\trann\develop\attendo-config` → ô **File name**: lần một gõ `web-student.txt`, lần hai gõ `web-admin.txt` → **Save**.
5. Bấm **Continue to console**.

Đúng khi: thư mục `attendo-config` có `web-student.txt` và `web-admin.txt`, mỗi file có dòng `projectId` đúng mã project và một dòng `measurementId: "G-..."`.

Các giá trị này là cấu hình công khai, được phép đưa vào repo; quyền đọc ghi dữ liệu do Security Rules quyết định.

## Bước 6. AI Logic cho nút Gợi ý AI (2 phút) (chưa thử)

1. Thanh bên trái → **AI** → **AI Logic** → **Get started**.
2. Chọn **Gemini Developer API** (gói miễn phí) → **Get started** / **Enable API**.

Đúng khi: trang AI Logic hiện **Gemini Developer API** ở trạng thái đã bật.

## Bước 7. Khoá cho GitHub (10 phút) (chưa thử)

Giống lần trước, chỉ khác project. Khoá có quyền lớn: không gửi file cho ai, không dán vào chat.

1. **Project settings** → tab **Service accounts** → **Generate new private key** → **Generate key**. File `attendo-app-firebase-adminsdk-....json` tải về Downloads.
2. Mở file bằng Notepad → Ctrl+F gõ `client_email` → chép phần trong ngoặc kép ngay sau (dạng `firebase-adminsdk-xxxxx@attendo-app.iam.gserviceaccount.com`).
3. Mở [Google Cloud IAM](https://console.cloud.google.com/iam-admin/iam) → ô chọn project trên cùng chọn **Attendo** → **Grant access** → ô **New principals**: dán tên vừa chép → **Select a role**: `Firebase Admin` → **Add another role** → `Service Usage Consumer` → **Save**.
4. Quay lại Notepad → Ctrl+A → Ctrl+C. Mở [GitHub Secrets](https://github.com/thiengthb/PRM393_Lab03_SE190533/settings/secrets/actions) → dòng `FIREBASE_SERVICE_ACCOUNT` → biểu tượng bút (**Update**) → ô Value: Ctrl+V → **Update secret**.
5. Xoá file .json trong Downloads, dọn thùng rác.

Đúng khi: trang IAM có dòng mang tên khoá, cột Role có **Firebase Admin** và **Service Usage Consumer**; trang Secrets ghi `FIREBASE_SERVICE_ACCOUNT` vừa cập nhật.

## Bước 8. Preset Cloudinary cho file PDF (2 phút) (chưa thử)

1. Đăng nhập [Cloudinary](https://console.cloudinary.com/) (tài khoản đang dùng cho app, cloud `twdfd7sq`).
2. Biểu tượng bánh răng (**Settings**) góc dưới trái → **Upload** → mục **Upload presets** → **Add Upload Preset**.
3. Điền:

   | Ô | Điền hoặc chọn |
   |---|---|
   | Upload preset name | `attendo_reports` |
   | Signing mode | **Unsigned** |
   | Asset folder | `attendo/reports` |

4. **Save**.

Đúng khi: danh sách Upload presets có `attendo_reports`, cột Mode ghi **Unsigned**.

## Bước 9. Báo Claude, rồi bấm deploy (1 phút + đợi 10 phút)

1. Nhắn Claude: "Firebase mới xong, mã project là ...". Claude đọc bốn file trong `attendo-config`, đưa cấu hình vào code, đổi mã app Android, tách Hosting thành 4 trang (sinh viên, quản trị, màn chiếu TV, FAP giả), rồi báo bạn chạy workflow.
2. Khi Claude báo: mở [Actions → Demo: Firebase thật](https://github.com/thiengthb/PRM393_Lab03_SE190533/actions/workflows/demo-firebase.yml) → **Run workflow** → Branch: nhánh Claude ghi → tick cả hai ô → ô **admin_email**: Gmail bạn dùng cho web admin → **Run workflow**.

Đúng khi: dấu tick xanh, phần **Summary** có 4 link web và dòng "Xong. Giảng viên quanm@fe.edu.vn ...".

## Bước 10. Tên miền được phép đăng nhập (2 phút) (chưa thử)

Làm sau bước 9 (lúc đó 4 trang web đã có địa chỉ).

1. **Authentication** → tab **Settings** → **Authorized domains** → **Add domain**.
2. Thêm lần lượt (thay `attendo-app` bằng mã project nếu khác):
   ```
   attendo-app-admin.web.app
   ```
   ```
   attendo-app-tv.web.app
   ```
   ```
   attendo-app-fap.web.app
   ```

Đúng khi: danh sách có `localhost`, `attendo-app.firebaseapp.com`, `attendo-app.web.app` và ba dòng vừa thêm.

## Project cũ

Project `hereby-se190533` để nguyên, không xoá cho tới khi nộp bài xong (phòng khi cần quay lại). Sau ngày 13/11 có thể xoá ở **Project settings → General → Delete project**.
