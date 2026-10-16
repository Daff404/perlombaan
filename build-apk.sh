#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
if [ ! -f settings/private.json ]; then
  echo "Salin settings/private.example.json menjadi settings/private.json lalu isi kunci Gemini."
  exit 1
fi
flutter pub get
flutter build apk --release --dart-define-from-file=settings/private.json
