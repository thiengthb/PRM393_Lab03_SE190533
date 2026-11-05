import {
  CONTEXT_FIELDS,
  CONTEXT_LABEL,
  type AttendanceStatus,
  type BatchContext,
  type ContextField,
  type DraftRow,
  type PageSnapshot,
  type SourceBatch,
} from './attendance';

export class DraftError extends Error {
  override name = 'DraftError';
}

export type ContextCheck = Readonly<{
  field: ContextField;
  page: string;
  source: string | null;
  /** `skipped` when either side does not carry the field (e.g. course on a local HTML page). */
  result: 'match' | 'skipped';
}>;

export type Draft = Readonly<{
  rows: DraftRow[];
  checks: readonly ContextCheck[];
  /** Page students absent from the source whose current page status was kept (opt-in only). */
  kept: readonly string[];
}>;

export type DraftOptions = Readonly<{
  /**
   * Keep the page's current status for students the source does not list, instead of failing.
   * Honored only for file and sheet sources: an approved backend batch is a full roster by
   * definition, so a gap there is always an error (docs/decisions.md D-007).
   */
  keepMissing?: boolean;
}>;

export function supportsKeepMissing(source: Pick<SourceBatch, 'kind'>): boolean {
  return source.kind === 'file' || source.kind === 'sheet';
}

function normalizeContextValue(field: ContextField, value: string): string {
  const trimmed = value.trim().replace(/\s+/g, ' ');
  if (field === 'slot') return trimmed.replace(/^\D+/, '').replace(/^0+(?=\d)/, '');
  return trimmed.toUpperCase();
}

function preview(codes: readonly string[]): string {
  return codes.length > 3 ? `${codes.slice(0, 3).join(', ')}...` : codes.join(', ');
}

/** Compare every context field both sides carry. Any difference is fatal (fail closed). */
export function checkContext(page: PageSnapshot, context: BatchContext): ContextCheck[] {
  return CONTEXT_FIELDS.map((field) => {
    const pageValue = page.context[field] ?? '';
    const sourceValue = context[field]?.trim() || null;
    if (!pageValue.trim() || sourceValue === null) {
      return { field, page: pageValue, source: sourceValue, result: 'skipped' as const };
    }
    if (normalizeContextValue(field, pageValue) !== normalizeContextValue(field, sourceValue)) {
      throw new DraftError(
        `${CONTEXT_LABEL[field]} không khớp: trang là "${pageValue}", nguồn là "${sourceValue}".`,
      );
    }
    return { field, page: pageValue, source: sourceValue, result: 'match' as const };
  });
}

/**
 * Build the editable draft for the page from a source. By default the roster must match exactly in
 * both directions; a missing, extra or duplicated student stops the flow rather than guessing.
 * With `keepMissing`, page students absent from a file/sheet keep their current status; extra or
 * duplicated codes still fail. The returned rows follow the PAGE order like the FAP table.
 */
export function buildDraft(
  page: PageSnapshot,
  source: SourceBatch,
  options: DraftOptions = {},
): Draft {
  const keepMissing = Boolean(options.keepMissing) && supportsKeepMissing(source);
  const checks = checkContext(page, source.context);
  const bySource = new Map<string, AttendanceStatus>();
  for (const row of source.rows) {
    const code = row.studentCode.trim().toUpperCase();
    if (!code) throw new DraftError('Nguồn có dòng thiếu mã sinh viên.');
    if (bySource.has(code)) throw new DraftError(`Nguồn có mã sinh viên trùng: ${code}.`);
    bySource.set(code, row.status);
  }
  const pageCodes = new Set(page.rows.map((row) => row.studentCode.toUpperCase()));
  const missing = page.rows
    .map((row) => row.studentCode)
    .filter((code) => !bySource.has(code.toUpperCase()));
  const extra = [...bySource.keys()].filter((code) => !pageCodes.has(code));
  const blockingMissing = keepMissing ? [] : missing;
  if (blockingMissing.length || extra.length) {
    const parts: string[] = [];
    if (blockingMissing.length) {
      parts.push(`thiếu ${missing.length} sinh viên của trang (${preview(missing)})`);
    }
    if (extra.length) parts.push(`dư ${extra.length} mã không có trên trang (${preview(extra)})`);
    throw new DraftError(`Danh sách không khớp: ${parts.join('; ')}.`);
  }
  if (missing.length === page.rows.length) {
    throw new DraftError('Nguồn không có sinh viên nào của trang.');
  }
  const rows = page.rows.map((row) => ({
    studentCode: row.studentCode,
    status: bySource.get(row.studentCode.toUpperCase()) ?? row.currentStatus,
  }));
  return { rows, checks, kept: keepMissing ? missing : [] };
}

/** The page itself as a source: start from what is currently selected on the page. */
export function pageAsSource(page: PageSnapshot): SourceBatch {
  return {
    kind: 'page',
    label: 'Trạng thái hiện có trên trang',
    context: {},
    rows: page.rows.map((row) => ({ studentCode: row.studentCode, status: row.currentStatus })),
  };
}

export type DraftSummary = Readonly<{
  total: number;
  attend: number;
  absent: number;
  changed: number;
}>;

export function summarize(page: PageSnapshot, rows: readonly DraftRow[]): DraftSummary {
  const current = new Map(page.rows.map((row) => [row.studentCode, row.currentStatus]));
  const attend = rows.filter((row) => row.status === 'ATTEND').length;
  return {
    total: rows.length,
    attend,
    absent: rows.length - attend,
    changed: rows.filter((row) => current.get(row.studentCode) !== row.status).length,
  };
}
