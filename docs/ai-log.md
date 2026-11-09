# Nhật ký dùng AI

Bài môn học PRM393 (Lab 3 và Final). Khuôn lấy từ `templates/AI-LOG.template.md` của repo thienai-workflow. Đề môn có mẫu riêng thì theo mẫu đó, giữ các cột dưới đây nếu mẫu thiếu.

## Khai báo công cụ

| Công cụ | Tài khoản của ai | Dùng vào việc gì | Không dùng vào việc gì |
|---|---|---|---|
| Claude (Anthropic), kèm Figma MCP tới 05/11 | thien | Đọc Figma; viết tài liệu; sinh mã Flutter, Security Rules, test, tài liệu `docs/`; tách monorepo; dựng giao diện, web admin, hộp thư, tính năng AI, extension; review mã (CR-01 đến CR-14); chụp màn trên Emulator bằng Playwright | (thien điền) |
| Google Gemini qua Firebase AI Logic | project `hereby-se190533` | Tính năng gợi ý lời nhắc trong app | (thien điền) |
| Google ARTEMIS | thien | Test E2E trên Android, phiên khám phá | (thien điền) |
| CodeRabbit hoặc GitHub Copilot | thien | Review pull request (chưa chạy) | (thien điền) |

## Nhật ký

AI-01 đến AI-09 ghi bù ngày 08/11/2026 từ lịch sử git: mỗi dòng là một phiên Claude có link trong commit (dòng `Claude-Session`). Prompt của các phiên này không lưu trong repo, nên cột prompt chỉ có link phiên.

| Mã | Ngày | Người | Công cụ | Việc | Prompt chính hoặc link phiên | Kết quả AI | Người kiểm gì | Quyết định | Bằng chứng |
|---|---|---|---|---|---|---|---|---|---|
| AI-01 | 30/10 | thien | Claude | Hoàn thiện mã Lab 3: sửa lỗi `flutter analyze`, thêm `android/`, `web/`, truy vết khung Figma | [phiên](https://claude.ai/code/session_01WXAvBXRn2dGa3TBETt24oY) | Mã Lab 3 bản cam trên `main` | | | `5ff0479`, `1e89719`, `5435678` |
| AI-02 | 02/11 | thien | Claude | Bài Final: gap review, Rules theo vai trò, web admin, luồng liên vai trò, tính năng AI, CI; Giai đoạn 0 nối Firebase | [phiên](https://claude.ai/code/session_01WXAvBYyfDTNCvruUXa7sKZ) | Nhánh `final-system`, 118 ca test Rules | | | `552e8f9`, `0afd0da`, `10fbd22`, `f6ae641` |
| AI-03 | 03/11 đến 04/11 | thien | Claude | Dựng giao diện v2 (Hereby, Biển sâu), mã số 6 chữ, màn TV, màn sinh viên, sửa 16 ca ARTEMIS, PDF lưu trên máy | [phiên](https://claude.ai/code/session_01URCHsPodKMj2xsrKMMxXc9) | Nhánh `ui-v2` | | | `ea62ac9`, `4737ed5`, `5313ee9`, `cae186a`, `6886a4a` |
| AI-04 | 04/11 | thien | Claude | Viết bàn giao phần đã xong và việc cần máy của thien | [phiên](https://claude.ai/code/session_01LiS5Xpef69tSrxQ5V9XfD1) | `docs/handoff/BAN-GIAO.md` | | | `a154bc6` |
| AI-05 | 05/11 | thien | Claude | Bản Windows, FAP giả lập và extension, FCM, Cloudinary thay Cloud Storage, web admin nối Firebase | [phiên](https://claude.ai/code/session_01URCHsRGf3PmP1QcwQFrHiG) | PR #2 đến #8 | | | `7196179`, `51e359b`, `7cac776`, `9328541`, `61f0ebc` |
| AI-06 | 05/11 | thien | Claude | Sửa toast Hoàn tác, mở lại mã ở slot đã qua; extension đọc trang FAP giả lập | [phiên](https://claude.ai/code/session_01URCHsQrZCbBZKrZ8uTqsAn) | PR #9 | | | `8549b29`, `2d8afa8` |
| AI-07 | 05/11 đến 06/11 | thien | Claude | Thiết kế lại giao diện theo thienui (3 bảng màu, 4 logo), màn rộng, web admin trên Emulator | [phiên](https://claude.ai/code/session_01URCHsRqj7jWggP1hnxneNw) | PR #10, #12 đến #16 | | | `1077469`, `175bc35`, `f3353c5`, `a455eb3`, `a99ad7c` |
| AI-08 | 05/11 đến 06/11 | thien | Claude | Extension đổi sang Hereby, theo bảng màu của app | [phiên](https://claude.ai/code/session_01URCHsNZbSHWF7DNruLk2C3) | PR #11 | | | `1f3b387`, `73ade09` |
| AI-09 | 06/11 | thien | Claude | Áp thienui Xanh ngọc và Onest, đổi thương hiệu Attendo, sửa CI test luồng web, chốt lúc mất mạng | [phiên](https://claude.ai/code/session_01LiS5XnHzKcDGStTG6wuXx4) | PR #17 | | | `c7ac96e`, `c0cb08c`, `71045b2`, `5f7d2fb` |
| AI-10 | 08/11 | thien | Claude | Áp quy trình thienai-workflow vào repo: `AGENTS.md`, `CLAUDE.md`, `docs/STATUS.md`, `docs/decisions/`, nhật ký này | "Đọc repo thienai workflow và áp các quy trình của nó lên project fap" | PR thêm các file trên | | | PR từ nhánh `docs/thienai-workflow` |
| AI-11 | 08/11 | thien | Claude | Gộp chồng PR giao diện #10 đến #17; chuẩn bị test tay và demo: bản cài dựng sẵn, workflow Firebase thật, dữ liệu demo, test W60, W61, W70, W71, sửa 5 test ghi cứng ngày, tài liệu hướng dẫn và nhật ký lỗi | "Làm document hướng dẫn tôi test tay và tự chạy toàn bộ phần mềm... test trước đảm bảo không có lỗi"; [phiên](https://claude.ai/code/session_01WXAvBWuNBPbdkG9oK6j8hR) | PR #19, `docs/demo/HUONG-DAN.md`, `docs/demo/loi.md` | | | PR #19, CI E2E builds run 42465928241 (31 ca đạt) |
| AI-12 | 09/11 | thien | Claude | Kế hoạch 09-13/11; vòng sửa nhanh trên laptop; CI gọn; đổi tên Attendo và Firebase mới; giao diện desktop (3 hướng, thien chọn A); web admin dạng bảng; Hosting 4 trang; LOI-05 | [phiên](https://claude.ai/code/session_01WXAvBZf1KHoWfb91p47mTz) | PR #27 | | | `7389f43`, `fe71f7b`, `1ecacbd`, `ddcf12c`, `9708d6c` |
| AI-13 | 09/11 | thien | Claude | Tự test trên Firebase thật (điện thoại qua cáp, web sinh viên, web giảng viên): ca T1, T2, T4 (AI), Cloudinary, non-fatal, Test crash. Sửa LOI-15 (App Check, quyết định 004), LOI-17 đến LOI-23, lỗi mã số chậm khi mở phiên, lỗi script dev | [phiên](https://claude.ai/code/session_01WXAvBZf1KHoWfb91p47mTz) | PR #27 | | | `c4894f8`, `864efd7`, `ac68a01`, `3e7f262`, `efec85c` |
| AI-14 | 09/11 | thien | Claude | LOI-14: tìm lỗi gốc trên web admin thật (chỉ mục tổng hợp sai thứ tự trường, lỗi JS thô trên web không đọc được mã), sửa và kiểm sau khi deploy. W70: dựng lại trên Emulator, nguyên nhân là phím Esc rời phiên laptop; sửa app theo lựa chọn của thien. LOI-20 kiểm trên app Windows; màn Sự cố kiểm trên Firebase thật, thêm E2E W34; sửa LOI-06, 07, 21, 24 | [phiên](https://claude.ai/code/session_01WXAvBY92FJWWaurr9uVYWH) | PR #27 | | | `ff734c2`, `8ec6244`, `ae36281`, CI E2E builds 42594858960 (32 ca đạt) |
| AI-15 | 09/11 | thien | Claude | Slide web hai bộ (Lab 3, Final) theo dàn ý thien duyệt: khung trình chiếu tự dựng (ghi chú, cửa sổ người nói, soi bằng chứng, PDF), nội dung và ghi chú lời nói, workflow đăng GitHub Pages | "một web như của project mln, nhưng chuyên nghiệp hơn"; [phiên](https://claude.ai/code/session_01WXAvBY92FJWWaurr9uVYWH) | `slides/`, workflow Slides | | | `0a847f8`, run 42630118800 |
| AI-16 | 09/11 | thien | Claude | Đổi màu mặc định toàn hệ thống: so 3 bảng (Xanh ngọc, Bản vẽ, Tím) trên các màn tiêu biểu, áp Bản vẽ cho app, web, extension, icon, slide (một hằng `AppPalette.fallback`); chấm cam trong logo chữ; chụp lại ảnh app cho slide | "cần một màu khác biệt, có thể là màu tím hoặc là màu trong slide của project mln"; [phiên](https://claude.ai/code/session_01WXAvBY92FJWWaurr9uVYWH) | D-T-09, D-T-10 | | | `f6ce1e4`, `997aa64`, `9daa0d4`, E2E run 42644368921 |

- **AI điền** mọi cột trừ "Người kiểm gì" và "Quyết định", cuối mỗi phiên, một dòng cho mỗi việc đáng kể.
- **Người điền** hai cột còn lại. "Người kiểm gì": kiểm cụ thể cái gì, bằng cách nào (đọc lại nguồn gốc, chạy test, so với đề). "Quyết định": Accept, Modify hoặc Reject, kèm một câu lý do.
- AI không tự điền hai cột đó, kể cả khi được nhờ. Dòng nào còn trống hai cột này thì chưa được coi là xong.
- "Bằng chứng": commit, PR, ảnh, hoặc link phiên chat.

## Vì sao người phải tự điền
Cột kiểm chứng là thứ giảng viên chấm: dùng AI mà không kiểm hoặc không giải thích được thì bị điểm 0 phần đó (MLN122). Nhật ký dài mà cột này trống còn tệ hơn không có nhật ký, vì nó cho thấy AI làm hết.
