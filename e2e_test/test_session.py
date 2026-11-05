"""TC-05, TC-06, TC-07: điểm danh một slot (FL-1), lỗi mạng (GV-102 .X), không quên chốt (FL-2)."""

import os

import pytest

from conftest import adb, analytics_logged


async def test_tc05_attend_live_slot(agent, fresh_app, analytics_debug):
    r = await agent.run(
        "Hereby is open on 'Tổng quan' and a slot is in progress (blue card with a white 'Điểm danh' "
        "button). Tap 'Điểm danh'. A QR code, a 6-digit code and a counter like '0 / 35' appear. Read the "
        "counter. Tap 'Đóng mã' at the bottom once: the QR disappears, a 'Mở lại mã' button appears and the "
        "bottom button becomes 'Chốt'. Turn ON the switch of the FIRST student under 'Chưa quét'. Tap 'Chốt' "
        "(there is no confirmation dialog). Wait for the message 'Đã chốt' with 'Hoàn tác'. Do NOT tap "
        "'Hoàn tác'. Read the two numbers on the result screen labelled 'có mặt' and 'vắng'. Report the values.",
        expect='{"counter_before": string, "closed_toast_seen": boolean, "dialog_seen": boolean, '
        '"present_tile": integer, "absent_tile": integer}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("closed_toast_seen") is True
    assert r.output.get("dialog_seen") is False, "v2 chốt một lần, không có hộp xác nhận (D-L3)"
    present, absent = r.output.get("present_tile"), r.output.get("absent_tile")
    assert isinstance(present, int) and isinstance(absent, int) and present >= 1
    total = int(str(r.output.get("counter_before", "")).split("/")[-1].strip())
    assert present + absent == total
    assert analytics_logged("attendance_session_open")
    assert analytics_logged("attendance_close")


@pytest.mark.error_path
async def test_tc06_close_offline_then_retry(agent, fresh_app):
    if os.environ.get("QA_RESEED_CMD"):
        await _tc06_emulator(agent)
        return
    try:
        r = await agent.run(
            "Hereby is open on 'Tổng quan' with a slot in progress. Tap 'Điểm danh', then tap 'Đóng mã' once "
            "(QR closes). Now open Android quick settings (swipe down twice from the top) and turn ON Airplane "
            "mode, then return to the app. Tap 'Chốt'. Wait 10 seconds: a yellow banner at the top with the "
            "title 'Chưa gửi được', the line 'Đã lưu trên máy' and a 'Thử lại' link must appear; read it. Then "
            "open quick settings again and turn OFF Airplane mode, wait 5 seconds, return to the app and tap "
            "'Thử lại'. "
            "Wait until 'Đã chốt' appears. Report the values.",
            expect='{"offline_title": string, "offline_detail": string, "closed_after_retry": boolean}',
        )
    finally:
        adb("shell", "cmd", "connectivity", "airplane-mode", "disable")
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("offline_title") == "Chưa gửi được"
    assert r.output.get("offline_detail") == "Đã lưu trên máy"
    assert r.output.get("closed_after_retry") is True


async def _tc06_emulator(agent) -> None:
    """Chế độ Emulator: app nói chuyện với laptop qua `adb reverse` (cáp USB), nên Chế độ máy bay không
    cắt được kết nối. Thay bằng gỡ `adb reverse` ở máy chủ giữa hai chỉ dẫn, nên ca này có ba chỉ dẫn."""
    r1 = await agent.run(
        "Hereby is open on 'Tổng quan' with a slot in progress. Tap 'Điểm danh', then tap 'Đóng mã' once. "
        "Report whether the QR code disappeared and the bottom button now reads 'Chốt'.",
        expect='{"qr_closed": boolean, "bottom_button": string}',
    )
    assert r1.status in ("completed", "success"), r1.error
    assert r1.output.get("qr_closed") is True
    adb("reverse", "--remove-all")  # mất kết nối tới Emulator
    try:
        r2 = await agent.run(
            "Hereby shows 'Điểm danh' with the QR closed. Tap 'Chốt' at the bottom once. Wait 12 seconds: a "
            "yellow banner at the top with a title, one more line and a 'Thử lại' link appears. Do NOT tap "
            "anything. Report the banner title and its second line.",
            expect='{"offline_title": string, "offline_detail": string}',
        )
    finally:
        for port in ("8080", "9099"):
            adb("reverse", f"tcp:{port}", f"tcp:{port}")
    r3 = await agent.run(
        "Hereby shows a yellow banner with 'Thử lại'. Wait 10 seconds, then tap 'Thử lại'. Wait up to 60 seconds "
        "until 'Đã chốt' appears. Report whether it appeared.",
        expect='{"closed_after_retry": boolean}',
    )
    assert r2.status in ("completed", "success"), r2.error
    assert r2.output.get("offline_title") == "Chưa gửi được"
    assert r2.output.get("offline_detail") == "Đã lưu trên máy"
    assert r3.status in ("completed", "success"), r3.error
    assert r3.output.get("closed_after_retry") is True


async def test_tc07_close_unclosed_slot(agent, fresh_app):
    r = await agent.run(
        "Hereby is open. Open the 'Điểm danh' tab (second bottom icon, QR). If needed use 'Tuần trước' to go "
        "back a week. Find a slot card that has an amber warning badge and a 'Chốt ngay' button (a past slot "
        "not closed yet). Tap 'Chốt ngay'. The screen 'Điểm danh' opens WITHOUT a QR code. Tap 'Chốt' at the "
        "bottom (no dialog) and wait for 'Đã chốt'. Tap 'Xong', open the 'Điểm danh' tab again and report "
        "whether that slot now shows a green tick badge.",
        expect='{"opened_without_qr": boolean, "closed_toast_seen": boolean, "now_green_tick": boolean}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("opened_without_qr") is True
    assert r.output.get("closed_toast_seen") is True
    assert r.output.get("now_green_tick") is True
