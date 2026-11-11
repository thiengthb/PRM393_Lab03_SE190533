# Script thuyết trình Attendo

Lời nói từng slide, khớp với ghi chú trong slide (bấm **N** để hiện ghi chú, **P** để mở cửa sổ người nói). Thời lượng là ước tính, chưa bấm giờ thử.

## Lab 3 · Công nghệ

Phần nói khoảng 10 phút 30 giây (slide 16, 17 là phụ lục, chỉ mở khi thầy hỏi).

### Slide 1 · Attendo · App điểm danh bằng mã QR (30 giây)

Em chào thầy và các bạn. Em là Thiên. Bài Lab 3 của em là Attendo, app điểm danh bằng mã QR, viết bằng Flutter và Firebase. Em đi theo thứ tự: bài toán, thiết kế so với app, kiến trúc, rồi từng dịch vụ Firebase, cuối cùng là kiểm thử và review code. Với mỗi dịch vụ em nói nó là gì, code nằm ở đâu, lỗi thì app làm gì, và bằng chứng nó đã chạy.

### Slide 2 · Bài toán và persona (45 giây)

Ba chuyện em thấy ở lớp: điểm danh gọi tên mất mấy phút đầu giờ; thầy hay quên chốt hoặc bấm nhầm một em, sửa lại phải qua giáo vụ; và sinh viên không biết mình sắp chạm ngưỡng vắng cho tới khi đã quá. Attendo nhắm thẳng ba chuyện đó. Persona chính từ Lab 2 là thầy Minh Quân, dạy dày; tiêu chí thành công là mở app tới chốt một slot không quá 20 giây. Sự kiện attendance_close đo được đoạn từ lúc mở mã tới lúc chốt, gồm cả thời gian chờ lớp quét; đoạn từ mở app tới mở mã em chưa đo.

### Slide 3 · Figma Lab 2 và app (45 giây)

Đây là ba màn chính đặt cạnh nhau, bên trái là Figma Lab 2, bên phải là app chạy thật. Luồng và bố cục giữ nguyên; chỗ nào khác đều có mã trong bảng traceability. Màn phiên điểm danh: chu kỳ đổi mã đọc từ Remote Config, và khi giảng viên mở cùng lúc trên điện thoại và laptop thì chỉ một máy được đổi mã. Màn báo sai đổi ô gõ tự do thành năm lý do có sẵn, để Analytics đếm được lý do nào hay gặp. Màn nhắc sinh viên thêm nút Gợi ý AI của phần Final. Màu và font đổi cho cả hệ thống, cũng có mã riêng.

### Slide 4 · MVVM với Riverpod (45 giây)

Kiến trúc là MVVM với Riverpod. Có năm cửa vào: app Android và app Windows cho giảng viên, web cho sinh viên và màn chiếu TV, web admin cho giáo vụ, và extension Chrome điền FAP. Tất cả dùng chung package core. Luật cứng: màn hình chỉ đọc state và gửi ý định; lọc và đếm nằm ở ViewModel; chỉ Repository mới import Firebase. Bên phải là các dịch vụ; Cloud Storage cần gói Blaze nên em đưa file PDF lên Cloudinary, thầy đã cho phép.

### Slide 5 · Design system trong code (40 giây)

Design system đi theo hai đường. Token màu, khoảng cách, bo góc, font nằm trong một file tokens.dart; theme dựng ColorScheme và TextTheme từ token, nên màn hình không viết mã màu nào. Đổi bảng màu trong Tài khoản là cả app đổi ngay, có 12 bảng, mỗi bảng có bản sáng và tối. Component trong Figma thành widget dùng chung trong packages/core, đủ các trạng thái như bấm, tắt, đang tải, lỗi. Extension không chạy Flutter nên em sinh file CSS từ cùng token. Bảng đầy đủ ở docs/design-traceability.md mục 3.

### Slide 6 · Authentication (35 giây)

Authentication: Firebase cấp uid và token, app không giữ mật khẩu. Vai trò không nằm trong Auth mà nằm ở users/uid trong Firestore, và Security Rules đọc request.auth để quyết định. Router chặn người vào sai cổng, ví dụ sinh viên mở app giảng viên. Một chi tiết: Firebase bật chống dò email, nên sai email hay sai mật khẩu đều báo cùng một câu, em chỉnh câu báo cho đúng. Ảnh bên phải là danh sách người dùng trên Firebase console, có cả tài khoản Google lẫn email.

### Slide 7 · Cloud Firestore và Security Rules (40 giây)

Firestore là nơi giữ mọi dữ liệu. Điểm em muốn nhấn: sinh viên không đọc được slot, vì slot chứa mã QR; sinh viên chỉ được ghi đúng một bản ghi điểm danh của chính mình, khi mã còn hạn và em có trong danh sách lớp. Luật đó có 196 ca test chạy trên Emulator mỗi lần em đẩy code, thầy bấm vào số 196 là ra lần chạy CI. Ảnh là Rules đang chạy trên console. Nếu mất mạng lúc chốt thì app lưu trên máy và hiện nút Thử lại.

### Slide 8 · Cloud Messaging (FCM) (50 giây)

FCM, em trả lời đúng năm câu thầy hỏi. Token là địa chỉ của một lần cài app trên một máy, không phải của người; cài lại app là token đổi. Máy chủ FCM cấp token qua getToken. SDK giữ token trên máy, và app ghi thêm một bản lên Firestore để phía gửi biết gửi tới đâu, Rules chỉ cho chủ tài khoản đọc. Gửi: không có server riêng, nên em viết script Node dùng Admin SDK với service account, gọi FCM HTTP v1; file service account là bí mật, không commit. Client xử lý ba trạng thái; ảnh là điện thoại thật nhận thông báo lúc app đang mở và lúc đã tắt. Nếu người dùng chưa cho phép thông báo thì Khu demo hiện nút xin quyền.

### Slide 9 · Analytics (40 giây)

Analytics: em không ghi sự kiện cho có. Mỗi sự kiện gắn với một câu hỏi, ví dụ mở mã rồi có chốt không, sinh viên quét lỗi vì sao, giảng viên xem hồ sơ em vắng nhiều rồi có nhắc không. Kế hoạch đủ 13 sự kiện nằm trong docs/analytics-plan. Ảnh là DebugView trên điện thoại thật: sự kiện attendance_close kèm tham số. Em đã có ảnh đủ 13 sự kiện: 11 trên điện thoại, 2 sự kiện quét mã và báo sai trên web sinh viên.

### Slide 10 · Crashlytics (40 giây)

Crashlytics: thầy dặn có nút làm app crash và admin xem được trên web. Nút Test crash nằm ở Khu demo. Vấn đề là Crashlytics không có API cho client đọc, nên ngoài báo cáo gửi Crashlytics, app ghi thêm một bản tóm tắt vào Firestore, chỉ admin đọc được. Ảnh bên trái là web admin hiện dòng Test crash ngay lúc bấm; bên phải là Crashlytics console với hai crash của lần chạy 09/11. Stack đầy đủ thì xem ở console.

### Slide 11 · Remote Config (40 giây)

Remote Config giữ những con số em có thể muốn đổi mà không phát hành lại app: chu kỳ đổi mã, thời gian mở mã, ngưỡng vắng, và cờ tắt AI. Mỗi tham số đều có giá trị mặc định trong app, nên mất mạng vẫn chạy. Ba ảnh là điện thoại thật hôm 10/11: em đổi ngưỡng vắng từ 20 lên 30 phần trăm và chu kỳ đổi mã từ 12 lên 15 giây trên console, app đổi theo mà không cần cài lại.

### Slide 12 · Cloudinary (35 giây)

Cloud Storage giờ phải lên gói Blaze, em giữ gói Spark nên dùng Cloudinary, thầy đã cho phép. Luồng có ba bước: tạo PDF trên máy, tải lên bằng preset unsigned vào thư mục theo uid, rồi ghi metadata vào Firestore. Không có API secret nằm trong app; Rules chỉ nhận link đúng thư mục của người ghi, nên không ai ghi đè được link của người khác. Ảnh là file PDF vừa tải lên, nằm đầu danh sách trên Cloudinary. Tải lên lỗi thì app báo và ghi một lỗi non-fatal lên Crashlytics.

### Slide 13 · ARTEMIS và các lớp test (60 giây)

Phần kiểm thử chính của Lab 3 là ARTEMIS. Em viết 17 ca chạy trên điện thoại thật, có 5 nhánh lỗi và 4 chỗ phải bấm vào hộp thoại của Android như chọn tài khoản Google hay cấp quyền camera. Mỗi ca em bắt agent trả về con số hoặc dòng chữ nó đọc được trên màn hình rồi so, chứ không chỉ tin vào chữ SUCCESS. Về kết quả, em nói thật là em mới chạy được một phần: 12 trên 17 ca, mỗi ca một lần chứ chưa đủ ba lần, vì hết ngân sách gọi model. Ba ca đạt hẳn. Sáu ca agent làm đúng trên giao diện nhưng trượt ở bước kiểm log Analytics, do em chưa bật log chi tiết của Firebase trên máy, nên đây là lỗi cấu hình test chứ không phải lỗi app. Ba ca còn lại trượt, trong đó một ca do nạp dữ liệu lỗi. Năm ca chưa chạy. Bên phải là các lớp test chạy trên CI mỗi lần em đẩy code: 70 unit test, 196 ca Rules, 33 luồng E2E trên bản web, và sáu ca em test tay trên Firebase thật.

### Slide 14 · AI code review (45 giây)

Code review bằng AI có hai nguồn. Claude review lượt đầu, nhưng chính Claude viết phần lớn mã nên lượt đó không độc lập; vì vậy em cho CodeRabbit review trên Pull Request. Tổng cộng 44 phát hiện, mỗi cái có file, loại, nhận hay bác và vì sao. CR-01 là lỗi bảo mật thật: bản đầu sinh viên đọc được slot nên thấy luôn mã QR. CR-15 do CodeRabbit tìm: ai cũng tự khai được MSSV của người khác, em sửa bằng một khoá MSSV trong Rules và thêm test. CR-30 em bác vì đo theo kích thước file thật thì chưa tới một mili giây.

### Slide 15 · Khó khăn và bài học (40 giây)

Ba bài học: nhiều lỗi chỉ hiện trên Firebase thật, như chỉ mục bị sai thứ tự trường mà Emulator không bắt; viết test cho Rules trước rẻ hơn sửa sau; và con số nào trên slide cũng phải trỏ về nơi nó chạy. Giới hạn: không có server nên thông báo gửi bằng script; web sinh viên chưa nhận thông báo đẩy. Công cụ AI em dùng: Claude Code viết phần lớn code, tài liệu và cả bộ slide này; CodeRabbit review PR; ARTEMIS để test; Gemini cho tính năng gợi ý. Từng phiên em ghi lại trong docs/ai-log. Em cảm ơn thầy.

### Slide 16 · Mã QR đổi mỗi 12 giây (phụ lục)

Đây là phần khó nhất. Mỗi 12 giây máy giảng viên sinh token mới và một mã 6 số, ghi vào slot và vào tài liệu tv cho màn chiếu, trong cùng một lần ghi. Sinh viên quét hoặc gõ mã, ghi bản điểm danh của mình; Rules kiểm token đúng và còn hạn. Mã vừa thay còn nhận thêm một chu kỳ để em gõ chậm không bị báo hết hạn. Em đo trên Firebase thật: mã mới tới máy chủ dưới 1,1 giây. Nếu giảng viên mở cả điện thoại lẫn laptop, chỉ một máy được đổi mã, máy kia hiện theo.

### Slide 17 · Bảng bằng chứng (phụ lục)

Đây là bảng tổng: mỗi dịch vụ một bằng chứng, và thầy bấm vào chỗ gạch chấm là mở đúng ảnh hoặc lần chạy CI. Dòng nào chưa có, em ghi là chưa có.

## Final · Hệ thống

Phần nói khoảng 7 phút 40 giây (chưa tính demo trực tiếp ở slide 11 đến 13).

### Slide 1 · Attendo · Hệ thống điểm danh bằng mã QR (25 giây)

Em là Thiên. Attendo là hệ thống điểm danh bằng mã QR: giảng viên mở mã trên điện thoại hoặc laptop, sinh viên quét, giáo vụ quản lý trên web, và cuối buổi extension điền sẵn kết quả vào FAP. Em trình bày theo bốn phần: vấn đề, thiết kế, demo theo từng luồng, và bằng chứng.

### Slide 2 · Bối cảnh, vấn đề và giải pháp (50 giây)

Hiện nay điểm danh là gọi tên rồi bấm từng em trên FAP. Mất vài phút đầu giờ, dễ quên chốt hay bấm nhầm, sửa thì phải nhờ giáo vụ. Còn sinh viên thường chỉ biết mình sắp cấm thi khi đã quá ngưỡng. Ba pain point và cách giải. Một, thời gian đầu giờ: mã QR đổi liên tục, sinh viên tự quét. Hai, quên chốt và sửa khó: app nhắc slot chưa chốt, sinh viên báo sai và giảng viên duyệt ngay trong app, cuối cùng extension điền FAP từ bản đã chốt. Ba, biết ngưỡng muộn: sinh viên luôn thấy mình đã vắng bao nhiêu trên tổng được phép, giảng viên nhắc sớm và có AI gợi ý lời nhắc.

### Slide 3 · Actor và persona (35 giây)

Bốn actor. Giảng viên dùng app trên điện thoại hoặc Windows, cộng extension trên Chrome. Sinh viên chỉ cần trình duyệt. Giáo vụ và quản trị dùng web admin; theo lời thầy, web chủ yếu phục vụ admin. Nhóm phát triển theo dõi trên Firebase console. Ba persona lấy từ Lab 2: thầy Minh Quân dạy dày là người dùng chính; cô Thu Hà hay quên điểm danh; và bạn Gia Huy, sinh viên ít khi để ý số buổi vắng của mình.

### Slide 4 · Business flow (45 giây)

Business flow theo bốn làn. Giảng viên nhập file lớp, giáo vụ duyệt, rồi giảng viên mới mở mã được. Mã hiện trên app và trên màn chiếu TV; sinh viên quét hoặc gõ mã. Cuối giờ giảng viên đóng mã và chốt, extension lấy bản đã chốt điền vào FAP. Nếu sinh viên thấy sai, em báo sai và giảng viên duyệt.

### Slide 5 · Bốn workflow lõi (45 giây)

Bốn workflow lõi. WF-01 điểm danh một buổi, từ mở mã tới điền FAP, có các nhánh mất mạng lúc chốt, hoàn tác và quên chốt. WF-02 báo sai và duyệt. WF-03 là luồng liên vai trò: giảng viên nhập lớp, giáo vụ duyệt trên web, app đổi ngay. WF-04 nhắc sinh viên vắng nhiều, có AI gợi ý; AI lỗi hay bị tắt thì vẫn có lời mẫu.

### Slide 6 · State machine (40 giây)

Ba state machine. Slot đi từ chưa mở, đang mở mã, đã đóng mã, tới đã chốt; được mở lại mã khi chưa chốt, và hoàn tác hay sửa sau khi chốt. Báo sai: chờ duyệt rồi duyệt hoặc từ chối có lý do. Lớp: chờ giáo vụ, duyệt hoặc từ chối, bị từ chối thì nhập lại. Mỗi mũi tên tương ứng một luật trong Security Rules, có test.

### Slide 7 · Kiến trúc hệ thống và công nghệ (45 giây)

Kiến trúc: một package lõi dùng chung cho cả bốn client Flutter, cộng extension Chrome. Không có server riêng: Firebase gói Spark lo xác thực, dữ liệu, Hosting, thông báo, theo dõi lỗi và AI; Cloudinary giữ file PDF. GitHub Actions chạy kiểm tra và dựng bản cài mỗi lần đẩy code. Hai quyết định kiến trúc: không dựng server, để Security Rules quyết định ai được ghi gì; và dồn logic vào một lõi dùng chung để không viết lại theo từng thiết bị.

### Slide 8 · Giao diện theo thiết bị (35 giây)

Cùng một màn phiên điểm danh trên ba thiết bị. Điện thoại: một cột, nút chính ở đáy. Laptop: mã bên trái, bảng lớp bên phải, có phím tắt. Màn chiếu TV: chỉ mã to và số đã có mặt, không cần đăng nhập. Cả ba dùng chung một ViewModel, nên logic chỉ viết một lần.

### Slide 9 · Traceability (25 giây)

Truy vết: mỗi yêu cầu đi tới màn, tới test tự động, tới bằng chứng chạy thật. Chỗ nào khác thiết kế ban đầu đều có mã D trong bảng traceability, kèm lý do.

### Slide 10 · Demo plan (35 giây)

Em demo bốn workflow theo đúng thứ tự một buổi học. Đầu tiên là điểm danh một buổi, từ mở mã tới điền FAP. Sau đó sinh viên báo sai và giảng viên duyệt. Thứ ba là luồng liên vai trò: quản trị duyệt lớp trên web thì app giảng viên đổi ngay. Cuối cùng là nhắc sinh viên vắng nhiều có AI gợi ý, và em tắt AI bằng Remote Config. Dữ liệu demo em nạp lại trước buổi, mỗi vai trò có một tài khoản riêng, và nếu mạng trục trặc thì em có video dự phòng.

### Slide 11 · WF-01 · Điểm danh một buổi (demo trực tiếp)

Demo WF-01, trên máy em sẽ làm trực tiếp; đây là các bước. Một, giảng viên mở mã. Hai, sinh viên quét hoặc gõ mã sáu số, máy báo đã ghi nhận và số có mặt tăng ngay. Ba, đóng mã rồi chốt, có hoàn tác. Bốn, extension đọc trang FAP, lấy bản đã chốt, kiểm khớp môn, lớp, ngày, slot rồi mới điền. Extension không bao giờ tự bấm Save trên FAP.

### Slide 12 · WF-02 Báo sai · WF-03 Duyệt lớp (demo trực tiếp)

Hai luồng liên vai trò. WF-03: giảng viên vừa nhập lớp thì lớp ở trạng thái chờ; giáo vụ bấm duyệt trên web admin, app giảng viên đổi ngay mà không cần tải lại, hộp thư có tin. Số giây của bước này em chưa đo, em ghi ở mục giới hạn. WF-02: sinh viên báo sai có lý do, giảng viên duyệt hoặc từ chối; từ chối thì phải có lý do và em đó không báo lại buổi đó được.

### Slide 13 · WF-04 · Gợi ý lời nhắc bằng AI (demo trực tiếp)

AI mức hai: ở màn nhắc sinh viên, nút Gợi ý AI gọi Gemini qua Firebase AI Logic, yêu cầu trả JSON đúng lược đồ: giọng nhắc, lời nhắc, bước tiếp theo. App kiểm chặt, sai lược đồ thì báo lỗi chứ không đoán. Kết quả chỉ điền vào ô soạn, giảng viên đọc, sửa, rồi mới gửi. Prompt, model và công tắc bật tắt đều nằm ở Remote Config. Từ tháng 11 Firebase bắt buộc App Check cho AI Logic, em xử lý ở quyết định 004.

### Slide 14 · Kiểm thử (40 giây)

Bằng chứng: 70 unit test, 196 ca Rules, 33 luồng E2E, sáu ca test tay trên Firebase thật; mọi con số bấm vào là ra lần chạy CI hoặc ảnh. Test thật tìm ra lỗi mà Emulator không thấy, như chỉ mục tổng hợp sai thứ tự trường. ARTEMIS em mới chạy được một phần, 12 trên 17 ca và mỗi ca một lần, em ghi đúng như vậy.

### Slide 15 · Kết quả, giới hạn và bài học (40 giây)

Tổng kết: bốn workflow chạy trên Firebase thật, năm cửa vào dùng chung một lõi, không cần server. Giới hạn: thông báo gửi bằng script, web sinh viên chưa có thông báo đẩy, extension chỉ bật cho FAP giả lập. Bài học lớn nhất của em là test trên Firebase thật bắt được những lỗi Emulator bỏ qua, như chỉ mục sai thứ tự hay App Check, và luồng liên vai trò phải mở hai màn hình cùng lúc mới thấy lỗi. Bước tiếp: lên Blaze thì dùng Cloud Functions gửi thông báo tự động, thử với một lớp thật, và xin phép trước khi bật extension cho FAP thật. Em cảm ơn thầy.
