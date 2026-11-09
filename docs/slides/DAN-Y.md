# Dàn ý hai bộ slide (thien duyệt 09/11/2026 20:40)

09/11/2026 · Claude soạn từ đề Lab 3, đề Final, guideline V11, tài liệu "Workflow là gì" và lời nhắn của thầy. Dựng slide sau khi giao diện đóng băng (trưa 11/11) và có bằng chứng thật; ảnh lấy từ app chạy thật và `evidence/`.

Hai bộ khác mục đích, nên tách:

| | Slide Lab 3 | Slide Final |
|---|---|---|
| Thầy chấm gì | Công nghệ và giải thích nguyên lý ("FCM token là gì, cấp ở đâu, client có lưu không...") | Hệ thống hoàn chỉnh theo guideline V11: vấn đề, thiết kế, demo theo workflow, bằng chứng |
| Số slide | 12 đến 15 | 15 + phụ lục (guideline V11 có 24 mục, đề Final giới hạn 12 đến 15) |
| File nộp | `slides/Lab03_<ID>_slides.pdf` | `slides/Final_<ID>_slides.pdf` |

Mỗi slide công nghệ dùng chung một khung, để trả lời được mọi câu kiểu thầy hỏi: **Nó là gì · Ai cấp hoặc chạy ở đâu · Lưu ở đâu · Code nằm ở file nào · Lỗi thì sao · Bằng chứng**.

## Slide Lab 3 · công nghệ

1. Attendo: điểm danh bằng mã QR cho lớp học (tên sản phẩm, lớp, người làm).
2. Bài toán trong một slide: gọi tên mất thời gian, sinh viên không biết mình sắp quá ngưỡng vắng.
3. Kiến trúc: Flutter MVVM + Riverpod; một ViewModel, nhiều View theo thiết bị (điện thoại, Windows, web); sơ đồ dịch vụ Firebase quanh app.
4. Authentication: email + Google, xác nhận email, vai trò lưu ở `users/{uid}`, Security Rules đọc `request.auth`.
5. Firestore và Security Rules: mô hình dữ liệu; luật quét mã (token + hạn, sinh viên không đọc được slot); 118+ ca test Rules trên Emulator.
6. Mã QR đổi mỗi 12 giây: token, mã vừa thay còn nhận 1 chu kỳ, mã 6 số, màn chiếu TV, một máy giữ quyền đổi mã (sơ đồ tuần tự).
7. FCM, đúng 5 câu thầy hỏi: token là gì (định danh một lần cài app trên một máy); cấp ở đâu (`getToken()` gọi máy chủ FCM, `messaging_service.dart`); client có lưu không (SDK giữ, app ghi thêm `users/{uid}/fcmTokens/{token}`); gửi thế nào, code ở đâu (`tool/fcm/send.mjs`, Admin SDK, FCM HTTP v1, service account); client dùng ra sao (3 trạng thái app, mở `data.route`).
8. Analytics: kế hoạch sự kiện, DebugView.
9. Crashlytics: nút Test crash → console; vì sao app gửi thêm bản tóm tắt vào `crashReports` (Crashlytics không có API đọc cho client) → admin xem ở web Sự cố.
10. Remote Config: tham số, fetch/activate, đổi trên console thì app đổi theo; cờ tắt AI.
11. Upload file: Cloudinary preset unsigned thay Cloud Storage (gói Spark), Rules chỉ nhận link đúng thư mục.
12. AI code review: các phát hiện trên PR, nhận hay bác, vì sao.
13. ARTEMIS: số ca × 3 lần, kết quả.
14. Bảng bằng chứng: mỗi dịch vụ một ảnh console.
15. Bài học và giới hạn.

## Slide Final · theo guideline V11

**Phần 1 · Vấn đề**
1. Tên, nhóm, một câu sản phẩm làm gì.
2. Bối cảnh: điểm danh FAP hiện nay, ai khổ ở đâu.
3. Ba pain point, mỗi cái có số liệu hoặc ví dụ.
4. Actor: giảng viên, sinh viên, quản trị (web admin), nhóm phát triển (Firebase console).

**Phần 2 · Thiết kế**
5. Business flow có swimlane theo 4 actor.
6. Bốn workflow lõi (WF-01 điểm danh một buổi, WF-02 báo sai, WF-03 duyệt lớp liên vai trò, WF-04 nhắc sinh viên vắng nhiều): trigger, các bước, rẽ nhánh, kết quả.
7. State machine: Slot (chưa mở → đang mở mã → đã đóng mã → đã chốt), Yêu cầu sửa, Lớp.
8. Kiến trúc và stack: 4 client (Android, Windows, web sinh viên, web admin) + extension, Firebase, Cloudinary, Gemini.
9. Giao diện theo thiết bị: cùng một màn trên điện thoại, Windows, web.
10. Traceability: yêu cầu → màn → test.

**Phần 3 · Demo** (chạy thật, theo thứ tự workflow)
11. WF-01 trên điện thoại + TV + web sinh viên + extension điền FAP giả.
12. WF-02 và WF-03, đo thời gian luồng liên vai trò.
13. AI mức 2 (Gợi ý AI khi nhắc sinh viên), tắt bằng Remote Config.

**Phần 4 · Bằng chứng**
14. Test: unit, Rules, E2E web, ARTEMIS, test tay 6 ca; con số lấy từ CI và `evidence/`.
15. Đạt được, giới hạn, hướng tiếp.

Phụ lục: mô hình dữ liệu, các slide công nghệ của Lab 3.

## thien đã chốt (09/11/2026 20:40)
- Dàn ý trên dùng như vậy.
- Làm slide dạng **web tự dựng** như repo MLN122 (`thiengthb/mln122-nhom9`) nhưng chuyên nghiệp hơn: một file HTML chạy không cần mạng, phím tắt, ghi chú lời nói, cửa sổ người nói, đồng hồ, phím soi bằng chứng; màu và phông của Attendo; xuất PDF để nộp. Không dùng Slides của Claude hay file .pptx.
- **Hai bộ tách riêng** (Lab 3 và Final).
- Đăng trên **GitHub Pages** của repo này; thien bật Pages một lần trong Settings.
- Ảnh giao diện chụp lại sau mốc đóng băng (trưa 11/11); trước đó dựng khung, nội dung, sơ đồ.
