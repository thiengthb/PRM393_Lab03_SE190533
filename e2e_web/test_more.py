"""Các nhánh phụ: file lỗi, link TV sai, đổi màu, khu demo, quên mật khẩu, sửa buổi đã chốt, màn rộng."""
import re

from flows_common import *
from test_lecturer import open_lecturer
from test_student import open_student


def test_w40_import_error_file(browser):
    p, _ = signup_lecturer(browser)
    tap(p, 'Nhập lớp ngay', exact=True)
    import_sample(p, 'lop-co-loi.csv')
    wait_text(p, 'dòng lỗi')
    shot(p, 'w40_file_loi')
    t = text_of(p)
    assert re.search(r'2 dòng lỗi', t), t[:800]
    assert 'Chọn file khác' in t


def test_w41_tv_bad_key(browser):
    tv = browser.page('lecturer', viewport={'width': 1280, 'height': 720}, path='/tv/ABCDEFGHJK')
    tv.wait_for_timeout(3000)
    shot(tv, 'w41_tv_sai_khoa')
    assert has(tv, 'Chưa mở điểm danh') or has(tv, 'hết hạn'), text_of(tv)


def test_w42_palette(browser):
    p = open_lecturer(browser)
    tap(p, 'Tài khoản', exact=True)
    tap(p, 'Màu giao diện')
    wait_text(p, 'Màu ')
    shot(p, 'w42_chon_mau')
    names = re.findall(r'^Màu (.+)$', text_of(p), re.M)
    other = [n for n in names if 'Xô thơm' not in n and 'giao diện' not in n]
    assert other, names
    tap(p, 'Màu ' + other[0], exact=True)
    wait_text(p, 'Màu giao diện, ' + other[0])
    shot(p, 'w42_da_doi_mau')


def test_w43_demo_area(browser):
    p = open_lecturer(browser)
    tap(p, 'Tài khoản', exact=True)
    tap(p, 'Khu demo')
    wait_text(p, 'Tải lại')
    shot(p, 'w43_khu_demo')
    t = scroll_text(p, steps=4)
    assert 'qr_rotate_seconds' in t or 'Remote Config' in t, t[:1500]


def test_w44_forgot_password(browser):
    p = browser.page('lecturer')
    wait_text(p, 'Quên mật khẩu?', 30000)
    tap(p, 'Quên mật khẩu?')
    wait_text(p, 'Gửi link đặt lại')
    fill(p, 0, LECTURER)
    tap(p, 'Gửi link đặt lại', exact=True)
    wait_text(p, 'Đã gửi link')
    shot(p, 'w44_quen_mat_khau')


def test_w45_edit_closed_slot(browser):
    """Sửa buổi đã chốt từ tab Buổi học của Chi tiết lớp."""
    p = open_lecturer(browser)
    tap(p, 'Lớp', exact=True)
    tap(p, 'PRM393 · SE1801, 35 sinh viên')
    tap(p, 'Buổi học', exact=True)
    wait_text(p, 'Thứ Tư, 04/11')
    tap(p, 'Thứ Tư, 04/11')
    p.wait_for_timeout(1500)
    shot(p, 'w45_buoi_da_chot')
    # Buổi đã chốt mở thẳng chế độ sửa: danh sách có mặt và nút Chốt lại
    t = text_of(p)
    assert '35 trên 35 đã có mặt' in t and 'Chốt' in t, t[:800]
    tap(p, 'Có mặt 35', dx=-30)
    tap(p, 'Có mặt Huỳnh Anh Dung')
    wait_text(p, '34 trên 35 đã có mặt')
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Đã chốt')
    shot(p, 'w45_chot_lai')


def test_w46_wide_layouts(browser):
    p = browser.page('lecturer', viewport=LAPTOP)
    login(p, LECTURER)
    wait_text(p, 'Đang diễn ra', 30000)
    p.wait_for_timeout(1500)
    shot(p, 'w46_gv_laptop')
    s = browser.page('student', viewport=LAPTOP)
    login(s, STUDENT)
    wait_text(s, 'Môn học', 30000)
    s.wait_for_timeout(1500)
    shot(s, 'w46_sv_laptop')


def test_w47_student_signup(browser):
    import json, time, urllib.request
    s = browser.page('student')
    wait_text(s, 'Đăng ký', 30000)
    tap(s, 'Đăng ký', exact=True)
    wait_text(s, 'MSSV')
    email = f'huy{int(time.time()) % 100000}@fpt.edu.vn'
    fill(s, 0, 'Lê Gia Huy')
    fill(s, 1, 'SE190601')
    fill(s, 2, email)
    fill(s, 3, PASSWORD)
    shot(s, 'w47_sv_dang_ky')
    tap(s, 'Tạo tài khoản', exact=True)
    wait_text(s, 'Xác nhận email')
    codes = json.load(urllib.request.urlopen('http://127.0.0.1:9099/emulator/v1/projects/hereby-se190533/oobCodes'))
    link = [c for c in codes['oobCodes'] if c['email'] == email][-1]['oobLink']
    urllib.request.urlopen(link.replace('localhost', '127.0.0.1')).read()
    tap(s, 'Xác nhận', exact=True)
    s.wait_for_timeout(2500)
    shot(s, 'w47_sv_moi')
    assert 'Chào Huy' in text_of(s) or 'Chưa có' in text_of(s), text_of(s)[:600]
