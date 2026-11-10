/* Every number or claim on a slide that carries class="pf" data-p="<id>" opens one of these.
   Only things that actually ran (AGENTS.md: fake evidence is cheating). Change REF after the PR merges. */
(() => {
  const REF = 'final-system';
  const GH = 'https://github.com/thiengthb/PRM393_Lab03_SE190533';
  const blob = (p) => `${GH}/blob/${REF}/${p}`;
  const run = (id) => `${GH}/actions/runs/${id}`;
  window.PROOFS = {
    rules181: { k: 'CI · Security Rules', t: '181 ca test Rules đạt, 0 lỗi', d: 'Job "Security Rules trên Emulator" của CI chạy firebase/tests/rules.test.mjs trên Firebase Emulator, commit ae36281 ngày 09/11/2026.', href: run(42608340989) },
    e2e33: { k: 'CI · E2E web', t: '33/33 ca E2E đạt', d: 'Playwright bấm qua mọi luồng trên bản web của app (giảng viên, sinh viên, admin, extension) với Firebase Emulator. Workflow "E2E builds", 09/11/2026 19:00.', href: run(42609057751) },
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
    cr14: { k: 'Code review', t: '14 phát hiện CR-01 đến CR-14', d: 'Mỗi phát hiện ghi file, loại, nhận hay bác và lý do; phát hiện nhận đều có commit sửa.', href: blob('docs/code-review.md') },
    events13: { k: 'Analytics', t: '13 sự kiện, mỗi sự kiện trả lời một câu hỏi', d: 'docs/analytics-plan.md: trigger ở ViewModel nào, tham số, câu hỏi, phễu theo luồng.', href: blob('docs/analytics-plan.md') },
    rc9: { k: 'Remote Config', t: '9 tham số có giá trị mặc định trong app', d: 'firebase/remote-config-defaults.json; app đọc qua ConfigService, khu demo hiện giá trị đang dùng và nguồn (remote/default).', href: blob('firebase/remote-config-defaults.json') },
    loi: { k: 'Nhật ký lỗi', t: 'Lỗi tìm được khi test, kèm cách sửa', d: 'docs/demo/loi.md: ai tìm, ở đâu, thấy gì, trạng thái; lỗi không phải của app cũng ghi lại.', href: blob('docs/demo/loi.md') },
    trace: { k: 'Traceability', t: 'Mọi chỗ khác thiết kế đều có mã D-…', d: 'docs/design-traceability.md: màn, khác biệt, lý do, đã vẽ lại hay chưa.', href: blob('docs/design-traceability.md') },
    t3: { k: 'Test tay · chưa đo', t: 'Thời gian duyệt lớp liên vai trò', d: 'Luồng đã chạy đúng trên Firebase thật 09/11 (T3). Số giây sẽ đo lại khi quay video; chưa có số thì không ghi số.', href: blob('docs/cross-role-flow.md') },
  };
})();
