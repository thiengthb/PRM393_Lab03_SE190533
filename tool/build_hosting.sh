#!/usr/bin/env bash
# Dựng ba trang lên cùng một Hosting: cổng sinh viên ở /, web admin ở /admin/, FAP giả lập ở /fap/.
# Dùng: RECAPTCHA_SITE_KEY=<key> ./tool/build_hosting.sh && (cd firebase && firebase deploy --only hosting)
set -euo pipefail
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
echo "Xong: firebase/public (sinh viên ở /, quản trị ở /admin/, FAP giả lập ở /fap/)"
