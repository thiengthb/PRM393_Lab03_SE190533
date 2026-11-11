# Usage (Windows, PowerShell): python make_voice_v2.py
# Writes one mp3 per line in voice-v2.json next to this script, folder "voice-v2".
import asyncio, json, pathlib, edge_tts
here = pathlib.Path(__file__).parent
out = here / "voice-v2"; out.mkdir(exist_ok=True)
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
async def main():
    for k, t in lines.items(): await one(k, t)
asyncio.run(main())
