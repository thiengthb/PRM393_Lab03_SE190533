# Báo cáo kiểm thử · Final

> Đề Final mục 9. **Ô trống là chưa chạy.** Không điền số chưa đo: đề coi bằng chứng giả là vi phạm liêm chính.

## 1. Kiểm tra đã chạy khi viết mã

| Kiểm tra | Công cụ | Kết quả | Ghi chú |
|---|---|---|---|
| Phân tích tĩnh `packages/core`, `web` | Dart analyzer 3.13.7 với mã nguồn Flutter 3.47.3 | Không có lỗi | Máy viết mã không tải được pub.dev nên dựng package từ GitHub, không phải `flutter analyze` thật |
| Phân tích tĩnh `mobile` | như trên | 1 lỗi giả ở `file_picker_service.dart:37` | Do lấy `cross_file` bản mới nhất thay vì bản 0.3.5+5 trong `pubspec.lock`; xác nhận lại bằng CI |
| `flutter analyze`, `flutter test`, `flutter build web` | GitHub Actions, Flutter 3.47.3, commit `3cad67b` | Đạt | Lấy ảnh từ tab Actions làm bằng chứng |
| Rules trên Emulator | GitHub Actions, job `rules`, commit `3cad67b` | Đạt | Tải artifact `rules-test-results` về `evidence/rules/` |

## 2. Security Rules (Emulator)

Bảng đầy đủ tự sinh tại [`evidence/rules/rules-test-results.md`](../evidence/rules/rules-test-results.md) sau khi chạy `cd firebase/tests && npm ci && npm test`.

Job `rules` trên commit `3cad67b` đạt, bộ test có 118 ca. Số liệu từng ca nằm trong artifact `rules-test-results`.

## 3. E2E (ARTEMIS)

Xem [`test-plan.md`](test-plan.md). Kết quả từng ca, trace và chi phí: [`evidence/artemis/results.md`](../evidence/artemis/results.md).

Chạy 11/11/2026 trên OPPO CPH1931, 1 lần mỗi ca (kế hoạch 3 lần, dừng vì hết ngân sách Gemini):

| Nhóm | Ca |
|---|---|
| Đạt | TC-02, TC-03, TC-13 |
| Đạt giao diện, trượt kiểm Analytics trong Logcat | TC-04, TC-05, TC-08, TC-11, TC-12, TC-14 |
| Trượt | TC-06 (không hiện dải mất mạng), TC-15 (không thấy thông báo) |
| Lỗi môi trường | TC-07 (nạp lại dữ liệu hỏng) |
| Chưa chạy | TC-01 (cần Firebase thật), TC-16, TC-09, TC-10, TC-23, TC-17..TC-22, phiên khám phá Pro |

## 4. Web admin (checklist, mỗi dòng một ảnh trong `evidence/web/`)

| # | Màn | Kiểm | Đạt | Ảnh |
|---|---|---|---|---|
| W-01 | Đăng nhập | Google Sign-In vào được bằng tài khoản staff | | |
| W-02 | Đăng nhập | Tài khoản student, lecturer, user bị từ chối với câu rõ ràng | | |
| W-03 | Đăng nhập | Đóng popup Google hiện “Đã hủy đăng nhập” | | |
| W-04 | Tổng quan | ≥ 3 số từ aggregation và biểu đồ theo môn khớp dữ liệu | | |
| W-05 | Tổng quan | Dự án trống hiện “Chưa có dữ liệu” | | |
| W-06 | Tổng quan | Tắt mạng rồi Tải lại hiện lỗi và nút Thử lại | | |
| W-07 | Duyệt lớp | Duyệt: thẻ rời tab Chờ duyệt, app đổi ngay | | |
| W-08 | Duyệt lớp | Từ chối không lý do bị chặn; có lý do thì app thấy lý do | | |
| W-09 | Duyệt lớp | Hàng đợi hết hiện “Đã xử lý hết” | | |
| W-10 | Duyệt lớp | Mã môn ngoài danh mục có cảnh báo | | |
| W-11 | Môn học | Tìm, thêm, sửa, lưu trữ, khôi phục | | |
| W-12 | Môn học | Thêm trùng mã báo lỗi, mã sai định dạng báo lỗi | | |
| W-13 | Môn học | Môn lưu trữ làm file nhập lớp trên app báo dòng lỗi | | |
| W-14 | Thông báo | Đăng: hiện trên hộp thư app đúng đối tượng, không cần tải lại | | |
| W-15 | Thông báo | Bỏ trống tiêu đề bị chặn; lưu trữ làm thông báo biến khỏi app | | |
| W-16 | Người dùng | Staff không thấy mục, gõ `/users` bị đẩy về Tổng quan | | |
| W-17 | Người dùng | Admin cấp staff cho tài khoản mới, không đổi được chính mình | | |
| W-18 | Remote Config | Đổi `dashboard_top_subjects`, biểu đồ đổi số môn | | |
| W-19 | Bố cục | Không tràn ở 1280, 900 và 600 px | | |

## 5. Luồng liên vai trò trên bản deploy, 3 lần

Xem bảng đo trong [`cross-role-flow.md`](cross-role-flow.md).

## 6. AI code review trên mã mới

Xem [`code-review.md`](code-review.md), CR-08 trở đi.
