#!/usr/bin/env python3
"""Assemble the Attendo demo videos from recorded clips, evidence stills and slide renders.

Usage: python3 build.py lab3|final [--draft]
"""
import json, os, subprocess, sys
from pathlib import Path

# MEDIA: the Codex hand-off folder (work/clips, work/voice, work/voice-v2/voice-v2).
# WORK: scratch folder with slides/ (slide PNGs), fonts/ (Onest TTF) and out/.
REPO = Path(__file__).resolve().parents[3]
MEDIA = Path(os.environ.get('MEDIA', '/mnt/user-data/uploads/giao-vi-c-video-cho-codex')).resolve()
WORK = Path(os.environ.get('WORK', '/tmp/v')).resolve()
CL = MEDIA / 'work/clips'
VO = MEDIA / 'work/voice'
V2 = MEDIA / 'work/voice-v2/voice-v2'
EV = REPO / 'evidence'
SL = WORK / 'slides'
OUT = WORK / 'out'; OUT.mkdir(parents=True, exist_ok=True)


def fpath(p):
    """Quote a path for an FFmpeg filter option (Windows drive colons, commas, quotes)."""
    s = Path(p).as_posix().replace('\\', '\\\\').replace("'", "'\\''")
    return "'" + s.replace(':', '\\:') + "'"


FONT = fpath(WORK / 'fonts/onest-semibold.ttf')
FONTB = fpath(WORK / 'fonts/onest-bold.ttf')
W, H, FPS = 1920, 1080, 30
DRAFT = False


def dur(p):
    return float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', str(p)]))


def voice(name):
    """New line from voice-v2 if present, else the original line."""
    p = V2 / f'{name}.mp3'
    return p if p.exists() else VO / f'{name}.mp3'


def esc(t):
    return t.replace('\\', '\\\\').replace(':', '\\:').replace("'", "’").replace('%', '\\%')


# ---------- part helpers ----------
def clip(name, ss, to, crop=None, blur=()):
    return dict(kind='clip', path=CL / f'{name}.mp4', ss=ss, to=to, crop=crop, blur=list(blur))


def img(path, d):
    return dict(kind='img', path=Path(path), d=d)


def slide(deck, n, d):
    return img(SL / f'{deck}-{n:02d}.png', d)


def card(text, d=6):
    return dict(kind='card', text=text, d=d)


def plen(p):
    return p['to'] - p['ss'] if p['kind'] == 'clip' else p['d']


def part_filter(i, p, inp):
    """Return (inputs args, filter string producing [p{i}])."""
    fit = (f"scale={W}:{H}:force_original_aspect_ratio=decrease:flags=lanczos,"
           f"pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:color=0x101317,setsar=1,fps={FPS},format=yuv420p")
    if p['kind'] == 'clip':
        args = ['-ss', str(p['ss']), '-to', str(p['to']), '-i', str(p['path'])]
        chain = f"[{inp}:v]setpts=PTS-STARTPTS"
        f = ''
        cur = f'c{i}'
        f += f"{chain}[{cur}];"
        for k, (x, y, w, h, t0, t1) in enumerate(p['blur']):
            a, b = t0 - p['ss'], t1 - p['ss']
            f += (f"[{cur}]split[{cur}a][{cur}b];[{cur}b]crop={w}:{h}:{x}:{y},boxblur=8:4[{cur}bl];"
                  f"[{cur}a][{cur}bl]overlay={x}:{y}:enable='between(t,{a},{b})'[{cur}x{k}];")
            cur = f'{cur}x{k}'
        if p['crop']:
            cw, ch, cx, cy = p['crop']
            f += f"[{cur}]crop={cw}:{ch}:{cx}:{cy}[{cur}k];"
            cur = f'{cur}k'
        f += f"[{cur}]{fit}[p{i}];"
        return args, f
    if p['kind'] == 'img':
        args = ['-loop', '1', '-framerate', str(FPS), '-t', str(p['d']), '-i', str(p['path'])]
        return args, f"[{inp}:v]{fit},trim=duration={p['d']}[p{i}];"
    # card: placeholder for a scene that is not recorded yet
    lines = p['text'].split('\n')
    args = ['-f', 'lavfi', '-t', str(p['d']), '-i', f'color=c=0x3a1d1d:s={W}x{H}:r={FPS}']
    f = f"[{inp}:v]format=yuv420p"
    for j, ln in enumerate(lines):
        size = 64 if j == 0 else 40
        y = 380 + (0 if j == 0 else 60 + 60 * j)
        f += f",drawtext=fontfile={FONTB}:text='{esc(ln)}':fontsize={size}:fontcolor=white:x=(w-tw)/2:y={y}"
    return args, f + f"[p{i}];"


def render_segment(idx, seg, tag):
    parts = seg['video']
    vlen = sum(plen(p) for p in parts)
    voices = [(off, Path(v), txt) for off, v, txt in seg.get('voices', [])]
    vend = max([off + dur(v) for off, v, _ in voices] or [0])
    D = round(max(vlen, vend + 0.8), 3)
    args, f = [], ''
    for i, p in enumerate(parts):
        a, ff = part_filter(i, p, i)
        args += a; f += ff
    n = len(parts)
    f += ''.join(f'[p{i}]' for i in range(n)) + f"concat=n={n}:v=1:a=0[cv];"
    f += f"[cv]tpad=stop_mode=clone:stop_duration={max(0, D - vlen) + 0.1},trim=duration={D}"
    if seg.get('title'):
        f += (f",drawtext=fontfile={FONTB}:text='{esc(seg['title'])}':fontsize=34:fontcolor=white:"
              f"box=1:boxcolor=0x1f3fbf@0.92:boxborderw=18:x=36:y=36:enable='lt(t,4.5)'")
    badge = (('BẢN NHÁP · ' if DRAFT else '') + seg.get('badge', '')).strip(' ·')
    if badge:
        f += (f",drawtext=fontfile={FONT}:text='{esc(badge)}':fontsize=26:fontcolor=white:"
              f"box=1:boxcolor=0x000000@0.72:boxborderw=12:x=36:y=h-th-34")
    f += '[vout];'
    ai = n
    for off, v, _ in voices:
        args += ['-i', str(v)]
    args += ['-f', 'lavfi', '-t', str(D), '-i', 'anullsrc=r=48000:cl=stereo']
    mix = []
    for k, (off, v, _) in enumerate(voices):
        ms = int(off * 1000)
        f += f"[{ai + k}:a]aresample=48000,aformat=channel_layouts=stereo,adelay={ms}|{ms}[a{k}];"
        mix.append(f'[a{k}]')
    sil = ai + len(voices)
    f += f"[{sil}:a]" + ''.join(mix) + f"amix=inputs={len(mix) + 1}:normalize=0:duration=first[aout]"
    out = OUT / f'{tag}-{idx:02d}.mp4'
    if os.environ.get('REUSE') and out.exists() and idx < int(os.environ['REUSE']):
        return out, dur(out), [(off, dur(v), txt) for off, v, txt in voices]
    cmd = ['ffmpeg', '-v', 'error', '-y'] + args + ['-filter_complex', f, '-map', '[vout]', '-map', '[aout]',
           '-t', str(D), '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '20', '-pix_fmt', 'yuv420p',
           '-r', str(FPS), '-c:a', 'aac', '-b:a', '160k', '-ar', '48000', str(out)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[-3000:]); sys.exit(f'segment {idx} failed')
    return out, D, [(off, dur(v), txt) for off, v, txt in voices]


def ts(t):
    h = int(t // 3600); m = int(t % 3600 // 60); s = t % 60
    return f'{h}:{m:02d}:{s:05.2f}'


def srt_ts(t):
    ms = int(round(t * 1000)); h, ms = divmod(ms, 3600000); m, ms = divmod(ms, 60000); s, ms = divmod(ms, 1000)
    return f'{h:02d}:{m:02d}:{s:02d},{ms:03d}'


def build(tag, segs, draft):
    files, events, t = [], [], 0.0
    for i, s in enumerate(segs):
        f, D, vs = render_segment(i, s, tag)
        files.append(f)
        for off, ln, txt in vs:
            events.append((t + off, t + off + ln, txt))
        print(f'{tag} seg {i:02d} {D:6.1f}s  {s.get("title", "")}')
        t += D
    lst = OUT / f'{tag}-list.txt'
    lst.write_text(''.join(f"file '{f}'\n" for f in files), encoding='utf-8')
    joined = OUT / f'{tag}-joined.mp4'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', str(lst), '-c', 'copy', str(joined)], check=True)
    # subtitles
    ass = OUT / f'{tag}.ass'
    head = f"""[Script Info]
ScriptType: v4.00+
PlayResX: {W}
PlayResY: {H}
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Sub,Onest SemiBold,44,&H00FFFFFF,&H00FFFFFF,&H00000000,&H50000000,0,0,0,0,100,100,0,0,3,14,0,2,220,220,46,1
Style: Credit,Onest SemiBold,22,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,3,8,0,3,30,30,20,1
Style: Draft,Onest Bold,26,&H0000D7FF,&H00FFFFFF,&H00000000,&H90000000,0,0,0,0,100,100,0,0,3,8,0,8,30,30,40,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    body = f"Dialogue: 0,{ts(0)},{ts(t)},Credit,,0,0,0,,Giọng đọc: Microsoft Edge TTS\n"
    srt = []
    for k, (a, b, txt) in enumerate(events, 1):
        body += f"Dialogue: 1,{ts(a)},{ts(b)},Sub,,0,0,0,,{txt}\n"
        srt.append(f"{k}\n{srt_ts(a)} --> {srt_ts(b)}\n{txt}\n")
    ass.write_text(head + body, encoding='utf-8')
    name = {'lab3': 'Lab03_SE190533_video', 'final': 'Final_SE190533_video'}[tag] + ('-ban-nhap' if draft else '')
    (OUT / f'{name}.srt').write_text('\n'.join(srt), encoding='utf-8')
    final = OUT / f'{name}.mp4'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(joined),
                    '-vf', f"ass=filename={fpath(ass)}:fontsdir={fpath(WORK / 'fonts')}", '-af', 'loudnorm=I=-16:TP=-1.5:LRA=11',
                    '-c:v', 'libx264', '-preset', 'medium', '-crf', '21', '-pix_fmt', 'yuv420p', '-r', str(FPS),
                    '-c:a', 'aac', '-b:a', '160k', '-ar', '48000', '-movflags', '+faststart', str(final)], check=True)
    print(f'{final}  {dur(final):.1f}s')


if __name__ == '__main__':
    tag = sys.argv[1]
    draft = '--draft' in sys.argv
    DRAFT = draft
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from scenes import LAB3, FINAL
    build(tag, LAB3 if tag == 'lab3' else FINAL, draft)
