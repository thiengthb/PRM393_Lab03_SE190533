# Kế hoạch đưa giao diện v2 vào Lab 3, bản 2, cập nhật 03/11/2026

Tài liệu này dành cho bạn và cho chat Claude làm Lab 3. Bản 2 giữ phần so sánh của bản đầu, rồi sửa thứ tự làm và các quyết định sau khi đối chiếu với đề Lab 3, code trên GitHub và Figma v2.

Đọc `docs/handoff/BAN-GIAO.md` trước: file đó ghi những câu ở mục 3 đã được trả lời và Giai đoạn 0 đã làm tới đâu.

## 1. Tình hình

Lab 3 hạn thứ Sáu 06/11 (giờ cụ thể cần bạn kiểm tra lại). Giao diện trong repo đang là bản cam, tên Quick Attend, còn Figma đã đổi nhiều về màu, tên, bố cục và một số hành vi.

Rủi ro lớn nhất là app chưa từng chạy trên Firebase thật, ít nhất theo những gì có trên GitHub. Nhánh `main` vẫn có `firebase_options.dart` giữ chỗ và không có `google-services.json`. Nếu lỗi nằm ở bước nối Firebase, càng phát hiện muộn càng mất nhiều phần phải làm lại. Vì vậy, bước nối Firebase được đưa lên đầu kế hoạch.

Bảng điểm của đề cũng ủng hộ thứ tự này. Đề ghi rằng tiêu chí không có bằng chứng thì coi như không đạt.

| Nhóm điểm | Điểm | Cần gì |
|---|---|---|
| Firebase và Analytics | 2,0 | App chạy thật, ảnh console, DebugView |
| ARTEMIS | 1,5 | Giao diện ổn định, đã có Firebase |
| AI code review | 0,5 | Mở PR, đã có 7 phát hiện từ lượt đầu |
| Slide và video | 2,0 | App chạy thật, cần nhiều giờ làm |
| Luồng, dữ liệu, trạng thái | 2,5 | Phần lớn đã có code, phải chạy được |
| Kiến trúc | 0,75 | Đã có, chỉ cần giữ luật |
| Giao diện đúng thiết kế và trợ năng | 0,75 | Đây là phần v2 tác động trực tiếp |

Bảng trên không có nghĩa v2 không đáng làm. Nó có nghĩa là v2 không được ăn vào thời gian của 6 điểm cần bằng chứng.

**Đã kiểm tra khi viết bản này:** đề Lab 3, code nhánh `main`, ảnh Figma các section 4, 5, 12, 16. **Chưa kiểm tra:** các section còn lại của Figma, nên bảng ở mục 5 vẫn lấy từ bản đầu của bạn.

## 2. Nguồn thiết kế

- Figma file key `1qIZVpL0Q7bD9UzT5TVBRy`, chỉ đọc. Trang chính là `03 Final UI · v2` (`239:4208`). Đường bấm xem ở `06 Prototype · v2` (`284:2`). Luồng xem ở `01 User Flow · v2` (`317:2`).
- Quyết định và lý do nằm trong `lessons/LAB2-ban-giao.md` đến `-5`. **Các file này chưa có trên GitHub**, vì repo `thiengthb/frontend` mới nhất là commit `fcd7d7f` ngày 02/11 và thư mục `lessons/` không có file LAB nào. Bạn cần đẩy chúng lên, hoặc dán chúng vào project, thì chat làm Lab 3 mới đọc được.

| Section | Nội dung | Id |
|---|---|---|
| 1 | Giảng viên vào app | `324:5333` |
| 2 | Tab 1 Tổng quan | `324:5341` |
| 3 | Tab 2 Điểm danh | `324:5352` |
| 4 | Phiên điểm danh | `324:5358` |
| 5 | Màn chiếu TV | `324:5368` |
| 6 | Yêu cầu sửa | `324:5372` |
| 7 | Vắng nhiều và hồ sơ | `324:5377` |
| 8 | Tab 3 Lớp | `324:5384` |
| 9 | Nhập lớp | `324:5391` |
| 10 | Tab 4 Tài khoản | `324:5397` |
| 11 | Sinh viên vào web, buổi vắng | `324:5401` |
| 12 | Sinh viên quét mã | `324:5408` |
| 13 | Chi tiết môn, báo sai | `324:5416` |
| 14 | Laptop | `324:5421` |
| 15 | Máy rộng 412 | `324:5424` |
| 16 | Riêng Lab 3 | `324:5429` |
| 17 | Thành phần v2 | `324:5435` |

## 3. Các câu cần bạn chốt

Mỗi câu có một cách mặc định. Nếu bạn không trả lời, chat Lab 3 làm theo mặc định và ghi vào bảng khác biệt.

**Ba câu mới, cần trả lời trước khi bắt đầu:**

1. **Firebase project đã có chưa, và app đã chạy trên máy bạn chưa?** Mặc định: coi như chưa, làm ở Giai đoạn 0.
2. **Làm trên nhánh nào?** Repo có nhánh `final-system` (ngày 02/11) đã tách code sang `mobile/`, `packages/core/`, `web/`, thêm web admin và bước giáo vụ duyệt lớp. Đề Lab 3 lại yêu cầu `lib/` ở gốc repo, còn bước duyệt lớp làm đổi luồng Lab 2. Mặc định: tạo `ui-v2` từ `main`, nộp Lab 3 từ đó, và không đụng `final-system` cho tới khi nộp xong. Sau đó mới gộp `main` vào `final-system`. Git nhận ra các file đã đổi chỗ, nhưng vẫn sẽ có xung đột ở những màn cả hai bên cùng sửa, nên cần để ra thời gian.
3. **Cloud Storage xử lý thế nào?** Đề Lab 3 bắt buộc (0,25 điểm) và ghi gói Spark là đủ. Theo mình biết, Firebase hiện yêu cầu gói Blaze cho bucket Storage, nhưng mình chưa đọc được nội dung trang chính thức nên bạn cần kiểm tra trên console. Mặc định: nâng Blaze nếu console yêu cầu và bạn đồng ý thêm thẻ, nếu không thì báo thầy trước khi làm, vì đề cho phép xin dùng cách tương đương khi dịch vụ không có sẵn.

**Bốn câu của bản đầu, có sửa mặc định:**

4. **Màn chiếu TV đăng nhập thế nào?** Bạn đề xuất link có khoá, và cách này vẫn hợp lý, nhưng có ba chỗ phải sửa.
   - Khoá không được hết hiệu lực khi đóng mã. Figma có trạng thái TV "Đã đóng mã" và nút "Mở lại mã", nên TV phải sống qua lần đóng mã. Mặc định: khoá hết hiệu lực khi hết giờ slot.
   - Trạng thái "Chưa mở điểm danh · Slot kế tiếp" không có nguồn dữ liệu, vì TV không đăng nhập nên không đọc được lịch. Mặc định: màn này chỉ ghi "Chưa mở điểm danh", dùng khi link hết hạn hoặc sai, và ghi vào bảng khác biệt.
   - Link phải gõ được trên máy phòng học. Mặc định: `/tv/` kèm khoá 10 ký tự, và nút Chiếu lên TV mở một sheet hiện link kèm nút Chép. Section 4 và 5 chưa có khung cho sheet này, nên phải thêm vào Figma.
5. **Mã số 6 chữ số dùng thế nào khi không có Cloud Functions?** Mặc định: mỗi lần đổi mã, app giảng viên ghi một bản ghi `qrCodes/{mã}`. Luật chỉ cho đọc đúng một mã, không cho liệt kê, và người đọc phải có tên trong lớp đó. Nhờ vậy, người ngoài lớp không dò được, nên chỉ còn rủi ro bạn cùng lớp thử nhiều lần. Rủi ro này ghi vào bảng khác biệt.
6. **Có giữ lối sửa slot đã chốt không?** Mặc định giữ, và lối vào là hàng trong tab Buổi học. Vì vậy **tab Buổi học không còn nằm trong danh sách được cắt**. Nếu cắt tab này, thầy không còn cách nào sửa buổi đã chốt, và đề coi màn không tới được là lỗi.
7. **Tám bảng màu có đổi màu thật không?** Mặc định: Biển sâu và Cam FPT đổi thật. Khung Chọn màu chỉ hiện những màu đã làm được, vì ô bấm mà không đổi gì là lỗi. Nếu còn giờ thì thêm sáu màu kia; nếu không thì ghi vào bảng khác biệt.

**Một việc nên làm hôm nay:** nhắn thầy một câu rằng bạn đã làm lại thiết kế sau góp ý của thầy, đổi tên thành Hereby, và Lab 3 sẽ theo bản mới. Đề chỉ nói được đổi thiết kế khi lúc dựng gặp vấn đề thật, còn v2 là thiết kế lại, nên có lời thầy đồng ý thì an toàn hơn nhiều.

## 4. Những lỗi mới phát hiện khi đối chiếu

Các mục dưới đây bản đầu chưa có. Mỗi mục đều ảnh hưởng tới cách làm.

**Mã số sẽ thường xuyên báo hết hạn.** Code tạo mã có hạn 15 giây (`session_viewmodel.dart`, chu kỳ cộng 3 giây trễ mạng). Tuy nhiên, luật lại so token với đúng token hiện tại (`firestore.rules` dòng 58), nên mã cũ hỏng ngay lúc đổi, và 3 giây dự phòng không có tác dụng. Với QR, lỗi này ít gặp vì quét rất nhanh. Với mã số, sinh viên phải nhìn lên TV rồi gõ 6 số trong khoảng còn lại của 12 giây, nên sẽ hỏng nhiều. Cách sửa: giữ thêm `qrTokenPrev`, luật nhận cả token vừa đổi. Việc này làm trước mã số.

**SV-101 hiện tên lớp khi chưa biết lớp nào.** Figma ghi "PRM393 · SE1801 · Slot 1" trên màn quét và màn nhập mã, trước khi sinh viên quét. Sinh viên không đọc được slot (luật CR-01), nên lúc đó chưa có dữ liệu này. Mặc định: bỏ dòng này ở hai màn đó, chỉ hiện sau khi có kết quả, và ghi vào bảng khác biệt.

**Màn TV bị router chặn.** `router.dart` đưa mọi người chưa đăng nhập về `/login`, nên phải thêm `/tv/:key` là đường công khai. Hosting cũng phải deploy sớm hơn dự kiến, vì TV chỉ chạy qua web. Luật đọc bản ghi TV phải kiểm hạn, và không được có `if true`.

**Mất mạng sẽ không tự hiện dải vàng.** Khi mất mạng, Firestore đọc bộ nhớ đệm và không báo lỗi, nên màn GV-001 .X sẽ không bao giờ xuất hiện theo cách hiện tại. Trong code chưa có chỗ nào dùng `isFromCache` (cờ báo dữ liệu lấy từ bộ nhớ đệm). Cách sửa: `SlotRepository` báo thêm cờ này cho `OverviewViewModel`.

**Tài liệu thiết kế Lab 2 vẫn là bản cũ.** Đề yêu cầu dựng theo `flutter-handoff.md` và chấm nội dung theo `screen-spec.md`. Hai file này cùng `DESIGN.md` trong repo Lab 2 vẫn là bản cam, commit 30/10. Trên Figma, các trang `02 Wireframe`, `04 Design System`, `05 Components` cũng chưa có bản v2. Bản đầu của kế hoạch chưa tính phần này.

**Đổi tên không nên đổi mã app.** Nên đổi nhãn thành Hereby và giữ `applicationId` là `vn.edu.fpt.quick_attend`. Đổi mã sau khi đã nối Firebase thì phải đăng ký lại Firebase, SHA-1 và biến `QA_APP_PACKAGE` trong test. Chốt việc này trước `flutterfire configure`.

**Test ARTEMIS bị ảnh hưởng nhiều hơn bốn ca.** Chữ "Quick Attend" nằm trong cả năm file test, nên cả 16 ca đều phải đọc lại, không chỉ TC-05, 06, 07, 12. TC-08 còn dùng 'Chú ý', TC-12 dùng 'Lịch' và 'Tháng'.

**Nút thấp hơn mức đề yêu cầu.** Đề yêu cầu vùng chạm ít nhất 48, trong khi nút trong thẻ cao 40 và nút trong hộp thoại cao 36. Câu này đang để mở từ trước, nên xử lý một lần trong `AppButton`: giữ hình như Figma, mở rộng vùng bấm vô hình lên 48.

## 5. Chênh lệch giữa code và Final UI v2

Các đường dẫn tính theo nhánh `main`.

**Nền tảng**

| Việc | Hiện tại | Cần đổi |
|---|---|---|
| Màu, `lib/theme/tokens.dart`, `app_theme.dart` | Cam, `_scheme` là hằng | Xem mục 6. Màn hình đã đọc màu qua Theme nên chỉ phải sửa thư mục `theme/` và `app.dart` |
| Tên | Quick Attend, 15 file trong `lib`, `web`, `android`, `e2e_test` | Hereby, không đổi `applicationId` |
| Logo | Ô cam chữ Q | Người giơ tay, App icon v2 `262:2800`, xuất thành icon launcher và favicon |
| Thanh tab, `navigation.dart` | Tab 2 lịch, tab 4 hình người | Tab 2 icon QR tên Điểm danh, tab 4 bánh răng, giữ nhãn cho trình đọc màn hình |
| Icon | Material Symbols (D-L3-03) | Giữ, chọn hình gần nhất với Figma |
| Thẻ | `QaCard` một kiểu | Hai kiểu: bấm được thì nổi, có viền và gờ; chỉ để xem thì chìm, nền xám, không viền |
| Nút | Cao 40, 36 | Vùng bấm 48, xem mục 4 |
| Chữ | "cấm thi", "Chú ý" | "fail", "Vắng nhiều" |

**Giảng viên**

| Màn | Việc chính | Mức |
|---|---|---|
| GV-001 | Đổi chỗ ngày và kỳ, ô số có icon, ô yêu cầu nền xanh nhạt có mũi tên. Thêm lịch tháng có chấm (chuyển `_MonthGrid` từ `schedule_screen.dart`), bấm ngày sang tab Điểm danh. Thêm thẻ chưa chốt, dải quên chốt .D3, dải nhiều slot .D4 và khung OV6 | Lớn |
| GV-001 .X, .E2 | Mất mạng giữ dữ liệu cũ kèm dải vàng, dùng `isFromCache`. Chưa có lớp dùng thẻ đậm và lịch trống | Vừa |
| GV-002 | Bỏ Hôm nay, Tuần, Tháng. Thay bằng hàng chuyển tuần, chip tuần và dải T2 đến CN, bấm ngày xem slot | Vừa |
| GV-101 | Bỏ màn. Phải sửa cả 5 chỗ trỏ tới `/slot/`, gồm thông báo nhắc slot | Nhỏ |
| GV-102 .D1, .D2 | Tách nút: Đóng mã khi đang mở, Chốt khi đã đóng. Bỏ hộp xác nhận OV1. Thêm mã số và Chiếu lên TV. Gộp danh sách đã quét thành hàng Có mặt mở ra được. Đổi "Mở lại" thành "Mở lại mã" | Lớn |
| GV-102 .D3 | Code đã tự đóng mã khi hết giờ. Chỉ cần thêm thông báo "Hết giờ, đã đóng mã" | Nhỏ |
| GV-102 .X, .S | Lỗi mạng dùng dải thay hộp thoại OV2. Màn đã chốt làm theo Figma | Vừa |
| TV-001 | Màn mới, ba trạng thái, đường công khai, sheet hiện link | Lớn |
| GV-003 | Chọn kỳ bằng dropdown nền xám, avatar lớp xanh, thêm .E | Vừa |
| GV-103 | Thẻ và avatar thống nhất, chỉ số vắng đổi màu. Tab Buổi học dùng thẻ chìm, có lối sửa buổi đã chốt. Giữ nút Xuất PDF | Vừa |
| GV-104, GV-201, OV3 | Đổi tên, chip Đã fail, em đã fail không có nút Nhắc nhở, lời nhắc nói rõ còn được vắng bao nhiêu, nút "Đã nhắc · ngày" | Vừa |
| GV-105, OV5 | Đối chiếu Figma, chỉnh màn trống | Nhỏ |
| GV-100 | Khung chọn file thấp lại, màn lỗi đổi nút chính thành Chọn file khác, "Bỏ 2 dòng lỗi" | Nhỏ |
| GV-004 | Hồ sơ thẻ chìm, thêm nhóm Giao diện và khung Chọn màu, Đăng xuất tách riêng, giữ nhóm Firebase | Vừa |

**Sinh viên**

| Màn | Việc chính | Mức |
|---|---|---|
| SV-001 | Đếm buổi vắng trên 4 thay cho số có mặt, dải vàng hoặc đỏ theo mức, bỏ nút Báo sai ở danh sách, thêm .D3 | Vừa |
| SV-002 | Icon tick và x ở đầu hàng, buổi vắng là thẻ nổi có Báo sai, thêm .D1 ghi kết quả. Buổi bị từ chối không báo lại được | Vừa |
| SV-101 | Thêm màn Nhập mã, dải còn vắng ở .S theo ba mức, .X2 có lối Nhập mã, bỏ tên lớp trước khi quét | Vừa |
| SV-102, SV-003 | Thẻ chìm, nút Gửi ở thanh đáy, màn Đã gửi có dòng buổi. SV-003 theo Figma | Nhỏ |

**Máy chủ và dữ liệu**

- `firebase/firestore.rules`: thêm `qrTokenPrev`, `qrCodes`, bản ghi TV. Không nới luật CR-01 (sinh viên không đọc slot).
- Mỗi lần đổi mã, app ghi slot, mã mới, xoá mã cũ và cập nhật TV trong một batch. Khoảng 20 lần ghi mỗi phút mở mã, thấp hơn nhiều so với hạn gói Spark. Số đã quét trên TV vì thế có thể trễ tới 12 giây; ghi vào bảng khác biệt.
- Hai lớp cùng lúc có thể trùng mã số, nên luật chỉ cho tạo khi mã chưa tồn tại và app thử lại mã khác.
- `OverviewData` cần thêm danh sách slot chưa chốt và dữ liệu chấm lịch tháng.
- Nhánh `final-system` đã có sẵn bộ test Rules trên Emulator (`firebase/tests/`) và file CI. Lấy hai phần này sang `ui-v2`, chỉnh đường dẫn cho `lib/` ở gốc, để mỗi lần push đều có analyze, test và test Rules.

## 6. Bảng màu mẫu A Biển sâu

| Biến | Mẫu A | Cam FPT |
|---|---|---|
| primary | `#0B4F71` | `#B9551F` |
| primary-pressed, edge-primary | `#07354E` | `#8A3D14` |
| primary-soft | `#DCEDF5` | `#FBEFE8` |
| on-primary-soft | `#0A4664` | `#9A4518` |
| primary-soft-edge | `#9CC9DF` | `#F9B98F` |
| brand | `#0B4F71` | `#F26F21` |
| warning-soft-edge (mới) | `#E8CB7F` | `#E8CB7F` |

Các màu còn lại không đổi giữa hai mẫu: warning `#A15C00`, warning-soft `#FFF6DD`, success `#15803D`, success-soft `#ECFDF3`, danger `#B42318`, danger-soft `#FEF0EF`, muted-surface `#F4F4F4`, edge `#E5E5E5`, fg-strong `#1F1F1F`, fg `#3C3C3C`, fg-muted `#6B6B6B`.

Tương phản đã tính cho mẫu A, đều trên mức 4,5 mà chữ thường cần: chữ trắng trên primary 8,86; on-primary-soft trên primary-soft 8,43; warning trên warning-soft 4,81; fg-muted trên muted-surface 4,85; danger trên danger-soft 5,92; success trên success-soft 4,76. Viền warning-soft-edge chỉ đạt 1,47, nên dải vàng phải luôn có chữ, không được chỉ dựa vào màu.

Trên code, các màu đổi theo mẫu đưa vào một lớp `AppPalette`, và `AppTheme.light()` nhận palette làm tham số. Lựa chọn lưu bằng `shared_preferences` đã có sẵn.

## 7. Thứ tự làm

Lịch dưới đây là đề xuất, vì chưa đo được tốc độ thật trên máy bạn. Mỗi giai đoạn kết thúc bằng một commit và CI đạt. Máy cloud của Claude không chạy được app, nên mỗi mốc giao diện cần bạn chạy thử và gửi ảnh.

**Giai đoạn 0, sáng thứ Ba: cho bản hiện tại chạy thật.** Chốt các câu ở mục 3. Tạo nhánh `ui-v2` từ `main`, thêm CI. Tạo Firebase project, chạy `flutterfire configure`, bật dịch vụ, thêm SHA-1, deploy Rules và Hosting. Mốc đạt: bản cam đăng nhập được, nhập được file mẫu, điểm danh trọn một vòng giữa điện thoại và web. **Chưa đạt mốc này thì chưa làm giao diện.**

**Giai đoạn 1, chiều thứ Ba: nền tảng và bằng chứng không phụ thuộc giao diện.** Làm màu, tên, logo, thanh tab, hai kiểu thẻ, vùng bấm 48. Song song, chụp bằng chứng Firebase: màn đăng nhập và tab Users, FCM ở ba trạng thái, Crashlytics, Remote Config trước và sau, tệp trong Storage. Những bằng chứng này chỉ cần app chạy, không cần giao diện cuối, nên làm ngay để giảm rủi ro. Làm xong giai đoạn này thì đã có bản đúng hướng và đã có phần lớn 2 điểm Firebase.

**Giai đoạn 2, thứ Tư: luồng chính của giảng viên.** Sửa `qrTokenPrev` trước, rồi làm GV-102, GV-001, GV-002. Đây là phần thầy xem đầu tiên.

**Giai đoạn 3, tối thứ Tư: mã số và TV-001, kèm luật và test Rules.** Đây là phần rủi ro kỹ thuật cao nhất, nên thử ngay trên điện thoại thật và trình duyệt khác. **Cổng quyết định sáng thứ Năm:** nếu chưa chạy ổn thì cắt, giữ nút theo bản Lab 3 và ghi vào bảng khác biệt. Không kéo dài sang giai đoạn sau.

**Giai đoạn 4, sáng thứ Năm: sinh viên, rồi các màn giảng viên còn lại.**

**Trưa thứ Năm: đóng băng giao diện.** Sau mốc này chỉ sửa lỗi.

**Giai đoạn 5, chiều thứ Năm: test và review.** Sửa chữ trong cả 16 ca ARTEMIS. Chạy mỗi ca 3 lần, phiên khám phá 15 đến 30 phút. Chụp DebugView từng sự kiện. Mở PR chạy CodeRabbit hoặc Copilot. Chuẩn bị sẵn khoá API cho model và tài khoản test Google từ hôm nay.

**Giai đoạn 6, tối thứ Năm đến thứ Sáu: tài liệu và sản phẩm nộp.** Cập nhật tài liệu ở mục 8, quay video, làm báo cáo và slide. Slide và video là 2 điểm, nên nên bắt đầu từ tối thứ Năm và giữ sáng thứ Sáu để sửa.

**Sau khi nộp Lab 3:** gộp `main` vào `final-system`, sửa xung đột, dựng lại màu cho web admin, rồi làm tiếp phần Final.

**Nếu thiếu giờ, cắt theo thứ tự này:**
1. Sáu bảng màu thêm.
2. Các khung trạng thái phụ như GV-001 .D4 và OV6.
3. TV-001.
4. Mã số, chỉ khi TV đã cắt, vì mã số chủ yếu phục vụ người ngồi xa TV.

Không cắt GV-102, tab Buổi học, phần test và bằng chứng.

## 8. Tài liệu phải cập nhật

- Repo Lab 2: `design/DESIGN.md`, `handoff/flutter-handoff.md`, `design/screen-spec.md` theo v2, hoặc tối thiểu thêm phần ghi rõ phần nào được v2 thay thế. Đây là tài liệu đề dùng để chấm.
- `docs/design-traceability.md`: mọi mã màn trỏ về trang v2. Id khung Lab 3 đã đổi: GV-004 `308:5155`, GV-103 `308:5285`, SV-003 `308:5363`, GV-092 `262:3145`, ghi chú `308:5554`.
- Bảng khác biệt: thêm D-L3 mới cho mã số, cách vào màn TV, trạng thái TV .E, số TV trễ tối đa 12 giây, SV-101 bỏ tên lớp, Chọn màu và bất kỳ phần nào bị cắt. Câu cuối của tài liệu ghi rằng khác biệt chưa có trong bảng là lỗi, nên bảng này cần đủ.
- Figma, bạn cấp quyền ghi từng lần: thêm sheet Chiếu lên TV, cập nhật khung ghi chú `308:5554`.
- `docs/test-plan.md`: đổi tên màn và các bước của cả 16 ca. TC-05 không còn hộp xác nhận. Thêm ca cho mã số và TV nếu còn giữ.
- `docs/architecture.md`: sơ đồ tuần tự FL-1 đang ghi "Chốt lần 1 đóng mã, lần 2 OV1", cần đổi.
- `README.md`: tên, bảng công cụ AI, link Figma trỏ trang v2, tài khoản test.

## 9. Điều dễ làm sai

- Giữ luật kiến trúc: màn hình không import Firebase, lọc và đếm nằm ở ViewModel. Lệnh kiểm tra có trong `docs/code-review.md`.
- Công tắc điểm danh là quyết định có lý do, thầy chê FAP phải bấm hai nút. Không đổi. Chuẩn bị sẵn một câu giải thích, vì repo học thiết kế của bạn có luật nháp CMP-001 nói ngược lại.
- Dữ liệu trên Figma chỉ là mẫu. App không được cứng số 7/20 hay 20 slot, mà phải tính từ Firestore. File `sample-data/` nên chỉnh để demo ra đúng các mức vắng.
- Hàng Có mặt: cho cả hàng bấm được, không chỉ ô xám cao 32.
- Icon SV-002 cần nhãn cho trình đọc màn hình. ARTEMIS cũng đọc cây này.
- Nền vàng nhạt rất dễ mất trên màn nhòe. Hãy xem thử trên laptop của bạn.
- Không điền kết quả chưa chạy vào tài liệu. Đề coi bằng chứng giả là vi phạm liêm chính.
- Câu còn mở chưa xử lý: tab Điểm danh có slot thứ Hai 19/10 mà lịch tháng không có chấm. Khi app lấy dữ liệu thật thì lỗi này tự hết, chỉ còn nằm trên Figma.
