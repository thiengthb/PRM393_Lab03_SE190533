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
    wait_text(p, 'Slot 1 · P.305')
    # Buổi đã chốt gần nhất (hàng đầu); ngày đổi theo ngày chạy seed nên đọc từ màn.
    m = re.search(r'^((?:Thứ [^,\n]+|Chủ nhật), \d\d/\d\d)\nSlot \d · [^\n]+\n(\d+) trên 35$', text_of(p), re.M)
    assert m, text_of(p)[:800]
    day, n = m.group(1), int(m.group(2))
    tap(p, day)
    p.wait_for_timeout(1500)
    # Buổi đã chốt mở thẳng chế độ sửa: danh sách có mặt và nút Chốt lại
    t = text_of(p)
    assert f'{n} trên 35 đã có mặt' in t and 'Chốt' in t, t[:800]
    tap(p, f'Có mặt {n}', dx=-30)
    tap(p, 'Có mặt Huỳnh Anh Dung')
    p.wait_for_timeout(800)
    after = int(re.search(r'(\d+) trên 35 đã có mặt', text_of(p)).group(1))
    assert abs(after - n) == 1, (n, after)
    shot(p, 'w45_sua_buoi_da_chot')
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Đã chốt')


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
    codes = json.load(urllib.request.urlopen('http://127.0.0.1:9099/emulator/v1/projects/attendo-app-2611/oobCodes'))
    link = [c for c in codes['oobCodes'] if c['email'] == email][-1]['oobLink']
    urllib.request.urlopen(link.replace('localhost', '127.0.0.1')).read()
    tap(s, 'Xác nhận', exact=True)
    s.wait_for_timeout(2500)
    shot(s, 'w47_sv_moi')
    assert 'Chào Huy' in text_of(s) or 'Chưa có' in text_of(s), text_of(s)[:600]


def _open_session(browser):
    p = open_lecturer(browser)
    tap(p, 'Đang diễn ra')
    wait_text(p, 'Mã số')
    return p


def _code(p):
    return re.search(r'Mã số ([\d ]+)', text_of(p)).group(1).replace(' ', '')


def _enter_code(s, code):
    tap(s, 'Quét mã', exact=True)
    tap(s, 'Nhập mã', exact=True)
    s.wait_for_timeout(800)
    s.keyboard.type(code, delay=30)
    tap(s, 'Gửi', exact=True)


def test_w48_previous_code_still_accepted(browser):
    """qrTokenPrev: mã vừa đổi vẫn nhận (sinh viên nhìn TV rồi gõ chậm)."""
    p = _open_session(browser)
    old = _code(p)
    for _ in range(40):
        p.wait_for_timeout(500)
        if _code(p) != old:
            break
    assert _code(p) != old, 'Mã không đổi sau 20 giây'
    s = open_student(browser)
    _enter_code(s, old)
    wait_text(s, 'Đã ghi nhận')
    shot(s, 'w48_ma_cu_van_nhan')


def test_w49_student_not_in_class(browser):
    import json, time, urllib.request
    p = _open_session(browser)
    s = browser.page('student')
    wait_text(s, 'Đăng ký', 30000)
    tap(s, 'Đăng ký', exact=True)
    email = f'ngoai{int(time.time()) % 100000}@fpt.edu.vn'
    fill(s, 0, 'Người Ngoài')
    fill(s, 1, 'SE199999')
    fill(s, 2, email)
    fill(s, 3, PASSWORD)
    tap(s, 'Tạo tài khoản', exact=True)
    wait_text(s, 'Xác nhận email')
    codes = json.load(urllib.request.urlopen('http://127.0.0.1:9099/emulator/v1/projects/attendo-app-2611/oobCodes'))
    link = [c for c in codes['oobCodes'] if c['email'] == email][-1]['oobLink']
    urllib.request.urlopen(link.replace('localhost', '127.0.0.1')).read()
    tap(s, 'Xác nhận', exact=True)
    wait_text(s, 'Quét mã', 20000)
    _enter_code(s, _code(p))
    s.wait_for_timeout(3000)
    shot(s, 'w49_khong_trong_lop')
    t = text_of(s)
    assert 'Đã ghi nhận' not in t, t
    assert 'Nhập lại' in t or 'không' in t.lower(), t


def test_w50_offline_close(browser):
    """TC-06 trên web: mất mạng lúc chốt → dải vàng, có mạng lại → Thử lại chốt được."""
    p = _open_session(browser)
    tap(p, 'Đóng mã', exact=True)
    wait_text(p, 'Mở lại mã')
    p.context.set_offline(True)
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Chưa gửi được', 20000)  # máy chủ không xác nhận sau 8 giây
    shot(p, 'w50_mat_mang')
    assert 'Đã lưu trên máy' in text_of(p)
    p.context.set_offline(False)
    import time as _t
    t0 = _t.time()
    for _ in range(6):
        # Có mạng lại thì app tự đổi sang Đã chốt khi Firestore gửi xong, có thể trước khi kịp bấm.
        if 'Thử lại' in text_of(p):
            try:
                tap(p, 'Thử lại', timeout=2000)
            except AssertionError:
                pass  # dải vàng vừa tự đổi sang Đã chốt
        if has(p, 'Đã chốt', 12000):
            break
    print(f'Có mạng lại → chốt xong sau {_t.time() - t0:.1f}s')
    wait_text(p, 'Đã chốt', 1000)
    shot(p, 'w50_co_mang_lai')


def test_w62_wrong_portal_login_then_back_out(browser):
    """Web sinh viên, đăng nhập bằng tài khoản giảng viên: màn chặn nói rõ lý do, nút Đăng xuất chạy được,
    rồi đăng nhập lại bằng tài khoản sinh viên mà không phải tải lại trang (LOI-10, thien gặp ngày 08/11)."""
    s = browser.page('student')
    wait_flutter(s)
    login(s, LECTURER)
    wait_text(s, 'Đây là tài khoản giảng viên, hãy dùng app Attendo', 20000)
    shot(s, 'w62_sai_cong')
    tap(s, 'Đăng xuất', exact=True)
    wait_text(s, 'Quên mật khẩu?', 20000)
    shot(s, 'w62_da_dang_xuat')
    login(s, STUDENT)
    wait_text(s, 'Môn học', 30000)
