import type {
  AttendanceStatus,
  DraftRow,
  PageContext,
  PageMode,
  PageSnapshot,
  VerifyResult,
} from '@/lib/attendance';

/**
 * DOM adapter for the FAP "Change attendance" layout (gvAttendance table, rdAbsent/rdPresent radio
 * pairs). Ported from the assistant project's fap-attendance-v2.js and kept deliberately strict:
 * every structural surprise throws before a single radio is touched.
 *
 * Capabilities: read, fill, verify, and (fixture only) fill + fixture save event. There is no
 * code path that clicks or submits a FAP control (docs/decisions.md D-002).
 */

export class AdapterError extends Error {
  override name = 'AdapterError';
}

type LiveRow = Readonly<{
  studentCode: string;
  name: string;
  currentStatus: AttendanceStatus;
  absent: HTMLInputElement;
  present: HTMLInputElement;
}>;

type AdapterEnv = Readonly<{
  document: Document;
  location: Pick<Location, 'origin' | 'protocol'>;
  fixtureOrigins: readonly string[];
}>;

const EXPECTED_HEADERS = '|GROUP|ROLL NUMBER|FULL NAME|ABSENT|PRESENT|...|COMMENT|SHOW IMAGE|';
const FIXTURE_VERSION = 'mock-fap-v2';
const CONTEXT_KEYS = ['mode', 'campus', 'course', 'group', 'date', 'slot', 'room'] as const;

const fail = (message: string): never => {
  throw new AdapterError(message);
};

function one<T extends Element>(root: ParentNode, selector: string): T {
  const nodes = root.querySelectorAll<T>(selector);
  if (nodes.length !== 1) fail('Bố cục thiếu hoặc trùng thành phần cần thiết.');
  return nodes[0]!;
}

const text = (node: Element) => (node.textContent ?? '').replace(/\s+/g, ' ').trim();

export function createFapV2Adapter(env: AdapterEnv) {
  const { document } = env;

  function mode(): PageMode {
    const marker = document.body?.dataset.fapFixture;
    if (env.fixtureOrigins.includes(env.location.origin) && marker === FIXTURE_VERSION) {
      return 'fixture';
    }
    if (env.location.protocol === 'file:' && !marker) return 'local';
    return fail('Chỉ hỗ trợ FAP giả lập v2 hoặc file HTML cục bộ. FAP trực tuyến chưa được bật.');
  }

  function inspect(): { context: PageContext; rows: LiveRow[] } {
    const pageMode = mode();
    const form = one<HTMLFormElement>(document, '#aspnetForm');
    const table = one<HTMLTableElement>(form, '#ctl00_mainContent_gvAttendance');
    const headers = [...(table.rows[0]?.cells ?? [])].map((cell) => text(cell).toUpperCase());
    if (headers.join('|') !== EXPECTED_HEADERS) fail('Phiên bản bố cục bảng không được hỗ trợ.');

    const groups = new Set<string>();
    const codes = new Set<string>();
    const radioNames = new Set<string>();
    const allRadios = [...form.querySelectorAll<HTMLInputElement>('input[type="radio"]')];
    const rows = [...table.rows].slice(1).map((row): LiveRow => {
      if (row.cells.length !== 10) fail('Bố cục dòng không được hỗ trợ.');
      groups.add(text(one(row.cells[1]!, 'span[id$="_txtGroupName"]')));
      const codeSpan = one<HTMLSpanElement>(row.cells[2]!, 'span[id$="_txtRollNumber"]');
      const studentCode = text(codeSpan);
      const prefix = codeSpan.id.slice(0, -'_txtRollNumber'.length);
      if (!/^ctl00_mainContent_gvAttendance_ctl\d+$/.test(prefix))
        fail('ID dòng không được hỗ trợ.');
      if (!/^[a-z0-9-]{2,32}$/i.test(studentCode) || codes.has(studentCode)) {
        fail('Mã sinh viên thiếu, không hợp lệ hoặc bị trùng.');
      }
      codes.add(studentCode);
      const name = text(one(row.cells[3]!, 'span[id$="_txtFullName"]'));
      const absent = one<HTMLInputElement>(row.cells[4]!, 'input[type="radio"][value="rdAbsent"]');
      const present = one<HTMLInputElement>(
        row.cells[5]!,
        'input[type="radio"][value="rdPresent"]',
      );
      const groupName = `${prefix.replaceAll('_', '$')}$chkCheck`;
      if (
        absent.id !== `${prefix}_rdAbsent` ||
        present.id !== `${prefix}_rdPresent` ||
        absent.name !== groupName ||
        present.name !== groupName ||
        radioNames.has(groupName) ||
        row.querySelectorAll('input[type="radio"]').length !== 2 ||
        absent.disabled ||
        present.disabled ||
        absent.checked === present.checked ||
        allRadios.filter((radio) => radio.name === groupName).length !== 2
      ) {
        fail('Nhóm radio thiếu, bị khóa, trùng hoặc không xác định được trạng thái.');
      }
      radioNames.add(groupName);
      return {
        studentCode,
        name,
        currentStatus: present.checked ? 'ATTEND' : 'ABSENT',
        absent,
        present,
      };
    });
    const [group] = groups;
    if (!rows.length || groups.size !== 1 || !group) {
      fail('Danh sách trống hoặc không thuộc một lớp xác định.');
    }

    const title = text(one(document, '#ctl00_mainContent_divTitle'));
    const match = title.match(
      /at slot\s+(\d+)\s+on\s+\w+\s+(\d{1,2})\/(\d{1,2})\/(\d{4})\s+at room\s+(.+?)\.\s*This is the session number/i,
    );
    if (!match) fail('Không xác minh được ngày, slot hoặc phòng từ tiêu đề.');
    const [, slot, day, month, year, room] = match!;
    const date = `${year}-${month!.padStart(2, '0')}-${day!.padStart(2, '0')}`;
    if (
      !Number.isFinite(Date.parse(date)) ||
      new Date(date).toISOString().slice(0, 10) !== date ||
      Number(slot) < 1
    ) {
      fail('Ngày hoặc slot không hợp lệ.');
    }
    const campus = text(one(document, '#ctl00_lblCampusName'));
    if (!campus) fail('Thiếu campus.');

    const fixture = pageMode === 'fixture';
    const context: PageContext = {
      mode: pageMode,
      campus,
      course: fixture ? (table.dataset.course ?? '') : '',
      sessionId: fixture ? (table.dataset.sessionId ?? '') : '',
      group: group!,
      date,
      slot: slot!,
      room: room!.trim(),
    };
    if (
      fixture &&
      (!context.course ||
        table.dataset.layoutVersion !== FIXTURE_VERSION ||
        rows.some((row) => !/^SE1[89]\d{4}$/.test(row.studentCode)))
    ) {
      fail('Fixture không đúng version hoặc chứa mã ngoài dữ liệu mẫu.');
    }
    return { context, rows };
  }

  function read(): PageSnapshot {
    const { context, rows } = inspect();
    return {
      context,
      rows: rows.map(({ studentCode, name, currentStatus }) => ({
        studentCode,
        name,
        currentStatus,
      })),
    };
  }

  function normalize(changes: unknown, rows: readonly LiveRow[]) {
    if (!Array.isArray(changes) || !changes.length || changes.length !== rows.length) {
      fail('Bản nháp và bảng không khớp đầy đủ.');
    }
    const seen = new Set<string>();
    const byCode = new Map(rows.map((row) => [row.studentCode, row]));
    return (changes as unknown[]).map((raw) => {
      const change = raw as Partial<DraftRow> | null;
      const row = change?.studentCode ? byCode.get(change.studentCode) : undefined;
      if (
        !row ||
        seen.has(row.studentCode) ||
        (change!.status !== 'ATTEND' && change!.status !== 'ABSENT')
      ) {
        fail('Bản nháp có mã trùng, thiếu hoặc trạng thái không hợp lệ.');
      }
      seen.add(row!.studentCode);
      return { row: row!, status: change!.status as AttendanceStatus };
    });
  }

  /** Re-inspect immediately before writing: context, roster, names and statuses must be unchanged. */
  function preflight(changes: unknown, expected: PageSnapshot | undefined) {
    const current = inspect();
    if (
      !expected?.context ||
      CONTEXT_KEYS.some((key) => current.context[key] !== expected.context[key])
    ) {
      fail('Context đã thay đổi. Hãy đọc lại trang.');
    }
    const targets = normalize(changes, current.rows);
    if (!Array.isArray(expected!.rows) || expected!.rows.length !== current.rows.length) {
      fail('Danh sách đã thay đổi. Hãy đọc lại trang.');
    }
    const before = new Map(expected!.rows.map((row) => [row.studentCode, row]));
    if (
      before.size !== current.rows.length ||
      current.rows.some(
        (row) =>
          before.get(row.studentCode)?.currentStatus !== row.currentStatus ||
          before.get(row.studentCode)?.name !== row.name,
      )
    ) {
      fail('Trạng thái hoặc danh sách đã thay đổi. Hãy đọc lại trang.');
    }
    return targets;
  }

  function verify(changes: unknown): VerifyResult {
    const { context, rows } = inspect();
    const targets = normalize(changes, rows);
    const mismatches = targets
      .filter((target) => target.row.currentStatus !== target.status)
      .map((target) => ({
        studentCode: target.row.studentCode,
        expected: target.status,
        actual: target.row.currentStatus,
      }));
    return {
      total: targets.length,
      matched: targets.length - mismatches.length,
      mismatches,
      page: {
        context,
        rows: rows.map(({ studentCode, name, currentStatus }) => ({
          studentCode,
          name,
          currentStatus,
        })),
      },
    };
  }

  function verifyUnchanged(changes: unknown, expected: PageSnapshot | undefined): VerifyResult {
    preflight(changes, expected);
    return verify(changes);
  }

  function fill(changes: unknown, expected: PageSnapshot | undefined): VerifyResult {
    const targets = preflight(changes, expected);
    let changed = 0;
    for (const { row, status } of targets) {
      const input = status === 'ATTEND' ? row.present : row.absent;
      // Set the property only: never run unknown inline click/postback handlers of a saved page.
      if (!input.checked) {
        input.checked = true;
        changed++;
      }
    }
    if (mode() === 'fixture') document.dispatchEvent(new Event('fap-fixture-change'));
    const result = verify(changes);
    if (result.mismatches.length) fail('Điền chưa khớp toàn bộ. Hãy đọc lại trang.');
    return { ...result, changed };
  }

  /**
   * Fixture only (ADR 0012 of the assistant project): fill, verify, then ask the synthetic fixture to
   * persist into its own sessionStorage and check its receipt. No FAP control is touched.
   */
  function fillAndSave(changes: unknown, expected: PageSnapshot | undefined): VerifyResult {
    if (mode() !== 'fixture') {
      fail('Lưu chỉ được bật trên FAP giả lập. File cục bộ không gửi dữ liệu lên FAP.');
    }
    const result = fill(changes, expected);
    const receipt = one<HTMLElement>(document, '#save-status');
    receipt.removeAttribute('data-saved-snapshot');
    receipt.removeAttribute('data-save-error');
    document.dispatchEvent(new Event('fap-fixture-save'));
    const snapshot = JSON.stringify(
      result.page.rows.map(({ studentCode, currentStatus }) => ({
        studentCode,
        status: currentStatus,
      })),
    );
    if (receipt.dataset.saveError || receipt.dataset.savedSnapshot !== snapshot) {
      fail('Đã điền nhưng chưa lưu được bản giả lập. Kiểm tra quyền lưu trữ rồi đọc lại trang.');
    }
    return { ...result, saved: true };
  }

  return { read, fill, verify: verifyUnchanged, fillAndSave };
}

export type FapV2Adapter = ReturnType<typeof createFapV2Adapter>;
