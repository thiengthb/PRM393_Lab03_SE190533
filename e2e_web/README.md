# Test luồng trên web (Playwright + Firebase Emulator)

Bấm qua các luồng như người dùng thật trên bản web của app (giảng viên `PORTAL=lecturer`, sinh viên
`PORTAL=student`) và web admin, dữ liệu là Firebase Emulator nạp bằng `firebase/tests/seed-demo.mjs`.
Không thay ARTEMIS: phần cần điện thoại thật (camera, FCM, Crashlytics, DebugView, hộp chọn file Android)
vẫn test bằng ARTEMIS theo `docs/test-plan.md`.

Mỗi test tự nạp lại dữ liệu mẫu (`--reset --live-now`), nên chạy riêng lẻ hay theo thứ tự nào cũng được.
`--live-now` kéo một slot trùm lên giờ hiện tại để lúc nào chạy cũng có slot đang diễn ra.

## Chạy trên CI

Workflow `.github/workflows/e2e-builds.yml` (đẩy lên nhánh `claude/e2e-flows` hoặc bấm *Run workflow*):
analyze, test, dựng 4 bản web với `EMULATOR_HOST=localhost`, chạy cả bộ test này, đính kèm ảnh màn và
`junit.xml` (artifact `e2e-web-shots`), rồi đẩy bản dựng lên nhánh `e2e-builds` để chạy lại ở máy khác.

## Chạy ở máy

```bash
# 1. Bản web dựng sẵn (hoặc tự dựng như trong workflow)
git clone --depth 1 -b e2e-builds https://github.com/thiengthb/PRM393_Lab03_SE190533 ../e2e-builds
# 2. Emulator
cd firebase/tests && npm ci
npx firebase-tools emulators:start --config ../firebase.json --project hereby-se190533 --only auth,firestore &
# 3. Server tĩnh: giảng viên :5001, sinh viên :5002, admin :5003, giáo vụ :5004
cd ../../e2e_web && python serve.py ../../e2e-builds &
# 4. Test
pip install playwright pytest && python -m playwright install chromium
python -m pytest -q
```

Ảnh màn ghi vào `e2e_web/shots/` (đổi bằng biến `SHOTS`).

## Bộ test

| File | Luồng |
|---|---|
| `test_lecturer.py` | W01 sai mật khẩu; W02 Tổng quan, 4 tab, chi tiết lớp; W03 phiên điểm danh: mã số, sinh viên nhập sai/đúng, màn TV, đóng/mở lại mã, chốt, hoàn tác; W04 chốt slot quên; W05 Vắng nhiều → Nhắc nhở; W06 em đã fail không có Nhắc nhở; W07 đăng xuất |
| `test_student.py` | W10 số vắng ở danh sách = chi tiết; W11 báo sai → giảng viên duyệt → web đổi; W12 từ chối có lý do; W13 tài khoản, đăng xuất |
| `test_cross_role.py` | W20 giảng viên mới đăng ký → nhập file → quản trị duyệt / từ chối → app đổi ngay, hộp thư có tin |
| `test_admin.py` | W30 số liệu Tổng quan; W31 thông báo tới hộp thư sinh viên, lưu trữ thì biến mất; W32 môn học: trùng mã, sai định dạng, thêm, lưu trữ, khôi phục; W33 người dùng, giáo vụ bị chặn |
| `test_more.py` | W40 file lỗi; W41 link TV sai; W42 đổi màu; W43 khu demo; W44 quên mật khẩu; W45 sửa buổi đã chốt; W46 màn rộng; W47 sinh viên đăng ký |

Cách bấm: bật cây semantics của Flutter (như trình đọc màn hình), tìm phần tử theo chữ / nhãn rồi bấm.
Vì vậy test cũng bắt được lỗi trợ năng (nút không có hành động bấm, chữ bị gộp vào node khác).
