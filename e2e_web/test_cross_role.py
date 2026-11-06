"""Luồng liên vai trò (Final): giảng viên mới đăng ký, nhập lớp, quản trị duyệt / từ chối trên web admin."""
import re
import time

from flows_common import *


def _wait_change(page, check, timeout=15):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if check(text_of(page)):
            return time.time() - t0
        page.wait_for_timeout(100)
    raise AssertionError('App không đổi sau %ss:\n%s' % (timeout, text_of(page)[:1200]))


def test_w20_signup_import_approve_reject(browser):
    p, email = signup_lecturer(browser)
    shot(p, 'w20_bat_dau')
    tap(p, 'Nhập lớp ngay', exact=True)
    import_sample(p)
    wait_text(p, 'Fall 2026 · 4 lớp · 8 slot mỗi tuần')
    shot(p, 'w20_xem_truoc')
    tap(p, 'Nhập', exact=True)
    wait_text(p, 'Đã gửi 4 lớp')
    wait_text(p, 'Chờ giáo vụ duyệt')
    tap(p, 'Tổng quan', exact=True)
    wait_text(p, 'PRM393 · SE1801, Chờ giáo vụ duyệt')
    shot(p, 'w20_gv_cho_duyet')

    a = browser.page('admin', viewport=LAPTOP)
    wait_text(a, 'Duyệt lớp', 30000)
    tap(a, 'Duyệt lớp', exact=True)
    wait_text(a, 'PRM393 · SE1801, Trần Thị Lan')
    shot(a, 'w20_admin_cho_duyet')
    cards = re.findall(r'^(\w+ · SE\d+), Trần Thị Lan', text_of(a), re.M)
    assert len(cards) == 4, cards

    # Duyệt PRM393 SE1801, đo thời gian app đổi
    i = cards.index('PRM393 · SE1801')
    t0 = time.time()
    tap(a, 'Duyệt', exact=True, nth=i, wait=0)
    dt = time.time() - t0 + _wait_change(p, lambda t: 'PRM393 · SE1801, Chờ giáo vụ duyệt' not in t)
    print(f'Duyệt → app đổi sau {dt:.2f}s (Emulator)')
    shot(a, 'w20_admin_da_duyet')
    shot(p, 'w20_gv_sau_duyet')

    # Từ chối PRN221 SE1810: không lý do bị chặn, có lý do thì gửi được
    cards = re.findall(r'^(\w+ · SE\d+), Trần Thị Lan', text_of(a), re.M)
    i = cards.index('PRN221 · SE1810')
    tap(a, 'Từ chối', exact=True, nth=i + 1)  # nth 0 là tab "Từ chối"
    a.wait_for_timeout(800)
    shot(a, 'w20_admin_hop_tu_choi')
    wait_text(a, 'Từ chối PRN221 · SE1810')
    tap(a, 'Từ chối', exact=True)
    a.wait_for_timeout(800)
    assert 'Hủy' in text_of(a), 'Từ chối không lý do phải bị chặn, hộp thoại vẫn mở'
    shot(a, 'w20_admin_thieu_ly_do')
    fill(a, 0, 'Sai sĩ số, nhập lại file mới')
    t0 = time.time()
    tap(a, 'Từ chối', exact=True, wait=0)
    dt = time.time() - t0 + _wait_change(p, lambda t: 'Sai sĩ số, nhập lại file mới' in t or 'Bị từ chối' in t)
    print(f'Từ chối → app đổi sau {dt:.2f}s (Emulator)')
    p.wait_for_timeout(1000)
    shot(p, 'w20_gv_bi_tu_choi')
    t = text_of(p)
    assert 'Sai sĩ số, nhập lại file mới' in t, t[:1500]
    assert 'Nhập lại' in t

    # Hộp thư có tin duyệt và tin từ chối
    tap(p, 'Hộp thư')
    wait_text(p, 'đã được duyệt')
    shot(p, 'w20_gv_hop_thu')
    tap(p, 'Quay lại')

    # Lớp đã duyệt mở được mã điểm danh (luật: classApproved)
    tap(p, 'Lớp', exact=True)
    wait_text(p, 'PRM393 · SE1801')
    shot(p, 'w20_gv_lop')
