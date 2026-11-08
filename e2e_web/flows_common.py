"""Bước dùng chung cho nhiều test."""
import json
import time
import urllib.request

from harness import *


def signup_lecturer(browser, name='Trần Thị Lan'):
    email = f'lan{int(time.time() * 1000) % 10**8}@fe.edu.vn'
    p = browser.page('lecturer')
    wait_text(p, 'Đăng ký', 30000)
    tap(p, 'Đăng ký', exact=True)
    wait_text(p, 'Tạo tài khoản')
    fill(p, 0, name)
    fill(p, 1, email)
    fill(p, 2, PASSWORD)
    tap(p, 'Tạo tài khoản', exact=True)
    wait_text(p, 'Xác nhận email')
    codes = json.load(urllib.request.urlopen('http://127.0.0.1:9099/emulator/v1/projects/attendo-app-2611/oobCodes'))
    link = [c for c in codes['oobCodes'] if c['email'] == email][-1]['oobLink']
    urllib.request.urlopen(link.replace('localhost', '127.0.0.1')).read()
    tap(p, 'Xác nhận', exact=True)
    wait_text(p, 'Nhập lớp ngay')
    return p, email


def import_sample(p, file='lop-fall-2026.csv'):
    with p.expect_file_chooser() as fc:
        tap(p, 'Chọn file')
    fc.value.set_files(str(REPO / 'mobile' / 'sample-data' / file))
    p.wait_for_timeout(1500)
