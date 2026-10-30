"""Tạo bảng kết quả (test ID, số lần chạy, tỉ lệ đạt, thời gian TB) từ runs/junit.xml và runs/runs.jsonl.

    uv run python report.py > ../evidence/artemis/results.md
"""

from __future__ import annotations

import json
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

RUNS = Path(__file__).parent / "runs"


def main() -> None:
    passed: dict[str, int] = defaultdict(int)
    total: dict[str, int] = defaultdict(int)
    for case in ET.parse(RUNS / "junit.xml").getroot().iter("testcase"):
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

    print("| Test | Runs | Pass rate | Avg time (s) | Trace IDs |")
    print("|---|---|---|---|---|")
    for name in sorted(total):
        tc = name.split("_")[1].upper().replace("TC", "TC-")
        avg = sum(secs[name]) / len(secs[name]) if secs[name] else 0
        flag = "" if passed[name] == total[name] else " ⚠ flaky"
        print(f"| {tc} `{name}` | {total[name]} | {passed[name]}/{total[name]}{flag} | {avg:.0f} | {', '.join(traces[name])} |")


if __name__ == "__main__":
    main()
