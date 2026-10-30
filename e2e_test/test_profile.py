"""TC-13, TC-14, TC-15: Remote Config trên màn, xuất và tải PDF, thông báo đẩy (khu demo Firebase)."""

import re

import pytest

from conftest import analytics_logged, env


async def test_tc13_remote_config_values_on_screen(agent, fresh_app):
    expected = int(env("QA_EXPECT_QR_SECONDS", "12"))
    r = await agent.run(
        "Quick Attend is open. Open 'Tài khoản' (last bottom icon), scroll to the 'Firebase' group and tap "
        "'Khu demo'. In the 'Remote Config' card, tap 'Tải lại' and wait 3 seconds. Read the values shown next to "
        "'qr_rotate_seconds' and 'absence_limit_percent' and 'Nguồn'. Then go back to 'Tổng quan', tap the white "
        "'Điểm danh' button on the orange slot card if present and read the chip text like 'Đổi mã 12s'.",
        expect='{"qr_rotate_seconds": integer, "absence_limit_percent": integer, "source": string, "chip": string|null}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("qr_rotate_seconds") == expected
    chip = r.output.get("chip")
    if chip:  # chỉ khi có slot đang diễn ra: số giây đếm lùi không vượt chu kỳ đặt trên console
        m = re.fullmatch(r"Đổi mã (\d+)s", chip.strip())
        assert m and 1 <= int(m.group(1)) <= expected, chip


async def test_tc14_export_and_upload_pdf(agent, fresh_app, analytics_debug):
    r = await agent.run(
        "Quick Attend is open. Open 'Tài khoản', tap 'Khu demo'. In the card 'Xuất báo cáo · Cloud Storage', tap "
        "the first class chip, then tap 'Xuất PDF và tải lên'. Wait until the green text starting with "
        "'Đã tải lên' appears (up to 60 seconds). Report that text and whether a link starting with https is shown.",
        expect='{"uploaded_text": string, "has_https_link": boolean, "size_kb": integer}',
        timeout=900,
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("uploaded_text", "").startswith("Đã tải lên reports/")
    assert r.output.get("has_https_link") is True
    assert r.output.get("size_kb", 0) > 0
    assert analytics_logged("export_report")


@pytest.mark.native
async def test_tc15_notification_permission_and_open(agent, fresh_app):
    r = await agent.run(
        "Quick Attend is open. Open 'Tài khoản' > 'Khu demo'. In 'Cloud Messaging' tap 'Cho phép'. If Android shows "
        "the notification permission dialog, tap 'Allow'. Read the value next to 'Quyền thông báo'. Then press the "
        "Home button. A test push titled 'Quick Attend test' has been sent with data route=/requests; open the "
        "notification shade, wait up to 60 seconds for it, and tap it. Report the screen title that opens.",
        expect='{"permission": string, "notification_seen": boolean, "opened_title": string}',
        timeout=900,
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("permission") == "Đã cho phép"
    assert r.output.get("notification_seen") is True
    assert r.output.get("opened_title") == "Yêu cầu sửa"
