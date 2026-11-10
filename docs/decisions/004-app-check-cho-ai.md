# 004. App Check cho nút Gợi ý AI

Ngày: 09/11/2026 · Trạng thái: Đã chọn · Người quyết: thien

## Cần quyết gì
Từ 02/11/2026, Firebase bắt buộc App Check cho Firebase AI Logic và không cho tắt (console chỉ còn "Show details", trạng thái "Basic - Enforced"). Nguồn: Firebase release notes 27/10/2026, trang AI Logic monitoring. APK demo cài ngoài Play Store không qua được Play Integrity nên không có token, và nút Gợi ý AI bị chặn: lần thử 09/11 trên project attendo-app-2611 trả về "Firebase App Check token is invalid" (LOI-15). Đề nói chấm trên máy thật, nên AI phải chạy trên một APK tự cài.

## Các phương án đã xét
| Phương án | Lúc nào nó là lựa chọn tốt | Lý do mạnh nhất để không chọn |
|---|---|---|
| A. Một debug token chung: tạo trên console, lưu ở GitHub secret `APP_CHECK_DEBUG_TOKEN`, dựng vào APK demo bằng `--dart-define` | Không biết trước máy chấm; cần AI chạy trên mọi máy cài APK | Token nằm trong APK, ai mổ APK thì dùng được quota Gemini miễn phí của project. Phải xoá token sau khi chấm |
| B. Token riêng từng máy (debug provider in token ngẫu nhiên ra Logcat, đăng ký từng cái) | Chỉ vài máy cố định | Thầy cài trên máy khác hoặc cài lại là AI hỏng tới khi đăng ký lại |
| C. Play Integrity thật: đưa app lên Play Console (kênh internal testing) | Sản phẩm thật | Phí 25 USD, chờ duyệt; không kịp 13/11 |
| D. Bỏ AI khi chấm, dùng câu mẫu | Không muốn đụng bảo mật | Mất phần AI mức 2 của đề Final |

## thien chọn
A (09/11, 11:12).

## AI chọn
A. Gói Spark không tính tiền, nên lộ token chỉ mất quota miễn phí; token thu hồi được bất cứ lúc nào trên console.

## Kết luận
A. Token không vào repo: chỉ ở GitHub secret và file `~/develop/attendo-config/app-check-debug-token.txt` trên laptop của thien (dev.ps1 đọc file này). Bản không có token vẫn dùng Play Integrity như cũ.

Việc phải làm sau khi chấm xong: console → Security → App Check → Apps → app Android → Manage debug tokens → xoá token `attendo-demo`; xoá secret `APP_CHECK_DEBUG_TOKEN`.
