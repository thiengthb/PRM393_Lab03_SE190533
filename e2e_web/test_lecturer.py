"""Luồng giảng viên trên bản web của app (PORTAL=lecturer), dữ liệu Emulator."""
import re

from harness import *


def open_lecturer(browser):
    p = browser.page('lecturer')
    login(p, LECTURER)
    wait_text(p, 'Tổng quan', 30000)
    return p


def test_w01_login_wrong_password(browser):
    p = browser.page('lecturer')
    login(p, LECTURER, 'SaiMatKhau1')
    wait_text(p, 'Sai email hoặc mật khẩu')
    shot(p, 'w01_login_sai')


def test_w02_overview_and_tabs(browser):
    p = open_lecturer(browser)
    wait_text(p, 'Đang diễn ra: PRM393 · SE1801')
    t = text_of(p)
    assert '3 yêu cầu sửa' in t and '2 slot chưa chốt' in t
    shot(p, 'w02_tong_quan')
    tap(p, 'Điểm danh', exact=True)
    wait_text(p, 'Tuần sau')
    tap(p, 'Tuần sau')
    wait_text(p, '09/11')
    shot(p, 'w02_tuan_sau')
    tap(p, 'Tuần trước'); tap(p, 'Tuần trước')
    wait_text(p, '26/10')
    tap(p, 'Lớp', exact=True)
    wait_text(p, 'PRM393 · SE1801, 35 sinh viên')
    shot(p, 'w02_lop')
    tap(p, 'PRM393 · SE1801, 35 sinh viên')
    wait_text(p, 'đã học 17 trên 20 buổi')
    shot(p, 'w02_chi_tiet_lop')
    tap(p, 'Buổi học', exact=True)
    wait_text(p, 'Thứ Tư, 04/11')
    shot(p, 'w02_tab_buoi_hoc')
    tap(p, 'Quay lại')
    tap(p, 'Tài khoản', exact=True)
    wait_text(p, 'Đăng xuất')
    shot(p, 'w02_tai_khoan')


def test_w03_session_code_tv_close_undo(browser):
    """FL-1 + FL-4c: mở mã, sinh viên nhập mã số, màn TV, đóng mã, mở lại, chốt, hoàn tác."""
    p = open_lecturer(browser)
    tap(p, 'Đang diễn ra')
    wait_text(p, 'Mã số')
    wait_text(p, '24 trên 35 đã có mặt')
    code = re.search(r'Mã số ([\d ]+)', text_of(p)).group(1).replace(' ', '')
    shot(p, 'w03_phien_mo')

    # Màn TV qua link chép từ sheet
    tap(p, 'Chiếu lên TV')
    tap(p, 'Chép link')
    link = p.evaluate('navigator.clipboard.readText()')
    assert re.match(r'https://hereby-se190533\.web\.app/tv/[A-Z0-9]{10}$', link), link
    p.keyboard.press('Escape')
    tv = browser.page('lecturer', viewport={'width': 1280, 'height': 720}, path='/tv/' + link.split('/tv/')[1])
    tv.wait_for_timeout(2500)
    shot(tv, 'w03_tv')

    # Sinh viên nhập sai rồi nhập đúng
    s = browser.page('student')
    login(s, STUDENT)
    wait_text(s, 'Môn học', 30000)
    tap(s, 'Quét mã', exact=True)
    tap(s, 'Nhập mã', exact=True)
    s.wait_for_timeout(800)
    s.keyboard.type('000000', delay=30)
    tap(s, 'Gửi', exact=True)
    wait_text(s, 'Mã không đúng hoặc đã hết hạn')
    shot(s, 'w03_sv_ma_sai')
    tap(s, 'Nhập lại', exact=True)
    s.wait_for_timeout(800)
    code = re.search(r'Mã số ([\d ]+)', text_of(p)).group(1).replace(' ', '')
    s.keyboard.type(code, delay=30)
    tap(s, 'Gửi', exact=True)
    wait_text(s, 'Đã ghi nhận')
    shot(s, 'w03_sv_da_ghi_nhan')
    wait_text(p, '25 trên 35 đã có mặt')

    # Đóng mã: TV đổi, mở lại mã: TV có mã lại
    tap(p, 'Đóng mã', exact=True)
    wait_text(p, 'Mở lại mã')
    tv.wait_for_timeout(2000)
    shot(tv, 'w03_tv_dong_ma')
    tap(p, 'Mở lại mã', dx=-60)
    wait_text(p, 'Mã số')
    tap(p, 'Đóng mã', exact=True)
    wait_text(p, 'Mở lại mã')

    # Bật tay 1 em rồi chốt, hoàn tác, chốt lại
    tap(p, 'Có mặt Dương Hữu Tiến')
    wait_text(p, '26 trên 35 đã có mặt')
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Đã chốt')
    shot(p, 'w03_da_chot')
    t = text_of(p)
    assert 'Hoàn tác' in t
    tap(p, 'Hoàn tác', exact=True)
    wait_text(p, 'Mở lại mã')
    wait_text(p, '26 trên 35 đã có mặt')
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Đã chốt')
    tap(p, 'Xong', exact=True)
    wait_text(p, 'Tổng quan')


def test_w04_close_unclosed_slot(browser):
    """FL-2: slot đã qua chưa chốt, mở không có QR, chốt."""
    p = open_lecturer(browser)
    tap(p, '2 slot chưa chốt', dx=-40)
    wait_text(p, 'Slot chưa chốt')
    shot(p, 'w04_ds_chua_chot')
    tap(p, 'Chốt ngay', nth=0)
    wait_text(p, 'Chốt')
    assert 'Mã số' not in text_of(p)
    shot(p, 'w04_chot_slot_cu')
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Đã chốt')
    tap(p, 'Xong', exact=True)
    p.wait_for_timeout(1500)
    tap(p, 'Quay lại') if 'Quay lại' in text_of(p) else None
    wait_text(p, 'chưa chốt')
    assert '2 slot chưa chốt' not in text_of(p)
    shot(p, 'w04_sau_khi_chot')


def test_w05_attention_reminder(browser):
    """FL-3: Vắng nhiều → Sắp chạm → em đầu → Nhắc nhở → Gửi."""
    p = open_lecturer(browser)
    tap(p, 'Xem tất cả')
    wait_text(p, 'Sắp chạm')
    tap(p, 'Sắp chạm', exact=True)
    p.wait_for_timeout(800)
    shot(p, 'w05_sap_cham')
    t = text_of(p)
    first = re.search(r'([^\n]+), (\d) trên 4 buổi vắng', t)
    assert first and int(first.group(2)) in (3, 4), t[:500]
    tap(p, first.group(0))
    wait_text(p, 'Buổi vắng')
    shot(p, 'w05_ho_so')
    tap(p, 'Nhắc nhở', exact=True)
    wait_text(p, 'Gửi')
    shot(p, 'w05_soan_nhac')
    msg = read_input(p, 0)
    assert msg.startswith('Em đã vắng ') and 'PRM393' in msg or 'buổi' in msg, msg
    tap(p, 'Gửi', exact=True)
    wait_text(p, 'Đã nhắc')
    shot(p, 'w05_da_nhac')


def test_w06_over_limit_has_no_reminder(browser):
    p = open_lecturer(browser)
    tap(p, 'Phạm Thị Tâm, 6 trên 4 buổi vắng')
    wait_text(p, 'Buổi vắng')
    shot(p, 'w06_da_fail')
    assert 'Nhắc nhở' not in text_of(p)


def test_w07_logout(browser):
    p = open_lecturer(browser)
    tap(p, 'Tài khoản', exact=True)
    tap(p, 'Đăng xuất', exact=True)
    wait_text(p, 'Đăng xuất?')
    shot(p, 'w07_hoi_dang_xuat')
    tap(p, 'Đăng xuất', exact=True, nth=0)
    wait_text(p, 'Đăng nhập với Google')
