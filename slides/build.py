#!/usr/bin/env python3
"""Build the slide decks into slides/site/ (what GitHub Pages serves) and, with --pdf, export PDFs.

  python3 slides/build.py            # site/ only
  python3 slides/build.py --pdf      # + site/<deck>.pdf (needs: pip install playwright && playwright install chromium)
  python3 slides/build.py --check    # + check/<deck>-NN-<theme>.png and an overflow report

Each page in site/ is one HTML file with the CSS and JS inlined; fonts and images sit in site/assets/.
Copy the whole site/ folder to a USB stick and it runs offline.
"""
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC, SITE = ROOT / 'src', ROOT / 'site'
DECKS = [('lab3', 'Lab 3 · Công nghệ', 'Mỗi dịch vụ Firebase: là gì, chạy ở đâu, code ở file nào, bằng chứng.'),
         ('final', 'Final · Hệ thống', 'Theo guideline V11: vấn đề, thiết kế, demo theo workflow, bằng chứng.')]


def build():
    if SITE.exists():
        shutil.rmtree(SITE)
    shutil.copytree(ROOT / 'assets', SITE / 'assets')
    css = (SRC / 'deck.css').read_text(encoding='utf-8').replace('../assets/', 'assets/')
    js = (SRC / 'deck.js').read_text(encoding='utf-8')
    proofs = (SRC / 'proofs.js').read_text(encoding='utf-8')
    for name, _, _ in DECKS:
        html = (SRC / f'{name}.html').read_text(encoding='utf-8')
        html = html.replace('<link rel="stylesheet" href="deck.css">', f'<style>\n{css}</style>')
        html = html.replace('<script src="proofs.js"></script>', f'<script>\n{proofs}</script>')
        html = html.replace('<script src="deck.js"></script>', f'<script>\n{js}</script>')
        missing = [m for m in re.findall(r'src="(assets/[^"]+)"', html) if not (SITE / m).exists()]
        if missing:
            print(f'[{name}] thiếu ảnh: {", ".join(sorted(set(missing)))}')
        (SITE / f'{name}.html').write_text(html, encoding='utf-8')
    cards = ''.join(
        f'<a class="card" href="{n}.html"><p class="kicker">{t}</p><h3>{t.split(" · ")[1]}</h3><p>{d}</p>'
        f'<p class="sm" style="margin-top:14px"><span class="chip brand">Mở slide</span> <span class="chip" data-pdf="{n}.pdf">PDF</span></p></a>'
        for n, t, d in DECKS)
    index = f'''<!doctype html><html lang="vi" data-theme="light"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Attendo · Slide</title><style>{css}
body{{overflow:auto}} .wrap{{max-width:1100px;margin:0 auto;padding:72px 28px}} a.card{{display:block;text-decoration:none;color:inherit}}
a.card:hover{{border-color:var(--brand)}} .keys{{margin-top:40px}} .keys kbd{{font-family:var(--mono);background:var(--muted);border-radius:6px;padding:2px 8px;margin-right:6px}}</style></head>
<body><div class="wrap"><p class="kicker">PRM393 · Attendo</p><h2>Slide thuyết trình</h2>
<p class="lead">Mở bằng Chrome hoặc Edge, bấm F để toàn màn hình. Mọi con số có gạch chấm đều bấm được để xem nguồn.</p>
<div class="cols" style="margin-top:40px">{cards}</div>
<div class="keys sm"><kbd>→</kbd>tiếp <kbd>←</kbd>lùi <kbd>N</kbd>ghi chú <kbd>P</kbd>cửa sổ người nói <kbd>T</kbd>đồng hồ <kbd>K</kbd>soi bằng chứng <kbd>D</kbd>sáng/tối <kbd>O</kbd>tổng quan <kbd>F</kbd>toàn màn hình</div>
</div><script>document.querySelectorAll('[data-pdf]').forEach(e=>{{e.onclick=ev=>{{ev.preventDefault();location.href=e.dataset.pdf}}}})</script></body></html>'''
    (SITE / 'index.html').write_text(index, encoding='utf-8')
    (SITE / '.nojekyll').write_text('')
    print(f'site: {SITE}')


def browser_pass(pdf, check):
    from playwright.sync_api import sync_playwright
    out = ROOT / 'check'
    if check:
        shutil.rmtree(out, ignore_errors=True)
        out.mkdir()
    problems = []
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page(viewport={'width': 1600, 'height': 900})
        for name, _, _ in DECKS:
            url = (SITE / f'{name}.html').as_uri()
            if pdf:
                pg.goto(url)
                pg.evaluate('document.fonts.ready')
                pg.wait_for_timeout(500)
                pg.pdf(path=str(SITE / f'{name}.pdf'), width='1600px', height='900px', print_background=True)
                print(f'pdf: site/{name}.pdf')
            if check:
                for theme in ('light', 'dark'):
                    pg.goto(url + '#1')
                    pg.evaluate(f"localStorage.setItem('deck-theme','{theme}')")
                    pg.reload()
                    pg.evaluate('document.fonts.ready')
                    n = pg.evaluate("document.querySelectorAll('.slide').length")
                    for i in range(n):
                        pg.evaluate(f"location.hash='#{i + 1}'")
                        pg.evaluate("document.querySelectorAll('[data-step]').forEach(e=>e.classList.remove('hide')); document.querySelector('.hint')?.remove()")
                        pg.wait_for_timeout(250)
                        pg.screenshot(path=str(out / f'{name}-{i + 1:02d}-{theme}.png'))
                        if theme == 'light':
                            over = pg.evaluate('''() => { const s = document.querySelector('.slide.on'); const r = [];
                              const box = s.getBoundingClientRect();
                              s.querySelectorAll('h1,h2,h3,p,li,td,.card,.qa>div,.stat,.shot,.phone,.laptop,svg.dia').forEach(e => {
                                const b = e.getBoundingClientRect(); if (!b.width) return;
                                if (b.bottom > box.bottom - 50 || b.right > box.right - 40) r.push(e.tagName + ' ' + (e.textContent||'').trim().slice(0,40));
                                if (e.scrollHeight > e.clientHeight + 2 && /^(P|LI|TD|H3)$/.test(e.tagName)) r.push('cut: ' + (e.textContent||'').trim().slice(0,40));
                              }); return r; }''')
                            if over:
                                problems.append(f'{name} slide {i + 1}: ' + ' | '.join(over[:4]))
                pg.evaluate("localStorage.removeItem('deck-theme')")
        b.close()
    if check:
        print('Tràn hoặc sát mép:' if problems else 'Không thấy chỗ tràn.')
        for x in problems:
            print('  ' + x)


if __name__ == '__main__':
    build()
    if '--pdf' in sys.argv or '--check' in sys.argv:
        browser_pass('--pdf' in sys.argv, '--check' in sys.argv)
