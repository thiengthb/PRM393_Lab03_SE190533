"""TC-08, TC-11, TC-12: Chú ý và hồ sơ (FL-3), duyệt báo sai (FL-4b), các tab và chi tiết lớp."""

import pytest

from conftest import analytics_logged


async def test_tc08_attention_and_reminder(agent, fresh_app, analytics_debug):
    r = await agent.run(
        "Quick Attend is open on 'Tổng quan'. In the 'Chú ý' section tap 'Xem tất cả'. On 'Chú ý', tap the FIRST "
        "student row. On 'Hồ sơ', read the student name and the big absence ratio (like '5/4'). Tap 'Nhắc nhở' at "
        "the bottom; a sheet 'Nhắc sinh viên' opens with a prefilled message; read it and tap 'Gửi'. Report the "
        "values and the label of the bottom button after sending.",
        expect='{"student_name": string, "ratio": string, "message": string, "button_after": string}',
    )
    assert r.status in ("completed", "success"), r.error
    ratio = r.output.get("ratio", "")
    absent, limit = (int(x) for x in ratio.split("/"))
    assert absent >= limit - 1, "Hàng Chú ý phải sắp chạm hoặc vượt ngưỡng"
    assert r.output.get("message", "").startswith(f"Em đã vắng {absent} buổi")
    assert r.output.get("button_after") == "Đã nhắc"
    assert analytics_logged("view_student") and analytics_logged("reminder_send")


async def test_tc11_approve_correction(agent, fresh_app, analytics_debug):
    r = await agent.run(
        "Quick Attend is open on 'Tổng quan'. Read the number in the tile labelled 'yêu cầu sửa', then tap that "
        "tile. On 'Yêu cầu sửa', read the student name on the FIRST card and tap its 'Duyệt' button. A message "
        "'Đã duyệt' with 'Hoàn tác' appears. Go back to 'Tổng quan' and read the 'yêu cầu sửa' number again.",
        expect='{"pending_before": integer, "student_name": string, "approved_toast": boolean, "pending_after": integer}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("approved_toast") is True
    assert r.output.get("pending_after") == r.output.get("pending_before", 0) - 1
    assert analytics_logged("correction_review")


async def test_tc12_tabs_and_class_detail(agent, fresh_app, analytics_debug):
    r = await agent.run(
        "Quick Attend is open. Tap each of the 4 bottom navigation icons from left to right and read each screen "
        "title. On 'Lịch', tap 'Tháng' and read the month label (like 'Tháng 10, 2026'). On 'Lớp', tap the first "
        "class card; on the class screen read the two numbers in the tiles ('sinh viên' and 'buổi đã học') and "
        "tap the 'Buổi học' tab and count the rows.",
        expect='{"titles": [string], "month_label": string, "students": integer, "held": string, "session_rows": integer}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("titles") == ["Tổng quan", "Lịch", "Lớp", "Tài khoản"]
    assert str(r.output.get("month_label", "")).startswith("Tháng ")
    assert r.output.get("students", 0) > 0
    assert "/" in str(r.output.get("held", ""))
    assert analytics_logged("view_class")
