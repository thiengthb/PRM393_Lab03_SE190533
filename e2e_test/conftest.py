"""Fixture chung cho bộ test ARTEMIS.

Biến môi trường (đặt trong e2e_test/.env, không commit):
  ARTEMIS_BASE_URL   http://127.0.0.1:8000 (daemon ARTEMIS chạy trên máy có ADB)
  ARTEMIS_DEVICE     serial thiết bị, ví dụ emulator-5554 hoặc R58M...
  QA_TEST_EMAIL      tài khoản Google TEST (không dùng tài khoản cá nhân)
  QA_TEST_PASSWORD   mật khẩu tài khoản email/mật khẩu TEST
  QA_EXPECT_QR_SECONDS  giá trị qr_rotate_seconds đang đặt trên Remote Config
  QA_RESEED_CMD      (tuỳ chọn) lệnh nạp lại dữ liệu mẫu vào Firebase Emulator trước MỖI test,
                     ví dụ: node ../firebase/tests/seed-demo.mjs --reset
                     Có biến này thì app phải là bản build EMULATOR_HOST=127.0.0.1 (docs/test-plan.md mục 3).
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import pytest
from artemis_client import ArtemisClient

APP_PACKAGE = os.environ.get("QA_APP_PACKAGE", "vn.edu.fpt.quick_attend")
RUNS = Path(__file__).parent / "runs"
RUNS.mkdir(exist_ok=True)


def _load_env() -> None:
    env = Path(__file__).parent / ".env"
    if env.exists():
        for line in env.read_text(encoding="utf-8").splitlines():
            if "=" in line and not line.lstrip().startswith("#"):
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())


_load_env()


def env(name: str, default: str | None = None) -> str:
    v = os.environ.get(name, default)
    if v is None:
        pytest.skip(f"Thiếu biến môi trường {name}")
    return v


@dataclass
class Run:
    """Kết quả một lần chạy, có output đã đọc thành dict."""

    test_id: str
    status: str
    trace_id: str
    seconds: float
    output: dict[str, Any] = field(default_factory=dict)
    raw_output: Any = None
    error: str | None = None


def _parse_output(raw: Any) -> dict[str, Any]:
    """ARTEMIS trả output dạng dict hoặc chuỗi có JSON bên trong."""
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str):
        m = re.search(r"\{.*\}", raw, re.S)
        if m:
            try:
                return json.loads(m.group(0))
            except json.JSONDecodeError:
                pass
    return {}


class Agent:
    def __init__(self, client: ArtemisClient, device: str, test_id: str) -> None:
        self.client = client
        self.device = device
        self.test_id = test_id

    async def run(self, instruction: str, *, expect: str, profile: str = "flash", timeout: float = 600) -> Run:
        """Gửi MỘT chỉ dẫn; yêu cầu agent trả JSON theo [expect] để assert trên giá trị."""
        started = time.monotonic()
        result = await self.client.run(
            instruction,
            profile=profile,  # type: ignore[arg-type]
            device_serial=self.device,
            expected_output=f"Return ONLY a JSON object: {expect}",
            enable_outputter=True,
            locked_app_package=APP_PACKAGE,
            timeout=timeout,
        )
        run = Run(
            test_id=self.test_id,
            status=result.status,
            trace_id=result.trace_id,
            seconds=round(time.monotonic() - started, 1),
            output=_parse_output(result.output),
            raw_output=result.output,
            error=result.error,
        )
        with (RUNS / "runs.jsonl").open("a", encoding="utf-8") as f:
            f.write(json.dumps(run.__dict__, ensure_ascii=False, default=str) + "\n")
        return run


@pytest.fixture
async def agent(request: pytest.FixtureRequest) -> Agent:
    client = ArtemisClient(env("ARTEMIS_BASE_URL", "http://127.0.0.1:8000"), default_profile="flash")
    test_id = request.node.originalname
    return Agent(client, env("ARTEMIS_DEVICE"), test_id)


# ---------- ADB: đặt điều kiện đầu, đọc Logcat ----------


def adb(*args: str) -> str:
    serial = os.environ.get("ARTEMIS_DEVICE")
    cmd = ["adb", *(["-s", serial] if serial else []), *args]
    return subprocess.run(cmd, capture_output=True, text=True, timeout=60).stdout


@pytest.fixture(autouse=True)
def demo_data(request: pytest.FixtureRequest) -> None:
    """Chế độ Emulator: mỗi test (và mỗi lần lặp --count) bắt đầu từ cùng một bộ dữ liệu.

    Cần vì TC-05, TC-07, TC-11 thay đổi dữ liệu (chốt slot, duyệt yêu cầu): lần chạy thứ hai sẽ
    không còn slot đang mở hay yêu cầu chờ duyệt nếu không nạp lại.
    """
    cmd = os.environ.get("QA_RESEED_CMD")
    if not cmd:
        return
    if request.node.get_closest_marker("real_firebase"):
        pytest.skip("Ca này chạy riêng với bản build Firebase thật (không có EMULATOR_HOST)")
    for port in ("8080", "9099"):
        adb("reverse", f"tcp:{port}", f"tcp:{port}")
    subprocess.run(cmd, shell=True, check=True, timeout=180, cwd=Path(__file__).parent)


@pytest.fixture
def fresh_app() -> None:
    """Mở app từ đầu (không phụ thuộc test trước)."""
    adb("shell", "am", "force-stop", APP_PACKAGE)
    adb("shell", "monkey", "-p", APP_PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(3)


@pytest.fixture
def signed_out() -> None:
    """Xóa dữ liệu app: trạng thái chưa đăng nhập."""
    adb("shell", "pm", "clear", APP_PACKAGE)
    adb("shell", "monkey", "-p", APP_PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(4)


@pytest.fixture
def analytics_debug() -> None:
    """Bật DebugView và xóa logcat để kiểm sự kiện analytics."""
    adb("shell", "setprop", "debug.firebase.analytics.app", APP_PACKAGE)
    adb("logcat", "-c")


def analytics_logged(event: str) -> bool:
    log = adb("logcat", "-d", "-s", "FA", "FA-SVC")
    return re.search(rf"name={re.escape(event)}\b", log) is not None


def push_file(local: str, remote_name: str) -> None:
    src = Path(__file__).parent.parent / local
    adb("push", str(src), f"/sdcard/Download/{remote_name}")
