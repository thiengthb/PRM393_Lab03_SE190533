import { useCallback, useEffect, useLayoutEffect, useReducer, useRef } from 'react';
import { toast } from 'sonner';

import type { AttendanceStatus, SourceBatch } from '@/lib/attendance';
import { applyToPage, getActiveTab, readPage, type ApplyAction } from '@/lib/page-bridge';
import { errorMessage } from '@/lib/utils';

import { initialState, reduce } from './workflow';

export function useWorkflow() {
  const [state, dispatch] = useReducer(reduce, initialState);
  // Async handlers read the latest committed state through this ref (synced before paint), so a
  // stale closure can never fill with an outdated draft or confirmation.
  const stateRef = useRef(state);
  useLayoutEffect(() => {
    stateRef.current = state;
  }, [state]);

  const read = useCallback(async () => {
    if (stateRef.current.busy) return;
    dispatch({ type: 'busy', busy: 'read' });
    try {
      const tab = await getActiveTab();
      dispatch({ type: 'pageRead', tab, page: await readPage(tab) });
    } catch (error) {
      dispatch({ type: 'pageFailed', message: errorMessage(error, 'Không đọc được trang.') });
    }
  }, []);

  /** Wrap any source loader: the loader may prompt (Google consent) or hit the network. */
  const loadSource = useCallback(async (load: () => Promise<SourceBatch>) => {
    if (stateRef.current.busy || !stateRef.current.page) return;
    dispatch({ type: 'busy', busy: 'source' });
    try {
      dispatch({ type: 'sourceLoaded', source: await load() });
    } catch (error) {
      dispatch({
        type: 'sourceFailed',
        message: errorMessage(error, 'Không tải được nguồn dữ liệu.'),
      });
    }
  }, []);

  const apply = useCallback(async (action: ApplyAction) => {
    const current = stateRef.current;
    if (current.busy || !current.tab || !current.page || !current.rows) return;
    if (action !== 'FAP_EXT_VERIFY' && !current.confirmed) return;
    dispatch({ type: 'busy', busy: action });
    try {
      const result = await applyToPage(current.tab, action, current.rows, current.page);
      dispatch({ type: 'applied', action, result });
      if (action !== 'FAP_EXT_VERIFY') toast.success('Đã điền và kiểm tra trang.');
    } catch (error) {
      const message = errorMessage(error, 'Không áp dụng được. Hãy đọc lại trang.');
      dispatch({ type: 'applyFailed', message });
      toast.error(message);
    }
  }, []);

  const setStatus = useCallback(
    (studentCode: string, status: AttendanceStatus) =>
      dispatch({ type: 'setStatus', studentCode, status }),
    [],
  );
  const setAll = useCallback(
    (status: AttendanceStatus, codes?: readonly string[]) =>
      dispatch({ type: 'setAll', status, codes }),
    [],
  );
  const confirm = useCallback((confirmed: boolean) => dispatch({ type: 'confirm', confirmed }), []);
  const clearSource = useCallback(() => dispatch({ type: 'clearSource' }), []);
  const setKeepMissing = useCallback(
    (keepMissing: boolean) => dispatch({ type: 'setKeepMissing', keepMissing }),
    [],
  );

  // The side panel outlives tab switches and navigations; a snapshot of another page is never
  // reused. Switching or reloading the tab invalidates the draft until the page is read again.
  useEffect(() => {
    const onActivated = (info: chrome.tabs.OnActivatedInfo) => {
      const tab = stateRef.current.tab;
      if (tab && info.tabId !== tab.id && info.windowId === tab.windowId) {
        dispatch({ type: 'invalidate', message: 'Bạn đã chuyển tab. Bấm Đọc trang để tiếp tục.' });
      }
    };
    const onUpdated = (tabId: number, change: chrome.tabs.OnUpdatedInfo) => {
      if (tabId === stateRef.current.tab?.id && change.status === 'loading') {
        dispatch({ type: 'invalidate', message: 'Trang vừa tải lại. Bấm Đọc trang để tiếp tục.' });
      }
    };
    chrome.tabs.onActivated.addListener(onActivated);
    chrome.tabs.onUpdated.addListener(onUpdated);
    void read();
    return () => {
      chrome.tabs.onActivated.removeListener(onActivated);
      chrome.tabs.onUpdated.removeListener(onUpdated);
    };
  }, [read]);

  return {
    state,
    read,
    loadSource,
    apply,
    setStatus,
    setAll,
    confirm,
    clearSource,
    setKeepMissing,
  };
}
