#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

URL_OVERRIDE="${1:-}"

BUILD_CMD=(
  flutter build apk
  --debug
  --flavor development
  --target lib/main_development.dart
  --dart-define-from-file=.env.development
)

if [[ -n "$URL_OVERRIDE" ]]; then
  BUILD_CMD+=(--dart-define "BASE_URL=$URL_OVERRIDE")
fi

"${BUILD_CMD[@]}"

echo
echo "Built: $ROOT_DIR/build/app/outputs/flutter-apk/app-development-debug.apk"
