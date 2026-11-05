import { readFileSync } from 'node:fs';
import { JSDOM } from 'jsdom';
import { describe, expect, it } from 'vitest';
import { createAttendanceRow } from '../src/attendance-row.js';
import { parseClasses, sessionNumber, sessionsFor, todayVn } from '../src/roster.js';
// Adapter của extension chỉ import type, nên chạy thẳng được ở đây: test này giữ trang giả lập và
// extension khớp nhau (tiêu đề, mã sinh viên, bảng), lỗi 05/11 “Đọc trang” báo không xác minh được.
import { createFapV2Adapter } from '../../extension/src/content/fap-v2-adapter.ts';

const csv = readFileSync(new URL('../../mobile/sample-data/lop-fall-2026.csv', import.meta.url), 'utf8');
const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const main = readFileSync(new URL('../src/main.js', import.meta.url), 'utf8').replace(/^import .*;\r?$/gm, '');
const ORIGIN = 'http://127.0.0.1:4173';

function page() {
  const dom = new JSDOM(html, { url: `${ORIGIN}/fap/`, runScripts: 'outside-only' });
  Object.assign(dom.window, { csvText: csv, parseClasses, sessionsFor, todayVn, createAttendanceRow });
  dom.window.eval(main);
  return dom.window.document;
}

describe('extension đọc được FAP giả lập', () => {
  it('Đọc trang: đúng lớp, slot, phòng và đủ sinh viên mẫu (mã SE19…)', () => {
    const document = page();
    const adapter = createFapV2Adapter({ document, location: { origin: ORIGIN, protocol: 'http:' }, fixtureOrigins: [ORIGIN] });
    const snap = adapter.read();
    const rows = document.querySelectorAll('#attendance-rows tr');
    expect(snap.context).toMatchObject({ mode: 'fixture', campus: 'FU-HCM' });
    expect(snap.context.group).toMatch(/^SE18\d{2}$/);
    expect(snap.rows).toHaveLength(rows.length);
    expect(snap.rows.every((r) => /^SE19\d{4}$/.test(r.studentCode))).toBe(true);
  });

  it('tiêu đề ghi số buổi như FAP thật', () => {
    const c = parseClasses(csv)[0]; // PRM393 SE1801, bắt đầu 07/09/2026, thứ Ba và thứ Năm
    expect(c.startDate).toBe('2026-09-07');
    expect(sessionNumber(c, '2026-09-08')).toBe(1);
    expect(sessionNumber(c, '2026-09-10')).toBe(2);
    expect(sessionNumber(c, '2026-09-15')).toBe(3);
    expect(sessionNumber(c, '2026-08-01')).toBe(1);
    expect(page().querySelector('#attendance-title').textContent).toMatch(/This is the session number \d+ of the course\.$/);
  });
});
