# FAP Attendance Extension

Extension Chrome/Edge (Manifest V3, side panel) giúp giảng viên **xem trước, điền và kiểm tra** điểm
danh trên trang điểm danh dạng FAP. Giảng viên luôn tự bấm Save. Dự án tách ra từ
`fap-attendance-assistant` (Lab 1), nay là một phần của hệ thống Attendo: nguồn **Attendo** đọc bản
điểm danh giảng viên đã chốt trên app Attendo, thẳng từ Firestore, không qua máy chủ riêng.

> Phạm vi hiện tại: FAP giả lập `mock-fap-v2` (`../fap-mock`, chạy ở `https://hereby-se190533.web.app/fap/`)
> và file HTML điểm danh đã lưu (`file://`). FAP trực
> tuyến bị tắt cho đến khi có cho phép chính thức (xem `docs/decisions.md` D-001).

## Tính năng

- **Bốn nguồn dữ liệu:**
  - **Attendo:** đăng nhập tài khoản giảng viên Attendo, chọn slot đã chốt cùng môn, lớp với trang.
  - **Tệp:** CSV/TSV/XLSX, gồm cả tab review xuất từ Lecturer Desktop.
  - **Google Sheets:** chỉ đọc.
  - **Thủ công:** sửa trực tiếp từ trạng thái đang có trên trang.
- **Đối chiếu chặt:**
  - Kiểm tra lớp, môn, ngày, slot, phòng và campus nếu nguồn có các thông tin đó.
  - Danh sách sinh viên phải khớp tuyệt đối. Thiếu, dư, trùng mã hoặc trạng thái lạ đều bị dừng.
  - Ngoại lệ có chủ đích: với nguồn Tệp và Sheets, có thể bật **"Sinh viên không có trong nguồn:
    giữ trạng thái hiện tại"** để nhập tệp chỉ liệt kê một phần lớp (ví dụ chỉ người vắng). Mã ngoài
    danh sách trang vẫn bị từ chối; bản đã duyệt từ máy chủ luôn phải đủ.
- **Bản nháp chỉnh được:**
  - Tìm kiếm sinh viên.
  - Đặt hàng loạt có mặt/vắng, cho toàn bộ hoặc chỉ các dòng đang lọc.
  - Đánh dấu những dòng sẽ thay đổi.
- **An toàn khi điền:** phải tick "Tôi đã kiểm tra..." mới điền được. Ngay trước khi ghi, extension
  đọc lại toàn bộ trang và sau khi điền thì kiểm tra lại từng dòng. Chuyển tab hoặc tải lại trang
  thì bản nháp bị hủy.
- **Tải tệp mẫu:** xuất CSV từ trang đang mở để điền offline rồi nhập lại.

## Cài đặt (bản build sẵn)

1. Giải nén `release/fap-attendance-extension-<version>.zip`.
2. Mở `chrome://extensions` hoặc `edge://extensions` và bật **Developer mode**.
3. Bấm **Load unpacked**, chọn thư mục vừa giải nén.
4. Ghim extension. Bấm biểu tượng hoặc `Alt+Shift+F` để mở side panel.
5. Nếu dùng file HTML đã lưu: vào **Chi tiết** của extension, bật **Cho phép truy cập URL tệp**.

## Sử dụng

1. Mở trang điểm danh (FAP giả lập hoặc file HTML), bấm **Đọc trang**.
2. Chọn nguồn:
   - **Attendo:** đăng nhập bằng email và mật khẩu Attendo. Extension tìm các slot đã chốt cùng môn
     và lớp với trang (slot trùng ngày, slot được chọn sẵn), rồi bấm **Lấy bản đã chốt**. Chỉ slot
     của chính giảng viên đọc được (Security Rules của Attendo).
   - **Tệp:** cần cột mã sinh viên (`STUDENT_CODE`, `Roll Number` hoặc `MSSV`) và cột trạng thái
     (`FINAL_STATUS`, `Status` hoặc `Trạng thái`). Giá trị nhận được: `ATTEND`/`ABSENT`,
     `Có mặt`/`Vắng`, `Present`/`Absent`, `1`/`0`.
   - **Sheets:** dán link có `#gid=` của tab cần đọc.
   - **Thủ công:** bắt đầu từ trạng thái hiện có trên trang.
3. Rà soát bản nháp và sửa nếu cần, tick xác nhận, rồi bấm **Chỉ điền** (hoặc **Điền và lưu giả
   lập** trên fixture).
4. Kiểm tra lại trang và **tự bấm Save trên FAP**.

## Phát triển

```powershell
npm install
copy .env.example .env.local   # tùy chọn: ghi đè cấu hình
npm run dev                    # HMR; load thư mục dist/ unpacked một lần
npm run check                  # typecheck, lint, prettier, test, build, kiểm tra dist
npm run package                # tạo release/*.zip kèm SHA-256
```

| Biến                        | Ý nghĩa                                                                      |
| --------------------------- | ---------------------------------------------------------------------------- |
| `VITE_HEREBY_API_KEY`       | Web API key Firebase của Attendo (công khai); để trống thì tắt nguồn Attendo |
| `VITE_HEREBY_PROJECT_ID`    | Project Firebase, mặc định `hereby-se190533`                                 |
| `VITE_FIXTURE_ORIGINS`      | Origin của FAP giả lập (bắt buộc https, trừ localhost)                       |
| `VITE_GOOGLE_CLIENT_ID`     | OAuth client loại Web, redirect `https://<extension-id>.chromiumapp.org/`    |
| `VITE_EXTENSION_PUBLIC_KEY` | Giữ extension ID cố định, cần cho OAuth khi load unpacked                    |

Tài liệu:

- `AGENTS.md`: các quy tắc bất biến.
- `docs/00-map.md`: luồng chạy và vai trò từng file.
- `docs/decisions.md`: các quyết định kiến trúc.
- `docs/privacy.md`: quyền extension xin và cách xử lý dữ liệu.
