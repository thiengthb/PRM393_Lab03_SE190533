"""Khung chạy Playwright cho bản web Flutter của Attendo trên Firebase Emulator."""
import os
import re
import time
from pathlib import Path

from playwright.sync_api import Page, sync_playwright, expect

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
FIREBASE_JS = REPO / 'firebase' / 'tests' / 'node_modules' / 'firebase'
SHOTS = Path(os.environ.get('SHOTS', ROOT / 'shots'))
PORTS = {'lecturer': 5001, 'student': 5002, 'admin': 5003, 'giaovu': 5004}
PASSWORD = 'Demo@123'
LECTURER = 'quanm@fe.edu.vn'
STUDENT = 'dung101@fpt.edu.vn'
PHONE = {'width': 390, 'height': 844}
LAPTOP = {'width': 1366, 'height': 820}


def _route(route):
    url = route.request.url
    if 'fonts.googleapis.com' in url or 'fonts.gstatic.com' in url:
        return route.abort()
    m = re.search(r'www\.gstatic\.com/firebasejs/[^/]+/([^?]+)', url)
    if m:
        f = FIREBASE_JS / m.group(1)
        if f.exists():
            return route.fulfill(path=str(f), content_type='application/javascript')
        return route.abort()
    if re.search(r'googleapis\.com|google-analytics|googletagmanager|recaptcha|gstatic', url) and 'localhost' not in url:
        return route.abort()
    return route.continue_()


class Browser:
    def __init__(self, headless=True):
        self._pw = sync_playwright().start()
        self.browser = self._pw.chromium.launch(headless=headless, args=['--disable-gpu'])
        self.errors = []

    def page(self, portal, viewport=PHONE, path='/'):
        ctx = self.browser.new_context(viewport=viewport, locale='vi-VN', timezone_id='Asia/Ho_Chi_Minh',
                                       permissions=['clipboard-read', 'clipboard-write'])
        ctx.route('**/*', _route)
        # Dải chữ đỏ "Running in emulator mode" của Firebase Auth che thanh nút đáy: ẩn đi.
        ctx.add_init_script("""new MutationObserver(() => document.querySelectorAll('.firebase-emulator-warning').forEach(e => e.remove()))
          .observe(document, {childList: true, subtree: true});""")
        page = ctx.new_page()
        page.on('console', lambda m: m.type == 'error' and self.errors.append(f'[{portal}] {m.text[:300]}'))
        page.on('pageerror', lambda e: self.errors.append(f'[{portal}] pageerror {str(e)[:300]}'))
        page.goto(f'http://localhost:{PORTS[portal]}{path}')
        wait_flutter(page)
        return page

    def close(self):
        self.browser.close()
        self._pw.stop()


def wait_flutter(page: Page, timeout=60000):
    page.wait_for_selector('flt-glass-pane, flutter-view', timeout=timeout, state='attached')
    page.wait_for_timeout(1500)
    semantics(page)


def semantics(page: Page):
    """Bật cây semantics của Flutter để tìm phần tử theo chữ / vai trò."""
    ph = page.locator('flt-semantics-placeholder')
    if ph.count():
        try:
            ph.first.dispatch_event('click')
        except Exception:
            pass
        page.wait_for_timeout(500)


def shot(page: Page, name):
    SHOTS.mkdir(parents=True, exist_ok=True)
    page.wait_for_timeout(400)
    page.screenshot(path=str(SHOTS / f'{name}.png'))


def text_of(page: Page):
    """Toàn bộ chữ đọc được trên cây semantics (để assert)."""
    return page.evaluate("""() => {
      const out = [];
      document.querySelectorAll('[id^="flt-semantic-node"]').forEach(n => {
        const l = n.getAttribute('aria-label'); if (l) out.push(l);
        const t = [...n.childNodes].filter(c => c.nodeType === 3 || c.tagName === 'SPAN').map(c => c.textContent).join('').trim(); if (t) out.push(t);
      });
      document.querySelectorAll('[id^="flt-semantic-node"] input, [id^="flt-semantic-node"] textarea').forEach(i => out.push('[input]' + (i.value||'')));
      return [...new Set(out)].join('\\n');
    }""")


def has(page: Page, s, timeout=10000):
    end = time.time() + timeout / 1000
    while time.time() < end:
        semantics(page)
        if s in text_of(page):
            return True
        page.wait_for_timeout(300)
    return False


def wait_text(page: Page, s, timeout=15000):
    if not has(page, s, timeout):
        shot(page, f'_fail_{re.sub(r"[^a-zA-Z0-9]", "_", s)[:30]}')
        raise AssertionError(f'Không thấy chữ "{s}". Màn có:\n{text_of(page)[:1500]}')


def _find(page: Page, name, exact):
    return page.evaluate("""([name, exact]) => {
      const res = [];
      document.querySelectorAll('[id^="flt-semantic-node"]').forEach((n) => {
        const l = ((n.getAttribute('aria-label') || '') + ' ' + [...n.childNodes].filter(c => c.nodeType === 3 || c.tagName === 'SPAN').map(c => c.textContent).join('')).trim();
        const first = l.split('\\n')[0].trim();
        const ok = exact ? (l === name || first === name) : l.includes(name);
        if (!ok) return;
        const r = n.getBoundingClientRect();
        if (r.width < 2 || r.height < 2) return;
        const role = n.getAttribute('role') || '';
        const click = ['button', 'link', 'tab', 'checkbox', 'switch', 'menuitem', 'radio', 'option'].includes(role) || n.hasAttribute('flt-tappable');
        res.push({id: n.id, right: r.x + r.width, x: r.x + r.width / 2, y: r.y + r.height / 2, click, role, l: l.slice(0, 80), exact: l === name});
      });
      res.sort((a, b) => (b.exact - a.exact) || (b.click - a.click));
      return res;
    }""", [name, exact])


def tap(page: Page, name, exact=False, nth=0, timeout=10000, mouse=True, dx=0, wait=700):
    """Bấm phần tử semantics có nhãn chứa `name` (như trình đọc màn hình: gửi hành động tap của node)."""
    end = time.time() + timeout / 1000
    last = None
    while time.time() < end:
        semantics(page)
        cands = _find(page, name, exact)
        if len(cands) > nth:
            c = cands[nth]
            vh = page.viewport_size['height']
            if mouse and not (56 < c['y'] < vh - 84):
                # Ngoài vùng nhìn thấy (dưới thanh tab / nút đáy): cuộn tới rồi tìm lại.
                page.mouse.move(page.viewport_size['width'] / 2, vh / 2)
                page.mouse.wheel(0, c['y'] - vh / 2)
                page.wait_for_timeout(600)
                cands = _find(page, name, exact)
                if len(cands) <= nth:
                    continue
                c = cands[nth]
            if mouse:
                # dx < 0: bấm cách mép phải |dx| px (nút nằm trong hàng đã gộp semantics).
                page.mouse.click(c['right'] + dx if dx < 0 else c['x'] + dx, c['y'])
            else:
                page.evaluate('(id) => document.getElementById(id).click()', c['id'])
            if wait:
                page.wait_for_timeout(wait)
            return c
        last = cands
        page.wait_for_timeout(300)
    shot(page, f'_fail_tap_{re.sub(r"[^a-zA-Z0-9]", "_", name)[:30]}')
    raise AssertionError(f'Không bấm được "{name}". Ứng viên: {last}\nMàn có:\n{text_of(page)[:1500]}')


def fill(page: Page, idx, value, clear=True):
    """Gõ vào ô nhập thứ `idx` (đếm theo thứ tự trên màn). Bấm rồi gõ phím vì fill() không ăn với ô mật khẩu."""
    semantics(page)
    box = page.locator('[id^="flt-semantic-node"] input, [id^="flt-semantic-node"] textarea').nth(idx)
    box.click()
    page.wait_for_timeout(350)
    if clear:
        page.keyboard.press('Control+A')
        page.keyboard.press('Backspace')
    page.keyboard.type(value, delay=10)
    page.wait_for_timeout(200)


def inputs(page: Page):
    return page.evaluate("""() => [...document.querySelectorAll('[id^="flt-semantic-node"] input, [id^="flt-semantic-node"] textarea')].map(i => i.value)""")


def login(page: Page, email, password=PASSWORD):
    wait_text(page, 'Đăng nhập', 30000)
    fill(page, 0, email)
    fill(page, 1, password)
    tap(page, 'Đăng nhập', exact=True)


def reseed():
    import subprocess
    env = dict(os.environ, FIRESTORE_EMULATOR_HOST='127.0.0.1:8080', FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099')
    out = subprocess.run(['node', 'seed-demo.mjs', '--reset', '--live-now'], cwd=REPO / 'firebase' / 'tests', env=env,
                         capture_output=True, text=True, timeout=120)
    if out.returncode:
        raise RuntimeError(out.stderr)
    return out.stdout.strip().splitlines()[-1]


def real_errors(errors):
    noise = ('firebase-analytics', 'ERR_FAILED', 'ERR_TUNNEL', 'installations', 'Failed to fetch', 'remoteconfig',
             'ERR_CONNECTION', 'ERR_NAME', 'fonts.g')
    return [e for e in errors if not any(n in e for n in noise)]


def read_input(page: Page, idx=0):
    """Giá trị ô nhập thứ idx (Flutter web chỉ đưa giá trị vào DOM khi ô đang được chọn)."""
    box = page.locator('[id^="flt-semantic-node"] input, [id^="flt-semantic-node"] textarea').nth(idx)
    box.click()
    page.wait_for_timeout(400)
    return box.input_value()


def scroll_text(page: Page, steps=8, dy=500):
    """Gom chữ khi cuộn hết danh sách (ListView chỉ dựng phần đang thấy)."""
    seen = []
    vw, vh = page.viewport_size['width'], page.viewport_size['height']
    page.mouse.move(vw / 2, vh / 2)
    for _ in range(steps):
        for line in text_of(page).split('\n'):
            if line not in seen:
                seen.append(line)
        page.mouse.wheel(0, dy)
        page.wait_for_timeout(500)
    page.mouse.wheel(0, -dy * steps)
    page.wait_for_timeout(500)
    return '\n'.join(seen)
