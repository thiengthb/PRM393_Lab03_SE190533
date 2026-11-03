// Dữ liệu mẫu cho Firebase Emulator: chụp màn và demo mà không đụng dữ liệu thật.
// Chạy (trong firebase/tests):
//   npx firebase emulators:exec --config ../../firebase.json --project hereby-se190533 --only auth,firestore \
//     "node seed-demo.mjs && sleep infinity"
// hoặc khi emulator đã chạy sẵn: node seed-demo.mjs
// Thêm --reset để xoá sạch Firestore trước khi ghi (ARTEMIS gọi trước mỗi test). Tài khoản Auth
// được giữ nguyên, nên app đang đăng nhập trên điện thoại vẫn dùng tiếp được.
// Rồi chạy app với --dart-define=EMULATOR_HOST=localhost.
//
// Lớp và sinh viên lấy từ sample-data/lop-fall-2026.csv. Riêng PRM393 SE1801 được đặt vào
// slot đang diễn ra lúc chạy script, để có màn điểm danh. Mọi giờ tính theo giờ Việt Nam.

import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp, writeBatch } from 'firebase/firestore';

const PROJECT = process.env.PROJECT ?? 'hereby-se190533';
const AUTH = 'http://127.0.0.1:9099';
const PASSWORD = 'Demo@123';
const VN = 7 * 3600 * 1000;

const SLOT_TIMES = { 1: [7, 0, 9, 15], 2: [9, 30, 11, 45], 3: [12, 30, 14, 45], 4: [15, 0, 17, 15], 5: [17, 30, 19, 45], 6: [20, 0, 22, 15] };

/** Ngày giờ Việt Nam → Date (UTC). */
const vn = (y, m, d, h = 0, min = 0) => new Date(Date.UTC(y, m - 1, d, h, min) - VN);
const vnParts = (date) => {
  const t = new Date(date.getTime() + VN);
  return { y: t.getUTCFullYear(), m: t.getUTCMonth() + 1, d: t.getUTCDate(), wd: ((t.getUTCDay() + 6) % 7) + 1, h: t.getUTCHours() };
};
const two = (n) => String(n).padStart(2, '0');

async function signUp(email, displayName) {
  const r = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password: PASSWORD, displayName, returnSecureToken: true }),
  });
  let j = await r.json();
  if (j.error?.message === 'EMAIL_EXISTS') {
    const r2 = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password: PASSWORD, returnSecureToken: true }),
    });
    j = await r2.json();
  }
  if (!j.localId) throw new Error(`signUp ${email}: ${JSON.stringify(j)}`);
  await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:update`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: 'Bearer owner' },
    body: JSON.stringify({ localId: j.localId, emailVerified: true }),
  });
  return j.localId;
}

if (process.argv.includes('--reset')) {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080';
  const r = await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  if (!r.ok) throw new Error(`Không xoá được Firestore emulator: ${r.status}`);
}

// ---------- đọc CSV mẫu ----------
const csv = readFileSync(new URL('../../sample-data/lop-fall-2026.csv', import.meta.url), 'utf8').trim().split('\n').slice(1);
const classes = new Map();
for (const line of csv) {
  const [subject, code, mssv, name, email, sched, start] = line.split(',').map((x) => x.trim());
  const key = `${subject}_${code}`;
  if (!classes.has(key)) classes.set(key, { subject, code, students: [], weekly: [], start: null });
  const c = classes.get(key);
  c.students.push({ code: mssv, name, email });
  if (sched) {
    c.weekly = sched.split(';').map((p) => {
      const [, t, s, room] = p.match(/T(\d)-S(\d)-(.+)/);
      return { weekday: Number(t) - 1, slotNo: Number(s), room };
    });
    const [dd, mm, yy] = start.split('/').map(Number);
    c.start = { y: yy, m: mm, d: dd };
  }
}

const now = new Date();
const today = vnParts(now);
const liveSlotNo = Number(Object.entries(SLOT_TIMES).find(([, t]) => {
  const s = vn(today.y, today.m, today.d, t[0], t[1]);
  const e = vn(today.y, today.m, today.d, t[2], t[3]);
  return now >= s && now < e;
})?.[0] ?? 0);
// PRM393 SE1801 học đúng thứ hôm nay, slot đang diễn ra (nếu đang trong giờ học).
const se1801 = classes.get('PRM393_SE1801');
if (liveSlotNo) se1801.weekly = [{ weekday: today.wd, slotNo: liveSlotNo, room: 'P.305' }, { weekday: today.wd === 5 ? 3 : 5, slotNo: 1, room: 'P.305' }];

const TERM = 'Fall 2026';
const WEEKS = 10;

// ---------- tài khoản ----------
const lecturerUid = await signUp('quanm@fe.edu.vn', 'Nguyễn Minh Quân');
const me = se1801.students[0]; // SE190101, tài khoản sinh viên mẫu
const studentUid = await signUp(me.email, me.name);
console.log('lecturer', lecturerUid, 'student', studentUid);

const env = await initializeTestEnvironment({ projectId: PROJECT, firestore: { host: '127.0.0.1', port: 8080 } });

await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  let batch = writeBatch(db);
  let ops = 0;
  const put = async (path, data) => {
    batch.set(doc(db, path), data);
    if (++ops >= 450) { await batch.commit(); batch = writeBatch(db); ops = 0; }
  };

  await put(`users/${lecturerUid}`, {
    role: 'lecturer', displayName: 'Nguyễn Minh Quân', email: 'quanm@fe.edu.vn',
    reminderBeforeSlot: true, reminderUnclosed: true, lastImportAt: Timestamp.fromDate(vn(2026, 9, 5, 20)),
  });
  await put(`users/${studentUid}`, { role: 'student', displayName: me.name, email: me.email, studentCode: me.code });

  // Số buổi vắng muốn có (tính trên các buổi đã chốt) cho vài em đầu danh sách, theo lớp.
  const plan = {
    PRM393_SE1801: { SE190101: 3, SE190102: 5, SE190103: 4, SE190104: 3, SE190105: 2, SE190106: 1 },
    PRM393_SE1802: { 2: 5, 5: 4, 9: 3, 12: 1 },
    MMA301_SE1805: { 1: 4, 3: 2 },
    PRN221_SE1810: { 0: 6, 4: 3, 7: 1 },
  };
  const unclosed = new Set();
  const requests = [];

  for (const [key, c] of classes) {
    const classId = `${lecturerUid}_${TERM.replace(' ', '')}_${c.subject}_${c.code}`.replace(/[^A-Za-z0-9_]/g, '');
    const label = `${c.subject} · ${c.code}`;
    const monday = vn(c.start.y, c.start.m, c.start.d);
    const slots = [];
    for (let w = 0; w < WEEKS; w++) {
      for (const ws of c.weekly) {
        const day = vnParts(new Date(monday.getTime() + (w * 7 + ws.weekday - 1) * 86400000));
        const t = SLOT_TIMES[ws.slotNo];
        slots.push({ ...ws, start: vn(day.y, day.m, day.d, t[0], t[1]), end: vn(day.y, day.m, day.d, t[2], t[3]) });
      }
    }
    slots.sort((a, b) => a.start - b.start);
    await put(`classes/${classId}`, {
      lecturerId: lecturerUid, term: TERM, subject: c.subject, code: c.code,
      studentCount: c.students.length, totalSlots: slots.length, importedAt: Timestamp.fromDate(vn(2026, 9, 5, 20)),
    });
    for (const s of c.students) {
      await put(`classes/${classId}/students/${s.code}`, { studentCode: s.code, name: s.name, email: s.email, lecturerId: lecturerUid });
    }

    const past = slots.filter((s) => s.end <= now);
    // Hai slot chưa chốt: slot gần nhất của PRM393 SE1802 và của PRN221 SE1810.
    if (key === 'PRM393_SE1802' || key === 'PRN221_SE1810') unclosed.add(`${classId}_${past.at(-1).start.getTime()}`);
    const closedPast = past.filter((s) => !unclosed.has(`${classId}_${s.start.getTime()}`));

    // Ai vắng buổi nào: em có n buổi vắng thì vắng n buổi rải đều trong các buổi đã chốt.
    const absentSet = new Map();
    for (const [who, n] of Object.entries(plan[key] ?? {})) {
      const st = /^\d+$/.test(who) ? c.students[Number(who)] : c.students.find((x) => x.code === who);
      const idx = new Set();
      for (let i = 0; i < n; i++) idx.add(Math.floor(((i + 0.5) * closedPast.length) / n));
      absentSet.set(st.code, idx);
    }

    for (const [i, s] of slots.entries()) {
      const d = vnParts(s.start);
      const id = `${classId}_${d.y}${two(d.m)}${two(d.d)}_s${s.slotNo}`;
      const copy = {
        slotId: id, lecturerId: lecturerUid, classId, subject: c.subject, classCode: c.code, term: TERM,
        start: Timestamp.fromDate(s.start), slotNo: s.slotNo, room: s.room, totalSlots: slots.length,
      };
      const base = { ...copy, end: Timestamp.fromDate(s.end), studentCount: c.students.length };
      delete base.slotId;
      const ci = closedPast.indexOf(s);
      const isLive = now >= s.start && now < s.end;
      if (ci >= 0) {
        let present = 0;
        for (const st of c.students) {
          const absent = absentSet.get(st.code)?.has(ci) ?? false;
          if (!absent) present++;
          await put(`slots/${id}/attendance/${st.code}`, {
            ...copy, studentCode: st.code, studentName: st.name, present: !absent,
            source: absent ? 'auto' : 'scan', final: true, at: Timestamp.fromDate(new Date(s.start.getTime() + 600000)),
          });
          if (absent && key === 'PRM393_SE1801') requests.push({ st, slotId: id, copy, s });
        }
        await put(`slots/${id}`, { ...base, closed: true, closedAt: Timestamp.fromDate(new Date(s.end.getTime() + 300000)), qrOpen: false, presentCount: present, absentCount: c.students.length - present });
      } else if (isLive) {
        // Đang diễn ra: 24 em đã quét, chưa mở mã trên app.
        for (const st of c.students.slice(6, 30)) {
          await put(`slots/${id}/attendance/${st.code}`, {
            ...copy, studentCode: st.code, studentName: st.name, present: true, source: 'scan', final: false,
            scannerUid: 'demo', at: Timestamp.fromDate(new Date(s.start.getTime() + 300000)),
          });
        }
        await put(`slots/${id}`, { ...base, closed: false, qrOpen: false });
      } else {
        await put(`slots/${id}`, { ...base, closed: false, qrOpen: false });
      }
      void i;
    }
  }

  // Yêu cầu sửa: em SE190101 có 1 đang chờ, 1 bị từ chối, 1 chưa báo; thêm 2 em khác đang chờ.
  const mine = requests.filter((r) => r.st.code === me.code);
  const others = requests.filter((r) => r.st.code !== me.code && ['SE190103', 'SE190105'].includes(r.st.code));
  const reqDoc = (r, status, reason, note, extra = {}) => ({
    studentUid: r.st.code === me.code ? studentUid : `demo-${r.st.code}`,
    studentCode: r.st.code, studentName: r.st.name, lecturerId: lecturerUid, slotId: r.slotId,
    classId: r.copy.classId, subject: r.copy.subject, slotStart: Timestamp.fromDate(r.s.start), slotNo: r.s.slotNo,
    reason, note, status, createdAt: Timestamp.fromDate(new Date(r.s.end.getTime() + 3600000)), ...extra,
  });
  if (mine[0]) await put(`requests/${mine[0].slotId}_${me.code}`, reqDoc(mine[0], 'rejected', 'Mạng lỗi, không quét được', '', { rejectReason: 'Không có mặt' }));
  if (mine.at(-1) && mine.length > 1) await put(`requests/${mine.at(-1).slotId}_${me.code}`, reqDoc(mine.at(-1), 'pending', 'Mạng lỗi, không quét được', 'Em quét rồi nhưng mạng lỗi'));
  const seen = new Set();
  for (const r of others.reverse()) {
    if (seen.has(r.st.code)) continue;
    seen.add(r.st.code);
    await put(`requests/${r.slotId}_${r.st.code}`, reqDoc(r, 'pending', r.st.code === 'SE190103' ? 'Điện thoại hết pin' : 'Quên quét mã', ''));
  }
  await batch.commit();
});

await env.cleanup();
console.log(`Xong. Giảng viên quanm@fe.edu.vn, sinh viên ${me.email}, mật khẩu ${PASSWORD}. Slot đang diễn ra: ${liveSlotNo || 'không có'}`);
