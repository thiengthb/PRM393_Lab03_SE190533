"""TC-01, TC-02, TC-16: đăng nhập, lỗi đăng nhập, đăng xuất (FL-0)."""

import pytest

from conftest import analytics_logged, env


@pytest.mark.native
async def test_tc01_google_sign_in(agent, signed_out, analytics_debug):
    email = env("QA_TEST_EMAIL")
    r = await agent.run(
        "The Quick Attend app is open on the sign-in screen (title 'Quick Attend'). "
        "Tap 'Đăng nhập với Google'. In the Google account picker dialog, choose the account "
        f"'{email}' (if a consent screen appears, tap Continue). "
        "Wait until the app shows the 'Tổng quan' screen with a bottom navigation bar of 4 icons. "
        "Report the screen title and the term label shown at the top-left of the content (e.g. 'Fall 2026').",
        expect='{"screen_title": string, "term": string, "bottom_tabs": integer}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("screen_title") == "Tổng quan"
    assert r.output.get("bottom_tabs") == 4
    assert str(r.output.get("term", "")).split(" ")[0] in ("Spring", "Summer", "Fall")
    assert analytics_logged("login"), "Không thấy sự kiện login trong Logcat (FA)"


@pytest.mark.error_path
async def test_tc02_wrong_password_shows_error(agent, signed_out):
    email = env("QA_TEST_EMAIL")
    r = await agent.run(
        "The Quick Attend app is open on the sign-in screen. "
        f"Type '{email}' in the 'Email' field and 'wrong-pass-123' in the 'Mật khẩu' field, then tap 'Đăng nhập'. "
        "Wait 5 seconds. Do NOT try other passwords. Report the red error text shown under the password field "
        "and whether the screen is still the sign-in screen.",
        expect='{"error_text": string, "still_on_sign_in": boolean}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("error_text") == "Sai email hoặc mật khẩu"
    assert r.output.get("still_on_sign_in") is True


async def test_tc16_sign_out(agent, fresh_app, analytics_debug):
    r = await agent.run(
        "Quick Attend is open and signed in as a lecturer. Tap the last icon (person) in the bottom navigation "
        "to open 'Tài khoản'. Scroll down and tap 'Đăng xuất'. A dialog titled 'Đăng xuất?' appears; tap the "
        "'Đăng xuất' button in the dialog. Report the title text of the screen that appears after signing out "
        "and the label of its main button.",
        expect='{"dialog_seen": boolean, "after_title": string, "main_button": string}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("dialog_seen") is True
    assert r.output.get("after_title") == "Quick Attend"
    assert r.output.get("main_button") == "Đăng nhập"
    assert analytics_logged("logout")
