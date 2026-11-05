import { describe, expect, it } from 'vitest';

import type { PageSnapshot, SourceBatch } from '@/lib/attendance';

import { initialState, reduce, type WorkflowState } from './workflow';

const tab = { id: 1, url: 'http://127.0.0.1:4173/', windowId: 1 };
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
const source: SourceBatch = {
  kind: 'file',
  label: 'f.csv',
  context: { group: 'SE1927' },
  rows: [
    { studentCode: 'SE180001', status: 'ATTEND' },
    { studentCode: 'SE180002', status: 'ABSENT' },
  ],
};

function ready(): WorkflowState {
  const read = reduce(initialState, { type: 'pageRead', tab, page });
  const loaded = reduce(read, { type: 'sourceLoaded', source });
  return reduce(loaded, { type: 'confirm', confirmed: true });
}

describe('workflow', () => {
  it('builds a draft and lets the lecturer confirm it', () => {
    const state = ready();
    expect(state.rows).toHaveLength(2);
    expect(state.confirmed).toBe(true);
  });

  it('any edit clears the confirmation', () => {
    const edited = reduce(ready(), {
      type: 'setStatus',
      studentCode: 'SE180002',
      status: 'ATTEND',
    });
    expect(edited.confirmed).toBe(false);
    expect(edited.rows![1]!.status).toBe('ATTEND');
    const bulk = reduce(ready(), { type: 'setAll', status: 'ABSENT', codes: ['SE180001'] });
    expect(bulk.rows!.map((r) => r.status)).toEqual(['ABSENT', 'ABSENT']);
    expect(bulk.confirmed).toBe(false);
  });

  it('cannot confirm without a draft', () => {
    expect(reduce(initialState, { type: 'confirm', confirmed: true }).confirmed).toBe(false);
  });

  it('a mismatching source is rejected and leaves no draft', () => {
    const read = reduce(initialState, { type: 'pageRead', tab, page });
    const state = reduce(read, {
      type: 'sourceLoaded',
      source: { ...source, context: { group: 'OTHER' } },
    });
    expect(state.rows).toBeNull();
    expect(state.source).toBeNull();
    expect(state.notice?.tone).toBe('destructive');
  });

  it('a failed write drops the page snapshot but keeps the source for a re-read', () => {
    const state = reduce(ready(), { type: 'applyFailed', message: 'drift' });
    expect(state.page).toBeNull();
    expect(state.rows).toBeNull();
    expect(state.source).toBe(source);
    const reread = reduce(state, { type: 'pageRead', tab, page });
    expect(reread.rows).toHaveLength(2);
    expect(reread.confirmed).toBe(false);
  });

  it('tab switch invalidates the draft', () => {
    const state = reduce(ready(), { type: 'invalidate', message: 'switched' });
    expect(state.page).toBeNull();
    expect(state.confirmed).toBe(false);
  });

  it('manual source follows the page as re-read', () => {
    const read = reduce(initialState, { type: 'pageRead', tab, page });
    const manual = reduce(read, {
      type: 'sourceLoaded',
      source: { kind: 'page', label: 'p', context: {}, rows: source.rows },
    });
    const reread = reduce(manual, { type: 'pageRead', tab, page });
    expect(reread.rows!.map((r) => r.status)).toEqual(['ABSENT', 'ABSENT']);
  });

  describe('keepMissing', () => {
    const partial: SourceBatch = {
      ...source,
      rows: [{ studentCode: 'SE180002', status: 'ATTEND' }],
    };
    const read = () => reduce(initialState, { type: 'pageRead', tab, page });

    it('a partial file fails by default and loads once the option is on', () => {
      const strict = reduce(read(), { type: 'sourceLoaded', source: partial });
      expect(strict.rows).toBeNull();
      const on = reduce(read(), { type: 'setKeepMissing', keepMissing: true });
      const loaded = reduce(on, { type: 'sourceLoaded', source: partial });
      expect(loaded.rows!.map((r) => r.status)).toEqual(['ABSENT', 'ATTEND']);
      expect(loaded.kept).toEqual(['SE180001']);
      expect(loaded.notice?.tone).toBe('warning');
    });

    it('toggling after load rebuilds the draft and clears the confirmation', () => {
      let state = reduce(read(), { type: 'setKeepMissing', keepMissing: true });
      state = reduce(state, { type: 'sourceLoaded', source: partial });
      state = reduce(state, { type: 'confirm', confirmed: true });
      const off = reduce(state, { type: 'setKeepMissing', keepMissing: false });
      expect(off.confirmed).toBe(false);
      expect(off.rows).toBeNull();
      expect(off.source).toBeNull();
      expect(off.notice?.tone).toBe('destructive');
    });

    it('the preference survives changing source and a failed page read', () => {
      let state = reduce(read(), { type: 'setKeepMissing', keepMissing: true });
      state = reduce(state, { type: 'clearSource' });
      state = reduce(state, { type: 'pageFailed', message: 'x' });
      expect(state.keepMissing).toBe(true);
    });

    it('a re-read keeps the NEW page status for unlisted students', () => {
      let state = reduce(read(), { type: 'setKeepMissing', keepMissing: true });
      state = reduce(state, { type: 'sourceLoaded', source: partial });
      const changedPage: PageSnapshot = {
        ...page,
        rows: page.rows.map((r) =>
          r.studentCode === 'SE180001' ? { ...r, currentStatus: 'ATTEND' } : r,
        ),
      };
      state = reduce(state, { type: 'pageRead', tab, page: changedPage });
      expect(state.rows!.map((r) => r.status)).toEqual(['ATTEND', 'ATTEND']);
    });
  });
});
