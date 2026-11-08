"""Đi đúng thứ tự tài liệu test tay (docs/demo/HUONG-DAN.md), trên dữ liệu demo (--demo), mỗi bước một ảnh.

Bản web giảng viên đứng thay app Android (cùng mã mobile/); khung laptop đứng thay app Windows.
Phần chỉ làm được trên máy thật (camera, chế độ máy bay, FCM, Crashlytics, chọn file Android) có ca riêng ở
tài liệu và không nằm ở đây.
"""
import re
import time

from flows_common import *
from test_extension import fill_fap_with_extension

DUNG = 'dung101@fpt.edu.vn'
# Cửa sổ Chrome nửa màn hình laptop (Windows + mũi tên trái): dưới 900 px nên web sinh viên hiện bố cục điện thoại,
# có nút Quét mã. Cửa sổ rộng chỉ hiện gợi ý "Quét mã trên điện thoại".
HALF_LAPTOP = {'width': 683, 'height': 768}
TIEN = 'tien102@fpt.edu.vn'


def _student(browser, email, viewport=PHONE):
    s = browser.page('student', viewport=viewport)
    login(s, email)
    wait_text(s, 'Môn học', 30000)
    return s


def _top(p):
    """Cuộn về đầu màn: Flutter chỉ đưa vào cây semantics phần đang thấy."""
    vw = p.viewport_size['width']
    p.mouse.move(vw / 2, 300)
    p.mouse.wheel(0, -6000)
    p.wait_for_timeout(500)


def _code(p):
    return re.search(r'Mã số ([\d ]+)', text_of(p)).group(1).replace(' ', '')


def _enter_code(s, code_of):
    tap(s, 'Quét mã', exact=True)
    tap(s, 'Nhập mã', exact=True)
    s.wait_for_timeout(800)
    s.keyboard.type(code_of(), delay=30)
    tap(s, 'Gửi', exact=True)


def test_w70_part_a_lecturer_session(browser):
    """L2-L9: tổng quan, mở phiên, mã số, TV, đóng mã, bật tay, chốt, hoàn tác, extension, quên chốt, mất mạng, sửa."""
    slot_no = int(re.search(r'Slot đang diễn ra: (\d)', reseed('--demo')).group(1))

    # L2
    p = browser.page('lecturer')
    login(p, LECTURER)
    wait_text(p, 'Đang diễn ra: PRM393 · SE1801', 30000)
    t = text_of(p)
    assert '3 yêu cầu sửa' in t and '2 slot chưa chốt' in t, t[:800]
    shot(p, 'l2_tong_quan')

    # L3
    tap(p, 'Đang diễn ra')
    wait_text(p, 'Mã số')
    wait_text(p, '24 trên 35 đã có mặt')
    shot(p, 'l3_phien_mo')
    s = _student(browser, DUNG, viewport=HALF_LAPTOP)
    _enter_code(s, lambda: '000000')
    wait_text(s, 'Mã không đúng hoặc đã hết hạn')
    shot(s, 'l3_sv_ma_sai')
    tap(s, 'Nhập lại', exact=True)
    s.wait_for_timeout(800)
    wait_text(p, 'Mã số')
    s.keyboard.type(_code(p), delay=30)
    tap(s, 'Gửi', exact=True)
    wait_text(s, 'Đã ghi nhận')
    shot(s, 'l3_sv_da_ghi_nhan')
    wait_text(p, '25 trên 35 đã có mặt')

    # L4: chỉ MỘT máy giảng viên giữ màn phiên (máy đang mở màn phiên là máy đổi mã). Điện thoại quay về Tổng quan,
    # laptop (thay app Windows) mở phiên, chiếu TV; sinh viên 2 vào bằng mã (camera không có ở đây)
    tap(p, 'Quay lại')
    wait_text(p, 'Tổng quan')
    w = browser.page('lecturer', viewport=LAPTOP)
    login(w, LECTURER)
    wait_text(w, 'Đang diễn ra', 30000)
    tap(w, 'Đang diễn ra')
    wait_text(w, '25 trên 35 đã có mặt')
    shot(w, 'l4_laptop_phien')
    tap(w, 'Chiếu lên TV')
    tap(w, 'Chép link')
    link = w.evaluate('navigator.clipboard.readText()')
    assert re.match(r'https://hereby-se190533\.web\.app/tv/[A-Z0-9]{10}$', link), link
    w.keyboard.press('Escape')
    tv = browser.page('lecturer', viewport={'width': 1280, 'height': 720}, path='/tv/' + link.split('/tv/')[1])
    tv.wait_for_timeout(2500)
    shot(tv, 'l4_tv')
    s2 = _student(browser, TIEN)
    shot(s2, 'l4_sv2_tong_quan')
    _enter_code(s2, lambda: _code(w))
    wait_text(s2, 'Đã ghi nhận')
    wait_text(w, '26 trên 35 đã có mặt')
    tv.wait_for_timeout(1500)
    shot(tv, 'l4_tv_26')
    # Trả màn phiên về điện thoại
    tap(w, 'Quay lại')
    wait_text(w, 'Tổng quan')
    tap(p, 'Đang diễn ra')
    _top(p)
    wait_text(p, '26 trên 35 đã có mặt')

    # L5
    tap(p, 'Đóng mã', exact=True)
    wait_text(p, 'Mở lại mã')
    tv.wait_for_timeout(2000)
    shot(tv, 'l5_tv_dong_ma')
    tap(p, 'Mở lại mã', dx=-60)
    wait_text(p, 'Mã số')
    tap(p, 'Đóng mã', exact=True)
    wait_text(p, 'Mở lại mã')
    shot(p, 'l5_da_dong_ma')
    tap(p, 'Có mặt Vũ Thu Tiến')
    _top(p)
    wait_text(p, '27 trên 35 đã có mặt')
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Đã chốt')
    shot(p, 'l5_da_chot')
    tap(p, 'Hoàn tác', exact=True)
    wait_text(p, 'Mở lại mã')
    _top(p)
    wait_text(p, '27 trên 35 đã có mặt')
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Đã chốt')
    tap(p, 'Xong', exact=True)
    wait_text(p, 'Tổng quan')

    # L6
    saved, mismatch = fill_fap_with_extension(browser, slot_no, 27, shots_prefix='l6')
    assert 'không khớp' in mismatch.lower(), mismatch[:600]
    print('FAP sau khi Save:', saved)

    # L7
    tap(p, '2 slot chưa chốt', dx=-40)
    wait_text(p, 'Slot chưa chốt')
    t = text_of(p)
    assert 'SE1802' in t and 'SE1810' in t, t[:600]
    shot(p, 'l7_ds_chua_chot')
    tap(p, 'Chốt ngay', nth=0)
    wait_text(p, 'Chốt')
    assert 'Mã số' not in text_of(p)
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Đã chốt')
    tap(p, 'Xong', exact=True)
    p.wait_for_timeout(1500)
    if 'Quay lại' in text_of(p):
        tap(p, 'Quay lại')
    # Còn một slot: Tổng quan hiện thẳng thẻ "... chưa chốt" có nút Chốt ngay thay cho dòng "n slot chưa chốt"
    wait_text(p, 'chưa chốt')
    assert 'slot chưa chốt' not in text_of(p) and 'Chốt ngay' in text_of(p), text_of(p)[:800]
    shot(p, 'l7_con_1')

    # L8 (web: tắt mạng của trình duyệt thay cho chế độ máy bay)
    tap(p, 'Chốt ngay', nth=0)
    wait_text(p, 'Chốt')
    p.context.set_offline(True)
    tap(p, 'Chốt', exact=True)
    # Danh sách dài (slot cũ, chưa ai quét) nên màn đã cuộn xuống; dải vàng nằm ở đầu màn.
    p.wait_for_timeout(10000)
    _top(p)
    wait_text(p, 'Chưa gửi được', 20000)
    assert 'Đã lưu trên máy' in text_of(p)
    shot(p, 'l8_mat_mang')
    p.context.set_offline(False)
    for _ in range(6):
        if 'Thử lại' in text_of(p):
            try:
                tap(p, 'Thử lại', timeout=2000)
            except AssertionError:
                pass
        if has(p, 'Đã chốt', 12000):
            break
    wait_text(p, 'Đã chốt')
    tap(p, 'Xong', exact=True)
    p.wait_for_timeout(1500)
    if 'Quay lại' in text_of(p):
        tap(p, 'Quay lại')
    wait_text(p, 'Tổng quan')
    p.wait_for_timeout(1500)
    assert 'chưa chốt' not in text_of(p), text_of(p)[:600]
    shot(p, 'l8_het_chua_chot')

    # L9
    tap(p, 'Lớp', exact=True)
    tap(p, 'PRM393 · SE1801, 35 sinh viên')
    tap(p, 'Buổi học', exact=True)
    wait_text(p, '27 trên 35')
    m = re.search(r'^((?:Thứ [^,\n]+|Chủ nhật), \d\d/\d\d)\nSlot \d · [^\n]+\n27 trên 35$', text_of(p), re.M)
    assert m, text_of(p)[:600]
    tap(p, m.group(1))
    p.wait_for_timeout(1500)
    assert '27 trên 35 đã có mặt' in text_of(p), text_of(p)[:600]
    shot(p, 'l9_sua_buoi')
    tap(p, 'Có mặt 27', dx=-30)
    tap(p, 'Có mặt Vũ Thu Tiến')
    _top(p)
    wait_text(p, '26 trên 35 đã có mặt')
    tap(p, 'Chốt', exact=True)
    wait_text(p, 'Đã chốt')
