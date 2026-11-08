"""TC-09, TC-10, TC-23: phía sinh viên (FL-4) — chạy với bản build PORTAL=student trên cùng thiết bị."""

import pytest

from conftest import analytics_logged


@pytest.mark.student
async def test_tc09_student_subject_detail(agent, fresh_app):
    r = await agent.run(
        "Hereby (student build) is open on the home page ('Chào <name>' at the top, 'Môn học' list). Read the FIRST "
        "subject card: subject code and the absence ratio on the right (absent / allowed, like '2/4'). Tap that "
        "card. On the subject page read the big ratio next to 'buổi vắng', then under 'Buổi học' count the rows "
        "with a green tick (present) and the rows with a red x (absent).",
        expect='{"subject": string, "list_ratio": string, "detail_ratio": string, "present_rows": integer, "absent_rows": integer}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("list_ratio") == r.output.get("detail_ratio")
    absent, _limit = (int(x) for x in r.output["detail_ratio"].split("/"))
    assert r.output.get("absent_rows") == absent
    assert isinstance(r.output.get("present_rows"), int)


@pytest.mark.student
@pytest.mark.error_path
async def test_tc10_report_requires_reason_then_sends(agent, fresh_app, analytics_debug):
    r = await agent.run(
        "Hereby (student build) is open. Tap the first subject card, then tap a session card with a red x and "
        "the link 'Báo sai'. On 'Báo sai', tap 'Gửi' at the bottom WITHOUT choosing a reason and read the red "
        "error text. Then choose "
        "'Mạng lỗi, không quét được', type 'Em quét rồi nhưng mạng lỗi' in 'Ghi thêm' and tap 'Gửi'. Report the "
        "title of the result screen.",
        expect='{"error_without_reason": string, "result_title": string}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("error_without_reason") == "Chọn lý do"
    assert r.output.get("result_title") == "Đã gửi"
    assert analytics_logged("correction_submit")


@pytest.mark.student
@pytest.mark.error_path
@pytest.mark.native
async def test_tc23_wrong_typed_code(agent, fresh_app, analytics_debug):
    r = await agent.run(
        "Hereby (student build) is open on the home page ('Chào <name>'). Tap 'Quét mã' at the bottom. If the app asks for the "
        "camera, tap 'Cho phép' and then 'Allow' (or 'While using the app') in the Android permission dialog. "
        "On the scan screen tap 'Nhập mã'. On 'Nhập mã', type the digits 000000 and tap 'Gửi'. Read the title "
        "of the red result and the label of the bottom button.",
        expect='{"camera_dialog_seen": boolean, "error_title": string, "bottom_button": string}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("error_title") == "Mã không đúng hoặc đã hết hạn"
    assert r.output.get("bottom_button") == "Nhập lại"
    assert analytics_logged("qr_scan")


@pytest.mark.exploratory
async def test_exploratory_session_pro(agent, fresh_app):
    """Phiên khám phá 15–30 phút, profile Pro (chạy riêng: pytest -m exploratory)."""
    r = await agent.run(
        "Explore the Hereby lecturer app for about 20 minutes like a new lecturer on the first day of term. "
        "Try every screen reachable from the 4 bottom tabs, every button, the attendance session (open, close "
        "code, reopen code, close, undo), 'Chiếu lên TV', filters on 'Vắng nhiều', week navigation on "
        "'Điểm danh', the colour picker in 'Tài khoản', and the 'Khu demo' screen (do NOT tap "
        "'Test crash'). Look for crashes, dead ends (no way back), overflowing or cut-off text, buttons that do "
        "nothing, wrong numbers between screens, and unreadable contrast. List every issue found.",
        expect='{"issues": [{"screen": string, "steps": string, "observed": string, "severity": "high|medium|low"}]}',
        profile="pro",
        timeout=2400,
    )
    assert r.status in ("completed", "success"), r.error
