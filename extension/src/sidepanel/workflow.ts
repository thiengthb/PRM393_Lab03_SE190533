import type {
  AttendanceStatus,
  DraftRow,
  PageSnapshot,
  SourceBatch,
  VerifyResult,
} from '@/lib/attendance';
import { buildDraft, DraftError, pageAsSource, type ContextCheck } from '@/lib/draft';
import type { ActiveTab, ApplyAction } from '@/lib/page-bridge';

/**
 * Pure state machine for the side panel. Invariants:
 * - a draft exists only for the page snapshot it was validated against;
 * - any edit, page change or failure clears the lecturer's confirmation;
 * - a failed write drops the page snapshot so the next action must re-read the page;
 * - `keepMissing` is a lecturer preference that survives source changes; toggling it rebuilds the
 *   draft (discarding manual edits) because the set of rows the source decides changes.
 */

export type Busy = 'read' | 'source' | ApplyAction | null;
export type Notice = Readonly<{
  tone: 'default' | 'success' | 'warning' | 'destructive';
  text: string;
}>;

export type WorkflowState = Readonly<{
  tab: ActiveTab | null;
  page: PageSnapshot | null;
  source: SourceBatch | null;
  rows: DraftRow[] | null;
  checks: readonly ContextCheck[];
  /** Students whose status came from the page because the source did not list them. */
  kept: readonly string[];
  keepMissing: boolean;
  confirmed: boolean;
  busy: Busy;
  notice: Notice | null;
}>;

export const initialState: WorkflowState = {
  tab: null,
  page: null,
  source: null,
  rows: null,
  checks: [],
  kept: [],
  keepMissing: false,
  confirmed: false,
  busy: null,
  notice: null,
};

export type WorkflowEvent =
  | { type: 'busy'; busy: Exclude<Busy, null> }
  | { type: 'pageRead'; tab: ActiveTab; page: PageSnapshot }
  | { type: 'pageFailed'; message: string }
  | { type: 'invalidate'; message: string }
  | { type: 'sourceLoaded'; source: SourceBatch }
  | { type: 'sourceFailed'; message: string }
  | { type: 'clearSource' }
  | { type: 'setKeepMissing'; keepMissing: boolean }
  | { type: 'setStatus'; studentCode: string; status: AttendanceStatus }
  | { type: 'setAll'; status: AttendanceStatus; codes?: readonly string[] }
  | { type: 'confirm'; confirmed: boolean }
  | { type: 'applied'; action: ApplyAction; result: VerifyResult }
  | { type: 'applyFailed'; message: string };

const NO_DRAFT = { rows: null, checks: [], kept: [] } as const;

function draftFor(
  page: PageSnapshot,
  source: SourceBatch,
  keepMissing: boolean,
): Pick<WorkflowState, 'rows' | 'checks' | 'kept'> & { error?: string } {
  try {
    const draft = buildDraft(page, source, { keepMissing });
    return { rows: draft.rows, checks: draft.checks, kept: draft.kept };
  } catch (error) {
    if (!(error instanceof DraftError)) throw error;
    return { ...NO_DRAFT, error: error.message };
  }
}

function loadedNotice(source: SourceBatch, kept: readonly string[]): Notice {
  const base = `Đã tải ${source.rows.length} dòng từ ${source.label}.`;
  return kept.length
    ? {
        tone: 'warning',
        text: `${base} ${kept.length} sinh viên không có trong nguồn được giữ trạng thái hiện tại. Kiểm tra bản nháp trước khi điền.`,
      }
    : { tone: 'success', text: `${base} Kiểm tra bản nháp trước khi điền.` };
}

function appliedMessage(action: ApplyAction, result: VerifyResult): Notice {
  if (action === 'FAP_EXT_VERIFY') {
    return result.mismatches.length
      ? {
          tone: 'warning',
          text: `Kiểm tra: ${result.matched}/${result.total} dòng khớp, còn ${result.mismatches.length} dòng khác bản nháp.`,
        }
      : { tone: 'success', text: `Kiểm tra: ${result.total}/${result.total} dòng khớp bản nháp.` };
  }
  if (action === 'FAP_EXT_FILL_SAVE') {
    return {
      tone: 'success',
      text: `Đã điền ${result.changed ?? 0} thay đổi, kiểm tra ${result.total}/${result.total} dòng và lưu bản giả lập.`,
    };
  }
  return {
    tone: 'success',
    text: `Đã điền ${result.changed ?? 0} thay đổi và kiểm tra ${result.total}/${result.total} dòng. Hãy tự kiểm tra rồi bấm Save trên trang.`,
  };
}

export function reduce(state: WorkflowState, event: WorkflowEvent): WorkflowState {
  switch (event.type) {
    case 'busy':
      return { ...state, busy: event.busy, notice: null };
    case 'pageRead': {
      const base = { ...state, tab: event.tab, page: event.page, busy: null, confirmed: false };
      if (!state.source) {
        return {
          ...base,
          ...NO_DRAFT,
          notice: {
            tone: 'default',
            text: `Đã đọc ${event.page.rows.length} sinh viên. Chọn nguồn dữ liệu.`,
          },
        };
      }
      // "Use the page as source" always means the page as it is NOW, never an older snapshot.
      const source = state.source.kind === 'page' ? pageAsSource(event.page) : state.source;
      const draft = draftFor(event.page, source, state.keepMissing);
      return {
        ...base,
        rows: draft.rows,
        checks: draft.checks,
        kept: draft.kept,
        source: draft.error ? null : source,
        notice: draft.error
          ? { tone: 'destructive', text: draft.error }
          : { tone: 'default', text: `Đã đọc lại trang và đối chiếu với ${source.label}.` },
      };
    }
    case 'pageFailed':
      return {
        ...initialState,
        keepMissing: state.keepMissing,
        tab: state.tab,
        notice: { tone: 'destructive', text: event.message },
      };
    case 'invalidate':
      if (!state.page && !state.notice) return state;
      return {
        ...state,
        ...NO_DRAFT,
        page: null,
        confirmed: false,
        busy: null,
        notice: { tone: 'warning', text: event.message },
      };
    case 'sourceLoaded': {
      if (!state.page) return { ...state, busy: null };
      const draft = draftFor(state.page, event.source, state.keepMissing);
      if (draft.error) {
        return {
          ...state,
          ...NO_DRAFT,
          busy: null,
          source: null,
          confirmed: false,
          notice: { tone: 'destructive', text: draft.error },
        };
      }
      return {
        ...state,
        busy: null,
        source: event.source,
        rows: draft.rows,
        checks: draft.checks,
        kept: draft.kept,
        confirmed: false,
        notice: loadedNotice(event.source, draft.kept),
      };
    }
    case 'sourceFailed':
      return { ...state, busy: null, notice: { tone: 'destructive', text: event.message } };
    case 'clearSource':
      return { ...state, ...NO_DRAFT, source: null, confirmed: false, notice: null };
    case 'setKeepMissing': {
      const next = { ...state, keepMissing: event.keepMissing, confirmed: false };
      if (!state.page || !state.source) return next;
      const draft = draftFor(state.page, state.source, event.keepMissing);
      if (draft.error) {
        return {
          ...next,
          ...NO_DRAFT,
          source: null,
          notice: { tone: 'destructive', text: draft.error },
        };
      }
      return {
        ...next,
        rows: draft.rows,
        checks: draft.checks,
        kept: draft.kept,
        notice: loadedNotice(state.source, draft.kept),
      };
    }
    case 'setStatus':
      if (!state.rows) return state;
      return {
        ...state,
        confirmed: false,
        rows: state.rows.map((row) =>
          row.studentCode === event.studentCode ? { ...row, status: event.status } : row,
        ),
      };
    case 'setAll': {
      if (!state.rows) return state;
      const only = event.codes ? new Set(event.codes) : null;
      return {
        ...state,
        confirmed: false,
        rows: state.rows.map((row) =>
          !only || only.has(row.studentCode) ? { ...row, status: event.status } : row,
        ),
      };
    }
    case 'confirm':
      return { ...state, confirmed: event.confirmed && Boolean(state.rows) };
    case 'applied':
      return {
        ...state,
        busy: null,
        page: event.result.page,
        confirmed: false,
        notice: appliedMessage(event.action, event.result),
      };
    case 'applyFailed':
      return {
        ...state,
        ...NO_DRAFT,
        busy: null,
        page: null,
        confirmed: false,
        notice: { tone: 'destructive', text: event.message },
      };
  }
}
