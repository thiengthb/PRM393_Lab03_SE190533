import { z } from 'zod';

import type { BatchContext, PageContext, SourceBatch } from '../attendance';
import { config } from '../config';
import { attendoApiOrigins } from '../env-config';

/**
 * Nguồn Attendo: giảng viên đăng nhập bằng tài khoản Attendo (Firebase Auth, REST), rồi extension
 * đọc slot đã chốt và bản điểm danh của slot đó từ Firestore (REST). Không có máy chủ riêng:
 * Security Rules của Attendo chỉ cho giảng viên đọc slot và điểm danh của chính mình.
 *
 * Phiên (ID token + refresh token) nằm trong chrome.storage.session: mất khi đóng trình duyệt,
 * không ghi xuống đĩa. Mật khẩu không được lưu.
 */

const STORAGE_KEY = 'attendoSession';
const LECTURER_ROLES = ['lecturer'] as const;
/** Làm mới ID token khi còn dưới 5 phút. */
const REFRESH_MARGIN_MS = 5 * 60_000;

const userSchema = z.object({
  id: z.string(),
  email: z.string(),
  displayName: z.string(),
  role: z.string(),
});

const storedSessionSchema = z.object({
  idToken: z.string().min(1),
  refreshToken: z.string().min(1),
  expiresAt: z.number(),
  user: userSchema,
});
export type LecturerSession = z.infer<typeof storedSessionSchema>;

const signInSchema = z.object({
  idToken: z.string(),
  refreshToken: z.string(),
  expiresIn: z.string(),
  localId: z.string(),
  email: z.string(),
});

const refreshSchema = z.object({
  id_token: z.string(),
  refresh_token: z.string(),
  expires_in: z.string(),
});

/** Giá trị Firestore REST (chỉ các kiểu Attendo dùng). */
const valueSchema = z.object({
  stringValue: z.string().optional(),
  integerValue: z.string().optional(),
  booleanValue: z.boolean().optional(),
  timestampValue: z.string().optional(),
});
const docSchema = z.object({
  name: z.string(),
  fields: z.record(z.string(), valueSchema).default({}),
});
type FirestoreDoc = z.infer<typeof docSchema>;

export class BackendError extends Error {
  override name = 'BackendError';
  constructor(
    message: string,
    readonly status?: number,
  ) {
    super(message);
  }
}

export function isBackendEnabled(): boolean {
  return config.attendo !== null;
}

function attendo() {
  if (!config.attendo) throw new BackendError('Bản build này đã tắt nguồn Attendo.');
  return config.attendo;
}

/** Câu lỗi tiếng Việt cho mã lỗi của Firebase Auth REST. */
export function authErrorMessage(code: string | undefined): string {
  switch (code?.split(' ')[0]) {
    case 'INVALID_LOGIN_CREDENTIALS':
    case 'EMAIL_NOT_FOUND':
    case 'INVALID_PASSWORD':
      return 'Sai email hoặc mật khẩu.';
    case 'USER_DISABLED':
      return 'Tài khoản đã bị khoá.';
    case 'TOO_MANY_ATTEMPTS_TRY_LATER':
      return 'Đăng nhập sai quá nhiều lần. Thử lại sau ít phút.';
    case 'TOKEN_EXPIRED':
    case 'INVALID_REFRESH_TOKEN':
      return 'Phiên đăng nhập đã hết. Đăng nhập lại.';
    default:
      return 'Đăng nhập thất bại.';
  }
}

async function call(url: string, init: RequestInit): Promise<unknown> {
  let response: Response;
  try {
    response = await fetch(url, { ...init, credentials: 'omit' });
  } catch {
    throw new BackendError('Không kết nối được Attendo. Kiểm tra mạng rồi thử lại.');
  }
  const body: unknown = await response.json().catch(() => null);
  if (!response.ok) {
    const message = (body as { error?: { message?: string } } | null)?.error?.message;
    if (url.includes('identitytoolkit') || url.includes('securetoken')) {
      throw new BackendError(authErrorMessage(message), response.status);
    }
    if (response.status === 403) {
      throw new BackendError('Attendo từ chối truy cập (tài khoản không phải chủ slot này).', 403);
    }
    throw new BackendError(message || `Attendo trả lỗi ${response.status}.`, response.status);
  }
  return body;
}

const api = () => attendoApiOrigins(attendo());

const firestoreBase = () =>
  `${api().firestore}/v1/projects/${attendo().projectId}/databases/(default)/documents`;

const bearer = (session: LecturerSession) => ({ Authorization: `Bearer ${session.idToken}` });

const str = (doc: FirestoreDoc, key: string) => doc.fields[key]?.stringValue ?? '';
const int = (doc: FirestoreDoc, key: string) => Number(doc.fields[key]?.integerValue ?? NaN);
const bool = (doc: FirestoreDoc, key: string) => doc.fields[key]?.booleanValue === true;
const docId = (doc: FirestoreDoc) => doc.name.split('/').at(-1) ?? '';

async function readProfile(idToken: string, uid: string, email: string) {
  const raw = await call(`${firestoreBase()}/users/${encodeURIComponent(uid)}`, {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  const doc = docSchema.parse(raw);
  const user = {
    id: uid,
    email,
    displayName: str(doc, 'displayName') || email,
    role: str(doc, 'role'),
  };
  if (!(LECTURER_ROLES as readonly string[]).includes(user.role)) {
    throw new BackendError('Tài khoản không có quyền giảng viên.');
  }
  return user;
}

async function refresh(session: LecturerSession): Promise<LecturerSession> {
  const raw = await call(`${api().token}/v1/token?key=${attendo().apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'refresh_token', refresh_token: session.refreshToken }),
  });
  const r = refreshSchema.parse(raw);
  const next = {
    ...session,
    idToken: r.id_token,
    refreshToken: r.refresh_token,
    expiresAt: Date.now() + Number(r.expires_in) * 1000,
  };
  await chrome.storage.session.set({ [STORAGE_KEY]: next });
  return next;
}

/** Phiên còn hạn (tự làm mới ID token khi sắp hết). */
async function fresh(session: LecturerSession): Promise<LecturerSession> {
  return session.expiresAt - Date.now() > REFRESH_MARGIN_MS ? session : refresh(session);
}

export async function loadSession(): Promise<LecturerSession | null> {
  const raw = (await chrome.storage.session.get(STORAGE_KEY))[STORAGE_KEY];
  const stored = storedSessionSchema.safeParse(raw);
  if (!stored.success) return null;
  try {
    return await fresh(stored.data);
  } catch {
    await chrome.storage.session.remove(STORAGE_KEY);
    return null;
  }
}

export async function signIn(email: string, password: string): Promise<LecturerSession> {
  const normalizedEmail = email.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
    throw new BackendError('Email không hợp lệ.');
  }
  if (password.length < 6 || password.length > 128) {
    throw new BackendError('Mật khẩu phải dài từ 6 đến 128 ký tự.');
  }
  const raw = await call(`${api().auth}/v1/accounts:signInWithPassword?key=${attendo().apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: normalizedEmail, password, returnSecureToken: true }),
  });
  const r = signInSchema.parse(raw);
  const user = await readProfile(r.idToken, r.localId, r.email);
  const session: LecturerSession = {
    idToken: r.idToken,
    refreshToken: r.refreshToken,
    expiresAt: Date.now() + Number(r.expiresIn) * 1000,
    user,
  };
  await chrome.storage.session.set({ [STORAGE_KEY]: session });
  return session;
}

export async function signOut(): Promise<void> {
  // Firebase Auth không có API thu hồi token cho client; xoá phiên trên máy là đủ.
  await chrome.storage.session.remove(STORAGE_KEY);
}

/** Ngày yyyy-MM-dd theo giờ Việt Nam của một timestamp Firestore. */
export function vnDate(timestamp: string): string {
  const ms = Date.parse(timestamp);
  return Number.isNaN(ms) ? '' : new Date(ms + 7 * 3600_000).toISOString().slice(0, 10);
}

/** Một slot đã chốt của giảng viên, đủ thông tin để đối chiếu với trang FAP. */
export type ClosedSlot = Readonly<{
  id: string;
  course: string;
  group: string;
  date: string;
  slot: string;
  room: string;
}>;

/** Đổi kết quả runQuery thành danh sách slot đã chốt, mới nhất trước. */
export function toClosedSlots(raw: unknown): ClosedSlot[] {
  const rows = z.array(z.object({ document: docSchema.optional() })).parse(raw);
  return rows
    .flatMap((row) => (row.document ? [row.document] : []))
    .filter((doc) => bool(doc, 'closed'))
    .map((doc) => ({
      id: docId(doc),
      course: str(doc, 'subject'),
      group: str(doc, 'classCode'),
      date: vnDate(doc.fields.start?.timestampValue ?? ''),
      slot: String(int(doc, 'slotNo')),
      room: str(doc, 'room'),
    }))
    .sort((a, b) => b.date.localeCompare(a.date) || Number(b.slot) - Number(a.slot));
}

/**
 * Slot đã chốt cùng môn và lớp với trang FAP. Chỉ lọc bằng phép bằng (lecturerId, subject,
 * classCode) nên Firestore không cần chỉ mục ghép; ngày và slot so trên máy.
 */
export async function findClosedSlots(
  current: LecturerSession,
  page: Pick<PageContext, 'course' | 'group'>,
): Promise<ClosedSlot[]> {
  const session = await fresh(current);
  const eq = (field: string, value: string) => ({
    fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: { stringValue: value } },
  });
  const raw = await call(`${firestoreBase()}:runQuery`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...bearer(session) },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'slots' }],
        where: {
          compositeFilter: {
            op: 'AND',
            filters: [
              eq('lecturerId', session.user.id),
              eq('subject', page.course),
              eq('classCode', page.group),
            ],
          },
        },
      },
    }),
  });
  return toClosedSlots(raw);
}

/** Đổi danh sách bản ghi điểm danh của slot thành dòng nháp (chỉ bản đã chốt). */
export function toRows(raw: unknown) {
  const list = z.object({ documents: z.array(docSchema).default([]) }).parse(raw ?? {});
  return list.documents
    .filter((doc) => bool(doc, 'final'))
    .map((doc) => ({
      studentCode: str(doc, 'studentCode') || docId(doc),
      status: bool(doc, 'present') ? ('ATTEND' as const) : ('ABSENT' as const),
    }))
    .sort((a, b) => a.studentCode.localeCompare(b.studentCode));
}

export async function loadClosedSlot(
  current: LecturerSession,
  slot: ClosedSlot,
): Promise<SourceBatch> {
  const session = await fresh(current);
  const raw = await call(
    `${firestoreBase()}/slots/${encodeURIComponent(slot.id)}/attendance?pageSize=300`,
    { headers: bearer(session) },
  );
  const rows = toRows(raw);
  if (rows.length === 0) throw new BackendError('Slot này chưa có bản điểm danh đã chốt.');
  const context: BatchContext = {
    course: slot.course,
    group: slot.group,
    date: slot.date,
    slot: slot.slot,
    room: slot.room || null,
  };
  return {
    kind: 'backend',
    label: `Attendo · ${slot.course} ${slot.group} · slot ${slot.slot} ngày ${slot.date}`,
    context,
    rows,
  };
}
