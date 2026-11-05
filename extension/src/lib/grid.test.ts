import { describe, expect, it } from 'vitest';

import { GridError, parseAttendanceGrid } from './grid';
import { parseDelimitedText } from './sources/file-import';
import { parseStatus } from './status';

describe('parseStatus', () => {
  it.each([
    ['ATTEND', 'ATTEND'],
    ['present', 'ATTEND'],
    ['Có mặt', 'ATTEND'],
    ['1', 'ATTEND'],
    ['ABSENT', 'ABSENT'],
    ['Vắng', 'ABSENT'],
    ['vang', 'ABSENT'],
    ['0', 'ABSENT'],
  ])('reads %s as %s', (value, expected) => expect(parseStatus(value)).toBe(expected));

  it.each(['', 'LATE', 'maybe', null])('refuses %s instead of defaulting', (value) =>
    expect(parseStatus(value)).toBeNull(),
  );
});

describe('parseAttendanceGrid', () => {
  it('reads the assistant review tab: context above, header on row 8, FINAL_STATUS wins', () => {
    const grid = [
      [],
      ['Attendance review - SWE201c / SE1927'],
      ['2026-09-18 · Slot 2 · NVH 611 · Revision 3'],
      ['LỚP', 'SE1927', 'MÔN', 'SWE201c', 'NGÀY', '2026-09-18', 'SLOT', '2'],
      [],
      ['HƯỚNG DẪN', '', 'Chỉ sửa FINAL_STATUS'],
      [],
      ['STUDENT_CODE', 'STUDENT_NAME', 'EMAIL', 'CHECK_IN_AT', 'SUGGESTED_STATUS', 'FINAL_STATUS'],
      ['se180001', 'A', 'a@x.test', '', 'ABSENT', 'ATTEND'],
      ['SE180002', 'B', 'b@x.test', '', 'ATTEND', 'ABSENT'],
    ];
    const parsed = parseAttendanceGrid(grid);
    expect(parsed.headerRow).toBe(8);
    expect(parsed.context).toEqual({
      group: 'SE1927',
      course: 'SWE201c',
      date: '2026-09-18',
      slot: '2',
    });
    expect(parsed.rows).toEqual([
      { studentCode: 'SE180001', status: 'ATTEND' },
      { studentCode: 'SE180002', status: 'ABSENT' },
    ]);
  });

  it('reads a plain CSV with Vietnamese headers and dd/mm/yyyy context', () => {
    const text =
      String.fromCharCode(0xfeff) +
      'Ngày;18/09/2026\nMSSV;Trạng thái\nSE180001;Có mặt\n\nSE180002;Vắng\n';
    const parsed = parseAttendanceGrid(parseDelimitedText(text));
    expect(parsed.context.date).toBe('2026-09-18');
    expect(parsed.rows.map((row) => row.status)).toEqual(['ATTEND', 'ABSENT']);
  });

  it.each([
    ['no header', [['a', 'b']], 'tiêu đề'],
    [
      'duplicate code',
      [
        ['MSSV', 'Status'],
        ['SE1', 'P'],
        ['SE1', 'A'],
      ],
      'trùng',
    ],
    [
      'unreadable status',
      [
        ['MSSV', 'Status'],
        ['SE180001', 'late'],
      ],
      'không đọc được',
    ],
    [
      'bad code',
      [
        ['MSSV', 'Status'],
        ['x', 'P'],
      ],
      'không hợp lệ',
    ],
    ['no rows', [['MSSV', 'Status']], 'không có dòng'],
  ])('fails on %s', (_name, grid, message) => {
    expect(() => parseAttendanceGrid(grid)).toThrow(GridError);
    expect(() => parseAttendanceGrid(grid)).toThrow(message);
  });
});
