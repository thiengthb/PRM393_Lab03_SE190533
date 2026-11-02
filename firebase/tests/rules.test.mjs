// Test Security Rules trên Emulator (đề Final mục 6, Appendix B):
// mỗi vai trò × mỗi collection có ít nhất một ca Allowed và một ca Denied.
// Vai trò không có quyền nào trên collection thì chỉ có ca Denied (ghi rõ trong docs/data-model.md).
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

let env;
const results = [];

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const ROLES = { student: 'stu', lecturer: 'lec', staff: 'sta', admin: 'adm', user: 'new', anon: null };

const slotCopy = {
  slotId: 's1', lecturerId: 'lec', classId: 'c1', subject: 'PRM393', classCode: 'SE1801',
  term: 'Fall 2026', start, slotNo: 1, room: 'P.305', totalSlots: 20,
};
const scan = (over = {}) => ({
  ...slotCopy, studentCode: 'SE190101', studentName: 'An', present: true, source: 'scan',
  final: false, token: 'tok', scannerUid: 'stu', ...over,
});
const newClass = (over = {}) => ({
  lecturerId: 'lec', term: 'Fall 2026', subject: 'PRM393', code: 'SE9999', status: 'pending',
  studentCount: 1, totalSlots: 20, lecturerName: 'Q', ...over,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-quick-attend',
    firestore: { rules: readFileSync(RULES, 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    const set = (p, v) => setDoc(doc(d, p), v);
    await set('users/stu', { role: 'student', displayName: 'An', email: 's@x', studentCode: 'SE190101' });
    await set('users/lec', { role: 'lecturer', displayName: 'Q', email: 'l@x' });
    await set('users/lec2', { role: 'lecturer', displayName: 'R', email: 'l2@x' });
    await set('users/sta', { role: 'staff', displayName: 'S', email: 'st@x' });
    await set('users/adm', { role: 'admin', displayName: 'A', email: 'a@x' });
    await set('users/new', { role: 'user', displayName: 'N', email: 'n@x' });
    await set('users/lec/inbox/i1', { title: 't', body: 'b', createdBy: 'sta' });
    await set('subjects/PRM393', { code: 'PRM393', name: 'Mobile', status: 'active', updatedBy: 'sta' });
    await set('announcements/all1', { title: 't', body: 'b', audience: 'all', status: 'published', createdBy: 'sta' });
    await set('announcements/lec1', { title: 't', body: 'b', audience: 'lecturer', status: 'published', createdBy: 'sta' });
    await set('announcements/stu1', { title: 't', body: 'b', audience: 'student', status: 'published', createdBy: 'sta' });
    await set('announcements/old1', { title: 't', body: 'b', audience: 'all', status: 'archived', createdBy: 'sta' });
    await set('classes/c1', newClass({ code: 'SE1801', status: 'approved' }));
    await set('classes/c2', newClass({ code: 'SE1802', status: 'pending' }));
    await set('classes/c3', newClass({ code: 'SE1803', status: 'rejected', rejectReason: 'Sai danh sách' }));
    await set('classes/c1/students/SE190101', { studentCode: 'SE190101', name: 'An', lecturerId: 'lec' });
    await set('slots/s1', { lecturerId: 'lec', classId: 'c1', subject: 'PRM393', classCode: 'SE1801', term: 'Fall 2026',
      start, slotNo: 1, room: 'P.305', totalSlots: 20, qrOpen: true, qrToken: 'tok', qrExpiresAt: future });
    await set('slots/s2', { lecturerId: 'lec', classId: 'c2', subject: 'PRM393', classCode: 'SE1802', term: 'Fall 2026',
      start, slotNo: 1, room: 'P.305', totalSlots: 20 });
    await set('slots/s1/attendance/SE190102', { ...slotCopy, studentCode: 'SE190102', studentName: 'B', present: true, source: 'manual', final: false });
    await set('slots/s1/attendance/SE190103', { ...slotCopy, studentCode: 'SE190101', studentName: 'An', present: false, source: 'auto', final: true });
    await set('requests/r1', { studentUid: 'stu', studentCode: 'SE190101', lecturerId: 'lec', slotId: 's1', reason: 'r', note: '', status: 'pending' });
    await set('reminders/m1', { lecturerId: 'lec', classId: 'c1', message: 'm' });
    await set('reports/p1', { ownerUid: 'lec', classId: 'c1', fileName: 'a.pdf', sizeKb: 1, destination: 'device' });
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
deny('users', 'student', 'tự đổi role thành admin', (d) => updateDoc(pdoc(d, 'users/stu'), { role: 'admin' }));
deny('users', 'student', 'đọc hồ sơ người khác', (d) => getDoc(pdoc(d, 'users/lec')));
allow('users', 'lecturer', 'tạo hồ sơ giảng viên lần đầu', () => setDoc(pdoc(db('fresh1'), 'users/fresh1'), { role: 'lecturer', displayName: 'Q', email: 'l@x' }));
deny('users', 'lecturer', 'tự đổi role', (d) => updateDoc(pdoc(d, 'users/lec'), { role: 'staff' }));
allow('users', 'lecturer', 'đổi công tắc nhắc', (d) => updateDoc(pdoc(d, 'users/lec'), { reminderBeforeSlot: false }));
allow('users', 'staff', 'đánh dấu đã đọc hộp thư của mình', (d) => updateDoc(pdoc(d, 'users/sta'), { lastInboxReadAt: serverTimestamp() }));
deny('users', 'staff', 'đổi vai trò người khác', (d) => updateDoc(pdoc(d, 'users/new'), { role: 'staff' }));
deny('users', 'staff', 'liệt kê người dùng', (d) => getDocs(collection(d, 'users')));
allow('users', 'admin', 'cấp quyền staff cho tài khoản mới', (d) => updateDoc(pdoc(d, 'users/new'), { role: 'staff' }));
allow('users', 'admin', 'liệt kê người dùng', (d) => getDocs(collection(d, 'users')));
deny('users', 'admin', 'tự đổi vai trò của mình', (d) => updateDoc(pdoc(d, 'users/adm'), { role: 'staff' }));
deny('users', 'admin', 'sửa trường khác của người khác', (d) => updateDoc(pdoc(d, 'users/new'), { displayName: 'X' }));
allow('users', 'user', 'tạo hồ sơ vai trò user', () => setDoc(pdoc(db('fresh2'), 'users/fresh2'), { role: 'user', displayName: 'N', email: 'n@x' }));
deny('users', 'user', 'tự tạo hồ sơ vai trò admin', () => setDoc(pdoc(db('fresh3'), 'users/fresh3'), { role: 'admin', displayName: 'N', email: 'n@x' }));
deny('users', 'user', 'tạo hồ sơ cho uid khác', () => setDoc(pdoc(db('fresh4'), 'users/fresh5'), { role: 'user', displayName: 'N', email: 'n@x' }));
deny('users', 'anon', 'đọc hồ sơ', (d) => getDoc(pdoc(d, 'users/stu')));

// ---------- users/{uid}/inbox ----------
allow('inbox', 'lecturer', 'đọc tin riêng của mình', (d) => getDocs(collection(d, 'users/lec/inbox')));
deny('inbox', 'lecturer', 'tự ghi tin', (d) => addDoc(collection(d, 'users/lec/inbox'), { title: 't', body: 'b', createdBy: 'lec' }));
allow('inbox', 'student', 'đọc tin riêng của mình', (d) => getDocs(collection(d, 'users/stu/inbox')));
deny('inbox', 'student', 'đọc tin của giảng viên', (d) => getDocs(collection(d, 'users/lec/inbox')));
allow('inbox', 'staff', 'ghi tin kết quả duyệt', (d) => addDoc(collection(d, 'users/lec/inbox'), { kind: 'class_review', title: 't', body: 'b', route: '/import', createdBy: 'sta', createdAt: serverTimestamp() }));
deny('inbox', 'staff', 'ghi tin mạo danh người khác', (d) => addDoc(collection(d, 'users/lec/inbox'), { title: 't', body: 'b', createdBy: 'adm' }));
allow('inbox', 'admin', 'ghi tin kết quả duyệt', (d) => addDoc(collection(d, 'users/lec/inbox'), { title: 't', body: 'b', createdBy: 'adm' }));
deny('inbox', 'admin', 'xóa tin', (d) => deleteDoc(pdoc(d, 'users/lec/inbox/i1')));
allow('inbox', 'user', 'đọc tin riêng của mình', (d) => getDocs(collection(d, 'users/new/inbox')));
deny('inbox', 'user', 'ghi tin', (d) => addDoc(collection(d, 'users/lec/inbox'), { title: 't', body: 'b', createdBy: 'new' }));

// ---------- subjects ----------
allow('subjects', 'student', 'đọc danh mục', (d) => getDoc(pdoc(d, 'subjects/PRM393')));
deny('subjects', 'student', 'thêm môn', (d) => setDoc(pdoc(d, 'subjects/ABC123'), { code: 'ABC123', name: 'x', status: 'active', updatedBy: 'stu' }));
allow('subjects', 'lecturer', 'đọc môn đang dùng', (d) => getDocs(query(collection(d, 'subjects'), where('status', '==', 'active'))));
deny('subjects', 'lecturer', 'sửa môn', (d) => updateDoc(pdoc(d, 'subjects/PRM393'), { name: 'x', updatedBy: 'lec' }));
allow('subjects', 'staff', 'thêm môn', (d) => setDoc(pdoc(d, 'subjects/ABC123'), { code: 'ABC123', name: 'x', status: 'active', updatedBy: 'sta' }));
allow('subjects', 'staff', 'lưu trữ môn', (d) => updateDoc(pdoc(d, 'subjects/PRM393'), { status: 'archived', updatedBy: 'sta' }));
deny('subjects', 'staff', 'mã môn khác id', (d) => setDoc(pdoc(d, 'subjects/ABC123'), { code: 'XYZ', name: 'x', status: 'active', updatedBy: 'sta' }));
deny('subjects', 'staff', 'xóa môn', (d) => deleteDoc(pdoc(d, 'subjects/PRM393')));
allow('subjects', 'admin', 'sửa tên môn', (d) => updateDoc(pdoc(d, 'subjects/PRM393'), { name: 'y', updatedBy: 'adm' }));
deny('subjects', 'admin', 'trạng thái lạ', (d) => updateDoc(pdoc(d, 'subjects/PRM393'), { status: 'x', updatedBy: 'adm' }));
allow('subjects', 'user', 'đọc danh mục', (d) => getDoc(pdoc(d, 'subjects/PRM393')));
deny('subjects', 'user', 'thêm môn', (d) => setDoc(pdoc(d, 'subjects/ABC123'), { code: 'ABC123', name: 'x', status: 'active', updatedBy: 'new' }));
deny('subjects', 'anon', 'đọc danh mục', (d) => getDoc(pdoc(d, 'subjects/PRM393')));

// ---------- announcements ----------
const annQ = (d, a) => query(collection(d, 'announcements'), where('status', '==', 'published'), where('audience', 'in', a));
allow('announcements', 'lecturer', 'truy vấn hộp thư như app', (d) => getDocs(annQ(d, ['all', 'lecturer'])));
deny('announcements', 'lecturer', 'đọc thông báo dành cho sinh viên', (d) => getDoc(pdoc(d, 'announcements/stu1')));
deny('announcements', 'lecturer', 'đăng thông báo', (d) => addDoc(collection(d, 'announcements'), { title: 't', body: 'b', audience: 'all', status: 'published', createdBy: 'lec' }));
allow('announcements', 'student', 'truy vấn hộp thư như app', (d) => getDocs(annQ(d, ['all', 'student'])));
deny('announcements', 'student', 'đọc thông báo đã lưu trữ', (d) => getDoc(pdoc(d, 'announcements/old1')));
allow('announcements', 'staff', 'đăng thông báo', (d) => addDoc(collection(d, 'announcements'), { title: 't', body: 'b', audience: 'all', status: 'published', createdBy: 'sta', publishedAt: serverTimestamp() }));
allow('announcements', 'staff', 'lưu trữ', (d) => updateDoc(pdoc(d, 'announcements/all1'), { status: 'archived' }));
deny('announcements', 'staff', 'tiêu đề quá 120 ký tự', (d) => addDoc(collection(d, 'announcements'), { title: 'x'.repeat(121), body: 'b', audience: 'all', status: 'published', createdBy: 'sta' }));
deny('announcements', 'staff', 'sửa nội dung sau khi đăng', (d) => updateDoc(pdoc(d, 'announcements/all1'), { body: 'khác' }));
allow('announcements', 'admin', 'đọc mọi thông báo', (d) => getDocs(collection(d, 'announcements')));
deny('announcements', 'admin', 'xóa thông báo', (d) => deleteDoc(pdoc(d, 'announcements/all1')));
deny('announcements', 'user', 'đọc thông báo', (d) => getDoc(pdoc(d, 'announcements/all1')));

// ---------- classes ----------
allow('classes', 'lecturer', 'gửi lớp mới trạng thái pending', (d) => setDoc(pdoc(d, 'classes/c9'), newClass()));
deny('classes', 'lecturer', 'tạo lớp đã approved', (d) => setDoc(pdoc(d, 'classes/c9'), newClass({ status: 'approved' })));
deny('classes', 'lecturer', 'tự duyệt lớp pending', (d) => updateDoc(pdoc(d, 'classes/c2'), { status: 'approved' }));
allow('classes', 'lecturer', 'gửi lại lớp bị từ chối', (d) => updateDoc(pdoc(d, 'classes/c3'), { status: 'pending' }));
allow('classes', 'lecturer', 'đọc lớp chưa tồn tại trước khi nhập', (d) => getDoc(pdoc(d, 'classes/khong-co')));
allow('classes', 'lecturer', 'liệt kê lớp của mình', (d) => getDocs(query(collection(d, 'classes'), where('lecturerId', '==', 'lec'))));
allow('classes', 'staff', 'duyệt pending → approved', (d) => updateDoc(pdoc(d, 'classes/c2'), { status: 'approved', reviewedBy: 'sta', reviewedAt: serverTimestamp() }));
allow('classes', 'staff', 'từ chối có lý do', (d) => updateDoc(pdoc(d, 'classes/c2'), { status: 'rejected', rejectReason: 'Sai', reviewedBy: 'sta', reviewedAt: serverTimestamp() }));
deny('classes', 'staff', 'từ chối không có lý do', (d) => updateDoc(pdoc(d, 'classes/c2'), { status: 'rejected', reviewedBy: 'sta' }));
deny('classes', 'staff', 'duyệt lại lớp đã approved', (d) => updateDoc(pdoc(d, 'classes/c1'), { status: 'rejected', rejectReason: 'x', reviewedBy: 'sta' }));
deny('classes', 'staff', 'sửa dữ liệu lớp khi duyệt', (d) => updateDoc(pdoc(d, 'classes/c2'), { status: 'approved', reviewedBy: 'sta', studentCount: 1000 }));
allow('classes', 'admin', 'xem hàng đợi', (d) => getDocs(query(collection(d, 'classes'), where('status', '==', 'pending'))));
deny('classes', 'admin', 'xóa lớp', (d) => deleteDoc(pdoc(d, 'classes/c1')));
deny('classes', 'student', 'đọc lớp', (d) => getDoc(pdoc(d, 'classes/c1')));
deny('classes', 'user', 'đọc lớp', (d) => getDoc(pdoc(d, 'classes/c1')));

// ---------- classes/{id}/students ----------
const stu = (c) => `classes/${c}/students/SE190102`;
const stuData = (uid) => ({ studentCode: 'SE190102', name: 'B', lecturerId: uid });
allow('students', 'lecturer', 'thêm sinh viên vào lớp của mình', (d) => setDoc(pdoc(d, stu('c1')), stuData('lec')));
deny('students', 'student', 'đọc danh sách lớp', (d) => getDocs(collection(d, 'classes/c1/students')));
allow('students', 'staff', 'đọc danh sách khi duyệt', (d) => getDocs(collection(d, 'classes/c1/students')));
deny('students', 'staff', 'sửa danh sách', (d) => setDoc(pdoc(d, stu('c1')), stuData('sta')));
allow('students', 'admin', 'đọc danh sách', (d) => getDocs(collection(d, 'classes/c1/students')));
deny('students', 'admin', 'xóa sinh viên', (d) => deleteDoc(pdoc(d, 'classes/c1/students/SE190101')));
deny('students', 'user', 'đọc danh sách', (d) => getDocs(collection(d, 'classes/c1/students')));
test('R-X1 students: giảng viên khác không được ghi vào lớp người khác → Denied', async () => {
  const entry = { id: 'R-X1', coll: 'students', role: 'lecturer (khác)', op: 'ghi vào lớp người khác', expected: 'Denied', result: 'Fail' };
  results.push(entry);
  await assertFails(setDoc(pdoc(db('lec2'), stu('c1')), stuData('lec2')));
  entry.result = 'Pass';
});

// ---------- slots ----------
allow('slots', 'lecturer', 'mở mã QR slot của lớp đã duyệt', (d) => updateDoc(pdoc(d, 'slots/s1'), { qrOpen: true, qrToken: 'x', qrExpiresAt: future }));
deny('slots', 'lecturer', 'mở mã QR khi lớp chưa duyệt', (d) => updateDoc(pdoc(d, 'slots/s2'), { qrOpen: true, qrToken: 'x', qrExpiresAt: future }));
deny('slots', 'student', 'đọc slot (có qrToken)', (d) => getDoc(pdoc(d, 'slots/s1')));
allow('slots', 'staff', 'đọc slot đã chốt để tổng hợp', (d) => getDocs(query(collection(d, 'slots'), where('closed', '==', true))));
deny('slots', 'staff', 'sửa slot', (d) => updateDoc(pdoc(d, 'slots/s1'), { room: 'x' }));
allow('slots', 'admin', 'đọc slot', (d) => getDoc(pdoc(d, 'slots/s1')));
deny('slots', 'admin', 'xóa slot', (d) => deleteDoc(pdoc(d, 'slots/s1')));
deny('slots', 'user', 'đọc slot', (d) => getDoc(pdoc(d, 'slots/s1')));
test('R-X2 slots: lớp mới và slot trong cùng batch như lúc nhập → Allowed', async () => {
  const entry = { id: 'R-X2', coll: 'slots', role: 'lecturer', op: 'batch tạo lớp + sinh viên + slot', expected: 'Allowed', result: 'Fail' };
  results.push(entry);
  const d = db('lec');
  const b = writeBatch(d);
  b.set(pdoc(d, 'classes/c9'), newClass());
  b.set(pdoc(d, 'classes/c9/students/SE190102'), stuData('lec'));
  b.set(pdoc(d, 'slots/s9'), { lecturerId: 'lec', classId: 'c9', subject: 'PRM393', classCode: 'SE9999', term: 'Fall 2026', start, slotNo: 1, room: 'P', totalSlots: 20 });
  await assertSucceeds(b.commit());
  entry.result = 'Pass';
});

// ---------- attendance ----------
const att = 'slots/s1/attendance/SE190101';
allow('attendance', 'student', 'quét đúng mã trong hạn', (d) => setDoc(pdoc(d, att), scan()));
deny('attendance', 'student', 'quét sai mã', (d) => setDoc(pdoc(d, att), scan({ token: 'sai' })));
deny('attendance', 'student', 'điểm danh hộ MSSV khác', (d) => setDoc(pdoc(d, 'slots/s1/attendance/SE190102'), scan({ studentCode: 'SE190102' })));
allow('attendance', 'student', 'đọc buổi của mình (collection group)', (d) => getDocs(query(collectionGroup(d, 'attendance'), where('studentCode', '==', 'SE190101'))));
allow('attendance', 'lecturer', 'đánh dấu tay ở lớp đã duyệt', (d) => setDoc(pdoc(d, att), { ...slotCopy, studentCode: 'SE190101', studentName: 'An', present: true, source: 'manual', final: false }));
deny('attendance', 'lecturer', 'đánh dấu ở lớp chưa duyệt', (d) => setDoc(pdoc(d, 'slots/s2/attendance/SE190101'), { ...slotCopy, slotId: 's2', classId: 'c2', studentCode: 'SE190101', present: true, source: 'manual', final: false }));
allow('attendance', 'lecturer', 'đọc toàn bộ của mình (collection group)', (d) => getDocs(query(collectionGroup(d, 'attendance'), where('lecturerId', '==', 'lec'))));
deny('attendance', 'staff', 'đọc điểm danh', (d) => getDoc(pdoc(d, 'slots/s1/attendance/SE190102')));
deny('attendance', 'staff', 'sửa điểm danh', (d) => setDoc(pdoc(d, att), scan()));
deny('attendance', 'admin', 'sửa điểm danh', (d) => setDoc(pdoc(d, att), scan()));
deny('attendance', 'user', 'quét mã', (d) => setDoc(pdoc(d, att), scan({ scannerUid: 'new' })));

// ---------- requests ----------
const reqData = (over = {}) => ({ studentUid: 'stu', studentCode: 'SE190101', lecturerId: 'lec', slotId: 's1', reason: 'r', note: '', status: 'pending', ...over });
allow('requests', 'student', 'gửi báo sai', (d) => setDoc(pdoc(d, 'requests/r2'), reqData()));
deny('requests', 'student', 'tự duyệt báo sai', (d) => updateDoc(pdoc(d, 'requests/r1'), { status: 'approved' }));
allow('requests', 'lecturer', 'duyệt pending → approved', (d) => updateDoc(pdoc(d, 'requests/r1'), { status: 'approved', reviewedAt: serverTimestamp() }));
deny('requests', 'lecturer', 'sửa lý do của sinh viên', (d) => updateDoc(pdoc(d, 'requests/r1'), { reason: 'x' }));
allow('requests', 'staff', 'đọc để thống kê', (d) => getDoc(pdoc(d, 'requests/r1')));
deny('requests', 'staff', 'duyệt thay giảng viên', (d) => updateDoc(pdoc(d, 'requests/r1'), { status: 'approved' }));
allow('requests', 'admin', 'đọc', (d) => getDoc(pdoc(d, 'requests/r1')));
deny('requests', 'admin', 'xóa', (d) => deleteDoc(pdoc(d, 'requests/r1')));
deny('requests', 'user', 'gửi báo sai', (d) => setDoc(pdoc(d, 'requests/r2'), reqData({ studentUid: 'new' })));

// ---------- reminders ----------
allow('reminders', 'lecturer', 'gửi lời nhắc', (d) => addDoc(collection(d, 'reminders'), { lecturerId: 'lec', classId: 'c1', message: 'm' }));
deny('reminders', 'lecturer', 'sửa lời nhắc đã gửi', (d) => updateDoc(pdoc(d, 'reminders/m1'), { message: 'x' }));
deny('reminders', 'student', 'đọc lời nhắc', (d) => getDoc(pdoc(d, 'reminders/m1')));
deny('reminders', 'staff', 'đọc lời nhắc', (d) => getDoc(pdoc(d, 'reminders/m1')));
deny('reminders', 'admin', 'tạo lời nhắc', (d) => addDoc(collection(d, 'reminders'), { lecturerId: 'adm', message: 'm' }));
deny('reminders', 'user', 'đọc lời nhắc', (d) => getDoc(pdoc(d, 'reminders/m1')));

// ---------- reports ----------
const repData = (owner) => ({ ownerUid: owner, classId: 'c1', fileName: 'a.pdf', sizeKb: 1, destination: 'device', createdAt: serverTimestamp() });
allow('reports', 'lecturer', 'ghi metadata báo cáo của mình', (d) => addDoc(collection(d, 'reports'), repData('lec')));
deny('reports', 'lecturer', 'ghi metadata tên người khác', (d) => addDoc(collection(d, 'reports'), repData('lec2')));
deny('reports', 'student', 'đọc báo cáo của giảng viên', (d) => getDoc(pdoc(d, 'reports/p1')));
allow('reports', 'staff', 'đọc metadata', (d) => getDoc(pdoc(d, 'reports/p1')));
deny('reports', 'staff', 'sửa metadata', (d) => updateDoc(pdoc(d, 'reports/p1'), { sizeKb: 2 }));
allow('reports', 'admin', 'đọc metadata', (d) => getDoc(pdoc(d, 'reports/p1')));
deny('reports', 'admin', 'xóa metadata', (d) => deleteDoc(pdoc(d, 'reports/p1')));
deny('reports', 'user', 'ghi metadata', (d) => addDoc(collection(d, 'reports'), repData('new')));
