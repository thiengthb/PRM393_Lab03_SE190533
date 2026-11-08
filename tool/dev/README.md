# Vòng sửa nhanh trên laptop

`dev.ps1` giữ bản `~/develop/attendo` luôn ở commit mới nhất của nhánh `claude/attendo-dev`, chạy một bản Attendo bằng `flutter run`, và tự nạp lại app khi code đổi (vài giây sau khi Claude đẩy code). Không cần CI, không cần cài lại APK.

Mỗi bản một cửa sổ PowerShell, đóng cửa sổ là dừng:

| Bản | Lệnh |
|---|---|
| App giảng viên trên điện thoại (cắm USB) | `powershell -ExecutionPolicy Bypass -File $HOME\develop\attendo\tool\dev\dev.ps1 -Target phone` |
| App giảng viên Windows (bản release, tự dựng lại khoảng 1 phút khi code đổi) | `... -Target windows` |
| App giảng viên trên trình duyệt, khổ laptop giống bản Windows, mở http://localhost:7303 | `... -Target lecturer` |
| Web admin, mở http://localhost:7301 | `... -Target admin` |
| Web sinh viên, mở http://localhost:7302 | `... -Target student` |

Log ở `~/develop/.attendo-dev/run-<bản>.log`. Lần đầu chạy lâu (dựng app 2 đến 5 phút); các lần sau chỉ vài giây.
