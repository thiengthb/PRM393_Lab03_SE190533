#!/usr/bin/env bash
# Builds the four Hosting sites (decision 002), one folder each under firebase/public:
#   student  student web (phone browser, laptop)          <project>.web.app
#   admin    web admin, laptop only                        <project>-admin.web.app
#   tv       classroom projector page, /tv/<key>           <project>-tv.web.app
#   fap      FAP mock for the extension demo, /fap/        <project>-fap.web.app
# Site names come from firebase/.firebaserc (targets). Deploy: cd firebase && firebase deploy --only hosting
set -euo pipefail
# Git Bash on Windows rewrites "/fap/" into a Windows path; turn that off.
export MSYS_NO_PATHCONV=1
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEY="--dart-define=RECAPTCHA_SITE_KEY=${RECAPTCHA_SITE_KEY:-}"
OUT="$ROOT/firebase/public"
rm -rf "$OUT"
mkdir -p "$OUT/student" "$OUT/admin" "$OUT/tv" "$OUT/fap/fap"
(cd "$ROOT/mobile" && flutter build web --release "$KEY" --dart-define=PORTAL=student)
cp -R "$ROOT/mobile/build/web/." "$OUT/student/"
# The projector page is the same build: /tv/<key> is a public route of the app.
cp -R "$ROOT/mobile/build/web/." "$OUT/tv/"
(cd "$ROOT/web" && flutter build web --release "$KEY")
cp -R "$ROOT/web/build/web/." "$OUT/admin/"
# FAP mock (not the real FAP), served at /fap/ like on the dev server.
(cd "$ROOT/fap-mock" && npm ci --no-audit --no-fund && npm run build)
cp -R "$ROOT/fap-mock/dist/." "$OUT/fap/fap/"
# Sample class files to download straight onto a phone or laptop when testing the import.
mkdir -p "$OUT/student/demo"
cp "$ROOT"/mobile/sample-data/*.csv "$OUT/student/demo/"
echo "Xong: firebase/public/{student,admin,tv,fap}"
