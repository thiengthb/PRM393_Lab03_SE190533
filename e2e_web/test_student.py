"""Luồng sinh viên (web sinh viên, PORTAL=student) và luồng báo sai liên vai trò."""
import re

from harness import *
from test_lecturer import open_lecturer


def open_student(browser):
    s = browser.page('student')
    login(s, STUDENT)
    wait_text(s, 'Môn học', 30000)
    return s


def test_w10_student_overview_matches_detail(browser):
    """FL-4: số vắng ở danh sách = số hàng vắng ở chi tiết."""
    s = open_student(browser)
    shot(s, 'w10_sv_tong_quan')
    m = re.search(r'PRM393 SE1801, vắng (\d) trên 4', text_of(s))
    assert m, text_of(s)
    tap(s, 'PRM393 SE1801')
    wait_text(s, 'Buổi học')
    shot(s, 'w10_sv_chi_tiet')
    all_text = scroll_text(s)
    rows = re.findall(r'^(Thứ [^\n]*, \d\d/\d\d), (có mặt|vắng)', all_text, re.M)
    assert [r[1] for r in rows].count('vắng') == int(m.group(1)), rows
    # Buổi bị từ chối không báo lại được: chỉ một hàng có "bấm để báo sai"
    assert all_text.count('bấm để báo sai') == 1, all_text


def test_w11_report_and_approve(browser):
    """FL-4 + FL-4b: báo sai thiếu lý do bị chặn; gửi; giảng viên duyệt; web đổi ngay."""
    s = open_student(browser)
    tap(s, 'PRM393 SE1801')
    tap(s, 'bấm để báo sai')
    wait_text(s, 'Quên quét mã')
    tap(s, 'Gửi', exact=True)
    s.wait_for_timeout(800)
    shot(s, 'w11_thieu_ly_do')
    assert 'Đã gửi' not in text_of(s)
    tap(s, 'Quên quét mã', exact=True)
    tap(s, 'Gửi', exact=True)
    wait_text(s, 'Đã gửi')
    shot(s, 'w11_da_gui')
    tap(s, 'Xong', exact=True)

    p = open_lecturer(browser)
    wait_text(p, '4 yêu cầu sửa')
    tap(p, 'yêu cầu sửa')
    wait_text(p, 'Thứ Tư, 07/10')
    shot(p, 'w11_gv_yeu_cau')
    # Duyệt đúng yêu cầu vừa gửi (thẻ cuối, buổi 07/10)
    tap(p, 'Duyệt', exact=True, nth=3)
    wait_text(p, 'Đã duyệt')
    shot(p, 'w11_gv_da_duyet')

    tap(s, 'PRM393 SE1801')
    wait_text(s, 'Thứ Tư, 07/10, có mặt')
    wait_text(s, 'Vắng 2 trên 4')
    shot(s, 'w11_sv_sau_duyet')


def test_w12_reject_with_reason(browser):
    """FL-4b từ chối: phải chọn lý do; sinh viên thấy bị từ chối, không báo lại được."""
    p = open_lecturer(browser)
    tap(p, 'yêu cầu sửa')
    wait_text(p, 'Huỳnh Anh Dung')
    tap(p, 'Từ chối', exact=True, nth=0)
    wait_text(p, 'Gửi từ chối')
    shot(p, 'w12_tu_choi')
    tap(p, 'Không có mặt', exact=True)
    tap(p, 'Gửi từ chối', exact=True)
    wait_text(p, 'Đã từ chối')
    shot(p, 'w12_da_tu_choi')
    s = open_student(browser)
    tap(s, 'PRM393 SE1801')
    wait_text(s, 'Thứ Tư, 28/10, vắng')
    shot(s, 'w12_sv_bi_tu_choi')
    row = re.search(r'Thứ Tư, 28/10, vắng[^\n]*', text_of(s)).group(0)
    assert 'từ chối' in row.lower(), row


def test_w13_student_account_logout(browser):
    s = open_student(browser)
    tap(s, 'mở tài khoản', dx=-50)
    wait_text(s, 'Đăng xuất')
    shot(s, 'w13_sv_tai_khoan')
    tap(s, 'Đăng xuất', exact=True)
    s.wait_for_timeout(800)
    if 'Hủy' in text_of(s):
        tap(s, 'Đăng xuất', exact=True, nth=0)
    wait_text(s, 'Đăng nhập với Google')
