import adapterScript from '../content/index.ts?script&iife';

import type { DraftRow, PageSnapshot, VerifyResult } from './attendance';
import { pageResponseSchemas, type PageRequest } from './messages';

export class PageError extends Error {
  override name = 'PageError';
}

export type ActiveTab = Readonly<{ id: number; url: string; windowId: number }>;

export async function getActiveTab(): Promise<ActiveTab> {
  const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
  if (typeof tab?.id !== 'number') throw new PageError('Không tìm thấy tab đang mở.');
  return { id: tab.id, url: tab.url ?? '', windowId: tab.windowId };
}

async function inject(tab: ActiveTab): Promise<void> {
  if (tab.url.startsWith('file:') && !(await chrome.extension.isAllowedFileSchemeAccess())) {
    throw new PageError(
      'Chưa bật "Cho phép truy cập URL tệp" cho extension. Mở trang quản lý extension, vào Chi tiết và bật tùy chọn này.',
    );
  }
  try {
    await chrome.scripting.executeScript({ target: { tabId: tab.id }, files: [adapterScript] });
  } catch {
    throw new PageError(
      'Extension không có quyền trên trang này. Chỉ FAP giả lập và file HTML cục bộ được hỗ trợ.',
    );
  }
}

async function send<T extends PageRequest['type']>(
  tabId: number,
  request: Extract<PageRequest, { type: T }>,
) {
  const response: unknown = await chrome.tabs.sendMessage(tabId, request).catch(() => null);
  const envelope = response as { ok?: boolean; data?: unknown; error?: unknown } | null;
  if (!envelope?.ok) {
    throw new PageError(
      typeof envelope?.error === 'string'
        ? envelope.error
        : 'Trang không phản hồi. Hãy đọc lại trang.',
    );
  }
  const parsed = pageResponseSchemas[request.type].safeParse(envelope.data);
  if (!parsed.success) throw new PageError('Trang trả dữ liệu không hợp lệ.');
  return parsed.data;
}

export async function readPage(tab: ActiveTab): Promise<PageSnapshot> {
  await inject(tab);
  return (await send(tab.id, { type: 'FAP_EXT_READ' })) as PageSnapshot;
}

export type ApplyAction = 'FAP_EXT_FILL' | 'FAP_EXT_VERIFY' | 'FAP_EXT_FILL_SAVE';

export async function applyToPage(
  tab: ActiveTab,
  action: ApplyAction,
  changes: readonly DraftRow[],
  expectedPage: PageSnapshot,
): Promise<VerifyResult> {
  return (await send(tab.id, {
    type: action,
    changes: [...changes],
    expectedPage,
  })) as VerifyResult;
}
