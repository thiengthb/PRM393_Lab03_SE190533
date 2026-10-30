"""TC-09, TC-10: phía sinh viên (FL-4) — chạy với bản build PORTAL=student trên cùng thiết bị."""

import pytest

from conftest import analytics_logged


@pytest.mark.student
async def test_tc09_student_subject_detail(agent, fresh_app):
    r = await agent.run(
        "Quick Attend (student build) is open on the page with the student's name and term (like 'Fall 2026'). "
        "Read the FIRST subject card: subject code and the ratio on the right (like '7/10'). Tap that card. On the "
        "subject page read the big ratio under the title and count how many session rows show 'Có mặt' and how "
        "many show 'Vắng'.",
        expect='{"subject": string, "list_ratio": string, "detail_ratio": string, "present_rows": integer, "absent_rows": integer}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("list_ratio") == r.output.get("detail_ratio")
    attended, held = (int(x) for x in r.output["detail_ratio"].split("/"))
    assert r.output.get("present_rows") == attended
    assert r.output.get("present_rows", 0) + r.output.get("absent_rows", 0) == held


@pytest.mark.student
@pytest.mark.error_path
async def test_tc10_report_requires_reason_then_sends(agent, fresh_app, analytics_debug):
    r = await agent.run(
        "Quick Attend (student build) is open. Tap the first subject card, then tap a session row marked 'Vắng'. "
        "On 'Báo sai', tap 'Gửi' WITHOUT choosing a reason and read the red error text. Then choose "
        "'Mạng lỗi, không quét được', type 'Em quét rồi nhưng mạng lỗi' in 'Ghi thêm' and tap 'Gửi'. Report the "
        "title of the result screen.",
        expect='{"error_without_reason": string, "result_title": string}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("error_without_reason") == "Chọn lý do"
    assert r.output.get("result_title") == "Đã gửi"
    assert analytics_logged("correction_submit")


@pytest.mark.exploratory
async def test_exploratory_session_pro(agent, fresh_app):
    """Phiên khám phá 15–30 phút, profile Pro (chạy riêng: pytest -m exploratory)."""
    r = await agent.run(
        "Explore the Quick Attend lecturer app for about 20 minutes like a new lecturer on the first day of term. "
        "Try every screen reachable from the 4 bottom tabs, every button, the attendance session (open, close, "
        "reopen, undo), filters on 'Chú ý', month navigation on 'Lịch', and the 'Khu demo' screen (do NOT tap "
        "'Test crash'). Look for crashes, dead ends (no way back), overflowing or cut-off text, buttons that do "
        "nothing, wrong numbers between screens, and unreadable contrast. List every issue found.",
        expect='{"issues": [{"screen": string, "steps": string, "observed": string, "severity": "high|medium|low"}]}',
        profile="pro",
        timeout=2400,
    )
    assert r.status in ("completed", "success"), r.error
