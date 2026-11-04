"""Tạo bảng kết quả (test ID, số lần chạy, tỉ lệ đạt, thời gian TB) từ runs/junit*.xml và runs/runs.jsonl.

    uv run python report.py ../evidence/artemis/results.md   # ghi file UTF-8 (dùng được trên Windows)
    uv run python report.py                                  # in ra màn hình

Mỗi lần chạy pytest nên ghi một file junit riêng (--junitxml=runs/junit-<tên>.xml), vì file mặc định
runs/junit.xml bị ghi đè ở lần chạy sau. Script gộp mọi file runs/junit*.xml.
"""

from __future__ import annotations

import json
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

RUNS = Path(__file__).parent / "runs"


def main() -> None:
    passed: dict[str, int] = defaultdict(int)
    total: dict[str, int] = defaultdict(int)
    cases = [c for f in sorted(RUNS.glob("junit*.xml")) for c in ET.parse(f).getroot().iter("testcase")]
    for case in cases:
        name = case.attrib["name"].split("[")[0]
        if case.find("skipped") is not None:
            continue
        total[name] += 1
        if case.find("failure") is None and case.find("error") is None:
            passed[name] += 1

    secs: dict[str, list[float]] = defaultdict(list)
    traces: dict[str, list[str]] = defaultdict(list)
    jl = RUNS / "runs.jsonl"
    if jl.exists():
        for line in jl.read_text(encoding="utf-8").splitlines():
            r = json.loads(line)
            secs[r["test_id"]].append(float(r["seconds"]))
            traces[r["test_id"]].append(r["trace_id"])

    lines = ["| Test | Runs | Pass rate | Avg time (s) | Trace IDs |", "|---|---|---|---|---|"]
    for name in sorted(total):
        tc = name.split("_")[1].upper().replace("TC", "TC-")
        avg = sum(secs[name]) / len(secs[name]) if secs[name] else 0
        flag = "" if passed[name] == total[name] else " ⚠ flaky"
        lines.append(f"| {tc} `{name}` | {total[name]} | {passed[name]}/{total[name]}{flag} | {avg:.0f} | {', '.join(traces[name])} |")
    text = "\n".join(lines) + "\n"
    if len(sys.argv) > 1:
        Path(sys.argv[1]).write_text(text, encoding="utf-8")
    else:
        sys.stdout.buffer.write(text.encode("utf-8"))


if __name__ == "__main__":
    main()
