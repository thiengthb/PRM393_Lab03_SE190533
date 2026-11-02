# Gap review · Lab 2 + Lab 3 → Final

> Giai đoạn 1 của đề Final. Soát ngày 02/11/2026 trên repo Lab 3 (commit `5435678`). “Đóng” nghĩa là mã đã viết và phân tích tĩnh sạch; những gì chỉ chứng minh được khi chạy thật nằm ở cột “Còn phải làm”, không tính là xong cho tới khi có bằng chứng trong `evidence/`.

## 1. Khoảng trống so với đề Final

| # | Đề yêu cầu | Lab 3 có gì | Cách đóng | Trạng thái |
|---|---|---|---|---|
| G-01 | `packages/core/`, `mobile/`, `web/` dùng chung một gói | Một project ở gốc repo | Tách monorepo: model, service Firestore, theme, widget vào core | Đóng |
| G-02 | Web admin 4 màn + form thông báo, trên Hosting | Chưa có | `web/`: Đăng nhập, Tổng quan, Duyệt lớp, Môn học, Thông báo, thêm Người dùng cho Admin | Đóng mã; còn deploy |
| G-03 | Vai trò `users/{uid}.role`, chỉ Admin đổi vai trò | Chỉ có lecturer, student | Thêm staff, admin, user; Rules chặn tự đổi vai trò; màn Người dùng | Đóng; Rules đạt trên CI |
| G-04 | Luồng liên vai trò có cả hai client | Có báo sai (sinh viên ↔ giảng viên) | Thêm duyệt lớp: giảng viên → giáo vụ → app đổi ngay + hộp thư. Báo sai thành luồng thứ hai (điểm thưởng) | Đóng mã; còn đo thời gian |
| G-05 | Hộp thư cho thông báo | Chỉ có trung tâm FCM lưu trên máy | `/inbox` gộp `announcements` và `users/{uid}/inbox`, nút thư có chấm ở Tổng quan, mục ở Tài khoản | Đóng |
| G-06 | Rules có test Emulator, mỗi vai trò × collection | Không có test | `firebase/tests/rules.test.mjs`, 118 ca sinh bảng kết quả | Đóng; đạt trên CI, còn lưu bảng kết quả vào `evidence/rules/` |
| G-07 | Tính năng AI mức 2 | Chưa có | Gợi ý lời nhắc ở GV-OV3, JSON → `ReminderDraft`, người dùng sửa rồi gửi | Đóng mã; còn chạy và lấy 3 cặp vào/ra thật |
| G-08 | App Check trên Firestore và AI Logic | Chưa có | `activateAppCheck()` ở cả hai client | Đóng mã; còn bật Enforce trên console |
| G-09 | PDF lưu và chia sẻ trên máy, metadata ở Firestore; Cloud Storage ngoài phạm vi | Tải lên Storage | Lưu + hộp chia sẻ + `reports`; Storage giữ sau cờ `report_cloud_upload`, mặc định tắt | Đóng |
| G-10 | Remote Config và Analytics ở cả hai client | Chỉ một client | Dịch chuyển service vào core; web đọc `dashboard_top_subjects`, ghi 4 sự kiện riêng | Đóng |
| G-11 | Tài liệu `data-model`, `cross-role-flow`, `ai-feature`, `test-report` | Chưa có | Đã viết; các số đo để trống tới khi chạy | Đóng mẫu |

## 2. Khoảng trống Lab 3 còn mở

Các mục này mã đã sẵn sàng nhưng chưa từng chạy trên Firebase thật, vì `firebase_options.dart` trong repo vẫn là bản giữ chỗ.

| # | Việc | Ai làm | Bằng chứng cần có |
|---|---|---|---|
| L3-1 | Tạo Firebase project, `flutterfire configure` cho `mobile/` và `web/` | Sinh viên | `google-services.json`, project ID khớp ảnh console |
| L3-2 | Chạy trên thiết bị Android, sửa lỗi lúc chạy nếu có | Sinh viên + AI | Ảnh màn hình so với Figma |
| L3-3 | FCM ở 3 trạng thái, DebugView mọi sự kiện, Crashlytics, Remote Config trước/sau | Sinh viên | `evidence/fcm`, `analytics`, `crashlytics`, `remote-config` |
| L3-4 | ARTEMIS ≥ 3 lần mỗi test, phiên khám phá Pro | Sinh viên | `evidence/artemis/` |
| L3-5 | Review lượt 2 bằng CodeRabbit hoặc Copilot trên PR | Sinh viên | `evidence/code-review/`, CR-12 trở đi |
| L3-6 | Báo cáo, slide, video | Sinh viên + AI | `report/`, `slides/`, link video |

## 3. Mâu thuẫn giữa hai đề và cách xử lý

| Điểm | Lab 3 nói | Final nói | Xử lý |
|---|---|---|---|
| Cloud Storage | Bắt buộc, “Spark là đủ” | Ngoài phạm vi | Theo Final làm mặc định. Firebase hiện yêu cầu gói Blaze để dùng bucket Storage, nên nếu cần nộp bằng chứng Lab 3 thì nâng Blaze rồi bật cờ `report_cloud_upload`, luật vẫn nằm ở `firebase/storage.rules`. Nên hỏi lại thầy nếu không muốn nâng gói |
| Cấu trúc repo | `lib/` ở gốc, tên `PRM393_Lab03_<ID>` | `mobile/`, `web/`, tên `PRM393_Final_<ID>` | Làm Final ở nhánh `final-system`, nhánh `main` giữ nguyên bản Lab 3 (commit `5435678`) |

## 4. Giới hạn đã biết, chấp nhận

- **Tự khai vai trò giảng viên và MSSV.** Không có Cloud Functions nên không xác minh được với nhà trường. Giảm rủi ro bằng cách lớp phải được giáo vụ duyệt thì mới điểm danh được; Rules còn kiểm MSSV có trong danh sách lớp khi quét.
- **Thông báo chỉ tới khi app đang chạy hoặc lúc mở lại.** Đề Final không có server để gửi FCM; hộp thư đọc Firestore thời gian thực. Push vẫn gửi từ console như Lab 3.
- **Dữ liệu tạo từ Lab 3 không có trường `status`.** Mã coi là `pending`; nhập lại file sẽ gửi lại để giáo vụ duyệt.
