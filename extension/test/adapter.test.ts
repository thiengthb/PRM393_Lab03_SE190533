// @vitest-environment jsdom
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { createFapV2Adapter, type FapV2Adapter } from '@/content/fap-v2-adapter';

import { installFixture, roster, SESSION_ID } from './fixtures/fap-v2-dom';

const FIXTURE = 'http://127.0.0.1:4173';
let adapter: FapV2Adapter;

function setup({ local = false, origin = FIXTURE } = {}) {
  installFixture(document, { local });
  adapter = createFapV2Adapter({
    document,
    location: local ? { origin: 'null', protocol: 'file:' } : { origin, protocol: 'http:' },
    fixtureOrigins: [FIXTURE],
  });
}

const changes = roster.map((row, i) => ({
  studentCode: row.studentCode,
  status: i < 31 ? ('ATTEND' as const) : ('ABSENT' as const),
}));
const presentCount = () => document.querySelectorAll('input[value="rdPresent"]:checked').length;

beforeEach(() => setup());

describe('fap-v2 adapter', () => {
  it('reads the exact context and fills idempotently without submitting', () => {
    const submit = vi.fn((event: Event) => event.preventDefault());
    document.querySelector('form')!.addEventListener('submit', submit);
    const page = adapter.read();
    expect(page.context).toEqual({
      mode: 'fixture',
      campus: 'FU-HL',
      course: 'SWE201c',
      sessionId: SESSION_ID,
      group: 'SE1927',
      date: '2026-09-18',
      slot: '2',
      room: 'NVH 611',
    });
    const result = adapter.fill(changes, page);
    expect(result).toMatchObject({ total: 40, matched: 40, changed: 31, mismatches: [] });
    expect(adapter.fill(changes, result.page).changed).toBe(0);
    expect(submit).not.toHaveBeenCalled();
  });

  it('reads local HTML, never runs inline click handlers and refuses to save', () => {
    setup({ local: true });
    const click = vi.fn();
    document.querySelector<HTMLInputElement>('input[value="rdPresent"]')!.onclick = click;
    const page = adapter.read();
    expect(page.context).toMatchObject({ mode: 'local', course: '', sessionId: '' });
    adapter.fill(changes, page);
    expect(click).not.toHaveBeenCalled();
    expect(() => adapter.fillAndSave(changes, adapter.read())).toThrow('chỉ được bật');
  });

  it.each(['https://fap.fpt.edu.vn', 'https://untrusted.example.test'])(
    'rejects origin %s before reading or writing',
    (origin) => {
      setup({ origin });
      expect(() => adapter.read()).toThrow('chưa được bật');
      expect(presentCount()).toBe(0);
    },
  );

  it.each<[string, () => void]>([
    ['wrong layout', () => void (document.querySelector('th:nth-child(3)')!.textContent = 'X')],
    [
      'duplicate code',
      () => {
        const spans = document.querySelectorAll('[id$="_txtRollNumber"]');
        spans[1]!.textContent = spans[0]!.textContent;
      },
    ],
    ['missing radio', () => document.querySelectorAll('input[value="rdPresent"]')[35]!.remove()],
    [
      'disabled radio',
      () =>
        void (document.querySelectorAll<HTMLInputElement>(
          'input[value="rdPresent"]',
        )[35]!.disabled = true),
    ],
    [
      'ambiguous status',
      () =>
        void (document.querySelector<HTMLInputElement>('input[value="rdAbsent"]')!.checked = false),
    ],
    [
      'cross-row radio name',
      () => void (document.querySelector<HTMLInputElement>('input[value="rdPresent"]')!.name = 'x'),
    ],
    [
      'context drift',
      () => {
        const title = document.querySelector('#ctl00_mainContent_divTitle')!;
        title.textContent = title.textContent!.replace('slot 2', 'slot 3');
      },
    ],
    [
      'status drift',
      () =>
        void (document.querySelector<HTMLInputElement>('input[value="rdPresent"]')!.checked = true),
    ],
  ])('fails closed on %s with no additional writes', (_name, mutate) => {
    const page = adapter.read();
    mutate();
    const before = presentCount();
    expect(() => adapter.fill(changes, page)).toThrow();
    expect(presentCount()).toBe(before);
  });

  it.each([
    ['missing row', changes.slice(1)],
    ['duplicate row', changes.map((x, i) => (i === 1 ? changes[0]! : x))],
    ['LATE status', changes.map((x, i) => (i === 0 ? { ...x, status: 'LATE' } : x))],
    ['extra row', [...changes, { studentCode: 'FA9999', status: 'ATTEND' }]],
  ])('rejects a draft with %s before touching rows', (_name, malformed) => {
    expect(() => adapter.fill(malformed, adapter.read())).toThrow();
    expect(presentCount()).toBe(0);
  });

  it('preserves lecturer comments', () => {
    const comment = document.querySelector<HTMLInputElement>('input[type="text"]')!;
    comment.value = 'Synthetic note';
    adapter.fill(changes, adapter.read());
    expect(comment.value).toBe('Synthetic note');
  });

  it('requires a matching fixture save receipt after verification', () => {
    document.addEventListener(
      'fap-fixture-save',
      () => {
        const rows = adapter.read().rows.map(({ studentCode, currentStatus }) => ({
          studentCode,
          status: currentStatus,
        }));
        document.querySelector<HTMLElement>('#save-status')!.dataset.savedSnapshot =
          JSON.stringify(rows);
      },
      { once: true },
    );
    expect(adapter.fillAndSave(changes, adapter.read())).toMatchObject({
      saved: true,
      matched: 40,
    });
    expect(() => adapter.fillAndSave(changes, adapter.read())).toThrow('chưa lưu');
  });

  it('never dispatches the save event when preflight fails', () => {
    const save = vi.fn();
    document.addEventListener('fap-fixture-save', save);
    expect(() => adapter.fillAndSave(changes.slice(1), adapter.read())).toThrow();
    expect(save).not.toHaveBeenCalled();
    document.removeEventListener('fap-fixture-save', save);
  });

  it('verify reports mismatches without writing', () => {
    const page = adapter.read();
    const result = adapter.verify(changes, page);
    expect(result.matched).toBe(9);
    expect(result.mismatches).toHaveLength(31);
    expect(presentCount()).toBe(0);
  });
});
