// Dữ liệu mẫu cho Firebase Emulator (mặc định) hoặc Firebase thật (--real): chụp màn, test luồng, demo.
//
// Emulator (khi emulator đã chạy): node seed-demo.mjs [--reset] [--live-now]
//   hoặc: npx firebase emulators:exec --config ../firebase.json --project attendo-app-2611 --only auth,firestore \
//     "node seed-demo.mjs && sleep infinity"
//   Rồi chạy app với --dart-define=EMULATOR_HOST=localhost.
// Firebase thật (chỉ chạy qua workflow "Demo: Firebase thật", có khoá service account):
//   GOOGLE_APPLICATION_CREDENTIALS=<khoá.json> node seed-demo.mjs --real --project attendo-app-2611 --reset --live-now
//
// --reset     xoá sạch Firestore trước khi ghi. Ở --real còn xoá các tài khoản Auth có "+demo" trong email
//             (tài khoản tự đăng ký lúc test tay), để luồng đăng ký làm lại được.
// --demo      thêm giảng viên nam@fe.edu.vn có lớp MMA301 SE1806 đang chờ duyệt (luồng liên vai trò)
//             và sinh viên tien102@fpt.edu.vn (SE190102, đã quá ngưỡng vắng).
// --admin-email <email>  cấp quyền Quản trị cho tài khoản Google đó (web admin chỉ đăng nhập bằng Google).
// --google-lecturer <gmail>  dữ liệu của giảng viên mẫu (4 lớp, slot đang diễn ra, yêu cầu sửa) nạp vào tài khoản
//             Gmail này thay cho quanm@fe.edu.vn: bấm "Tiếp tục với Google" là vào thẳng. Firebase coi Google là
//             nguồn tin cậy cho @gmail.com nên lần đăng nhập Google đầu tiên gắn vào đúng tài khoản (giữ uid);
//             mật khẩu Demo@123 với email Gmail đó vẫn dùng được để dự phòng.
// --google-student <gmail>   tương tự cho sinh viên mẫu SE190101 (thay dung101@fpt.edu.vn).
// --live-now  ngoài giờ học thì kéo một slot trùm lên giờ hiện tại để lúc nào cũng có slot đang diễn ra.
// Tài khoản mẫu được giữ (chỉ đặt lại mật khẩu), nên app đang đăng nhập vẫn dùng tiếp được.
//
// Lớp và sinh viên lấy từ mobile/sample-data/lop-fall-2026.csv. Riêng PRM393 SE1801 được đặt vào
// slot đang diễn ra lúc chạy script, để có màn điểm danh. Mọi giờ tính theo giờ Việt Nam.

import { readFileSync } from 'node:fs';

const REAL = process.argv.includes('--real');
const arg = (name) => {
  const i = process.argv.indexOf(name);
  return i > 0 ? process.argv[i + 1] : undefined;
};
const PROJECT = (REAL ? arg('--project') : process.env.PROJECT) ?? 'attendo-app-2611';
if (REAL) {
  if (!arg('--project')) throw new Error('--real cần --project <id> ghi rõ, để không ghi nhầm project.');
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) throw new Error('--real cần GOOGLE_APPLICATION_CREDENTIALS (khoá service account).');
  delete process.env.FIRESTORE_EMULATOR_HOST;
  delete process.env.FIREBASE_AUTH_EMULATOR_HOST;
} else {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
}
const { initializeApp, applicationDefault } = await import('firebase-admin/app');
const { getAuth } = await import('firebase-admin/auth');
const { getFirestore, Timestamp } = await import('firebase-admin/firestore');
const app = initializeApp(REAL ? { projectId: PROJECT, credential: applicationDefault() } : { projectId: PROJECT });
const auth = getAuth(app);
const fs = getFirestore(app);
const ts = (date) => Timestamp.fromDate(date);

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

/** Tạo tài khoản đã xác nhận email, hoặc đặt lại mật khẩu nếu đã có. Trả uid. */
async function signUp(email, displayName) {
  try {
    const u = await auth.getUserByEmail(email);
    await auth.updateUser(u.uid, { password: PASSWORD, displayName, emailVerified: true, disabled: false });
    return u.uid;
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    return (await auth.createUser({ email, password: PASSWORD, displayName, emailVerified: true })).uid;
  }
}

if (process.argv.includes('--reset')) {
  if (REAL) {
    for (const col of await fs.listCollections()) await fs.recursiveDelete(col);
    let page;
    const throwaway = [];
    do {
      page = await auth.listUsers(1000, page?.pageToken);
      throwaway.push(...page.users.filter((u) => (u.email ?? '').split('@')[0].includes('+demo')).map((u) => u.uid));
    } while (page.pageToken);
    if (throwaway.length) await auth.deleteUsers(throwaway);
    console.log(`Đã xoá Firestore và ${throwaway.length} tài khoản +demo`);
  } else {
    const host = process.env.FIRESTORE_EMULATOR_HOST;
    const r = await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
    if (!r.ok) throw new Error(`Không xoá được Firestore emulator: ${r.status}`);
  }
}

// ---------- đọc CSV mẫu ----------
const csv = readFileSync(new URL('../../mobile/sample-data/lop-fall-2026.csv', import.meta.url), 'utf8').trim().split('\n').slice(1);
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
// --live-now (test luồng tự động): ngoài giờ học thì kéo một slot trùm lên giờ hiện tại
// (bắt đầu 30 phút trước, dài 2 giờ 15) để lúc nào chạy cũng có slot đang diễn ra.
if (process.argv.includes('--live-now')) {
  const inSlot = Object.values(SLOT_TIMES).some((t) => {
    const s = vn(today.y, today.m, today.d, t[0], t[1]);
    return now >= s && now < vn(today.y, today.m, today.d, t[2], t[3]);
  });
  if (!inSlot) {
    const t = new Date(now.getTime() + VN);
    const mins = t.getUTCHours() * 60 + t.getUTCMinutes() - 30;
    const no = Number(Object.entries(SLOT_TIMES).find(([, x]) => x[0] * 60 + x[1] > mins)?.[0] ?? 6);
    SLOT_TIMES[no] = [Math.floor(mins / 60), mins % 60, Math.floor((mins + 135) / 60), (mins + 135) % 60];
  }
}
const liveSlotNo = Number(Object.entries(SLOT_TIMES).find(([, t]) => {
  const s = vn(today.y, today.m, today.d, t[0], t[1]);
  const e = vn(today.y, today.m, today.d, t[2], t[3]);
  return now >= s && now < e;
})?.[0] ?? 0);
// PRM393 SE1801 học đúng thứ hôm nay, slot đang diễn ra (nếu đang trong giờ học).
const se1801 = classes.get('PRM393_SE1801');
if (liveSlotNo) {
  se1801.weekly = [{ weekday: today.wd, slotNo: liveSlotNo, room: 'P.305' }, { weekday: today.wd === 5 ? 3 : 5, slotNo: 1, room: 'P.305' }];
  // Lớp khác trùng giờ với slot vừa đặt (một giảng viên không dạy hai lớp cùng lúc) thì dời sang slot trống.
  const taken = (wd, no) => [...classes.values()].some((c) => c.weekly.some((w) => w.weekday === wd && w.slotNo === no));
  for (const c of classes.values()) {
    if (c === se1801) continue;
    for (const w of c.weekly) {
      for (const sw of se1801.weekly) {
        if (w.weekday !== sw.weekday || w.slotNo !== sw.slotNo) continue;
        w.slotNo = [1, 2, 3, 4, 5, 6].find((n) => !taken(w.weekday, n));
      }
    }
  }
}

// ---------- tài khoản Google cho demo ----------
const isEmail = (e) => /^[^@\s,]+@[^@\s,]+\.[^@\s,]+$/.test(e);
const googleLecturer = (arg('--google-lecturer') ?? '').trim().toLowerCase();
const googleStudent = (arg('--google-student') ?? '').trim().toLowerCase();
const adminEmails = (arg('--admin-email') ?? '').split(',').map((e) => e.trim().toLowerCase()).filter(Boolean);
for (const e of [googleLecturer, googleStudent].filter(Boolean)) {
  if (!isEmail(e)) throw new Error(`Email không hợp lệ: ${e}`);
}
{
  // One account holds one role (the users doc has a single role), so the three must differ.
  const all = [googleLecturer, googleStudent, ...adminEmails].filter(Boolean);
  if (new Set(all).size !== all.length) {
    throw new Error('Mỗi tài khoản chỉ giữ một vai: --google-lecturer, --google-student và --admin-email phải khác nhau.');
  }
}
const LECTURER_EMAIL = googleLecturer || 'quanm@fe.edu.vn';
const LECTURER_NAME = 'Nguyễn Minh Quân';

const TERM = 'Fall 2026';
const WEEKS = 10;

// ---------- tài khoản ----------
const lecturerUid = await signUp(LECTURER_EMAIL, LECTURER_NAME);
const me = se1801.students[0]; // SE190101, tài khoản sinh viên mẫu
// The roster row carries the email too, so the class list shows the account the student signs in with.
if (googleStudent) me.email = googleStudent;
const studentUid = await signUp(me.email, me.name);
// Final: giáo vụ và quản trị đăng nhập web admin (cùng mật khẩu Demo@123).
const staffUid = await signUp('giaovu@fe.edu.vn', 'Phòng Giáo vụ');
const adminUid = await signUp('admin@fe.edu.vn', 'Quản trị Attendo');
console.log('lecturer', lecturerUid, 'student', studentUid, 'staff', staffUid, 'admin', adminUid);

{
  let batch = fs.batch();
  let ops = 0;
  const put = async (path, data) => {
    batch.set(fs.doc(path), data);
    if (++ops >= 450) { await batch.commit(); batch = fs.batch(); ops = 0; }
  };

  await put(`users/${lecturerUid}`, {
    role: 'lecturer', displayName: LECTURER_NAME, email: LECTURER_EMAIL,
    reminderBeforeSlot: true, reminderUnclosed: true, lastImportAt: ts(vn(2026, 9, 5, 20)),
  });
  await put(`users/${studentUid}`, { role: 'student', displayName: me.name, email: me.email, studentCode: me.code });
  await put(`users/${staffUid}`, { role: 'staff', displayName: 'Phòng Giáo vụ', email: 'giaovu@fe.edu.vn' });
  await put(`users/${adminUid}`, { role: 'admin', displayName: 'Quản trị Attendo', email: 'admin@fe.edu.vn' });
  // --admin-email <gmail>: web admin chỉ đăng nhập bằng Google, nên cấp quyền Quản trị cho tài khoản Google thật
  // (phải đăng nhập Google vào /admin một lần trước để có tài khoản). Nạp lại dữ liệu xoá hồ sơ, nên mỗi lần
  // nạp đều phải truyền lại.
  for (const email of adminEmails) {
    try {
      const u = await auth.getUserByEmail(email);
      await put(`users/${u.uid}`, { role: 'admin', displayName: u.displayName ?? email, email });
      console.log(`Cấp quyền Quản trị cho ${email}`);
    } catch (e) {
      if (e.code !== 'auth/user-not-found') throw e;
      console.log(`CHƯA cấp quyền Quản trị cho ${email}: tài khoản này chưa đăng nhập Google vào /admin lần nào`);
    }
  }
  for (const [code, name] of [['PRM393', 'Mobile Programming'], ['MMA301', 'Multiplatform Mobile App'], ['PRN221', 'Advanced C# Programming']]) {
    await put(`subjects/${code}`, { code, name, status: 'active', updatedBy: staffUid, updatedAt: ts(vn(2026, 9, 1, 8)) });
  }
  await put('announcements/welcome', {
    title: 'Chào kỳ Fall 2026', body: 'Hạn nhập danh sách lớp là 15/09.', audience: 'all', status: 'published',
    createdBy: staffUid, publishedAt: ts(vn(2026, 9, 1, 8)),
  });

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
      lecturerId: lecturerUid, lecturerName: LECTURER_NAME, term: TERM, subject: c.subject, code: c.code,
      studentCount: c.students.length, totalSlots: slots.length, importedAt: ts(vn(2026, 9, 5, 20)),
      // Final: lớp mẫu đã được giáo vụ duyệt, nên mở mã QR được ngay.
      status: 'approved', reviewedBy: staffUid, reviewedAt: ts(vn(2026, 9, 6, 9)),
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
        start: ts(s.start), slotNo: s.slotNo, room: s.room, totalSlots: slots.length,
      };
      const base = { ...copy, end: ts(s.end), studentCount: c.students.length };
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
            source: absent ? 'auto' : 'scan', final: true, at: ts(new Date(s.start.getTime() + 600000)),
          });
          if (absent && key === 'PRM393_SE1801') requests.push({ st, slotId: id, copy, s });
        }
        await put(`slots/${id}`, { ...base, closed: true, closedAt: ts(new Date(s.end.getTime() + 300000)), qrOpen: false, presentCount: present, absentCount: c.students.length - present });
      } else if (isLive) {
        // Đang diễn ra: 24 em đã quét, chưa mở mã trên app.
        for (const st of c.students.slice(6, 30)) {
          await put(`slots/${id}/attendance/${st.code}`, {
            ...copy, studentCode: st.code, studentName: st.name, present: true, source: 'scan', final: false,
            scannerUid: 'demo', at: ts(new Date(s.start.getTime() + 300000)),
          });
        }
        await put(`slots/${id}`, { ...base, closed: false, qrOpen: false });
      } else {
        await put(`slots/${id}`, { ...base, closed: false, qrOpen: false });
      }
      void i;
    }
  }

  // --demo: giảng viên thứ hai vừa nhập một lớp, đang chờ giáo vụ duyệt, để demo luồng liên vai trò
  // (quản trị duyệt trên web admin → app giảng viên đổi ngay) mà không phải đăng ký tài khoản mới.
  if (process.argv.includes('--demo')) {
    // Sinh viên thứ hai (đã quá ngưỡng vắng) để xem màn sinh viên "đã fail" và có hai người quét mã.
    const tien = se1801.students.find((x) => x.code === 'SE190102');
    const tienUid = await signUp(tien.email, tien.name);
    await put(`users/${tienUid}`, { role: 'student', displayName: tien.name, email: tien.email, studentCode: tien.code });
    const namUid = await signUp('nam@fe.edu.vn', 'Lê Hoàng Nam');
    await put(`users/${namUid}`, { role: 'lecturer', displayName: 'Lê Hoàng Nam', email: 'nam@fe.edu.vn', reminderBeforeSlot: true, reminderUnclosed: true, lastImportAt: ts(new Date(now.getTime() - 3600000)) });
    const classId = `${namUid}_${TERM.replace(' ', '')}_MMA301_SE1806`.replace(/[^A-Za-z0-9_]/g, '');
    const namStudents = [['SE190901', 'Phạm Gia Bảo'], ['SE190902', 'Ngô Thảo Vy'], ['SE190903', 'Lý Minh Khang'], ['SE190904', 'Đỗ Ngọc Hân'], ['SE190905', 'Vũ Quốc Thịnh'], ['SE190906', 'Bùi Khánh Linh']];
    const weekly = [{ weekday: 2, slotNo: 2, room: 'P.210' }, { weekday: 4, slotNo: 2, room: 'P.210' }];
    const monday = vn(2026, 9, 7);
    const namSlots = [];
    for (let w = 0; w < WEEKS; w++) {
      for (const ws of weekly) {
        const day = vnParts(new Date(monday.getTime() + (w * 7 + ws.weekday - 1) * 86400000));
        const t = SLOT_TIMES[ws.slotNo];
        namSlots.push({ ...ws, start: vn(day.y, day.m, day.d, t[0], t[1]), end: vn(day.y, day.m, day.d, t[2], t[3]) });
      }
    }
    await put(`classes/${classId}`, {
      lecturerId: namUid, lecturerName: 'Lê Hoàng Nam', term: TERM, subject: 'MMA301', code: 'SE1806',
      studentCount: namStudents.length, totalSlots: namSlots.length, status: 'pending',
      importedAt: ts(new Date(now.getTime() - 3600000)), submittedAt: ts(new Date(now.getTime() - 3600000)),
    });
    for (const [code, name] of namStudents) {
      await put(`classes/${classId}/students/${code}`, { studentCode: code, name, email: `${code.toLowerCase()}@fpt.edu.vn`, lecturerId: namUid });
    }
    for (const s of namSlots) {
      const d = vnParts(s.start);
      await put(`slots/${classId}_${d.y}${two(d.m)}${two(d.d)}_s${s.slotNo}`, {
        lecturerId: namUid, classId, subject: 'MMA301', classCode: 'SE1806', term: TERM, start: ts(s.start), end: ts(s.end),
        slotNo: s.slotNo, room: s.room, totalSlots: namSlots.length, studentCount: namStudents.length, closed: false, qrOpen: false,
      });
    }
  }

  // Yêu cầu sửa: em SE190101 có 1 đang chờ, 1 bị từ chối, 1 chưa báo; thêm 2 em khác đang chờ.
  const mine = requests.filter((r) => r.st.code === me.code);
  const others = requests.filter((r) => r.st.code !== me.code && ['SE190103', 'SE190105'].includes(r.st.code));
  const reqDoc = (r, status, reason, note, extra = {}) => ({
    studentUid: r.st.code === me.code ? studentUid : `demo-${r.st.code}`,
    studentCode: r.st.code, studentName: r.st.name, lecturerId: lecturerUid, slotId: r.slotId,
    classId: r.copy.classId, subject: r.copy.subject, slotStart: ts(r.s.start), slotNo: r.s.slotNo,
    reason, note, status, createdAt: ts(new Date(r.s.end.getTime() + 3600000)), ...extra,
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
}

console.log(`Xong. Giảng viên ${LECTURER_EMAIL}${process.argv.includes("--demo") ? " và nam@fe.edu.vn (lớp chờ duyệt), sinh viên tien102@fpt.edu.vn" : ""}, sinh viên ${me.email}, giáo vụ giaovu@fe.edu.vn, quản trị admin@fe.edu.vn, mật khẩu ${PASSWORD}. Slot đang diễn ra: ${liveSlotNo || 'không có'}`);
