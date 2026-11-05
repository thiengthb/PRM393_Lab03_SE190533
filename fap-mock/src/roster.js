// Danh sách lớp lấy từ file mẫu mobile/sample-data/lop-fall-2026.csv, đúng file giảng viên
// nhập vào Hereby, nên mã sinh viên trên FAP giả lập khớp dữ liệu Hereby.
// Cột: mon, lop, mssv, ho_ten, email, lich (T3-S1-P.305;T5-S1-P.305), bat_dau.

/** @returns {{courseCode:string, groupCode:string, startDate:string|null, students:{studentCode:string, fullName:string}[], slots:{weekday:number, slotNo:number, room:string}[]}[]} */
export function parseClasses(csvText) {
  const byKey = new Map();
  const lines = csvText.trim().split(/\r?\n/u).slice(1);
  for (const line of lines) {
    const [course, group, code, name, , schedule, start] = line.split(',').map((x) => (x ?? '').trim());
    if (!course || !group || !code) continue;
    const key = `${course}_${group}`;
    if (!byKey.has(key)) byKey.set(key, { courseCode: course, groupCode: group, students: [], slots: [], startDate: null });
    const c = byKey.get(key);
    const startMatch = start?.match(/^(\d{2})\/(\d{2})\/(\d{4})$/u);
    if (startMatch) c.startDate = `${startMatch[3]}-${startMatch[2]}-${startMatch[1]}`;
    c.students.push({ studentCode: code, fullName: name });
    if (schedule) {
      c.slots = schedule.split(';').map((part) => {
        const m = part.match(/^T(\d)-S(\d)-(.+)$/u);
        if (!m) throw new Error(`Lịch không đúng dạng: ${part}`);
        return { weekday: Number(m[1]), slotNo: Number(m[2]), room: m[3] };
      });
    }
  }
  return [...byKey.values()];
}

/** Mọi buổi có thể chọn trong ngày [date]: lớp × slot trong tuần. Buổi đúng thứ của ngày lên đầu. */
export function sessionsFor(classes, date) {
  const weekday = vnWeekday(date);
  const all = classes.flatMap((c) =>
    c.slots.map((s) => ({
      courseCode: c.courseCode,
      groupCode: c.groupCode,
      campus: 'FU-HCM',
      sessionDate: date,
      slotCode: `SLOT_${s.slotNo}`,
      room: s.room,
      rosterCount: c.students.length,
      students: c.students,
      scheduled: s.weekday === weekday,
      sessionNumber: sessionNumber(c, date),
    })),
  );
  return all.sort((a, b) => Number(b.scheduled) - Number(a.scheduled) || a.slotCode.localeCompare(b.slotCode));
}

/**
 * Buổi thứ mấy của lớp tính đến hết ngày [date] (FAP ghi “This is the session number N of the course”).
 * Đếm các ngày có lịch từ ngày bắt đầu; trước ngày bắt đầu hoặc không có lịch thì là 1.
 */
export function sessionNumber(c, date) {
  if (!c.startDate || date < c.startDate || c.slots.length === 0) return 1;
  let count = 0;
  for (let d = new Date(`${c.startDate}T12:00:00+07:00`); ; d.setUTCDate(d.getUTCDate() + 1)) {
    const day = d.toISOString().slice(0, 10);
    if (day > date) break;
    count += c.slots.filter((s) => s.weekday === vnWeekday(day)).length;
  }
  return Math.max(count, 1);
}

/** Thứ theo cách gọi Việt Nam: 2 = thứ Hai … 8 = Chủ nhật. */
export function vnWeekday(date) {
  const d = new Date(`${date}T12:00:00+07:00`).getUTCDay();
  return d === 0 ? 8 : d + 1;
}

/** Ngày hôm nay theo giờ Việt Nam, dạng yyyy-MM-dd. */
export function todayVn(now = new Date()) {
  return new Date(now.getTime() + 7 * 3600_000).toISOString().slice(0, 10);
}
