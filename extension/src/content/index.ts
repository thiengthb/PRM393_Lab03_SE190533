import { config } from '@/lib/config';
import { pageRequestSchema, type PageResponse } from '@/lib/messages';

import { createFapV2Adapter } from './fap-v2-adapter';

/**
 * Injected on demand by the side panel (chrome.scripting.executeScript), never declared as an
 * always-on content script. Re-injection is idempotent thanks to the global guard.
 */
declare global {
  var __FAP_EXT_ADAPTER_INSTALLED__: boolean | undefined;
}

export function installAdapter(): void {
  if (globalThis.__FAP_EXT_ADAPTER_INSTALLED__) return;
  globalThis.__FAP_EXT_ADAPTER_INSTALLED__ = true;
  const adapter = createFapV2Adapter({
    document,
    location,
    fixtureOrigins: config.fixtureOrigins,
  });

  chrome.runtime.onMessage.addListener((message: unknown, sender, sendResponse) => {
    const type = (message as { type?: unknown } | null)?.type;
    if (typeof type !== 'string' || !type.startsWith('FAP_EXT_')) return false;
    const reply = (response: PageResponse<unknown>) => sendResponse(response);
    if (sender.id !== chrome.runtime.id) {
      reply({ ok: false, error: 'Nguồn yêu cầu không hợp lệ.' });
      return false;
    }
    const parsed = pageRequestSchema.safeParse(message);
    if (!parsed.success) {
      reply({ ok: false, error: 'Yêu cầu không được hỗ trợ.' });
      return false;
    }
    try {
      const request = parsed.data;
      if (request.type === 'FAP_EXT_READ') reply({ ok: true, data: adapter.read() });
      else if (request.type === 'FAP_EXT_FILL') {
        reply({ ok: true, data: adapter.fill(request.changes, request.expectedPage) });
      } else if (request.type === 'FAP_EXT_VERIFY') {
        reply({ ok: true, data: adapter.verify(request.changes, request.expectedPage) });
      } else {
        reply({ ok: true, data: adapter.fillAndSave(request.changes, request.expectedPage) });
      }
    } catch (error) {
      reply({
        ok: false,
        error: error instanceof Error ? error.message : 'Không thể xử lý trang.',
      });
    }
    return false;
  });
}

installAdapter();
