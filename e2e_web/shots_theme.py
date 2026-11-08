"""Chụp các màn chính ở chế độ sáng và tối (theo máy) bằng bản web trên Emulator.
Chạy: SHOTS=/tmp/x python3 shots_theme.py"""
import sys

from harness import *
from harness import _route


def page(b, portal, scheme, viewport=PHONE, path='/'):
    ctx = b.browser.new_context(viewport=viewport, locale='vi-VN', timezone_id='Asia/Ho_Chi_Minh',
                                color_scheme=scheme, device_scale_factor=2,
                                permissions=['clipboard-read', 'clipboard-write'])
    ctx.route('**/*', _route)
    ctx.add_init_script("""new MutationObserver(() => document.querySelectorAll('.firebase-emulator-warning').forEach(e => e.remove()))
      .observe(document, {childList: true, subtree: true});""")
    p = ctx.new_page()
    p.goto(f'http://localhost:{PORTS[portal]}{path}')
    wait_flutter(p)
    return p


def run(b, scheme):
    s = scheme[0]
    reseed()
    p = page(b, 'lecturer', scheme)
    wait_text(p, 'Đăng nhập', 30000)
    shot(p, f'{s}_01_dang_nhap')
    login(p, LECTURER)
    wait_text(p, 'Đang diễn ra: PRM393 · SE1801', 30000)
    p.wait_for_timeout(800)
    shot(p, f'{s}_02_tong_quan')
    tap(p, 'Điểm danh', exact=True, nth=1)
    wait_text(p, 'Tuần sau')
    shot(p, f'{s}_03_lich')
    tap(p, 'Lớp', exact=True)
    wait_text(p, 'PRM393 · SE1801, 35 sinh viên')
    shot(p, f'{s}_04_lop')
    tap(p, 'PRM393 · SE1801, 35 sinh viên')
    wait_text(p, ' trên 20 buổi')
    shot(p, f'{s}_05_chi_tiet_lop')
    tap(p, 'Quay lại')
    tap(p, 'Tài khoản', exact=True)
    wait_text(p, 'Đăng xuất')
    shot(p, f'{s}_06_tai_khoan')
    tap(p, 'Tổng quan', exact=True)
    tap(p, 'Đang diễn ra')
    wait_text(p, 'Mã số')
    p.wait_for_timeout(800)
    shot(p, f'{s}_07_phien_mo')
    p.context.close()

    w = page(b, 'lecturer', scheme, viewport=LAPTOP)
    login(w, LECTURER)
    wait_text(w, 'Đang diễn ra: PRM393 · SE1801', 30000)
    w.wait_for_timeout(800)
    shot(w, f'{s}_08_laptop_tong_quan')
    w.context.close()

    st = page(b, 'student', scheme)
    login(st, STUDENT)
    wait_text(st, 'Môn học', 30000)
    st.wait_for_timeout(800)
    shot(st, f'{s}_09_sv_trang_chu')
    tap(st, 'PRM393 SE1801')
    st.wait_for_timeout(1200)
    shot(st, f'{s}_10_sv_chi_tiet')
    st.context.close()


if __name__ == '__main__':
    b = Browser()
    try:
        for scheme in sys.argv[1:] or ['light', 'dark']:
            run(b, scheme)
    finally:
        b.close()
