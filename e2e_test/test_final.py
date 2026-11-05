"""TC-17..TC-21: phần Final trên app giảng viên: gửi lớp chờ duyệt, nhận kết quả, hộp thư, AI.

Bước trên web admin do người chạy làm (hoặc đã chuẩn bị trước), test ghi rõ ở điều kiện đầu.
Xem docs/test-plan.md mục 2b và docs/cross-role-flow.md.
"""

import pytest

from conftest import analytics_logged, env, push_file


async def test_tc17_import_goes_to_pending(agent, fresh_app, analytics_debug):
    """Luồng liên vai trò, bước 1: nhập lớp xong thấy 'Chờ giáo vụ duyệt', chưa có slot để điểm danh."""
    push_file("mobile/sample-data/lop-fall-2026.csv", "lop-fall-2026.csv")
    r = await agent.run(
        "Hereby is open on 'Tổng quan' with an account that has no classes this term. Tap 'Nhập', tap "
        "'Chọn file', pick lop-fall-2026.csv from Downloads, tap 'Nhập' and wait for the result screen. Report the "
        "large title and the line under it. Tap 'Tổng quan' and report the text under the first class card.",
        expect='{"title": string, "subtitle": string, "first_card_status": string}',
        timeout=900,
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("title", "").startswith("Đã gửi")
    assert "Chờ giáo vụ duyệt" in r.output.get("subtitle", "")
    assert r.output.get("first_card_status") == "Chờ giáo vụ duyệt"
    assert analytics_logged("import_classes")


async def test_tc18_approval_updates_app(agent, fresh_app):
    """Bước 3: điều kiện đầu là giáo vụ đã duyệt lớp SE1801 trên web admin (app đang mở thì tự đổi)."""
    subject = env("QA_APPROVED_CLASS", "PRM393 · SE1801")
    r = await agent.run(
        "Hereby is open on 'Tổng quan'. Report whether a card saying 'Chờ giáo vụ duyệt' still shows for "
        f"{subject}. Tap the mail icon in the top bar. Report the title of the first message in 'Hộp thư'. "
        "Tap it and report the title of the screen that opens.",
        expect='{"still_pending": boolean, "first_message": string, "opened_title": string}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("still_pending") is False
    assert r.output.get("first_message", "").endswith("đã được duyệt")
    assert subject.split(" · ")[1] in r.output.get("opened_title", "")


@pytest.mark.error_path
async def test_tc19_rejection_shows_reason(agent, fresh_app):
    """Đường lỗi: điều kiện đầu là giáo vụ đã từ chối lớp với lý do QA_REJECT_REASON."""
    reason = env("QA_REJECT_REASON", "Sai danh sách")
    r = await agent.run(
        "Hereby is open on 'Tổng quan'. Find the card saying 'Bị từ chối'. Report the reason text on the card "
        "and whether a button 'Nhập lại' is shown. Tap 'Nhập lại' and report the screen title.",
        expect='{"reason": string, "has_resubmit": boolean, "opened_title": string}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("reason") == reason
    assert r.output.get("has_resubmit") is True
    assert r.output.get("opened_title") == "Nhập lớp"


async def test_tc20_announcement_in_inbox(agent, fresh_app, analytics_debug):
    """Điều kiện đầu: thông báo tiêu đề QA_ANNOUNCEMENT_TITLE đã đăng cho Giảng viên hoặc Tất cả."""
    title = env("QA_ANNOUNCEMENT_TITLE", "Lịch nghỉ lễ")
    r = await agent.run(
        "Hereby is open. Tap the mail icon in the top bar of 'Tổng quan'. In 'Hộp thư' report the titles of all "
        "visible messages. Go back and report whether the red dot still shows on the mail icon.",
        expect='{"titles": [string], "dot_after_open": boolean}',
    )
    assert r.status in ("completed", "success"), r.error
    assert title in r.output.get("titles", [])
    assert r.output.get("dot_after_open") is False
    assert analytics_logged("inbox_open")


async def test_tc21_ai_draft_is_labelled_and_editable(agent, fresh_app, analytics_debug):
    """AI: gợi ý có nhãn, sửa được, gửi xong ghi ai_result_accepted. Cần ai_reminder_enabled=true và mạng."""
    r = await agent.run(
        "Hereby is open on 'Tổng quan'. Tap 'Xem tất cả' next to 'Vắng nhiều', open the first student, tap "
        "'Nhắc nhở'. Tap 'Gợi ý AI' and wait up to 30 seconds. Report the label under the text box and the full text "
        "in the box. Add the word ' Cảm ơn em.' at the end of the text, then tap 'Gửi' and report the button label "
        "shown at the bottom afterwards.",
        expect='{"label": string, "draft": string, "button_after": string}',
        timeout=900,
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("label", "").startswith("AI gợi ý")
    assert len(r.output.get("draft", "")) > 10
    assert r.output.get("button_after") == "Đã nhắc"
    assert analytics_logged("ai_request")
    assert analytics_logged("ai_result_accepted")


@pytest.mark.error_path
async def test_tc22_ai_off_flow_still_works(agent, fresh_app):
    """Điều kiện đầu: Remote Config ai_reminder_enabled=false đã phát hành, app đã tải (Khu demo → Tải lại)."""
    r = await agent.run(
        "Hereby is open on 'Tổng quan'. Tap 'Xem tất cả' next to 'Vắng nhiều', open the first student, tap "
        "'Nhắc nhở'. Report whether a button 'Gợi ý AI' is visible and the text in the box.",
        expect='{"ai_button": boolean, "text": string}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("ai_button") is False
    assert r.output.get("text", "").startswith("Em đã vắng")
