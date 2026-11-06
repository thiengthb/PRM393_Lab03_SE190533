"""Sinh icon app Attendo (Android, Windows, web) và SVG biểu tượng từ một hình học duy nhất.

Biểu tượng: ô bo góc 15/64 màu thương hiệu #308E84, vòng trắng bán kính 16/64 nét 8/64, chấm
giữa bán kính 5,5/64 (cùng hình với BrandMark trong packages/core/lib/widgets/brand.dart).
Chạy từ gốc repo: python3 tool/brand/gen_icons.py   (cần Pillow)
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
BRAND = (0x30, 0x8E, 0x84, 255)
WHITE = (255, 255, 255, 255)
SS = 8  # vẽ to gấp 8 rồi thu nhỏ cho mép mịn


def mark(size, full_bleed=False):
    s = size * SS
    u = s / 64
    im = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if full_bleed:
        d.rectangle([0, 0, s, s], fill=BRAND)
    else:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=15 * u, fill=BRAND)
    c = 32 * u
    r_out, r_in = (16 + 4) * u, (16 - 4) * u
    d.ellipse([c - r_out, c - r_out, c + r_out, c + r_out], fill=WHITE)
    d.ellipse([c - r_in, c - r_in, c + r_in, c + r_in], fill=BRAND)
    dot = 5.5 * u
    d.ellipse([c - dot, c - dot, c + dot, c + dot], fill=WHITE)
    return im.resize((size, size), Image.LANCZOS)


def save(img, rel, mode=None):
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    (img.convert(mode) if mode else img).save(p)
    print(rel)


for folder, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    save(mark(px), f'mobile/android/app/src/main/res/mipmap-{folder}/ic_launcher.png')

for app, fav in (('mobile', 16), ('web', 32)):
    save(mark(fav), f'{app}/web/favicon.png')
    for px in (192, 512):
        save(mark(px), f'{app}/web/icons/Icon-{px}.png')
        save(mark(px, full_bleed=True), f'{app}/web/icons/Icon-maskable-{px}.png', 'RGB')

ico = ROOT / 'mobile/windows/runner/resources/app_icon.ico'
mark(256).save(ico, sizes=[(n, n) for n in (16, 24, 32, 48, 64, 128, 256)])
print(ico.relative_to(ROOT))

svg = '''<svg width="64" height="64" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
<!-- Attendo: vòng có chấm giữa (“bạn ở đây”) trên ô bo góc màu thương hiệu. Sinh bởi tool/brand/gen_icons.py. -->
<rect width="64" height="64" rx="15" fill="#308E84"/>
<circle cx="32" cy="32" r="16" stroke="white" stroke-width="8"/>
<circle cx="32" cy="32" r="5.5" fill="white"/>
</svg>
'''
(ROOT / 'design/brand/attendo-app-icon.svg').write_text(svg)
print('design/brand/attendo-app-icon.svg')
