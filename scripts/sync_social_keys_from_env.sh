#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_ENV="$ROOT_DIR/.env.development"
PROD_ENV="$ROOT_DIR/.env.production"
IOS_DIR="$ROOT_DIR/ios/Flutter"

read_env_key() {
  local env_file="$1"
  local key="$2"
  awk -F= -v k="$key" '$1==k { $1=""; sub(/^=/, ""); gsub(/^[ \t]+|[ \t]+$/, "", $0); print; exit }' "$env_file"
}

write_facebook_xcconfig() {
  local env_file="$1"
  local output_file="$2"
  local app_id client_token display_name
  app_id="$(read_env_key "$env_file" "FACEBOOK_APP_ID")"
  client_token="$(read_env_key "$env_file" "FACEBOOK_CLIENT_TOKEN")"
  display_name="$(read_env_key "$env_file" "FACEBOOK_DISPLAY_NAME")"

  cat > "$output_file" <<EOF
// Auto-generated from $(basename "$env_file").
FACEBOOK_APP_ID=$app_id
FACEBOOK_CLIENT_TOKEN=$client_token
FACEBOOK_DISPLAY_NAME=$display_name
EOF
}

write_facebook_xcconfig "$DEV_ENV" "$IOS_DIR/Facebook.debug.xcconfig"
write_facebook_xcconfig "$PROD_ENV" "$IOS_DIR/Facebook.release.xcconfig"

echo "Synced iOS Facebook xcconfig files from .env files."
