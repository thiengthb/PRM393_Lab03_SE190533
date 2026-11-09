# Slide thuyết trình Attendo

Hai bộ slide dạng trang web tự dựng (thien chốt 09/11/2026, xem `docs/slides/DAN-Y.md`):

| Bộ | Nguồn | Nội dung |
|---|---|---|
| Lab 3 · Công nghệ | `src/lab3.html` | Mỗi dịch vụ Firebase: là gì, ai cấp, lưu ở đâu, code ở file nào, lỗi thì sao, bằng chứng |
| Final · Hệ thống | `src/final.html` | Theo guideline V11: vấn đề, thiết kế, demo theo workflow, bằng chứng |

Bản đăng: GitHub Pages của repo (nhánh `gh-pages`, workflow `Slides` tự dựng mỗi lần sửa `slides/`).

## Trình chiếu
Mở bằng Chrome hoặc Edge, bấm **F** để toàn màn hình.

| Phím | Việc |
|---|---|
| → Space PageDown, hoặc bấm vào 2/3 bên phải | Tiếp (hiện từng bước nếu slide có bước) |
| ← PageUp, hoặc bấm vào 1/3 bên trái | Lùi |
| N | Ghi chú lời nói ở đáy màn |
| P | Mở cửa sổ người nói (ghi chú, slide tiếp, đồng hồ); hai cửa sổ đi cùng nhau |
| T | Bắt đầu / dừng đồng hồ |
| K | Soi bằng chứng: tô mọi con số có nguồn. Bấm vào số có gạch chấm để xem ảnh và link |
| D | Sáng / tối |
| O | Xem tổng quan, bấm một slide để nhảy tới |
| Ctrl+P | In ra PDF (mỗi slide một trang) |

Không cần mạng khi chiếu: chép cả thư mục `site/` (sau khi build) vào USB là chạy.

## Sửa slide
- Nội dung và ghi chú: `src/lab3.html`, `src/final.html`. Mỗi slide là một `<section class="slide" data-title data-sec>`, ghi chú trong `<aside class="notes">`.
- Bằng chứng: `src/proofs.js`. Số trên slide viết `<span class="pf" data-p="id">…</span>`. **Chỉ ghi thứ đã chạy thật** (AGENTS.md); chưa có thì ghi "chưa kiểm".
- Màu, chữ, bố cục: `src/deck.css` (màu lấy từ bảng mặc định Bản vẽ của app, D-T-09). Điều khiển: `src/deck.js`.
- Ảnh: `assets/img/app/` (màn app, chụp từ E2E hoặc máy thật), `assets/img/ev/` (bản sao ảnh trong `evidence/`).

## Build và kiểm tra
```
pip install playwright
python -m playwright install chromium
python slides/build.py --pdf --check
```
Ra `site/` (trang web và PDF) và `check/` (ảnh từng slide ở hai kiểu sáng, tối, kèm báo chỗ tràn mép). Hai thư mục này không commit.

## Việc còn lại
- Chụp lại ảnh app sau mốc đóng băng giao diện (trưa 11/11); ảnh hiện tại chụp từ E2E trên Emulator ngày 09/11.
- Điền khi có: ảnh DebugView, kết quả ARTEMIS, review AI trên PR, số giây duyệt lớp (T3).

Phông: Onest và IBM Plex Mono, giấy phép SIL OFL 1.1 (`assets/fonts/OFL.txt`).
