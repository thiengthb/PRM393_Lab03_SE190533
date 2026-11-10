#!/usr/bin/env python3
"""Copy screenshots from an inbox folder into evidence/<area>/ and blur personal Gmail addresses.

  python3 tool/evidence/import_shots.py <inbox-dir>

File names follow docs/manual-test/lab3-evidence.md: "<area>-NN-<what>.png" goes to evidence/<area>/NN-<what>.png
(area: auth, firestore, analytics, remote-config, storage, ...). The repo is public, so every word OCR reads as
a @gmail.com address is covered with a solid box before the copy is written. Prints what it blurred so a
person can check the result by eye.
"""
import re
import sys
from pathlib import Path

import pytesseract
from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parents[2]
NAME = re.compile(r'^(auth|firestore|analytics|remote-config|storage|fcm|crashlytics|artemis|code-review|web)-(\d\d-.+\.png)$')
GMAIL = re.compile(r'@gmail|gmail\.com|tranngocthien', re.I)


def blur_gmail(img: Image.Image) -> int:
    big = img.convert('RGB')
    scale = 2 if big.width < 2000 else 1
    ocr_src = big.resize((big.width * scale, big.height * scale)) if scale > 1 else big
    data = pytesseract.image_to_data(ocr_src, output_type=pytesseract.Output.DICT)
    draw = ImageDraw.Draw(img)
    hits = 0
    for i, word in enumerate(data['text']):
        if word and GMAIL.search(word):
            x, y, w, h = (data[k][i] // scale for k in ('left', 'top', 'width', 'height'))
            box = (max(0, x - 120), max(0, y - 4), x + w + 6, y + h + 4)
            region = img.crop(box).filter(ImageFilter.GaussianBlur(8))
            img.paste(region, box)
            draw.rectangle(box, outline=(200, 200, 200))
            hits += 1
    return hits


def main():
    inbox = Path(sys.argv[1])
    for src in sorted(inbox.glob('*.png')):
        m = NAME.match(src.name)
        if not m:
            print(f'skip (name): {src.name}')
            continue
        dest = REPO / 'evidence' / m.group(1) / m.group(2)
        dest.parent.mkdir(parents=True, exist_ok=True)
        img = Image.open(src)
        hits = blur_gmail(img)
        img.save(dest)
        print(f'{src.name} -> {dest.relative_to(REPO)} (blurred {hits})')


if __name__ == '__main__':
    main()
