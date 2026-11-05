import type { PageSnapshot } from './attendance';

function csvCell(value: string): string {
  // Neutralize spreadsheet formula injection, then quote when needed.
  const safe = /^[=+\-@\t\r]/.test(value) ? `'${value}` : value;
  return /[",\n\r;]/.test(safe) ? `"${safe.replaceAll('"', '""')}"` : safe;
}

/**
 * A CSV the lecturer can fill offline: context rows the importer understands, then one row per
 * student on the page with its current status. Re-importing it unchanged yields zero changes.
 */
export function buildTemplateCsv(page: PageSnapshot): string {
  const { context } = page;
  const lines = [
    ['LỚP', context.group, 'MÔN', context.course, 'NGÀY', context.date, 'SLOT', context.slot],
    ['PHÒNG', context.room, 'CAMPUS', context.campus],
    [],
    ['STUDENT_CODE', 'FULL_NAME', 'STATUS'],
    ...page.rows.map((row) => [row.studentCode, row.name, row.currentStatus]),
  ];
  return `${String.fromCharCode(0xfeff)}${lines.map((line) => line.map(csvCell).join(',')).join('\r\n')}\r\n`;
}
