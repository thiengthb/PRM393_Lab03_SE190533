"""Web admin (Final): tổng quan, thông báo tới hộp thư app, môn học, người dùng, quyền vào."""
import re
import time

from harness import *
from test_lecturer import open_lecturer
from test_student import open_student


def open_admin(browser):
    a = browser.page('admin', viewport=LAPTOP)
    wait_text(a, 'Duyệt lớp', 30000)
    return a


def test_w30_dashboard_numbers(browser):
    a = open_admin(browser)
    wait_text(a, '4 lớp đã duyệt')
    t = text_of(a)
    assert '0 lớp chờ duyệt' in t and '131 sinh viên' in t, t
    assert re.search(r'PRM393 có mặt \d+ phần trăm', t)
    shot(a, 'w30_admin_tong_quan')


def test_w31_announcement_to_student_inbox(browser):
    a = open_admin(browser)
    tap(a, 'Thông báo', exact=True)
    wait_text(a, 'Đã đăng')
    # Bỏ trống tiêu đề bị chặn
    tap(a, 'Đăng', exact=True)
    a.wait_for_timeout(800)
    shot(a, 'w31_thieu_tieu_de')
    assert text_of(a).count('Chào kỳ Fall 2026') == 1
    title = f'Nghỉ học bù {int(time.time()) % 1000}'
    fill(a, 0, title)
    fill(a, 1, 'Thứ Bảy 14/11 nghỉ, học bù sau.')
    tap(a, 'Sinh viên', exact=True)
    s = open_student(browser)
    tap(a, 'Đăng', exact=True)
    wait_text(a, title)
    shot(a, 'w31_da_dang')
    # Sinh viên thấy trong hộp thư (không cần tải lại); giảng viên thì không
    tap(s, 'mở tài khoản', dx=-50)
    tap(s, 'Hộp thư')
    wait_text(s, title)
    shot(s, 'w31_sv_hop_thu')
    p = open_lecturer(browser)
    tap(p, 'Hộp thư')
    wait_text(p, 'Chào kỳ Fall 2026')
    assert title not in text_of(p)
    # Lưu trữ: biến khỏi hộp thư sinh viên
    tap(a, f'Lưu trữ', nth=0)
    a.wait_for_timeout(800)
    if 'Hủy' in text_of(a):
        tap(a, 'Lưu trữ', exact=True)
    for _ in range(30):
        if title not in text_of(s):
            break
        s.wait_for_timeout(300)
    assert title not in text_of(s), 'Thông báo lưu trữ vẫn hiện ở hộp thư sinh viên'


def test_w32_subjects_crud(browser):
    a = open_admin(browser)
    tap(a, 'Môn học', exact=True)
    wait_text(a, 'Thêm môn')
    tap(a, 'Thêm môn')
    a.wait_for_timeout(800)
    shot(a, 'w32_form_them')
    # Trùng mã
    fill(a, 0, 'PRM393')
    fill(a, 1, 'Trùng')
    tap(a, 'Lưu', exact=True)
    a.wait_for_timeout(800)
    shot(a, 'w32_trung_ma')
    t = text_of(a)
    assert re.search(r'(đã có|trùng|tồn tại)', t, re.I), t[-500:]
    # Sai định dạng
    fill(a, 0, 'P-1')
    tap(a, 'Lưu', exact=True)
    a.wait_for_timeout(800)
    shot(a, 'w32_sai_dinh_dang')
    assert 'Hủy' in text_of(a)
    # Đúng
    fill(a, 0, 'SWP391')
    fill(a, 1, 'Software Development Project')
    tap(a, 'Lưu', exact=True)
    wait_text(a, 'SWP391 Software Development Project')
    shot(a, 'w32_da_them')
    # Lưu trữ rồi khôi phục
    tap(a, 'Lưu trữ SWP391')
    a.wait_for_timeout(600)
    if 'Hủy' in text_of(a):
        tap(a, 'Lưu trữ', exact=True)
    for _ in range(20):
        if 'SWP391 Software' not in text_of(a):
            break
        a.wait_for_timeout(300)
    tap(a, 'Đã lưu trữ', exact=True)
    wait_text(a, 'SWP391')
    shot(a, 'w32_da_luu_tru')
    tap(a, 'Khôi phục SWP391')
    a.wait_for_timeout(1000)
    tap(a, 'Đang dùng', exact=True)
    wait_text(a, 'SWP391 Software Development Project')


def test_w33_users_and_denied(browser):
    a = open_admin(browser)
    tap(a, 'Người dùng', exact=True)
    wait_text(a, 'Quản trị · bạn')
    shot(a, 'w33_nguoi_dung')
    g = browser.page('giaovu', viewport=LAPTOP)
    wait_text(g, 'chưa được cấp quyền', 30000)
    shot(g, 'w33_giao_vu_bi_chan')
