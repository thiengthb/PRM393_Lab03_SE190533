# Debug W70: lecturer phone leaves the session, laptop opens it; prints the slot doc and whether
# the 6-digit code shows each second. Needs the emulator + serve.py from e2e_web/README.md.
# Run: python3 -I tool/e2e/debug_takeover.py
import sys, time, re
import os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'e2e_web'))
from harness import *
from playwright.sync_api import sync_playwright
reseed('--demo')
if True:
    b = Browser()
    p = b.page('lecturer')
    login(p, LECTURER); wait_text(p, 'Đang diễn ra', 30000)
    tap(p, 'Đang diễn ra'); wait_text(p, 'Mã số')
    tap(p, 'Quay lại'); wait_text(p, 'Tổng quan')
    w = b.page('lecturer', viewport=LAPTOP)
    logs = []
    w.on('console', lambda m: logs.append(m.text))
    login(w, LECTURER); wait_text(w, 'Đang diễn ra', 30000)
    import json, urllib.request
    def slots():
        url='http://127.0.0.1:8080/v1/projects/attendo-app-2611/databases/(default)/documents/slots?pageSize=300'
        req=urllib.request.Request(url, headers={'Authorization':'Bearer owner'})
        docs=json.load(urllib.request.urlopen(req)).get('documents',[])
        out=[]
        for d in docs:
            f=d['fields']
            if f.get('qrOpen',{}).get('booleanValue'):
                out.append((f.get('qrToken',{}).get('stringValue'), f.get('qrLeaseUntil',{}).get('timestampValue'), f.get('qrExpiresAt',{}).get('timestampValue')))
        return out
    print('before tap', time.strftime('%H:%M:%S'), slots())
    tap(w, 'Đang diễn ra')
    for i in range(12):
        time.sleep(1)
        print('  t+%d'%i, time.strftime('%H:%M:%S'), slots(), 'code' if re.search(r'Mã số [\d ]+', text_of(w)) else '-')
    for i in range(2):
        time.sleep(3)
        t = text_of(w)
        m = re.search(r'Mã số ([\d ]+)', t)
        if i == 0: print('TEXT0:', t[:900].replace('\n',' | '))
        print(i, round(time.time()%100,1), 'code:', m.group(1) if m else None, '| follower' if 'đang đổi mã' in t or 'máy' in t else '')
    print('\n'.join(l[:400] for l in logs if 'gstatic' not in l and 'Noto' not in l)[:6000])
