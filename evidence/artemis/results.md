# Kết quả ARTEMIS (lần 1, ngày 11/11/2026)

Điện thoại thật OPPO CPH1931 (Android 10), Firebase Emulator, app debug `EMULATOR_HOST=127.0.0.1`, ARTEMIS Flash trên `gemini-3.7-flash` (dự phòng `gemini-2.5-flash`). Mỗi ca chạy **1 lần**, chưa đủ 3 lần: dừng vì hết tiền trả trước của khoá Gemini (lỗi 402) và vượt ngân sách nhóm.

| Ca | Kết quả | Thời gian (s) | Trace | Ghi chú |
|---|---|---|---|---|
| TC-02 Sai mật khẩu | **Đạt** | 311 | 7536c09c | Đọc được "Sai email hoặc mật khẩu", vẫn ở màn đăng nhập |
| TC-03 File lỗi | **Đạt** | 96 | e8b0e20b | "2 dòng lỗi, chưa nhập", dòng 3 và 4 |
| TC-13 Remote Config | **Đạt** | 125 | 875bb1c2 | qr_rotate 12 s, absence_limit 20 %, nguồn remote |
| TC-04 Nhập file đúng | Giao diện đạt, analytics chưa | 86 | 87b551b3 | 4 lớp, 8 slot/tuần |
| TC-05 Điểm danh slot đang mở | Giao diện đạt, analytics chưa | 334 | 9e0ccb0a | 24/35 → 25 có mặt, 10 vắng |
| TC-08 Sắp chạm và nhắc | Giao diện đạt, analytics chưa | 96 | a61e1bd9 | 4/4, tin nhắc điền sẵn, "Đã nhắc · 11/11" |
| TC-11 Duyệt yêu cầu sửa | Giao diện đạt, analytics chưa | 95 | a83c1a35 | Chờ duyệt 3 → 2 |
| TC-12 Tab và chi tiết lớp | Giao diện đạt, analytics chưa | 219 | 7460f305 | 4 tab, 30 SV, 19/20 buổi |
| TC-14 Xuất PDF | Giao diện đạt, analytics chưa | 102 | 2aa60f45 | Có link Cloudinary, 15 KB |
| TC-15 Quyền thông báo | Trượt | 603 | fef751f0 | Đã cho phép, nhưng không thấy thông báo trong 600 s |
| TC-06 Chốt khi mất mạng | Trượt | 594 | 768709e6 | Không hiện dải "mất mạng"; bước cuối dừng vì lỗi 402 |
| TC-07 Chốt slot chưa chốt | Lỗi môi trường | 0 | | Nạp lại dữ liệu hỏng (Firestore emulator 499) khi TC-06 còn chạy |
| TC-01, TC-16, TC-09, TC-10, TC-23 | Chưa chạy | | | TC-01 cần Firebase thật; còn lại hết ngân sách |

"Analytics chưa": phần giao diện đúng, chỉ câu kiểm sự kiện Firebase Analytics trong Logcat trượt vì máy chưa bật `log.tag.FA VERBOSE`. Đã thêm vào fixture `analytics_debug`; chưa chạy lại.

## Sửa bộ test trong lần này
- ARTEMIS Flash không trả JSON kết quả về daemon nên mọi ca đều ra `output={}`. Vá ARTEMIS cục bộ để Flash cũng chạy Outputter và in một dòng `ARTEMIS_STRUCTURED_OUTPUT_JSON`; `conftest.py` đọc đúng dòng đó trong `traces/<id>/stdout.log` khi daemon không trả output (không có dòng thì ca trượt).
- TC-02 và TC-16 đăng xuất app, các ca sau cần đăng nhập: chạy theo nhóm và đăng nhập lại giữa các nhóm.

## Chi phí
Khoảng 355 lượt gọi Gemini cho 12 lần chạy (14 đến 87 lượt mỗi ca, trung vị khoảng 19); TC-02 tốn 34 lượt, khoảng 383 nghìn token đầu vào. Ngày 10/11: lỗi 503/504 (model quá tải) rồi 429 (gói miễn phí 20 lượt mỗi model mỗi ngày).
