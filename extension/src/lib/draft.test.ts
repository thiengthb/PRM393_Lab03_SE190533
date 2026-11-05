import { describe, expect, it } from 'vitest';

import type { PageSnapshot, SourceBatch } from './attendance';
import { buildDraft, DraftError, pageAsSource, summarize } from './draft';
import { parseAttendanceGrid } from './grid';
import { parseDelimitedText } from './sources/file-import';
import { buildTemplateCsv } from './template';

const page: PageSnapshot = {
  context: {
    mode: 'fixture',
    campus: 'FU-HL',
    course: 'SWE201c',
    sessionId: '',
    group: 'SE1927',
    date: '2026-09-18',
    slot: '2',
    room: 'NVH 611',
  },
  rows: [
    { studentCode: 'SE180001', name: 'A', currentStatus: 'ABSENT' },
    { studentCode: 'SE180002', name: 'B', currentStatus: 'ABSENT' },
  ],
};

const source = (overrides: Partial<SourceBatch> = {}): SourceBatch => ({
  kind: 'file',
  label: 'test.csv',
  context: {},
  rows: [
    { studentCode: 'se180002', status: 'ATTEND' },
    { studentCode: 'SE180001', status: 'ABSENT' },
  ],
  ...overrides,
});

describe('buildDraft', () => {
  it('follows page order, matches codes case-insensitively and reports checks', () => {
    const draft = buildDraft(
      page,
      source({ context: { group: 'se1927', slot: 'SLOT_2', room: null } }),
    );
    expect(draft.rows).toEqual([
      { studentCode: 'SE180001', status: 'ABSENT' },
      { studentCode: 'SE180002', status: 'ATTEND' },
    ]);
    expect(draft.checks.filter((c) => c.result === 'match').map((c) => c.field)).toEqual([
      'group',
      'slot',
    ]);
  });

  it.each([
    ['context mismatch', source({ context: { date: '2026-09-19' } }), 'Ngày không khớp'],
    [
      'missing student',
      source({ rows: [{ studentCode: 'SE180001', status: 'ATTEND' }] }),
      'thiếu 1',
    ],
    [
      'extra student',
      source({ rows: [...source().rows, { studentCode: 'SE189999', status: 'ATTEND' }] }),
      'dư 1',
    ],
    [
      'duplicate',
      source({ rows: [...source().rows, { studentCode: 'SE180001', status: 'ATTEND' }] }),
      'trùng',
    ],
  ])('fails closed on %s', (_name, batch, message) => {
    expect(() => buildDraft(page, batch)).toThrow(DraftError);
    expect(() => buildDraft(page, batch)).toThrow(message);
  });

  describe('keepMissing', () => {
    const partial = source({ rows: [{ studentCode: 'SE180002', status: 'ATTEND' }] });

    it('keeps the current page status for students the file does not list', () => {
      const draft = buildDraft(page, partial, { keepMissing: true });
      expect(draft.rows).toEqual([
        { studentCode: 'SE180001', status: 'ABSENT' },
        { studentCode: 'SE180002', status: 'ATTEND' },
      ]);
      expect(draft.kept).toEqual(['SE180001']);
      expect(summarize(page, draft.rows).changed).toBe(1);
    });

    it('works for sheets too and reports nothing kept when the file is complete', () => {
      expect(buildDraft(page, { ...partial, kind: 'sheet' }, { keepMissing: true }).kept).toEqual([
        'SE180001',
      ]);
      expect(buildDraft(page, source(), { keepMissing: true }).kept).toEqual([]);
    });

    it('is ignored for an approved backend batch, which must stay a full roster', () => {
      expect(() =>
        buildDraft(page, { ...partial, kind: 'backend' }, { keepMissing: true }),
      ).toThrow('thiếu 1');
    });

    it('still rejects codes that are not on the page, and duplicates', () => {
      const extra = source({ rows: [{ studentCode: 'SE189999', status: 'ATTEND' }] });
      expect(() => buildDraft(page, extra, { keepMissing: true })).toThrow('dư 1');
      const dup = source({
        rows: [
          { studentCode: 'SE180002', status: 'ATTEND' },
          { studentCode: 'se180002', status: 'ABSENT' },
        ],
      });
      expect(() => buildDraft(page, dup, { keepMissing: true })).toThrow('trùng');
    });

    it('refuses a source with no student of the page', () => {
      expect(() => buildDraft(page, source({ rows: [] }), { keepMissing: true })).toThrow(
        'không có sinh viên nào',
      );
    });

    it('stays strict by default', () => {
      expect(() => buildDraft(page, partial)).toThrow('thiếu 1');
    });
  });

  it('skips fields a local page does not carry', () => {
    const local = { ...page, context: { ...page.context, mode: 'local' as const, course: '' } };
    const draft = buildDraft(local, source({ context: { course: 'OTHER' } }));
    expect(draft.checks.find((c) => c.field === 'course')?.result).toBe('skipped');
  });

  it('page-as-source yields zero changes', () => {
    const draft = buildDraft(page, pageAsSource(page));
    expect(summarize(page, draft.rows)).toEqual({ total: 2, attend: 0, absent: 2, changed: 0 });
  });
});

describe('template CSV', () => {
  it('round-trips through the importer with the page context', () => {
    const parsed = parseAttendanceGrid(parseDelimitedText(buildTemplateCsv(page)));
    expect(parsed.context).toMatchObject({
      group: 'SE1927',
      slot: '2',
      room: 'NVH 611',
      campus: 'FU-HL',
    });
    const draft = buildDraft(page, { kind: 'file', label: 't', ...parsed });
    expect(summarize(page, draft.rows).changed).toBe(0);
  });

  it('neutralizes formula-looking cells', () => {
    const evil = { ...page, rows: [{ ...page.rows[0]!, name: '=HYPERLINK("x")' }] };
    expect(buildTemplateCsv(evil)).toContain(`"'=HYPERLINK(""x"")"`);
  });
});
