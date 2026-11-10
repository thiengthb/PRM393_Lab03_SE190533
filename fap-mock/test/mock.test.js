import { readFileSync } from 'node:fs';
import { JSDOM } from 'jsdom';
import { describe, expect, it } from 'vitest';
import { createAttendanceRow } from '../src/attendance-row.js';
import { parseClasses, sessionsFor, todayVn, vnWeekday } from '../src/roster.js';

const csv = readFileSync(new URL('../../mobile/sample-data/lop-fall-2026.csv', import.meta.url), 'utf8');
const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
// main.js chạy trong JSDOM: bỏ dòng import, đưa các hàm vào window.
const main = readFileSync(new URL('../src/main.js', import.meta.url), 'utf8').replace(/^import .*;\r?$/gm, '');

function create() {
  const dom = new JSDOM(html, { url: 'http://127.0.0.1:4173/fap/', runScripts: 'outside-only' });
  Object.assign(dom.window, { csvText: csv, parseClasses, sessionsFor, todayVn, createAttendanceRow });
  dom.window.eval(main);
  return dom;
}

describe('FAP giả lập đọc file lớp mẫu của Attendo', () => {
  it('tách 4 lớp, mỗi lớp 2 slot mỗi tuần, có đủ sinh viên', () => {
    const classes = parseClasses(csv);
    expect(classes.map((c) => `${c.courseCode} ${c.groupCode}`)).toEqual(['PRM393 SE1801', 'PRM393 SE1802', 'MMA301 SE1805', 'PRN221 SE1810']);
    expect(classes.every((c) => c.slots.length === 2 && c.students.length > 0)).toBe(true);
    expect(classes[0].students[0]).toEqual({ studentCode: 'SE190101', fullName: 'Huỳnh Anh Dung' });
  });

  it('buổi đúng thứ của ngày lên đầu (thứ Ba 08/09/2026: PRM393 SE1801 slot 1)', () => {
    expect(vnWeekday('2026-09-08')).toBe(3);
    const s = sessionsFor(parseClasses(csv), '2026-09-08');
    // 8 buổi trong lịch tuần của 4 lớp + các slot 1-6 còn lại của mỗi lớp (18 buổi).
    expect(s).toHaveLength(26);
    expect(s[0]).toMatchObject({ courseCode: 'PRM393', groupCode: 'SE1801', slotCode: 'SLOT_1', room: 'P.305', scheduled: true });
  });

  it('chọn được mọi slot 1-6 của một lớp, phòng lấy theo lịch của lớp (buổi demo đặt vào slot đang diễn ra)', () => {
    const s = sessionsFor(parseClasses(csv), '2026-11-08').filter((x) => x.courseCode === 'PRM393' && x.groupCode === 'SE1801');
    expect(new Set(s.map((x) => x.slotCode))).toEqual(new Set([1, 2, 3, 4, 5, 6].map((n) => `SLOT_${n}`)));
    expect(s.every((x) => x.room === 'P.305')).toBe(true);
  });

  it('dựng bảng đúng cấu trúc mock-fap-v2 và lưu vào sessionStorage', () => {
    const dom = create();
    const d = dom.window.document;
    const rows = d.querySelectorAll('#attendance-rows tr');
    expect(rows.length).toBeGreaterThan(0);
    expect(d.querySelectorAll('#attendance-rows input[type=radio]')).toHaveLength(rows.length * 2);
    expect(d.querySelector('#attendance-title').textContent).toMatch(/^Attendance for .* at slot \d on \w+ \d{2}\/\d{2}\/\d{4} at room /);
    rows[0].querySelector('input[value="rdPresent"]').checked = true;
    d.querySelector('#aspnetForm').dispatchEvent(new dom.window.Event('submit', { cancelable: true }));
    expect(d.querySelector('#save-status').dataset.savedSnapshot).toContain('"status":"ATTEND"');
    expect(html).toContain('Không phải trang FAP chính thức');
    dom.window.close();
  });
});
