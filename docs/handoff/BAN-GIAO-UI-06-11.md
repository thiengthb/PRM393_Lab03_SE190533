# Bàn giao giao diện Hereby, 06/11/2026

Tài liệu này để làm tiếp phần giao diện từ một tài khoản Claude khác, không cần chat cũ.
Bản cũ hơn (Lab 3, 03/11) ở `docs/handoff/BAN-GIAO.md`; phần Firebase, laptop, tài khoản trong đó vẫn đúng.

**Câu dán để mở chat mới:**

> Gắn repo `thiengthb/PRM393_Lab03_SE190533` với quyền push. Đọc `docs/handoff/BAN-GIAO-UI-06-11.md` trên nhánh `claude/ui-redesign-teal`, tóm tắt cho mình trong vài câu, rồi làm tiếp từ mục 6 "Việc tiếp theo". Nhắn với mình bằng tiếng Việt.

## 1. Bối cảnh ngắn

- **Hereby**: điểm danh bằng mã QR cho FPTU. Một monorepo Flutter: `mobile/` (app giảng viên Android + Windows, và web sinh viên khi build `--dart-define=PORTAL=student`), `web/` (web admin), `packages/core` (theme, widget, service dùng chung), `extension/` (extension Chrome "Hereby cho FAP", React + shadcn), `fap-mock/`, `firebase/`.
- **Hạn cuối mọi thứ** (Lab 3 + Final + slide + video): **thứ Sáu 13/11/2026**. Mốc đóng băng giao diện tự đặt: trưa thứ Tư 11/11.
- Nhánh gốc của bài Final: `final-system`.

## 2. Thiết kế đã chốt (thien chọn ngày 05-06/11)

| Mục | Chốt | Ở đâu trong code |
|---|---|---|
| Phong cách | Kiểu thienui / shadcn: thẻ trắng viền 1, không bóng, không gradient; bo 6 (nút, ô nhập, tabs) và 10 (thẻ, hộp thoại); chữ giao diện 14; mục chọn nền xám trung tính | `packages/core/lib/theme/app_theme.dart`, `packages/core/lib/widgets/*` |
| Bảng màu | **C "Xanh xô thơm"**: primary `#386F5F` (nút chính chữ trắng), primary-edge `#295E4F`, soft `#EAF7F2`, on-soft `#275749`; nền `#FBFAF8`, muted `#F1F0EC`, viền `#E1E0DA`, mực `#1C1B16`, chữ phụ `#6A6963`; thành công `#397949`, cảnh báo `#8D5E00`, lỗi `#AB413E` | `packages/core/lib/theme/tokens.dart` (`AppColors`, `AppPalette.teal`: id giữ `teal` cho lựa chọn đã lưu, tên hiện "Xô thơm") |
| Font | Be Vietnam Pro, đóng gói sẵn (không tải mạng) | `packages/core/fonts/`, `AppFont.family` |
| Logo | Chấm tròn giữa khung ngắm bốn góc, nền phẳng màu primary | `design/icon/hereby-app-icon.svg`, `BrandMark` trong `packages/core/lib/widgets/brand.dart`, icon Android `mipmap-*`, Windows `app_icon.ico`, web `icons/`, `favicon.png` |
| Tên | Giữ **Hereby** | |
| Icon giao diện | **Lucide** (gói `lucide_icons_flutter`), không dùng `Icons.*` của Material nữa | Import `package:quick_attend_core/theme/app_icons.dart` rồi dùng `LucideIcons.xxx` |
| Figma | **Bỏ hẳn** từ 05/11; luật Lab 2 không còn ràng buộc Lab 3 / Final | |

Mọi quyết định giao diện ghi ở `docs/design-traceability.md`, mục D-U-01 đến D-U-15. Trang so sánh 3 bảng màu, 4 logo, 3 tên: https://claude.ai/artifact/RyjCyWBCdybbWt4SBFtwCP (tài khoản mới có thể không mở được; nội dung chính đã ghi ở bảng trên).

**Đổi màu thì sửa một chỗ:** `tokens.dart`, rồi chạy `node tool/tokens/gen_css.mjs` để sinh lại `design/tokens/hereby.css` (extension đọc file này; biến có tiền tố `--hb-`). Test `mobile/test/tokens_css_test.dart` báo nếu hai file lệch. Nếu đổi màu logo thì vẽ lại icon (mục 5).

## 3. Các PR đang mở

Chồng PR giao diện, **merge đúng thứ tự** (mỗi PR xếp trên PR trước):

| Thứ tự | PR | Nhánh | Nội dung |
|---|---|---|---|
| 1 | #10 | `claude/ui-p0-audit` | Web admin chạy được trên Firebase Emulator (`EMULATOR_HOST`, `EMULATOR_LOGIN`) |
| 2 | #12 | `claude/ui-p1-core` | Font đóng gói, `AppSideNav` chung, chữ màn rộng, token CSS |
| 3 | #13 | `claude/ui-p2-lecturer` | App giảng viên dùng hết màn rộng (Windows) |
| 4 | #14 | `claude/ui-p3-student` | Web sinh viên gọn trên màn rộng |
| 5 | #15 | `claude/ui-p4-admin` | Web admin bớt chữ |
| 6 | #16 | `claude/ui-redesign-teal` | **Thiết kế lại toàn bộ**: phong cách shadcn, bảng Xanh xô thơm, Be Vietnam Pro, logo mới, Lucide, bố cục mới (thẻ chào, danh sách gộp, màn TV, đăng nhập chia đôi) |

Riêng: **#11** `claude/project-thread-2h44q5` → `final-system`: extension đổi sang Hereby. Lúc viết tài liệu này PR #11 còn theo bảng B "Teal + san hô"; cần đổi sang Xanh xô thơm (màu trong `extension/src/styles/globals.css`, icon `extension/public/icons/*` vẽ lại từ SVG logo, mô tả PR). Icon trong extension đã là Lucide (`lucide-react`).

**#1** (Cloudinary, vào `ui-v2`) đã có trong `final-system` qua PR #2; có thể đóng.

CI của #16 xanh tới commit `0768863`; các commit sau (`f3353c5`, `a455eb3`) đã chạy `flutter analyze` và `flutter test` trên máy cloud: mobile 48/48, web 11/11, chỉ còn 2 info `deprecated_member_use` có từ trước ở `messaging_service.dart`.

## 4. Ảnh chụp mới nhất

Thư mục dự án (project files, không nằm trong repo): `lab3-hereby/ui-teal/` có các bản qua từng vòng: `shadcn/`, `teal-sau/`, `teal-san-ho/`. Bản Xanh xô thơm chưa lưu riêng; chụp lại theo mục 5 nếu cần.

## 5. Cách chụp màn trên máy cloud (không cần điện thoại)

Máy cloud chạy được Flutter web + Firebase Emulator. Các bước (Flutter 3.47.3 ở `/opt/flutter-sdk/flutter/bin`; nếu máy mới chưa có thì tải bản linux từ storage.googleapis.com):

```bash
# 1. Emulator + dữ liệu mẫu
cd firebase/tests && npm ci
npx firebase emulators:start --config ../firebase.json --project hereby-se190533 --only auth,firestore &
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 node seed-demo.mjs --reset

# 2. Build web (từ gốc repo)
(cd web && flutter build web --release --no-web-resources-cdn --dart-define=EMULATOR_HOST=localhost --dart-define=EMULATOR_LOGIN=admin@fe.edu.vn)
(cd mobile && flutter build web --release --no-web-resources-cdn --dart-define=EMULATOR_HOST=localhost --dart-define=PORTAL=lecturer -o build/web-lecturer)
(cd mobile && flutter build web --release --no-web-resources-cdn --dart-define=EMULATOR_HOST=localhost --dart-define=PORTAL=student -o build/web-student)
```

3. Phục vụ mỗi thư mục build bằng một server tĩnh có SPA fallback (mọi đường dẫn không có file trả `index.html`).
4. Chụp bằng Playwright (Chromium có sẵn trên máy cloud). Mẹo đã kiểm:
   - Chặn `fonts.googleapis.com` / `fonts.gstatic.com`; chuyển `www.gstatic.com/firebasejs/<ver>/<file>` sang `firebase/tests/node_modules/firebase/<file>` bằng `context.route`, vì máy cloud không vào được gstatic.
   - Đăng nhập: bấm `flt-semantics-placeholder` để bật semantics, rồi `getByRole('textbox')`; ô email dùng `fill`, ô mật khẩu phải **bấm vào rồi `keyboard.type`** (fill không ăn).
   - Chuyển màn bằng **bấm chuột theo toạ độ**; `page.goto` thẳng đường dẫn con ra trang trắng. Trên khung 390×844, thanh tab đáy ở y ≈ 782 (dải chữ đỏ "Running in emulator mode" che phần dưới).
   - Tài khoản mẫu (mật khẩu `Demo@123`): `quanm@fe.edu.vn` giảng viên, `dung101@fpt.edu.vn` sinh viên, `admin@fe.edu.vn` quản trị, `giaovu@fe.edu.vn` giáo vụ.
5. Vẽ lại icon app từ SVG: render SVG bằng Playwright ra PNG đúng kích thước từng file (`mipmap-*` 48-192, web `Icon-192/512`, `Icon-maskable-*` nền tràn và hình thu 78%, `favicon` 16/32), gộp `app_icon.ico` 16-256 bằng Pillow.

## 6. Việc tiếp theo

1. **Bạn xem lại** giao diện bảng Xanh xô thơm (chạy app trên điện thoại hoặc Windows từ nhánh `claude/ui-redesign-teal`) và báo chỗ chưa ưng.
2. **Merge chồng PR** #10 → #12 → #13 → #14 → #15 → #16 vào `final-system` (từng cái, đợi CI xanh). Khi merge #10 xong, GitHub tự đổi base của #12 về `final-system`, cứ thế tiếp.
3. **PR #11 extension**: đổi sang Xanh xô thơm như mục 3, rồi merge sau #16 để map biến shadcn sang `--hb-*` của `design/tokens/hereby.css`.
4. **Soát lần cuối trên máy thật**: Android (OPPO A5 2020) và bản Windows; màn TV `/tv/:key`; chế độ tối chưa làm (app chỉ có giao diện sáng).
5. **P6**: ảnh màn và slide trình bày (bạn thích PPTX, mỗi lần sửa một số phiên bản mới, nét đậm hơn thay vì chữ to hơn).
6. Phần Lab 3 còn lại (cần máy bạn): DebugView, chạy ARTEMIS trên máy thật, chụp bằng chứng vào `evidence/`, PR cho công cụ AI review, video.

## 7. Cách làm việc với thien

- Nhắn tiếng Việt, câu đủ ý, ít thuật ngữ; giải thích khi cần.
- Thích được xem trước rồi chọn (trang so sánh 2-3 phương án), sau đó làm thẳng.
- Commit với `user.name=thiengthb`, `user.email=tranngocthien697@gmail.com`. Không đưa tên model vào commit hay PR.
- Laptop: Windows PowerShell 5, repo ở `C:\Users\trann\develop\PRM393_Lab03_SE190533`; đưa mỗi lệnh một dòng, không dùng `&&`.
- Firebase project `hereby-se190533`, đăng nhập bằng tài khoản Google `tranngocthien024@gmail.com`; gói Spark (không Blaze, không Cloud Storage; file lên Cloudinary).
