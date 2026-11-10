# Việc còn lại trước hạn nộp 13/11, theo thứ tự làm

Viết 10/11/2026 20:40. Mỗi phần ghi: làm ở đâu, bấm gì, thấy gì là đúng, và 📸 chụp ngay tại bước đó. Phần nào đã có hướng dẫn riêng thì ở đây chỉ ghi phần còn thiếu và trỏ sang file đó. PowerShell: mỗi dòng một lệnh, gõ xong một dòng mới gõ dòng sau.

Tổng thời gian khoảng 3 giờ, chưa tính quay video. Chia gợi ý: **tối 10/11** làm phần 1 đến 5; **sáng 11/11** phần 6 (ARTEMIS) nếu thầy đã trả lời; **chiều 11/11** (sau mốc đóng băng giao diện) phần 7, 8; **12/11** phần 9.

| # | Việc | Ai | Mất | Cần laptop |
|---|---|---|---|---|
| 1 | Xác nhận 9 quyết định review CodeRabbit | thien | 10 phút | Không, làm trên điện thoại được |
| 2 | Gộp PR #29 rồi PR #30 | thien | 10 phút | Không |
| 3 | Chạy workflow nạp lại dữ liệu và deploy Rules | thien | 5 phút | Không |
| 4 | Chụp ảnh console Lab 3 còn thiếu | thien | 40 phút | Có, kèm điện thoại |
| 5 | Chụp 2 ảnh CodeRabbit | thien | 5 phút | Có |
| 6 | ARTEMIS | thien | 1 đến 2 giờ | Có, kèm điện thoại |
| 7 | Chụp lại ảnh app cho slide | Claude | | |
| 8 | Quay video Lab 3 và Final, đo WF-03 | thien | 2 giờ | Có |
| 9 | Hai câu trả lời, nhắn thầy, nộp | thien + Claude | 20 phút | Không |

---

## 1. Xác nhận 9 quyết định review CodeRabbit (10 phút)

Đề Lab 3 mục 8: AI tìm, **người quyết**. Claude đã sửa theo đề xuất nhưng cột Quyết định đang ghi "Đề xuất", chờ bạn.

1. Mở [docs/code-review.md trên nhánh PR #30](https://github.com/thiengthb/PRM393_Lab03_SE190533/blob/claude/project-thread-uaz0j1/docs/code-review.md#lượt-2b-coderabbit-tự-review-pr-29), kéo tới mục **Lượt 2b**.
2. Đọc 9 dòng CR-31 đến CR-39, mỗi dòng có cột "Lý do".
3. Nhắn Claude một câu, ví dụ: "đồng ý hết" hoặc "đồng ý hết, trừ CR-39: sửa luôn".

**Sau đó:** Claude đổi "Đề xuất: Accepted" thành "Accepted" và ghi ngày bạn quyết.

## 2. Gộp PR #29 rồi PR #30 (10 phút)

PR #30 nằm trên PR #29, nên phải gộp #29 trước.

1. Mở https://github.com/thiengthb/PRM393_Lab03_SE190533/pull/29
2. Kéo xuống cuối trang. **Thấy gì là đúng:** dòng "All checks have passed" và nút xanh **Merge pull request**.
3. Bấm **Merge pull request** → **Confirm merge**.
4. Mở https://github.com/thiengthb/PRM393_Lab03_SE190533/pull/30
5. Bấm nút **Edit** cạnh tiêu đề PR. Ô **base** (đang ghi `claude/code-review-fixes`) đổi thành `final-system` → bấm **Change base** trong hộp thoại hiện ra.
6. Kéo xuống cuối, bấm **Ready for review** (PR đang là bản nháp).
7. Đợi khoảng 5 phút cho CI chạy. **Thấy gì là đúng:** "All checks have passed".
8. Bấm **Merge pull request** → **Confirm merge**.

**Dễ nhầm:** nếu bước 5 báo xung đột (conflict) thì dừng, nhắn Claude; đừng bấm "Resolve conflicts".

## 3. Nạp lại dữ liệu và deploy Rules (5 phút)

Rules mới có khoá MSSV (CR-15) nên phải deploy; dữ liệu nạp lại để tài khoản mẫu có khoá đó. **Làm ngay trước phần 4**, vì phần 4 cần một buổi đang diễn ra.

1. Mở [Actions → Demo: Firebase thật](https://github.com/thiengthb/PRM393_Lab03_SE190533/actions/workflows/demo-firebase.yml)
2. Bấm **Run workflow** (bên phải). Ô **Branch** chọn `final-system`. **Tick cả hai ô**: xoá dữ liệu (reset) và deploy. Bấm **Run workflow** màu xanh.
3. Đợi tick xanh, khoảng 3 phút. Bấm vào lần chạy, mở bước cuối, tìm dòng `Slot đang diễn ra: N` và ghi số **N** lại.
4. Điện thoại: mở app, Tổng quan có thẻ **Đang diễn ra: PRM393 · SE1801**. **Xem giờ kết thúc** trên thẻ: còn dưới 45 phút thì đợi slot đó hết rồi chạy lại bước 2.

**Thấy gì là đúng:** lần chạy xanh; app có buổi đang diễn ra.

## 4. Ảnh console Lab 3 còn thiếu (40 phút)

Đã có: E1 (Authentication), E2 (Firestore), 10 trên 13 sự kiện DebugView. Còn thiếu 4 việc dưới đây. Hướng dẫn đầy đủ từng bước: [`docs/manual-test/lab3-evidence.md`](lab3-evidence.md). **Làm đúng thứ tự này**, vì E4 cần buổi đang diễn ra còn mở.

Lưu ảnh laptop vào `$HOME\develop\evidence-inbox` với đúng tên ở cột "Lưu thành". Ảnh điện thoại thì chụp bằng điện thoại.

### 4a. Bật DebugView cho điện thoại

Cắm cáp điện thoại vào laptop. PowerShell:

```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell setprop debug.firebase.analytics.app app.attendo
```

Tắt hẳn app trên điện thoại rồi mở lại. Laptop mở [DebugView](https://console.firebase.google.com/project/attendo-app-2611/analytics/debugview), ô **Debug device** chọn **CPH1931**.

### 4b. Sự kiện `attendance_session_open` (điện thoại)

1. Tổng quan → bấm **Điểm danh** ở thẻ Đang diễn ra. **Chưa bấm Đóng mã.**
2. 📸 DebugView có dòng `attendance_session_open`. Bấm vào dòng đó để khung phải hiện tham số, rồi chụp. Lưu `analytics-09-session-open.png`.

### 4c. E4 Remote Config, làm khi phiên vẫn đang mở (15 phút)

Làm theo **E4** trong `lab3-evidence.md` (đổi `qr_rotate_seconds` 12 → 15 và `absence_limit_percent` 20 → 30). Có 5 ảnh, chụp đúng chỗ có 📸. Thêm một việc vì phiên đang mở:

- Sau khi Publish và bấm **Tải lại** ở Khu demo, quay lại màn phiên điểm danh. 📸 (điện thoại) dòng dưới mã ghi **Đổi mã 15s**.

**Nhớ:** làm xong trả về `12` và `20`, Publish. ARTEMIS cần giá trị mặc định.

### 4d. Hai sự kiện web: `qr_scan`, `correction_submit` (10 phút)

Làm theo **E3.4** trong `lab3-evidence.md` (cài tiện ích Google Analytics Debugger, Chrome thường, nick 697):

1. Web sinh viên → **Nhập mã điểm danh** → gõ đúng **mã 6 số** đang hiện trên điện thoại → **Gửi**. **Thấy gì là đúng:** web báo đã ghi nhận; số có mặt trên điện thoại tăng 1.
2. Mở PRM393 · SE1801 → một buổi **Vắng** → **Báo sai** → chọn lý do → **Gửi**.
3. 📸 DebugView chọn thiết bị trình duyệt, thấy `qr_scan` và `correction_submit`. Lưu `analytics-04-web-student.png`.

Không hiện trên DebugView thì làm theo mục "Nếu web không hiện trên DebugView" ngay dưới E3.4. **Đừng chụp trang Realtime thay thế**: đề đòi DebugView.

Xong thì quay lại điện thoại: **Đóng mã** → **Chốt**.

### 4e. E5 Cloudinary và E6 Crashlytics (10 phút)

1. Điện thoại: tab **Lớp** → PRM393 · SE1801 → **Xuất PDF** (để có file mới trên Cloudinary).
2. Làm **E5** trong `lab3-evidence.md`. 📸 `storage-01-cloudinary.png`.
3. Làm **E6**. 📸 `crashlytics-04-keys.png`.

### 4f. Tắt DebugView, gửi ảnh

```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell setprop debug.firebase.analytics.app .none.
```

Gửi tất cả ảnh vào chat (cả ảnh điện thoại), kèm câu "xong phần 4". Claude chép vào `evidence/`, che Gmail, rồi đưa vào báo cáo và slide.

## 5. Hai ảnh CodeRabbit (5 phút)

1. Mở https://github.com/thiengthb/PRM393_Lab03_SE190533/pull/28 , tab **Conversation**.
2. Tìm bình luận của **coderabbitai** có tiêu đề "Walkthrough" hoặc "Summary". 📸 Lưu `code-review-01-summary.png`.
3. Tab **Files changed** → mở `firebase/firestore.rules` → kéo tới bình luận của coderabbitai ở dòng khoảng 35 (phát hiện CR-15: tự khai MSSV người khác). 📸 Lưu `code-review-02-inline.png`.

**Dễ nhầm:** đừng chụp đường link "View in dashboard" của CodeRabbit nếu nó hiện đầy đủ trên thanh địa chỉ: link đó chứa mã chia sẻ.

## 6. ARTEMIS (1 đến 2 giờ, chờ thầy)

Lab 3 1,5 điểm. Đang vướng: khoá Gemini miễn phí chỉ 20 lượt mỗi ngày.

- **Nếu thầy đã trả lời** có cách khác (khoá của lớp, model khác): nhắn Claude câu trả lời, Claude sửa cấu hình.
- **Nếu chọn nạp tiền:** làm theo [`gemini-billing.md`](gemini-billing.md). **Không bật Auto-reload.** Rồi chạy từng bước, xem số dư sau mỗi bước:

```
cd $HOME\develop\attendo
powershell -ExecutionPolicy Bypass -File tool\artemis\run-e2e.ps1 -Step lecturer -SkipInstall
```

```
powershell -ExecutionPolicy Bypass -File tool\artemis\run-e2e.ps1 -Step student
```

```
powershell -ExecutionPolicy Bypass -File tool\artemis\run-e2e.ps1 -Step report
```

**Thấy gì là đúng:** có file `evidence\artemis\results.md` với bảng tỉ lệ đạt từng ca. Gửi file đó (hoặc chụp màn hình cửa sổ PowerShell nếu báo LOI) cho Claude.

## 7. Ảnh app cho slide (Claude làm)

Sau mốc đóng băng giao diện (trưa 11/11), Claude chụp lại ảnh app từ bộ E2E và cập nhật slide. Bạn chỉ cần báo "đã đóng băng" khi không sửa giao diện nữa.

## 8. Quay video (2 giờ)

- **Video Lab 3** (khoảng 8 phút): [`docs/demo/video-lab3.md`](../demo/video-lab3.md). Cảnh 19 cần ARTEMIS (phần 6); chưa có thì quay các cảnh khác trước.
- **Video Final** (khoảng 10 phút): [`docs/demo/video-final.md`](../demo/video-final.md). Trong lúc quay:
  - **WF-03 đo 3 lần** (cảnh 13 đến 14): mỗi lần chạy lại workflow Demo có tick xoá dữ liệu để lớp MMA301 · SE1806 về "Chờ duyệt". Ghi số giây từ lúc bấm **Duyệt lớp này** tới lúc chữ "Chờ giáo vụ duyệt" biến mất trên điện thoại.
  - **AI 3 cặp** (cảnh 16 đến 18): mỗi lần bấm **Gợi ý AI**, 📸 điện thoại chụp sheet có câu AI trả về; một lần cố ý làm hỏng (tắt Wi-Fi rồi bấm) để có ca lỗi.
- Tải lên YouTube chế độ **Không công khai**. Gửi Claude hai link, 3 số giây và 4 ảnh AI. Claude điền vào README, báo cáo, slide.

## 9. Hai câu trả lời, nhắn thầy, nộp (20 phút)

**Trả lời Claude hai câu:**
1. README phải ghi tên **Admin đầu tiên** (đề Final). Ghi địa chỉ Gmail nick 628 công khai, hay ghi "gửi riêng cho thầy"?
2. Có gửi email tài khoản demo riêng cho thầy không, gửi qua đâu?

**Nhắn thầy về tên repo** (quyết định 003; đề Final bắt `PRM393_Final_<ID>`). Tin nhắn soạn sẵn, sửa theo giọng của bạn:

> Em chào thầy, em là Thiên, SE190533. Bài Final em làm tiếp trên repo Lab 3 như đề. Em muốn đổi tên repo thành "attendo" (tên sản phẩm) thay vì PRM393_Final_SE190533, mã số sinh viên em ghi trong README và trang bìa báo cáo; tên file nộp vẫn giữ đúng đề (report/Final_SE190533.pdf). Thầy cho em đổi như vậy được không ạ? Nếu không em sẽ để đúng tên đề yêu cầu. Em cảm ơn thầy.

Thầy trả lời thế nào thì nhắn Claude. Đổi tên repo làm **sau cùng** (thứ Sáu), vì đổi xong phải cập nhật remote trên laptop.

**Nộp:** Claude dựng và commit `report/Lab03_SE190533.pdf`, `report/Final_SE190533.pdf`, `slides/Lab03_SE190533_slides.pdf`, `slides/Final_SE190533_slides.pdf` khi mọi số liệu đã điền. Bạn nộp link repo, hai PDF báo cáo, hai PDF slide, hai link video theo cổng nộp bài.

## Bảng theo dõi

| # | Việc | Xong |
|---|---|---|
| 1 | Xác nhận CR-31 đến CR-39 | Xong 20:42 10/11 |
| 2 | Gộp PR #29, PR #30 | |
| 3 | Workflow Demo: deploy + reset | |
| 4 | Ảnh E3 (3 sự kiện), E4, E5, E6 | |
| 5 | 2 ảnh CodeRabbit | |
| 6 | ARTEMIS | |
| 7 | Ảnh app cho slide (Claude) | |
| 8 | Video Lab 3, video Final, 3 số đo WF-03, 3 cặp AI + 1 lỗi | |
| 9 | Admin đầu tiên, nhắn thầy, nộp | |
