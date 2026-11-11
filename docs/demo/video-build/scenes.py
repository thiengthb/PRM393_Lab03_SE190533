import json, re
from pathlib import Path
from build import clip, img, slide, card, voice, dur, EV

MD = Path('/home/user/prm393_lab03_se190533/docs/demo/loi-thoai-video.md').read_text(encoding='utf-8')
lab_part, fin_part = MD.split('## Video Final')
def lines(part):
    return {int(m.group(1)): m.group(2).strip() for m in re.finditer(r'^(\d+)\. (.+)$', part, re.M)}
L, F = lines(lab_part), lines(fin_part)
NEW = json.loads(Path('/mnt/project-files/video-attendo/voice-v2.json').read_text(encoding='utf-8'))

def v(name, off):
    """(offset, mp3, subtitle) for an original line (lab3-07) or a new one (lab3-06b)."""
    if name in NEW:
        return (off, voice(name), NEW[name])
    deck, n = name.split('-')
    return (off, voice(name), (L if deck == 'lab3' else F)[int(n)])

def after(prev, gap=0.6):
    off, p, _ = prev
    return off + dur(p) + gap

REAL = 'Quay thật · Firebase thật · '
SLIDE = 'Slide thuyết trình'
FAP_CROP = (1308, 1000, 22, 12)
FAP_BLUR = [(495, 650, 230, 38, 0, 32), (1238, 72, 36, 38, 0, 999)]
F09_BLUR = [(1420, 740, 500, 280, 37, 46)]

_v14 = v('lab3-14b', 0.5)
LAB3 = [
    dict(title='Giới thiệu', badge=SLIDE, video=[slide('lab3', i, 4) for i in range(1, 6)], voices=[v('lab3-01', 0.5)]),
    dict(video=[card('CẢNH 2 CHƯA QUAY\nĐăng nhập bằng Google trên điện thoại\nQuay thêm rồi thay vào chỗ này', 5)]),
    dict(title='Mở phiên điểm danh', badge=REAL + '11/11/2026 13:01', video=[clip('lab3-03', 0, 30)], voices=[v('lab3-03', 12)]),
    dict(title='Sinh viên nhập mã', badge=REAL + '11/11/2026 13:02', video=[clip('lab3-04-05', 0, 45)],
         voices=[v('lab3-04', 1), v('lab3-05', 29)]),
    dict(title='Firestore', badge='Ảnh chụp console · 10/11/2026', video=[slide('lab3', 7, 4), img(EV / 'firestore/01-classes.png', 6)],
         voices=[v('lab3-06b', 0.5)]),
    dict(title='Đóng mã và chốt', badge=REAL + '11/11/2026 13:04', video=[clip('lab3-07', 0, 50)], voices=[v('lab3-07', 10)]),
    dict(title='Analytics', badge='Ảnh chụp DebugView · 10/11/2026', video=[img(EV / 'analytics/03-attendance-close.png', 9)],
         voices=[v('lab3-08b', 0.5)]),
    dict(title='Báo sai và duyệt', badge=REAL + '11/11/2026 13:06', video=[clip('lab3-09-11', 0, 42), clip('lab3-09-11', 66, 100)],
         voices=[v('lab3-09', 2), v('lab3-10', 51)]),
    dict(title='Cloud Messaging', badge='Ảnh chụp trên điện thoại · 11/11/2026',
         video=[slide('lab3', 8, 4), img(EV / 'fcm/01-app-dang-mo.png', 4), img(EV / 'fcm/02-app-o-nen-banner.png', 4), img(EV / 'fcm/04-app-da-tat.png', 5)],
         voices=[v('lab3-12b', 0.5)]),
    dict(title='Crashlytics', badge='Ảnh chụp web admin · 11/11/2026', video=[img(EV / 'crashlytics/02-web-admin-test-crash.png', 10)],
         voices=[_v14, v('lab3-15', after(_v14))]),
    dict(badge='Ảnh chụp Crashlytics console · 09/11/2026', video=[img(EV / 'crashlytics/03-crashlytics-console.png', 5)], voices=[v('lab3-16b', 0.5)]),
    dict(title='Remote Config', badge='Ảnh chụp · 10/11/2026',
         video=[img(EV / 'remote-config/03-console-published.png', 4), img(EV / 'remote-config/04-after-khudemo.png', 4), img(EV / 'remote-config/06-session-15s.png', 4)],
         voices=[v('lab3-17b', 0.5)]),
    dict(title='Xuất PDF lên Cloudinary', badge=REAL + '11/11/2026 13:10', video=[clip('lab3-18', 10, 45)], voices=[v('lab3-18', 10)]),
    dict(title='ARTEMIS', badge='Slide · số liệu từ evidence/artemis/results.md', video=[slide('lab3', 13, 10)], voices=[v('lab3-19', 0.5)]),
    dict(title='AI code review', badge=SLIDE, video=[slide('lab3', 14, 10)], voices=[v('lab3-20', 0.5)]),
    dict(badge=SLIDE, video=[slide('lab3', 15, 7)], voices=[v('lab3-21', 0.5)]),
]

FINAL = [
    dict(title='Bối cảnh và actor', badge=SLIDE, video=[slide('final', i, 7) for i in (1, 2, 3)], voices=[v('final-01', 0.5)]),
    dict(title='Kiến trúc', badge=SLIDE, video=[slide('final', i, 4) for i in (4, 5, 6, 7)], voices=[v('final-02', 0.5)]),
    dict(badge=SLIDE, video=[slide('final', 8, 4), slide('final', 10, 4)], voices=[v('final-03', 0.5)]),
    dict(title='WF-01 · Mở phiên trên điện thoại', badge=REAL + '11/11/2026 18:03', video=[clip('final-04-05', 0, 20)], voices=[v('final-04', 1)]),
    dict(title='Cùng phiên trên Windows', badge=REAL + '11/11/2026 18:03', video=[clip('final-04-05', 20, 50)], voices=[v('final-05', 12)]),
    dict(title='Chiếu lên TV', badge=REAL + '11/11/2026 18:04', video=[clip('final-06', 10, 60)], voices=[v('final-06', 35)]),
    dict(video=[card('CẢNH 7 CHƯA QUAY\nSinh viên quét mã QR trên TV bằng điện thoại\nQuay thêm rồi thay vào chỗ này', 5)]),
    dict(title='Nhập mã 6 số', badge=REAL + '11/11/2026 18:06', video=[clip('final-08', 0, 65)], voices=[v('final-08', 26)]),
    dict(title='Đóng mã và chốt', badge=REAL + '11/11/2026 18:07', video=[clip('final-09', 0, 50, blur=F09_BLUR)], voices=[v('final-09', 10)]),
    dict(title='Extension FAP · sai ngày', badge=REAL + 'FAP giả lập · 11/11/2026 23:59',
         video=[clip('final-fap-fill', 0, 16, crop=FAP_CROP, blur=FAP_BLUR)], voices=[v('final-11b', 1)]),
    dict(title='Extension FAP · điền bản đã chốt', badge='Quay thật · buổi SE1802 ngày 09/11 · quay 11/11/2026 23:59',
         video=[clip('final-fap-fill', 16, 60, crop=FAP_CROP, blur=FAP_BLUR)], voices=[v('final-10b', 1)]),
    dict(title='WF-02 · Báo sai', badge=REAL + '11/11/2026 13:06', video=[clip('lab3-09-11', 0, 42), clip('lab3-09-11', 66, 100)],
         voices=[v('final-12b', 2)]),
    dict(title='WF-03 · Duyệt lớp liên vai trò', badge=REAL + '11/11/2026 23:24', video=[clip('final-13-14', 10, 80)],
         voices=[v('final-13', 26), v('final-14', 42)]),
    dict(video=[card('CẢNH 15 CHƯA QUAY\nLướt web admin: Tổng quan, Môn học, Thông báo, Người dùng, Sự cố\nQuay thêm rồi thay vào chỗ này', 5)]),
    dict(title='WF-04 · Nhắc sinh viên, có AI', badge=REAL + '11/11/2026 13:08', video=[clip('final-16-17', 10, 82)],
         voices=[v('final-16', 38), v('final-17b', 52)]),
    dict(video=[card('CẢNH 18-19 CHƯA QUAY\nTắt Gợi ý AI bằng Remote Config rồi bật lại\nQuay thêm rồi thay vào chỗ này', 5)]),
    dict(title='Chạy test Security Rules', badge='Chạy thật trên Emulator · 11/11/2026 23:10',
         video=[clip('final-20-take3', 26, 90, crop=(1475, 750, 195, 200))], voices=[v('final-20', 2)]),
    dict(title='Bằng chứng kiểm thử', badge=SLIDE, video=[slide('final', 14, 10)], voices=[v('final-21', 0.5)]),
    dict(badge=SLIDE, video=[slide('final', 15, 8)], voices=[v('final-22', 0.5)]),
]
