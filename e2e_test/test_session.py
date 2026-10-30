"""TC-05, TC-06, TC-07: điểm danh một slot (FL-1), lỗi mạng (GV-OV2), không quên chốt (FL-2)."""

import pytest

from conftest import adb, analytics_logged


async def test_tc05_attend_live_slot(agent, fresh_app, analytics_debug):
    r = await agent.run(
        "Quick Attend is open on 'Tổng quan' and a slot is in progress (orange card with a white 'Điểm danh' "
        "button). Tap 'Điểm danh'. A QR code and a counter like '0/35' appear. Read the counter. Tap the "
        "'Chốt' button at the bottom once: the QR disappears and a 'Mở lại' button appears. Turn ON the "
        "switch of the FIRST student under 'Chưa quét'. Tap 'Chốt' again; a dialog 'Chốt điểm danh?' appears "
        "with text like '1 có mặt · 34 vắng'. Read that text, then tap 'Chốt' in the dialog. Wait for the "
        "message 'Đã chốt'. Report the values.",
        expect='{"counter_before": string, "dialog_text": string, "closed_toast_seen": boolean, '
        '"present_tile": integer, "absent_tile": integer}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("closed_toast_seen") is True
    present, absent = r.output.get("present_tile"), r.output.get("absent_tile")
    assert isinstance(present, int) and isinstance(absent, int) and present >= 1
    assert r.output.get("dialog_text") == f"{present} có mặt · {absent} vắng"
    assert analytics_logged("attendance_session_open")
    assert analytics_logged("attendance_close")


@pytest.mark.error_path
async def test_tc06_close_offline_then_retry(agent, fresh_app):
    try:
        r = await agent.run(
            "Quick Attend is open on 'Tổng quan' with a slot in progress. Tap 'Điểm danh', then tap 'Chốt' once "
            "(QR closes). Now open Android quick settings (swipe down twice from the top) and turn ON Airplane "
            "mode, then return to the app. Tap 'Chốt' and confirm 'Chốt' in the dialog. Wait 10 seconds: a "
            "dialog 'Chưa gửi được' with 'Mất mạng · đã lưu trên máy' must appear; read it. Then open quick "
            "settings again and turn OFF Airplane mode, wait 5 seconds, return to the app and tap 'Thử lại'. "
            "Wait until 'Đã chốt' appears. Report the values.",
            expect='{"offline_title": string, "offline_detail": string, "closed_after_retry": boolean}',
        )
    finally:
        adb("shell", "cmd", "connectivity", "airplane-mode", "disable")
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("offline_title") == "Chưa gửi được"
    assert r.output.get("offline_detail") == "Mất mạng · đã lưu trên máy"
    assert r.output.get("closed_after_retry") is True


async def test_tc07_close_unclosed_slot(agent, fresh_app):
    r = await agent.run(
        "Quick Attend is open. Open the 'Lịch' tab (calendar icon) and tap 'Tuần'. Find a slot card that has an "
        "amber warning triangle and a 'Chốt ngay' button (a past slot not closed yet). Tap 'Chốt ngay'. The "
        "screen 'Điểm danh' opens WITHOUT a QR code. Tap 'Chốt', confirm 'Chốt' in the dialog, wait for "
        "'Đã chốt'. Then go back to 'Lịch' > 'Tuần' and report whether that slot now shows a green tick.",
        expect='{"opened_without_qr": boolean, "closed_toast_seen": boolean, "now_green_tick": boolean}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("opened_without_qr") is True
    assert r.output.get("closed_toast_seen") is True
    assert r.output.get("now_green_tick") is True
