/* Every number or claim on a slide that carries class="pf" data-p="<id>" opens one of these.
   Only things that actually ran (AGENTS.md: fake evidence is cheating). Change REF after the PR merges. */
(() => {
  const REF = 'final-system';
  const GH = 'https://github.com/thiengthb/PRM393_Lab03_SE190533';
  const blob = (p) => `${GH}/blob/${REF}/${p}`;
  const run = (id) => `${GH}/actions/runs/${id}`;
  window.PROOFS = {
    e2e33: { k: 'CI · E2E web', t: '33/33 ca E2E đạt', d: 'Playwright bấm qua mọi luồng trên bản web của app (giảng viên, sinh viên, admin, extension) với Firebase Emulator. Workflow "E2E builds", 09/11/2026 19:00.', href: run(42609057751) },
    rules196: { k: 'Emulator + CI · Security Rules', t: '196 ca test Rules đạt, 0 lỗi', d: 'firebase/tests/rules.test.mjs trên Firebase Emulator, 10/11/2026, sau các bản sửa CodeRabbit CR-15 và CR-25 (thêm 13 ca). CI xanh trên PR #29. Bảng từng ca: evidence/rules/rules-test-results.md.', href: run(42787095197) },
    debugview: { k: 'Analytics · DebugView', t: 'Đủ 13 trên 13 sự kiện có ảnh DebugView', d: 'Điện thoại thật, 10/11/2026: sign_up, import_classes, logout, login, attendance_session_open, attendance_close, view_class, export_report, view_student, reminder_send, correction_review. Web sinh viên, 11/11/2026: qr_scan, correction_submit (ảnh này).', img: 'assets/img/ev/analytics-04.png', href: blob('evidence/analytics/README.md') },
    cr44: { k: 'Code review', t: '44 phát hiện CR-01 đến CR-44', d: 'Claude review lượt 1 và 3 (CR-01 đến CR-14); CodeRabbit review PR #28 (CR-15 đến CR-30), PR #29 (CR-31 đến CR-39) và PR #30 (CR-40 đến CR-44). Mỗi dòng có file, loại, nhận hay bác và lý do; phát hiện nhận có commit sửa, phát hiện bác ghi lý do.', href: blob('docs/code-review.md') },
    unit70: { k: 'CI · flutter test', t: '59 test app + 11 test web admin đạt', d: 'Job "Analyze, test, build web", commit ae36281.', href: run(42608340989) },
    t1: { k: 'Test tay · Firebase thật', t: 'T1 điểm danh trọn một buổi', d: 'thien chạy 09/11 19:00 đến 19:25: TV, quét QR bằng iPhone, extension điền FAP giả 25/35 khớp app và chặn sai ngày.', img: 'assets/img/ev/ext-02.png', href: blob('evidence/extension/README.md') },
    extFill: { k: 'Test tay · Firebase thật', t: 'Extension điền 25 có mặt, 10 vắng', d: 'Bản nháp khớp Môn, Lớp, Ngày, Slot, Phòng; trang FAP giả 25 present · 10 absent.', img: 'assets/img/ev/ext-02.png', href: blob('evidence/extension/02-dien-25-co-mat.png') },
    extBlock: { k: 'Test tay · Firebase thật', t: 'Extension chặn sai ngày', d: 'Trang FAP là PRN221 SE1810 ngày 09/11, nguồn là slot 04/11: báo "Ngày không khớp", không điền.', img: 'assets/img/ev/ext-03.png', href: blob('evidence/extension/03-chan-sai-ngay.png') },
    fcm3: { k: 'Test tay · FCM', t: 'Nhận thông báo ở cả 3 trạng thái app', d: 'Điện thoại Oppo, 09/11 20:15 đến 20:20: đang mở, ở nền, đã tắt. Gửi bằng Send test message trên console.', img: 'assets/img/ev/fcm-04.png', href: blob('evidence/fcm/README.md') },
    crash: { k: 'Test tay · Crashlytics', t: 'Test crash lên console và web admin', d: '09/11 20:25 lỗi non-fatal, 20:26 Test crash: web admin Sự cố hiện ngay; Crashlytics console có 2 crash ngày 09/11.', img: 'assets/img/ev/crash-03.png', href: blob('evidence/crashlytics/README.md') },
    crashWeb: { k: 'Test tay · web admin', t: 'Màn Sự cố nhận bản tóm tắt ngay', d: 'Hai dòng Lỗi non-fatal và Test crash, vai trò Giảng viên, nền tảng android.', img: 'assets/img/ev/crash-02.png', href: blob('evidence/crashlytics/02-web-admin-test-crash.png') },
    dash98: { k: 'Firebase thật · Claude kiểm', t: 'Tổng quan admin: 4 lớp, 131 sinh viên, có mặt 98%', d: 'Sau khi sửa LOI-14 (chỉ mục tổng hợp sai thứ tự trường), 09/11 15:35. 2279 lượt có mặt, 47 vắng.', href: blob('docs/demo/loi.md') },
    lag: { k: 'Firebase thật · Claude đo', t: 'Mã mới tới máy chủ trong dưới 1,1 giây', d: 'Đo 09/11 19:05 trên app Windows: thời điểm đổi mã so với lúc tài liệu tv/{key} đổi trên máy chủ: 1,08 s, 0,32 s, 0,17 s.', href: blob('docs/demo/loi.md') },
    qrValid: { k: 'Thiết kế · Rules', t: 'Mã vừa thay còn nhận thêm 1 chu kỳ', d: 'qrTokenPrev + qrPrevExpiresAt: sinh viên quét chậm hoặc gõ mã số không bị báo hết hạn ngay lúc mã đổi. Có test Rules và E2E W48.', href: blob('firebase/firestore.rules') },
    ai: { k: 'Firebase thật · Claude kiểm', t: 'Gợi ý AI chạy trên điện thoại', d: '09/11 11:56: ô soạn hiện lời nhắc do Gemini viết sau khi qua App Check (quyết định 004).', href: blob('docs/decisions/004-app-check-cho-ai.md') },
    events13: { k: 'Analytics', t: '13 sự kiện, mỗi sự kiện trả lời một câu hỏi', d: 'docs/analytics-plan.md: trigger ở ViewModel nào, tham số, câu hỏi, phễu theo luồng.', href: blob('docs/analytics-plan.md') },
    rcE4: { k: 'Remote Config · điện thoại thật', t: 'Đổi trên console, app đổi theo không cần cài lại', d: '10/11/2026: qr_rotate_seconds 12 → 15 và absence_limit_percent 20 → 30. Khu demo nhận 15s, 30%; Vắng nhiều từ 6/4 (đỏ) thành 6/6 (vàng); mở lại mã đếm Đổi mã 15s. Sau đó trả về 12 và 20.', img: 'assets/img/ev/rc-06.png', href: blob('evidence/remote-config/README.md') },
    cloud: { k: 'Cloudinary · điện thoại thật', t: 'PDF báo cáo lớp đã lên Cloudinary', d: '10/11/2026 21:26: Xuất PDF PRM393 · SE1801 trên điện thoại; file PRM393-SE1801-20261110-2126 đứng đầu Assets.', img: 'assets/img/ev/storage-01.png', href: blob('evidence/storage/README.md') },
    crashKeys: { k: 'Crashlytics · tab Keys', t: 'Khoá tuỳ chỉnh đi kèm crash', d: 'Sự kiện 09/11 20:26 trên CPH1931: last_error_where = demo_import_parse và lý do lỗi. Khoá role, term nằm dưới khung ảnh.', img: 'assets/img/ev/crash-04.png', href: blob('evidence/crashlytics/README.md') },
    rc9: { k: 'Remote Config', t: '9 tham số có giá trị mặc định trong app', d: 'firebase/remote-config-defaults.json; app đọc qua ConfigService, khu demo hiện giá trị đang dùng và nguồn (remote/default).', href: blob('firebase/remote-config-defaults.json') },
    loi: { k: 'Nhật ký lỗi', t: 'Lỗi tìm được khi test, kèm cách sửa', d: 'docs/demo/loi.md: ai tìm, ở đâu, thấy gì, trạng thái; lỗi không phải của app cũng ghi lại.', href: blob('docs/demo/loi.md') },
    trace: { k: 'Traceability', t: 'Mọi chỗ khác thiết kế đều có mã D-…', d: 'docs/design-traceability.md: màn, khác biệt, lý do, đã vẽ lại hay chưa.', href: blob('docs/design-traceability.md') },
    t3: { k: 'Test tay · chưa đo', t: 'Thời gian duyệt lớp liên vai trò', d: 'Luồng đã chạy đúng trên Firebase thật 09/11 (T3). Số giây sẽ đo lại khi quay video; chưa có số thì không ghi số.', href: blob('docs/cross-role-flow.md') },
  };
})();
