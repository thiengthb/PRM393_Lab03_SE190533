"""W60: giảng viên chốt slot trên app → extension "Attendo cho FAP" lấy bản đã chốt → điền vào FAP giả lập.

Cần thêm (ngoài các bản web của harness):
  EXT_DIR   extension dựng với VITE_HEREBY_EMULATOR_HOST=127.0.0.1 (mặc định extension/dist-e2e)
  FAP_URL   FAP giả lập (mặc định http://127.0.0.1:4173/fap/, `cd fap-mock && npx vite preview`)
"""
import os
import re
from datetime import datetime, timedelta, timezone

import pytest

from harness import *
from test_lecturer import open_lecturer

EXT_DIR = os.environ.get('EXT_DIR', str(REPO / 'extension' / 'dist-e2e'))
FAP_URL = os.environ.get('FAP_URL', 'http://127.0.0.1:4173/fap/')


def _today_vn():
    return (datetime.now(timezone.utc) + timedelta(hours=7)).strftime('%Y-%m-%d')


def fill_fap_with_extension(browser, slot_no, present, shots_prefix='w60'):
    """FAP giả lập (hôm nay, PRM393 · SE1801 · slot_no) + extension: đọc trang, đăng nhập, lấy bản đã chốt, điền.
    Kiểm số em Present trên FAP bằng [present]."""
    ctx = browser._pw.chromium.launch_persistent_context(
        '', channel='chromium', headless=True, viewport={'width': 1280, 'height': 800},
        locale='vi-VN', timezone_id='Asia/Ho_Chi_Minh',
        args=[f'--disable-extensions-except={EXT_DIR}', f'--load-extension={EXT_DIR}'])
    try:
        sw = ctx.service_workers[0] if ctx.service_workers else ctx.wait_for_event('serviceworker', timeout=20000)
        ext_id = sw.url.split('/')[2]
        fap = ctx.new_page()
        fap.goto(FAP_URL)
        fap.fill('#session-date', _today_vn())
        fap.dispatch_event('#session-date', 'change')
        options = fap.eval_on_selector_all('#today-class option', 'os => os.map(o => [o.value, o.textContent])')
        value = next(v for v, label in options if f'PRM393 · SE1801 · Slot {slot_no} ·' in label)
        fap.select_option('#today-class', value)
        assert fap.locator('#attendance-rows tr').count() == 35
        fap.screenshot(path=str(SHOTS / f'{shots_prefix}_fap_truoc.png'))
        # Bảng thật là side panel, chỉ mở được bằng tay người; ở đây mở trang của bảng trong một tab và chỉ
        # "tab đang xem" sang tab FAP (bảng luôn làm việc với tab đang xem).
        panel = ctx.new_page()
        panel.set_viewport_size({'width': 400, 'height': 900})
        panel.goto(f'chrome-extension://{ext_id}/src/sidepanel/index.html')
        panel.evaluate("""async () => {
          const [fap] = await chrome.tabs.query({ url: 'http://127.0.0.1:4173/*' });
          const query = chrome.tabs.query.bind(chrome.tabs);
          chrome.tabs.query = async (q) => (q && q.active ? [fap] : query(q));
        }""")
        panel.get_by_role('button', name='Đọc trang').click()
        expect(panel.get_by_text('Đã đọc 35 sinh viên')).to_be_visible(timeout=15000)
        panel.fill('#login-email', LECTURER)
        panel.fill('#login-password', PASSWORD)
        panel.get_by_role('button', name='Đăng nhập', exact=True).click()
        slot_select = panel.locator('#hereby-slot')
        expect(slot_select).to_be_visible(timeout=15000)
        assert f'{_today_vn()} · slot {slot_no}' in slot_select.locator('option:checked').inner_text()
        panel.screenshot(path=str(SHOTS / f'{shots_prefix}_panel_chon_slot.png'), full_page=True)
        panel.get_by_role('button', name='Lấy bản đã chốt').click()
        expect(panel.get_by_text('Khớp Môn, Lớp, Ngày, Slot, Phòng.')).to_be_visible(timeout=15000)
        panel.get_by_text('Tôi đã kiểm tra danh sách').click()
        panel.get_by_role('button', name='Điền vào trang').click()
        expect(panel.get_by_text('kiểm tra 35/35 dòng')).to_be_visible(timeout=15000)
        panel.screenshot(path=str(SHOTS / f'{shots_prefix}_panel_da_dien.png'), full_page=True)
        checked = fap.eval_on_selector_all('#attendance-rows input[value="rdPresent"]', 'xs => xs.filter(x => x.checked).length')
        assert checked == present, f'FAP có {checked} em Present, app có {present} em có mặt'
        fap.click('#ctl00_mainContent_btnSave')
        fap.wait_for_timeout(800)
        fap.screenshot(path=str(SHOTS / f'{shots_prefix}_fap_sau.png'))
        saved = fap.inner_text('#save-status')

        # Chặn sai: trang FAP đổi sang slot khác thì bản đã chốt không được điền
        other = next(v for v, label in options if 'PRM393 · SE1801 · Slot' in label and f'Slot {slot_no} ·' not in label)
        fap.select_option('#today-class', other)
        panel.get_by_role('button', name='Đọc lại').click()
        panel.wait_for_timeout(1500)
        panel.locator('#hereby-slot').select_option(index=0)
        panel.get_by_role('button', name='Lấy bản đã chốt').click()
        panel.wait_for_timeout(1500)
        panel.screenshot(path=str(SHOTS / f'{shots_prefix}_panel_sai_slot.png'), full_page=True)
        mismatch = panel.inner_text('body')
        return saved, mismatch
    finally:
        ctx.close()


@pytest.mark.skipif(not os.path.exists(os.path.join(EXT_DIR, 'manifest.json')), reason='chưa dựng extension bản e2e')
def test_w60_extension_fills_fap_from_closed_slot(browser):
    slot_no = int(re.search(r'Slot đang diễn ra: (\d)', reseed()).group(1))

    # 1. Giảng viên chốt slot đang diễn ra trên app (bản web)
    p = open_lecturer(browser)
    tap(p, 'Đang diễn ra')
    wait_text(p, 'Mã số')
    present = int(re.search(r'(\d+) trên 35 đã có mặt', text_of(p)).group(1))
    tap(p, 'Đóng mã', exact=True)
    wait_text(p, 'Mở lại mã')
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Đã chốt')
    tap(p, 'Xong', exact=True)
    wait_text(p, 'Tổng quan')
    # 2-4. FAP giả lập + extension
    saved, mismatch = fill_fap_with_extension(browser, slot_no, present)
    assert 'không khớp' in mismatch.lower(), mismatch[:800]
