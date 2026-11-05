import type { AttendanceStatus } from './attendance';

/** Uppercase, strip Vietnamese diacritics and every non-alphanumeric character. */
export function normalizeToken(value: unknown): string {
  return String(value ?? '')
    .replace(/đ/gi, 'D')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '');
}

const ATTEND = new Set(['ATTEND', 'ATTENDED', 'PRESENT', 'P', 'COMAT', 'X', '1', 'TRUE', 'YES']);
const ABSENT = new Set(['ABSENT', 'A', 'VANG', 'VANGMAT', '0', 'FALSE', 'NO']);

/**
 * Interpret a status cell from a file or sheet. Returns null for anything not explicitly listed,
 * including an empty cell, so an unreadable status fails the import instead of defaulting.
 */
export function parseStatus(value: unknown): AttendanceStatus | null {
  const token = normalizeToken(value);
  if (ATTEND.has(token)) return 'ATTEND';
  if (ABSENT.has(token)) return 'ABSENT';
  return null;
}
