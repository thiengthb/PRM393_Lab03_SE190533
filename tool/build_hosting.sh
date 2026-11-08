#!/usr/bin/env bash
# Dựng ba trang lên cùng một Hosting: cổng sinh viên ở /, web admin ở /admin/, FAP giả lập ở /fap/.
# Dùng: RECAPTCHA_SITE_KEY=<key> ./tool/build_hosting.sh && (cd firebase && firebase deploy --only hosting)
set -euo pipefail
# Git Bash trên Windows tự đổi "/admin/" thành "C:/Program Files/Git/admin/"; tắt việc đổi đường dẫn đó.
export MSYS_NO_PATHCONV=1
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEY="--dart-define=RECAPTCHA_SITE_KEY=${RECAPTCHA_SITE_KEY:-}"
rm -rf "$ROOT/firebase/public"
(cd "$ROOT/mobile" && flutter build web --release "$KEY" --dart-define=PORTAL=student)
(cd "$ROOT/web" && flutter build web --release "$KEY" --base-href /admin/)
mkdir -p "$ROOT/firebase/public"
cp -R "$ROOT/mobile/build/web/." "$ROOT/firebase/public/"
mkdir -p "$ROOT/firebase/public/admin"
cp -R "$ROOT/web/build/web/." "$ROOT/firebase/public/admin/"
# FAP giả lập cho extension (không phải FAP thật), build bằng Vite.
(cd "$ROOT/fap-mock" && npm ci --no-audit --no-fund && npm run build)
mkdir -p "$ROOT/firebase/public/fap"
cp -R "$ROOT/fap-mock/dist/." "$ROOT/firebase/public/fap/"
# File lớp mẫu để tải thẳng về điện thoại hay laptop khi test nhập lớp (không cần cáp, không cần adb).
mkdir -p "$ROOT/firebase/public/demo"
cp "$ROOT"/mobile/sample-data/*.csv "$ROOT/firebase/public/demo/"
echo "Xong: firebase/public (sinh viên ở /, quản trị ở /admin/, FAP giả lập ở /fap/, file mẫu ở /demo/)"
