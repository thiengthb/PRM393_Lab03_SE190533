#!/usr/bin/env python3
"""Build a report PDF from Markdown: pandoc turns report/<name>/report.md into HTML, headless
Chrome prints it to report/<Out>.pdf.

  python3 report/build.py lab3     # -> report/Lab03_SE190533.pdf
  python3 report/build.py final    # -> report/Final_SE190533.pdf

Needs pandoc and Google Chrome (or Chromium) on PATH.
"""
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = {'lab3': 'Lab03_SE190533.pdf', 'final': 'Final_SE190533.pdf'}

CSS = """
@font-face { font-family: Onest; src: url('../../slides/assets/fonts/onest-regular.woff2'); font-weight: 400; }
@font-face { font-family: Onest; src: url('../../slides/assets/fonts/onest-semibold.woff2'); font-weight: 600; }
@font-face { font-family: Onest; src: url('../../slides/assets/fonts/onest-bold.woff2'); font-weight: 700; }
@page { size: A4; margin: 18mm 16mm 18mm 16mm; }
body { font-family: Onest, sans-serif; font-size: 10.5pt; line-height: 1.5; color: #1f2430; }
header#title-block-header { border-bottom: 3px solid #1D4ED8; margin-bottom: 18px; padding-bottom: 10px; }
h1.title { font-size: 24pt; margin: 0; color: #1D4ED8; }
p.subtitle { font-size: 13pt; margin: 4px 0; }
p.author, p.date { margin: 2px 0; color: #4b5565; }
h1 { font-size: 15pt; color: #1D4ED8; margin-top: 22px; border-bottom: 1px solid #dbe0e8; padding-bottom: 3px; break-after: avoid; }
h2 { font-size: 12pt; margin-top: 14px; break-after: avoid; }
table { border-collapse: collapse; width: 100%; margin: 8px 0; font-size: 9.5pt; break-inside: avoid; }
th, td { border: 1px solid #dbe0e8; padding: 4px 6px; vertical-align: top; text-align: left; }
th { background: #eef2fb; }
code { font-family: 'IBM Plex Mono', monospace; font-size: 9pt; background: #f2f4f8; padding: 0 3px; border-radius: 3px; }
figure { margin: 8px 0; text-align: center; break-inside: avoid; display: inline-block; vertical-align: top; }
figure img { max-width: 100%; border: 1px solid #dbe0e8; border-radius: 6px; }
figcaption { font-size: 8.5pt; color: #4b5565; }
strong { color: #111827; }
"""


def main():
    name = sys.argv[1] if len(sys.argv) > 1 else 'lab3'
    src = ROOT / name / 'report.md'
    html = ROOT / name / 'report.html'
    (ROOT / name / 'report.css').write_text(CSS, encoding='utf-8')
    subprocess.run(['pandoc', str(src), '-s', '--from', 'markdown+implicit_figures', '--css', 'report.css',
                    '--metadata', 'pagetitle=' + name, '-o', str(html)], check=True)
    chrome = shutil.which('google-chrome') or shutil.which('chromium') or shutil.which('chrome')
    pdf = ROOT / OUT[name]
    subprocess.run([chrome, '--headless=new', '--no-sandbox', '--disable-gpu', '--allow-file-access-from-files',
                    '--no-pdf-header-footer', f'--print-to-pdf={pdf}', html.as_uri()], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    html.unlink()
    (ROOT / name / 'report.css').unlink()
    print(pdf)


if __name__ == '__main__':
    main()
