# Bật trả phí cho khoá Gemini (để chạy ARTEMIS)

Khoá Gemini miễn phí chỉ cho 20 lần gọi mỗi model mỗi ngày (ARTEMIS báo lỗi 429 "Free Tier" lúc 10:59 ngày 10/11/2026), mà bộ ARTEMIS Lab 3 cần vài trăm lần. thien chọn bật trả phí (cách A) lúc 11:04.

Mọi bước cần tài khoản Google và thẻ của bạn nên mình chưa thử được, bước nào cũng `(chưa thử)`. Mình viết theo trang [Gemini API · Billing](https://ai.google.dev/gemini-api/docs/billing), đọc ngày 10/11/2026. Theo trang đó, tài khoản mới dùng **Prepay**: nạp trước tối thiểu **10 USD**, mỗi lần gọi trừ dần vào số dư; số dư về 0 thì khoá bị tạm dừng.

**Không chắc chắn dừng đúng ở 10 USD.** Trang Billing (đọc lại 10/11/2026) ghi rõ hai điều:
- Hệ thống tính tiền trễ khoảng 10 phút, nên trong khoảng đó app vẫn gọi được và số dư có thể xuống âm. Phần âm bị trừ vào lần nạp sau.
- Có tính năng **Auto-reload** tự mua thêm tín dụng khi số dư thấp. Nếu hộp thoại mời bật thì **không bật**; nếu đã lỡ bật thì vào **Manage auto-reload** để tắt trước khi chạy ARTEMIS.

Vì vậy chạy ARTEMIS từng bước (`-Step lecturer`, rồi `-Step student`), xem số dư sau mỗi bước, đừng để chạy liền nhiều giờ.

## 1. Mở trang khoá API `(chưa thử)`

1. Mở https://aistudio.google.com/apikey bằng nick **628** (nick bạn đã tạo khoá sáng nay).
2. Bảng giữa trang có dòng khoá bạn tạo sáng nay, cột **Billing Tier** (hoặc **Plan**) ghi **Free**.
3. Bấm **Set up billing** ở dòng đó.

**Thấy gì là đúng:** hộp thoại thiết lập thanh toán hiện ra.

**Dễ nhầm:** nếu có nhiều dòng, chọn đúng dòng có khoá đang nằm trong `artemis\.env`: 4 ký tự cuối của khoá trên trang phải trùng 4 ký tự cuối trong file.

## 2. Thêm thẻ và nạp tiền `(chưa thử)`

1. Hộp thoại hỏi quốc gia: chọn **Vietnam**, tick đồng ý điều khoản, bấm **Continue**.
2. Điền thông tin liên hệ và thẻ (Visa/Mastercard, thẻ ghi nợ quốc tế cũng được). Bấm **Continue** hoặc **Submit**.
3. Nếu được hỏi chọn **Prepay** hay **Postpay**, chọn **Prepay**.
4. Ô số tiền nạp: điền

```
10
```

   rồi bấm **Purchase** (hoặc **Add credits**).

**Thấy gì là đúng:** thông báo dạng "Your Google Cloud billing account and Gemini API project are now linked". Cột Billing Tier của dòng khoá đổi thành **Tier 1** hoặc **Paid**.

**Nếu lỗi:** có người gặp lỗi `OR_BACR2_44` ở bước cuối, hoặc cột vẫn ghi Free sau khi đã thanh toán. Chụp màn hình gửi mình.

## 3. Đặt hạn mức chi `(chưa thử)`

1. Mở trang **Billing** của AI Studio (thanh bên trái, mục **Billing**; hoặc nút **Billing** ở góc phải trang khoá).
2. Ở dự án của khoá, tìm **Spend cap** (hạn mức chi theo tháng), bấm **Edit**.
3. Điền

```
10
```

   rồi bấm **Save**.

**Thấy gì là đúng:** dòng dự án hiện hạn mức `$10`.

## 4. Báo mình

Nhắn "đã bật trả phí". Mình sẽ đưa lệnh chạy lại ARTEMIS. Không cần đổi khoá trong `artemis\.env` vì vẫn là khoá cũ, chỉ dự án của nó đổi sang trả phí.

Sau khi nộp bài: vào trang Billing tắt **Auto reload** nếu có bật, để không bị nạp thêm.
