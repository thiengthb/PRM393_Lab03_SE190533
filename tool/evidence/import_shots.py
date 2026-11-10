#!/usr/bin/env python3
"""Copy screenshots from an inbox folder into evidence/<area>/ and blur personal Gmail addresses.

  python3 tool/evidence/import_shots.py <inbox-dir>

File names follow docs/manual-test/lab3-evidence.md: "<area>-NN-<what>.png" goes to evidence/<area>/NN-<what>.png
(area: auth, firestore, analytics, remote-config, storage, ...). The repo is public, so every word OCR reads as
a @gmail.com address is covered with a solid box before the copy is written. Prints every box so a person can
check each result by eye before committing: OCR can miss an address, and a missed address stays visible.
"""
import re
import sys
from pathlib import Path

import pytesseract
from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[2]
NAME = re.compile(r'^(auth|firestore|analytics|remote-config|storage|fcm|crashlytics|artemis|code-review|web)-(\d\d-.+\.png)$')
GMAIL = re.compile(r'@gmail|gmail\.com|tranngocthien', re.I)


def blur_gmail(img: Image.Image) -> int:
    """Cover every Gmail address with an opaque box. OCR may split "name@gmail.com" into several words, so the
    box spans the whole run of touching words on the same line, not just the word that matched."""
    big = img.convert('RGB')
    scale = 2 if big.width < 2000 else 1
    ocr_src = big.resize((big.width * scale, big.height * scale)) if scale > 1 else big
    data = pytesseract.image_to_data(ocr_src, output_type=pytesseract.Output.DICT)
    words = [
        {'text': t, 'line': (data['block_num'][i], data['par_num'][i], data['line_num'][i]),
         **{k: data[k][i] // scale for k in ('left', 'top', 'width', 'height')}}
        for i, t in enumerate(data['text']) if t and t.strip()
    ]
    draw = ImageDraw.Draw(img)
    hits = 0
    for i, w in enumerate(words):
        if not GMAIL.search(w['text']):
            continue
        first = last = i
        # Extend over neighbours on the same line that sit closer than a quarter of the text height (closer than a space): the user name
        # before "@gmail.com", or the domain after a matched user name.
        while first > 0 and words[first - 1]['line'] == w['line'] and \
                w_gap(words[first - 1], words[first]) < words[first]['height'] // 4:
            first -= 1
        while last + 1 < len(words) and words[last + 1]['line'] == w['line'] and \
                w_gap(words[last], words[last + 1]) < words[last]['height'] // 4:
            last += 1
        # A match that starts at "@" or "gmail" has no user name; take the previous word on the line as well,
        # even across a space, since OCR often splits an address there.
        if re.match(r'@|gmail', words[first]['text'], re.I) and first > 0 and words[first - 1]['line'] == w['line'] \
                and w_gap(words[first - 1], words[first]) < 2 * words[first]['height']:
            first -= 1
        run = words[first:last + 1]
        x0 = min(r['left'] for r in run)
        y0 = min(r['top'] for r in run)
        x1 = max(r['left'] + r['width'] for r in run)
        y1 = max(r['top'] + r['height'] for r in run)
        box = (max(0, x0 - 6), max(0, y0 - 4), min(img.width, x1 + 6), min(img.height, y1 + 4))
        draw.rectangle(box, fill=(128, 128, 128))
        print(f'  covered {box}')
        hits += 1
    return hits


def w_gap(a: dict, b: dict) -> int:
    return b['left'] - (a['left'] + a['width'])

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
        print(f'{src.name} -> {dest.relative_to(REPO)} (covered {hits}) - check it by eye before committing')


if __name__ == '__main__':
    main()
