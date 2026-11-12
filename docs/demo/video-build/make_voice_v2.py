# Usage (Windows, PowerShell): python make_voice_v2.py
# Writes one mp3 per line in voice-v2.json into MEDIA/work/voice-v2/voice-v2,
# the folder build.py reads (MEDIA = the Codex hand-off folder, as for build.py).
# Without MEDIA it falls back to a "voice-v2" folder next to this script.
import asyncio, json, os, pathlib, sys, edge_tts
here = pathlib.Path(__file__).parent
media = os.environ.get("MEDIA")
out = pathlib.Path(media) / "work/voice-v2/voice-v2" if media else here / "voice-v2"
out.mkdir(parents=True, exist_ok=True)
lines = json.loads((here / "voice-v2.json").read_text(encoding="utf-8"))
async def one(k, t):
    for attempt in range(4):
        try:
            await edge_tts.Communicate(t, "vi-VN-NamMinhNeural", rate="+5%").save(str(out / f"{k}.mp3"))
            if (out / f"{k}.mp3").stat().st_size > 1000: print("ok", k); return
        except Exception as e:
            print("retry", k, e)
        await asyncio.sleep(2 + attempt * 2)
    print("FAIL", k)
    failed.append(k)
failed = []
async def main():
    for k, t in lines.items(): await one(k, t)
asyncio.run(main())
if failed:
    sys.exit("failed: " + ", ".join(failed))
