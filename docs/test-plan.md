# Test plan · ARTEMIS E2E

> Đề Lab 3 mục 7, Appendix B. Mã: `e2e_test/`. Mỗi test là một hàm pytest gửi **một** chỉ dẫn qua `ArtemisClient.run`, yêu cầu agent trả **JSON** (tham số `expected_output`, `enable_outputter=True`) rồi assert trên giá trị agent đọc được, không chỉ `status`.
> ARTEMIS ghim commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` (28/09/2026). Profile **Flash** cho hồi quy, **Pro** cho phiên khám phá.

## 1. Luồng quan trọng → màn

| Luồng | Màn (Lab 2) | Test |
|---|---|---|
| FL-0 Đăng nhập, đăng ký, nhập lớp | GV-090, GV-091, GV-092, GV-093, GV-100, GV-001 .E2 | TC-01, TC-02, TC-03, TC-04 |
| FL-0b Sang kỳ mới | GV-001 .E2, GV-100, GV-003 .D2 | TC-04 (nhập file kỳ mới), TC-12 (chip kỳ) |
| FL-1 Điểm danh một slot | GV-001, GV-101, GV-102 (.D1, .D2, OV1, .L, .S) | TC-05 |
| FL-1 đường lỗi | GV-102 .X, GV-OV2 | TC-06 |
| FL-2 Không quên chốt | GV-002 .D2, GV-102 .D2 | TC-07 |
| FL-3 Chăm sóc sinh viên | GV-001, GV-104, GV-201, GV-OV3 | TC-08 |
| FL-4 Sinh viên xem, báo sai | SV-001, SV-002, SV-102 | TC-09, TC-10 |
| FL-4b Duyệt báo sai | GV-001, GV-105 | TC-11 |
| Các tab, chi tiết lớp | GV-001..004, GV-103 | TC-12 |
| Remote Config trên màn | Khu demo, GV-102 | TC-13 |
| Xuất và tải file | Khu demo (GV-103 dùng chung) | TC-14 |
| Thông báo đẩy | Khu demo, trung tâm thông báo, GV-105 | TC-15 |
| Đăng xuất | GV-004 .C | TC-16 |

## 2. Test case

Điều kiện đầu chung: Android 13+ (thiết bị thật hoặc emulator có Google Play), app build debug `flutter build apk --debug`, tài khoản **Google test** riêng (`QA_TEST_EMAIL`), dữ liệu đã nhập bằng `sample-data/lop-fall-2026.csv`. Mỗi test tự đặt điều kiện đầu bằng fixture (`signed_out` xóa dữ liệu app, `fresh_app` mở lại app), không phụ thuộc thứ tự.

| ID | Flow | Điều kiện đầu | Chỉ dẫn (tóm tắt; nguyên văn trong file test) | Kết quả mong đợi (assert) | Loại | File |
|---|---|---|---|---|---|---|
| TC-01 | FL-0 Sign-in | Đã cài, chưa đăng nhập | Bấm “Đăng nhập với Google” → chọn tài khoản test trong hộp chọn của Android | `screen_title == "Tổng quan"`, `bottom_tabs == 4`, kỳ dạng “Fall 2026”; Logcat có `login` | **Native** | test_auth.py |
| TC-02 | FL-0 Sign-in | Chưa đăng nhập | Nhập email test + mật khẩu sai → Đăng nhập | `error_text == "Sai email hoặc mật khẩu"`, vẫn ở màn đăng nhập | **Error path** | test_auth.py |
| TC-03 | FL-0 Nhập lớp | Đã đăng nhập; `lop-co-loi.csv` trong Downloads | Tài khoản → Nhập danh sách lớp → Chọn file (bộ chọn file Android) | `heading == "2 dòng lỗi, chưa nhập"`, dòng lỗi `[3, 4]` | **Error path**, Native | test_import.py |
| TC-04 | FL-0, FL-0b | Đã đăng nhập; `lop-fall-2026.csv` trong Downloads | Chọn file → Nhập | `classes_imported == 4`, `weekly_slots == 8`; Logcat có `import_classes` | Happy path | test_import.py |
| TC-05 | FL-1 | Có slot đang diễn ra | Điểm danh → đọc bộ đếm → Chốt (đóng mã) → bật 1 em → Chốt → OV1 → Chốt | toast “Đã chốt”; chữ hộp thoại khớp ô có mặt / vắng; Logcat có `attendance_session_open`, `attendance_close` | Happy path | test_session.py |
| TC-06 | FL-1 lỗi | Có slot đang diễn ra | Đóng mã → bật chế độ máy bay → Chốt → thấy GV-OV2 → tắt máy bay → Thử lại | `offline_title == "Chưa gửi được"`, chi tiết “Mất mạng · đã lưu trên máy”, chốt được sau Thử lại | **Error path** | test_session.py |
| TC-07 | FL-2 | Có slot đã qua chưa chốt | Lịch → Tuần → Chốt ngay → Chốt → OV1 | mở không có QR; “Đã chốt”; thẻ đổi tick xanh | Happy path | test_session.py |
| TC-08 | FL-3 | Có sinh viên sắp chạm / vượt ngưỡng | Chú ý → Xem tất cả → hàng đầu → Nhắc nhở → Gửi | tỉ lệ `absent ≥ limit − 1`; nội dung “Em đã vắng N buổi …”; nút đổi “Đã nhắc”; Logcat `view_student`, `reminder_send` | Happy path | test_detail.py |
| TC-09 | FL-4 | Bản build sinh viên, đã đăng nhập, có buổi đã chốt | Đọc thẻ môn đầu → mở chi tiết → đếm hàng Có mặt / Vắng | tỉ lệ ở danh sách = ở chi tiết; số hàng Có mặt = tử số; tổng hàng = mẫu số | Happy path | test_student.py |
| TC-10 | FL-4 | Bản build sinh viên, có buổi Vắng | Mở buổi Vắng → Gửi không chọn lý do → chọn lý do → Gửi | lỗi “Chọn lý do”; màn “Đã gửi”; Logcat `correction_submit` | **Error path** | test_student.py |
| TC-11 | FL-4b | Có ≥ 1 yêu cầu sửa (sau TC-10) | Đọc ô “yêu cầu sửa” → mở → Duyệt thẻ đầu → quay lại | toast “Đã duyệt”; số yêu cầu giảm đúng 1; Logcat `correction_review` | Happy path | test_detail.py |
| TC-12 | Tab, chi tiết | Đã nhập lớp | Bấm 4 tab, Lịch → Tháng, Lớp → lớp đầu → tab Buổi học | tiêu đề `["Tổng quan","Lịch","Lớp","Tài khoản"]`; nhãn “Tháng …”; số sinh viên > 0; Logcat `view_class` | Happy path | test_detail.py |
| TC-13 | Remote Config | Đặt `qr_rotate_seconds` trên console = `QA_EXPECT_QR_SECONDS` | Khu demo → Tải lại → đọc giá trị → (nếu có slot) đọc chip “Đổi mã Ns” | giá trị trên màn = giá trị console; chip ≤ chu kỳ | Happy path | test_profile.py |
| TC-14 | Xuất, tải lên | Có lớp kỳ này | Khu demo → chọn lớp → Xuất PDF và tải lên | chữ bắt đầu “Đã tải lên reports/”; có link https; `size_kb > 0`; Logcat `export_report` | Happy path | test_profile.py |
| TC-15 | FCM | Gửi tin test từ console, data `route=/requests`, khi app chạy nền | Cho phép → hộp quyền Android → Home → mở thông báo trong khay → chạm | quyền “Đã cho phép”; thấy thông báo; mở “Yêu cầu sửa” | **Native** | test_profile.py |
| TC-16 | Sign-out | Đã đăng nhập | Tài khoản → Đăng xuất → hộp thoại → Đăng xuất | thấy hộp thoại; về màn “Quick Attend” nút “Đăng nhập”; Logcat `logout` | Happy path | test_auth.py |

16 case (đề ≥ 10): 4 đường lỗi (TC-02, TC-03, TC-06, TC-10), 3 tương tác native (TC-01 hộp chọn tài khoản Google, TC-03 bộ chọn file, TC-15 hộp quyền thông báo + khay thông báo). Kiểm analytics trong 9 test qua Logcat `FA`.

**Semantics:** các widget chính có nhãn cho cây accessibility (ARTEMIS đọc cây này trước khi dùng thị giác): nút (`AppButton` → `Semantics(button, label)`), hàng sinh viên và công tắc (“Có mặt <tên>”), thẻ slot (“Slot 1 PRM393 · SE1801 07:00 – 09:15 đang diễn ra”), ô số, chip, tab, bộ đếm “32 trên 35 đã có mặt”, mã QR.

## 3. Cách chạy

```bash
cd e2e_test
uv sync
cp .env.example .env   # điền ARTEMIS_DEVICE, QA_TEST_EMAIL, QA_TEST_PASSWORD, QA_EXPECT_QR_SECONDS
# Máy có ADB: khởi động daemon ARTEMIS (repo google/artemis, commit đã ghim)
#   ./start.sh   hoặc   uv run artemis ui
uv run pytest --count=3 -p no:randomly           # hồi quy, mỗi test 3 lần (Flash)
uv run pytest -m student --count=3               # cài bản build sinh viên trước
uv run pytest -m exploratory -s                  # phiên khám phá (Pro)
uv run python report.py > ../evidence/artemis/results.md
```

Bằng chứng: `runs/junit.xml`, `runs/runs.jsonl` (trace ID mỗi lần chạy), bản phát lại và ảnh trong giao diện ARTEMIS (`http://localhost:8000`, chép vào `evidence/artemis/`).

## 4. Kết quả

> Điền sau khi chạy trên thiết bị (bảng do `report.py` sinh). Chưa chạy thì để trống, **không** điền tay.

| Test | Runs | Pass rate | Avg time (s) | Trace IDs |
|---|---|---|---|---|
| | | | | |

### Test không đạt 3/3 (flaky) và cách sửa

| Test | Nguyên nhân (app / thời gian / chỉ dẫn mơ hồ) | Sửa |
|---|---|---|
| | | |

## 5. Phiên khám phá (Pro, 15–30 phút)

`test_exploratory_session_pro`: đóng vai giảng viên ngày đầu kỳ, đi hết màn từ 4 tab, phiên điểm danh (mở, đóng, mở lại, hoàn tác), bộ lọc Chú ý, chuyển tháng ở Lịch, khu demo (không bấm Test crash). Agent trả danh sách lỗi theo màn, bước, hiện tượng, mức độ.

| # | Màn | Bước | Hiện tượng | Mức | Xử lý |
|---|---|---|---|---|---|
| | | | | | |
