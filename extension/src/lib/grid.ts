import type { BatchContext, ContextField, DraftRow } from './attendance';
import { normalizeToken, parseStatus } from './status';

export class GridError extends Error {
  override name = 'GridError';
}

export type ParsedGrid = Readonly<{
  context: BatchContext;
  rows: DraftRow[];
  /** 1-based sheet row of the header, for messages. */
  headerRow: number;
}>;

const CODE_HEADERS = new Set([
  'STUDENTCODE',
  'ROLLNUMBER',
  'ROLLNO',
  'MSSV',
  'MASV',
  'MASINHVIEN',
  'STUDENTID',
]);
/** Ordered by priority: the review template's FINAL_STATUS wins over a generic STATUS column. */
const STATUS_HEADERS = ['FINALSTATUS', 'STATUS', 'TRANGTHAI', 'ATTENDANCE', 'DIEMDANH'];
const CONTEXT_LABELS: Record<string, ContextField> = {
  LOP: 'group',
  GROUP: 'group',
  MON: 'course',
  COURSE: 'course',
  NGAY: 'date',
  DATE: 'date',
  SLOT: 'slot',
  PHONG: 'room',
  ROOM: 'room',
  CAMPUS: 'campus',
};
const HEADER_SCAN_LIMIT = 30;
export const MAX_GRID_ROWS = 500;

function cellText(value: unknown): string {
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return value.toISOString().slice(0, 10);
  }
  return String(value ?? '').trim();
}

function toIsoDate(value: string): string {
  const dmy = value.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (dmy) return `${dmy[3]}-${dmy[2]!.padStart(2, '0')}-${dmy[1]!.padStart(2, '0')}`;
  return value;
}

/** Label/value pairs above the header, e.g. the exported review tab's "LỚP | SE1927 | MÔN | ...". */
function readContext(rows: readonly string[][]): BatchContext {
  const context: BatchContext = {};
  for (const row of rows) {
    for (let index = 0; index < row.length - 1; index++) {
      const field = CONTEXT_LABELS[normalizeToken(row[index])];
      const value = row[index + 1];
      if (field && value && !CONTEXT_LABELS[normalizeToken(value)] && !context[field]) {
        context[field] = field === 'date' ? toIsoDate(value) : value;
      }
    }
  }
  return context;
}

/**
 * Turn a raw 2-D grid (CSV, XLSX sheet or Google Sheets values) into draft rows. The header can sit
 * anywhere in the first rows, so the assistant's exported review tab (header on row 8) and a plain
 * two-column CSV both work. Every data row must have a known status; nothing is defaulted.
 */
export function parseAttendanceGrid(grid: readonly (readonly unknown[])[]): ParsedGrid {
  const rows = grid.map((row) => row.map(cellText));
  let headerIndex = -1;
  let codeColumn = -1;
  let statusColumn = -1;
  for (let index = 0; index < Math.min(rows.length, HEADER_SCAN_LIMIT); index++) {
    const tokens = rows[index]!.map(normalizeToken);
    const code = tokens.findIndex((token) => CODE_HEADERS.has(token));
    const status = STATUS_HEADERS.map((header) => tokens.indexOf(header)).find((i) => i >= 0);
    if (code >= 0 && status !== undefined) {
      headerIndex = index;
      codeColumn = code;
      statusColumn = status;
      break;
    }
  }
  if (headerIndex < 0) {
    throw new GridError(
      'Không tìm thấy dòng tiêu đề. Cần một cột mã sinh viên (STUDENT_CODE, Roll Number hoặc MSSV) và một cột trạng thái (FINAL_STATUS, Status hoặc Trạng thái).',
    );
  }
  const dataRows = rows.slice(headerIndex + 1);
  if (dataRows.length > MAX_GRID_ROWS) {
    throw new GridError(`Tệp có quá nhiều dòng (tối đa ${MAX_GRID_ROWS}).`);
  }
  const seen = new Set<string>();
  const parsed: DraftRow[] = [];
  dataRows.forEach((row, offset) => {
    const sheetRow = headerIndex + offset + 2;
    if (row.every((cell) => !cell)) return;
    const code = (row[codeColumn] ?? '').toUpperCase();
    if (!/^[A-Z0-9-]{2,32}$/.test(code)) {
      throw new GridError(
        `Dòng ${sheetRow}: mã sinh viên "${row[codeColumn] ?? ''}" không hợp lệ.`,
      );
    }
    if (seen.has(code)) throw new GridError(`Dòng ${sheetRow}: mã ${code} bị trùng.`);
    const status = parseStatus(row[statusColumn]);
    if (status === null) {
      throw new GridError(
        `Dòng ${sheetRow}: trạng thái "${row[statusColumn] ?? ''}" của ${code} không đọc được. Dùng ATTEND/ABSENT, Có mặt/Vắng hoặc 1/0.`,
      );
    }
    seen.add(code);
    parsed.push({ studentCode: code, status });
  });
  if (!parsed.length) throw new GridError('Tệp không có dòng sinh viên nào dưới tiêu đề.');
  return {
    context: readContext(rows.slice(0, headerIndex)),
    rows: parsed,
    headerRow: headerIndex + 1,
  };
}
