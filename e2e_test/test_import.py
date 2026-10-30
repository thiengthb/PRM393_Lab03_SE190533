"""TC-03, TC-04: nhập lớp từ file (FL-0, FL-0b, GV-100)."""

import pytest

from conftest import analytics_logged, push_file


@pytest.mark.error_path
@pytest.mark.native
async def test_tc03_import_file_with_errors(agent, fresh_app):
    push_file("sample-data/lop-co-loi.csv", "lop-co-loi.csv")
    r = await agent.run(
        "Quick Attend is open, signed in as a lecturer. Open the 'Tài khoản' tab (last bottom icon), tap "
        "'Nhập danh sách lớp', then tap 'Chọn file'. In the Android file picker, open Downloads and choose "
        "'lop-co-loi.csv'. Back in the app, report the heading that says how many rows have errors, and the "
        "list of row numbers shown (e.g. 'Dòng 3'). Do not tap 'Bỏ qua'.",
        expect='{"heading": string, "error_rows": [integer]}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("heading") == "2 dòng lỗi, chưa nhập"
    assert sorted(r.output.get("error_rows", [])) == [3, 4]


@pytest.mark.native
async def test_tc04_import_valid_file(agent, fresh_app, analytics_debug):
    push_file("sample-data/lop-fall-2026.csv", "lop-fall-2026.csv")
    r = await agent.run(
        "Quick Attend is open, signed in as a lecturer. Open the 'Tài khoản' tab, tap 'Nhập danh sách lớp', "
        "tap 'Chọn file', pick 'lop-fall-2026.csv' from Downloads. On the preview, tap 'Nhập' at the bottom "
        "and wait until a screen titled 'Đã nhập N lớp' appears. Report N and the number of slots per week shown.",
        expect='{"classes_imported": integer, "weekly_slots": integer}',
    )
    assert r.status in ("completed", "success"), r.error
    assert r.output.get("classes_imported") == 4
    assert r.output.get("weekly_slots") == 8
    assert analytics_logged("import_classes")
