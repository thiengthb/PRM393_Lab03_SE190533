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
    rows = re.findall(r'^((?:Thứ [^,\n]*|Chủ nhật), \d\d/\d\d), (có mặt|vắng)', all_text, re.M)
    assert [r[1] for r in rows].count('vắng') == int(m.group(1)), rows
    # Buổi bị từ chối không báo lại được: chỉ một hàng có "bấm để báo sai"
    assert all_text.count('bấm để báo sai') == 1, all_text


def test_w11_report_and_approve(browser):
    """FL-4 + FL-4b: báo sai thiếu lý do bị chặn; gửi; giảng viên duyệt; web đổi ngay."""
    s = open_student(browser)
    tap(s, 'PRM393 SE1801')
    wait_text(s, 'Buổi học')
    # Ngày của buổi vắng chưa báo đổi theo ngày chạy seed: đọc từ màn.
    day = re.search(r'^((?:Thứ [^,\n]*|Chủ nhật), \d\d/\d\d), vắng, bấm để báo sai', scroll_text(s), re.M).group(1)
    tap(s, 'bấm để báo sai')
    wait_text(s, 'Quên quét mã')
    shot(s, 'w11_sv_bao_sai')
    tap(s, 'Gửi', exact=True)
    s.wait_for_timeout(800)
    assert 'Đã gửi' not in text_of(s)
    tap(s, 'Quên quét mã', exact=True)
    tap(s, 'Gửi', exact=True)
    wait_text(s, 'Đã gửi')
    shot(s, 'w11_sv_da_gui')
    tap(s, 'Xong', exact=True)

    p = open_lecturer(browser)
    wait_text(p, '4 yêu cầu sửa')
    tap(p, 'yêu cầu sửa')
    wait_text(p, f'PRM393 · {day} · Slot')
    # Duyệt đúng thẻ vừa gửi: thẻ của Huỳnh Anh Dung có buổi `day`
    cards = re.findall(r'^([^\n]+)\nVắng\nPRM393 · ([^·\n]+) · Slot', text_of(p), re.M)
    i = next(k for k, (name, d) in enumerate(cards) if name == 'Huỳnh Anh Dung' and d.strip() == day)
    shot(p, 'w11_gv_yeu_cau')
    tap(p, 'Duyệt', exact=True, nth=i)
    wait_text(p, 'Đã duyệt')
    shot(p, 'w11_gv_da_duyet')

    tap(s, 'PRM393 SE1801')
    wait_text(s, f'{day}, có mặt')
    wait_text(s, 'Vắng 2 trên 4')
    shot(s, 'w11_sv_sau_duyet')


def test_w12_reject_with_reason(browser):
    """FL-4b từ chối: phải chọn lý do; sinh viên thấy bị từ chối, không báo lại được."""
    p = open_lecturer(browser)
    tap(p, 'yêu cầu sửa')
    wait_text(p, 'Huỳnh Anh Dung')
    # Thẻ đầu tiên là yêu cầu đang chờ của Huỳnh Anh Dung; ngày đọc từ màn (đổi theo ngày chạy seed).
    first = re.search(r'^([^\n]+)\nVắng\nPRM393 · ([^·\n]+) · Slot', text_of(p), re.M)
    assert first and first.group(1) == 'Huỳnh Anh Dung', text_of(p)[:600]
    day = first.group(2).strip()
    tap(p, 'Từ chối', exact=True, nth=0)
    wait_text(p, 'Gửi từ chối')
    tap(p, 'Không có mặt', exact=True)
    shot(p, 'w12_gv_tu_choi')
    tap(p, 'Gửi từ chối', exact=True)
    wait_text(p, 'Đã từ chối')
    s = open_student(browser)
    tap(s, 'PRM393 SE1801')
    wait_text(s, f'{day}, vắng')
    row = re.search(re.escape(day) + r', vắng[^\n]*', text_of(s)).group(0)
    assert 'từ chối' in row.lower(), row
    shot(s, 'w12_sv_bi_tu_choi')


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
