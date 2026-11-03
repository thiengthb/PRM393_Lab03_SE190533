// Test Security Rules trên Emulator cho nhánh ui-v2 (Lab 3).
// Mỗi vai trò (giảng viên, sinh viên, chưa đăng nhập) × mỗi collection có ca Allowed và ca Denied.
// Chạy: cd firebase/tests && npm ci && npm test  → in bảng vào evidence/rules/rules-test-results.md
import { after, before, beforeEach, test } from 'node:test';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  addDoc, collection, collectionGroup, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp,
  setDoc, Timestamp, updateDoc, where, writeBatch,
} from 'firebase/firestore';

const RULES = new URL('../firestore.rules', import.meta.url);
const OUT = new URL('../../evidence/rules/rules-test-results.md', import.meta.url);
const start = Timestamp.fromDate(new Date('2026-11-03T00:30:00Z'));
const future = Timestamp.fromDate(new Date(Date.now() + 3600_000));
const past = Timestamp.fromDate(new Date(Date.now() - 60_000));

let env;
const results = [];

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const ROLES = { student: 'stu', lecturer: 'lec', lecturer2: 'lec2', anon: null };

const slotCopy = {
  slotId: 's1', lecturerId: 'lec', classId: 'c1', subject: 'PRM393', classCode: 'SE1801',
  term: 'Fall 2026', start, slotNo: 1, room: 'P.305', totalSlots: 20,
};
const scan = (over = {}) => ({
  ...slotCopy, studentCode: 'SE190101', studentName: 'An', present: true, source: 'scan',
  final: false, token: 'tok', scannerUid: 'stu', ...over,
});
const slotData = (over = {}) => ({
  lecturerId: 'lec', classId: 'c1', subject: 'PRM393', classCode: 'SE1801', term: 'Fall 2026',
  start, slotNo: 1, room: 'P.305', totalSlots: 20, ...over,
});
const codeData = (over = {}) => ({ lecturerId: 'lec', slotId: 's1', classId: 'c1', payload: 'qa2|s1|tok', expiresAt: future, ...over });
const tvData = (over = {}) => ({
  lecturerId: 'lec', slotId: 's1', title: 'PRM393 · SE1801', subtitle: 'P.305', open: true, present: 3, total: 35,
  qr: 'qa2|s1|tok', code: '482917', rotatedAt: future, rotateSeconds: 12, endsAt: future, validUntil: future, ...over,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-hereby',
    firestore: { rules: readFileSync(RULES, 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    const set = (p, v) => setDoc(doc(d, p), v);
    await set('users/stu', { role: 'student', displayName: 'An', email: 's@x', studentCode: 'SE190101' });
    await set('users/stu2', { role: 'student', displayName: 'Bình', email: 's2@x', studentCode: 'SE190999' });
    await set('users/lec', { role: 'lecturer', displayName: 'Q', email: 'l@x' });
    await set('users/lec2', { role: 'lecturer', displayName: 'R', email: 'l2@x' });
    await set('classes/c1', { lecturerId: 'lec', term: 'Fall 2026', subject: 'PRM393', code: 'SE1801', studentCount: 1, totalSlots: 20 });
    await set('classes/c2', { lecturerId: 'lec2', term: 'Fall 2026', subject: 'MAD101', code: 'SE1802', studentCount: 1, totalSlots: 20 });
    await set('classes/c1/students/SE190101', { studentCode: 'SE190101', name: 'An', lecturerId: 'lec' });
    await set('slots/s1', slotData({ qrOpen: true, qrToken: 'tok', qrExpiresAt: future, qrTokenPrev: 'old', qrPrevExpiresAt: future }));
    await set('slots/s2', slotData({ lecturerId: 'lec2', classId: 'c2', subject: 'MAD101', classCode: 'SE1802' }));
    await set('slots/s1/attendance/SE190102', { ...slotCopy, studentCode: 'SE190102', studentName: 'B', present: true, source: 'manual', final: false });
    await set('requests/r1', { studentUid: 'stu', studentCode: 'SE190101', lecturerId: 'lec', slotId: 's1', reason: 'r', note: '', status: 'pending' });
    await set('reminders/m1', { lecturerId: 'lec', classId: 'c1', message: 'm' });
    await set('reports/p1', { ownerUid: 'lec', classId: 'c1', fileName: 'a.pdf', sizeKb: 1, destination: 'device' });
    await set('qrCodes/482917', codeData());
    await set('qrCodes/111111', codeData({ expiresAt: past }));
    await set('qrCodes/222222', codeData({ lecturerId: 'lec2', slotId: 's2', classId: 'c2' }));
    await set('qrCodes/333333', codeData({ lecturerId: 'lec2', slotId: 's2', classId: 'c2', expiresAt: past }));
    await set('tv/ABCDEFGH23', tvData());
    await set('tv/OLDKEY2345', tvData({ validUntil: past }));
  });
});

after(async () => {
  await env.cleanup();
  const pass = results.filter((r) => r.result === 'Pass').length;
  const rows = results.map((r) => `| ${r.id} | ${r.coll} | ${r.role} | ${r.op} | ${r.expected} | ${r.result} |`).join('\n');
  mkdirSync(new URL('.', OUT), { recursive: true });
  writeFileSync(OUT, `# Kết quả test Security Rules\n\nSinh tự động bởi \`firebase/tests/rules.test.mjs\` trên Firestore Emulator, ${new Date().toISOString()}.\n\n` +
    `**${pass}/${results.length} ca đạt.**\n\n| ID | Collection | Vai trò | Thao tác | Mong đợi | Kết quả |\n|---|---|---|---|---|---|\n${rows}\n`);
});

let n = 0;
function allow(coll, role, op, fn) { add(coll, role, op, 'Allowed', fn); }
function deny(coll, role, op, fn) { add(coll, role, op, 'Denied', fn); }
function add(coll, role, op, expected, fn) {
  const id = `R-${String(++n).padStart(3, '0')}`;
  test(`${id} ${coll} ${role} ${op} → ${expected}`, async () => {
    const entry = { id, coll, role, op, expected, result: 'Fail' };
    results.push(entry);
    const p = fn(db(ROLES[role]));
    await (expected === 'Allowed' ? assertSucceeds(p) : assertFails(p));
    entry.result = 'Pass';
  });
}

const pdoc = (d, p) => doc(d, p);

// ---------- users ----------
allow('users', 'student', 'đọc hồ sơ của mình', (d) => getDoc(pdoc(d, 'users/stu')));
deny('users', 'student', 'tự đổi role thành lecturer', (d) => updateDoc(pdoc(d, 'users/stu'), { role: 'lecturer' }));
deny('users', 'student', 'đổi MSSV', (d) => updateDoc(pdoc(d, 'users/stu'), { studentCode: 'SE190102' }));
allow('users', 'lecturer', 'đổi công tắc nhắc', (d) => updateDoc(pdoc(d, 'users/lec'), { reminderBeforeSlot: false }));
deny('users', 'lecturer', 'đọc hồ sơ người khác', (d) => getDoc(pdoc(d, 'users/stu')));
deny('users', 'anon', 'đọc hồ sơ', (d) => getDoc(pdoc(d, 'users/stu')));

// ---------- classes ----------
allow('classes', 'lecturer', 'liệt kê lớp của mình', (d) => getDocs(query(collection(d, 'classes'), where('lecturerId', '==', 'lec'))));
deny('classes', 'lecturer', 'đọc lớp người khác', (d) => getDoc(pdoc(d, 'classes/c2')));
deny('classes', 'student', 'đọc lớp', (d) => getDoc(pdoc(d, 'classes/c1')));
deny('classes', 'anon', 'đọc lớp', (d) => getDoc(pdoc(d, 'classes/c1')));

// ---------- classes/{id}/students ----------
const stuData = (uid) => ({ studentCode: 'SE190102', name: 'B', lecturerId: uid });
allow('students', 'lecturer', 'thêm sinh viên vào lớp của mình', (d) => setDoc(pdoc(d, 'classes/c1/students/SE190102'), stuData('lec')));
deny('students', 'lecturer2', 'ghi vào lớp người khác', (d) => setDoc(pdoc(d, 'classes/c1/students/SE190102'), stuData('lec2')));
deny('students', 'student', 'đọc danh sách lớp', (d) => getDocs(collection(d, 'classes/c1/students')));

// ---------- slots ----------
allow('slots', 'lecturer', 'mở mã QR slot của mình', (d) => updateDoc(pdoc(d, 'slots/s1'), { qrOpen: true, qrToken: 'x', qrExpiresAt: future }));
deny('slots', 'lecturer2', 'sửa slot người khác', (d) => updateDoc(pdoc(d, 'slots/s1'), { qrToken: 'x' }));
deny('slots', 'student', 'đọc slot (có qrToken)', (d) => getDoc(pdoc(d, 'slots/s1')));
deny('slots', 'anon', 'đọc slot', (d) => getDoc(pdoc(d, 'slots/s1')));

// ---------- attendance ----------
const att = 'slots/s1/attendance/SE190101';
allow('attendance', 'student', 'quét đúng mã trong hạn', (d) => setDoc(pdoc(d, att), scan()));
allow('attendance', 'student', 'quét mã vừa thay (qrTokenPrev) trong hạn', (d) => setDoc(pdoc(d, att), scan({ token: 'old' })));
deny('attendance', 'student', 'quét sai mã', (d) => setDoc(pdoc(d, att), scan({ token: 'sai' })));
deny('attendance', 'student', 'điểm danh hộ MSSV khác', (d) => setDoc(pdoc(d, 'slots/s1/attendance/SE190102'), scan({ studentCode: 'SE190102' })));
deny('attendance', 'student', 'ghi sang lớp khác (classId không khớp)', (d) => setDoc(pdoc(d, att), scan({ classId: 'c2' })));
allow('attendance', 'student', 'đọc buổi của mình (collection group)', (d) => getDocs(query(collectionGroup(d, 'attendance'), where('studentCode', '==', 'SE190101'))));
allow('attendance', 'lecturer', 'đánh dấu tay', (d) => setDoc(pdoc(d, att), { ...slotCopy, studentCode: 'SE190101', studentName: 'An', present: true, source: 'manual', final: false }));
deny('attendance', 'lecturer2', 'đánh dấu ở slot người khác', (d) => setDoc(pdoc(d, att), { ...slotCopy, lecturerId: 'lec2', studentCode: 'SE190101', present: true, source: 'manual', final: false }));
deny('attendance', 'anon', 'quét mã', (d) => setDoc(pdoc(d, att), scan()));
test('R-X1 attendance: mã vừa thay đã hết hạn → Denied', async () => {
  const entry = { id: 'R-X1', coll: 'attendance', role: 'student', op: 'quét mã cũ sau 1 chu kỳ', expected: 'Denied', result: 'Fail' };
  results.push(entry);
  await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'slots/s1'), { qrPrevExpiresAt: past }));
  await assertFails(setDoc(pdoc(db('stu'), att), scan({ token: 'old' })));
  entry.result = 'Pass';
});

// ---------- qrCodes (mã số 6 chữ) ----------
allow('qrCodes', 'student', 'đọc đúng mã còn hạn của lớp mình', (d) => getDoc(pdoc(d, 'qrCodes/482917')));
deny('qrCodes', 'student', 'đọc mã đã hết hạn', (d) => getDoc(pdoc(d, 'qrCodes/111111')));
deny('qrCodes', 'student', 'đọc mã của lớp không có tên', (d) => getDoc(pdoc(d, 'qrCodes/222222')));
deny('qrCodes', 'student', 'liệt kê để dò mã', (d) => getDocs(collection(d, 'qrCodes')));
deny('qrCodes', 'student', 'đọc mã không tồn tại', (d) => getDoc(pdoc(d, 'qrCodes/999999')));
allow('qrCodes', 'lecturer', 'ghi mã mới cùng lần đổi mã (batch)', (d) => {
  const b = writeBatch(d);
  b.update(pdoc(d, 'slots/s1'), { qrToken: 'tok2', qrExpiresAt: future });
  b.set(pdoc(d, 'qrCodes/654321'), codeData({ payload: 'qa2|s1|tok2' }));
  b.delete(pdoc(d, 'qrCodes/482917'));
  return b.commit();
});
deny('qrCodes', 'lecturer', 'ghi đè mã còn hạn của lớp khác', (d) => setDoc(pdoc(d, 'qrCodes/222222'), codeData()));
allow('qrCodes', 'lecturer', 'ghi đè mã đã hết hạn của lớp khác', (d) => setDoc(pdoc(d, 'qrCodes/333333'), codeData()));
deny('qrCodes', 'lecturer', 'mã không phải 6 chữ số', (d) => setDoc(pdoc(d, 'qrCodes/12AB56'), codeData()));
deny('qrCodes', 'lecturer2', 'ghi mã cho slot người khác', (d) => setDoc(pdoc(d, 'qrCodes/765432'), codeData({ lecturerId: 'lec2' })));
deny('qrCodes', 'lecturer2', 'xoá mã người khác', (d) => deleteDoc(pdoc(d, 'qrCodes/482917')));
deny('qrCodes', 'anon', 'đọc mã', (d) => getDoc(pdoc(d, 'qrCodes/482917')));
test('R-X2 qrCodes: sinh viên lớp khác đọc mã còn hạn → Denied', async () => {
  const entry = { id: 'R-X2', coll: 'qrCodes', role: 'student (lớp khác)', op: 'đọc mã của lớp không có tên', expected: 'Denied', result: 'Fail' };
  results.push(entry);
  await assertFails(getDoc(pdoc(db('stu2'), 'qrCodes/482917')));
  entry.result = 'Pass';
});

// ---------- tv (màn chiếu, không đăng nhập) ----------
allow('tv', 'anon', 'đọc màn chiếu bằng khoá còn hạn', (d) => getDoc(pdoc(d, 'tv/ABCDEFGH23')));
deny('tv', 'anon', 'đọc link đã hết hạn', (d) => getDoc(pdoc(d, 'tv/OLDKEY2345')));
deny('tv', 'anon', 'liệt kê để dò khoá', (d) => getDocs(collection(d, 'tv')));
deny('tv', 'anon', 'ghi màn chiếu', (d) => setDoc(pdoc(d, 'tv/ABCDEFGH23'), tvData({ present: 99 })));
allow('tv', 'lecturer', 'tạo màn chiếu và lưu khoá vào slot (batch)', (d) => {
  const b = writeBatch(d);
  b.set(pdoc(d, 'tv/NEWKEY2345'), tvData());
  b.update(pdoc(d, 'slots/s1'), { tvKey: 'NEWKEY2345' });
  return b.commit();
});
allow('tv', 'lecturer', 'cập nhật khung khi đổi mã', (d) => setDoc(pdoc(d, 'tv/ABCDEFGH23'), tvData({ present: 4, code: '654321' })));
deny('tv', 'lecturer', 'thêm trường lạ', (d) => setDoc(pdoc(d, 'tv/ABCDEFGH23'), tvData({ note: 'x' })));
deny('tv', 'lecturer', 'chuyển màn chiếu sang slot khác', (d) => setDoc(pdoc(d, 'tv/ABCDEFGH23'), tvData({ slotId: 's2' })));
deny('tv', 'lecturer2', 'sửa màn chiếu người khác', (d) => setDoc(pdoc(d, 'tv/ABCDEFGH23'), tvData({ lecturerId: 'lec2' })));
deny('tv', 'student', 'sửa số đã quét', (d) => updateDoc(pdoc(d, 'tv/ABCDEFGH23'), { present: 35 }));
allow('tv', 'student', 'đọc màn chiếu (như mọi người có link)', (d) => getDoc(pdoc(d, 'tv/ABCDEFGH23')));

// ---------- requests ----------
const reqData = (over = {}) => ({ studentUid: 'stu', studentCode: 'SE190101', lecturerId: 'lec', slotId: 's1', reason: 'r', note: '', status: 'pending', ...over });
allow('requests', 'student', 'gửi báo sai', (d) => setDoc(pdoc(d, 'requests/r2'), reqData()));
deny('requests', 'student', 'tự duyệt báo sai', (d) => updateDoc(pdoc(d, 'requests/r1'), { status: 'approved' }));
allow('requests', 'lecturer', 'duyệt pending → approved', (d) => updateDoc(pdoc(d, 'requests/r1'), { status: 'approved', reviewedAt: serverTimestamp() }));
deny('requests', 'lecturer', 'sửa lý do của sinh viên', (d) => updateDoc(pdoc(d, 'requests/r1'), { reason: 'x' }));
deny('requests', 'anon', 'đọc báo sai', (d) => getDoc(pdoc(d, 'requests/r1')));

// ---------- reminders ----------
allow('reminders', 'lecturer', 'gửi lời nhắc', (d) => addDoc(collection(d, 'reminders'), { lecturerId: 'lec', classId: 'c1', message: 'm' }));
deny('reminders', 'lecturer', 'sửa lời nhắc đã gửi', (d) => updateDoc(pdoc(d, 'reminders/m1'), { message: 'x' }));
deny('reminders', 'student', 'đọc lời nhắc', (d) => getDoc(pdoc(d, 'reminders/m1')));

// ---------- reports ----------
const repData = (owner) => ({ ownerUid: owner, classId: 'c1', fileName: 'a.pdf', sizeKb: 1, destination: 'device', createdAt: serverTimestamp() });
allow('reports', 'lecturer', 'ghi metadata báo cáo của mình', (d) => addDoc(collection(d, 'reports'), repData('lec')));
deny('reports', 'lecturer', 'ghi metadata tên người khác', (d) => addDoc(collection(d, 'reports'), repData('lec2')));
deny('reports', 'lecturer', 'xoá metadata', (d) => deleteDoc(pdoc(d, 'reports/p1')));
deny('reports', 'student', 'đọc báo cáo của giảng viên', (d) => getDoc(pdoc(d, 'reports/p1')));
