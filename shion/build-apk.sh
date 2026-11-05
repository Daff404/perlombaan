#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
flutter pub get
if [ -f settings/api.json ]; then
  flutter build apk --release --dart-define-from-file=settings/api.json
else
  flutter build apk --release
fi
