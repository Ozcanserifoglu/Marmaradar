#!/usr/bin/env bash
# Build a release Flutter binary with Google Sign-In dart-defines baked in.
#
# Usage:
#   ./scripts/build-release-mobile.sh              # appbundle (default)
#   ./scripts/build-release-mobile.sh apk
#   ./scripts/build-release-mobile.sh appbundle
#   ./scripts/build-release-mobile.sh ipa
#   ./scripts/build-release-mobile.sh apk --obfuscate --split-debug-info=build/debug-info
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$ROOT_DIR/mobile"
OAUTH_DEFINES_FILE="$MOBILE_DIR/dart_defines.oauth.json"

TARGET="${1:-appbundle}"
shift || true
EXTRA_ARGS=("$@")

case "$TARGET" in
  apk|appbundle|ipa|ios)
    ;;
  *)
    echo "Unknown target: $TARGET"
    echo "Usage: $0 [apk|appbundle|ipa] [extra flutter build args...]"
    exit 1
    ;;
esac

if [[ ! -f "$OAUTH_DEFINES_FILE" ]]; then
  echo "Missing $OAUTH_DEFINES_FILE"
  exit 1
fi

# Allow overriding GOOGLE_SERVER_CLIENT_ID via env without editing the JSON file.
GOOGLE_SERVER_CLIENT_ID="${GOOGLE_SERVER_CLIENT_ID:-}"

cd "$MOBILE_DIR"
flutter pub get

BUILD_ARGS=(
  --dart-define-from-file="$OAUTH_DEFINES_FILE"
)

if [[ -n "$GOOGLE_SERVER_CLIENT_ID" ]]; then
  BUILD_ARGS+=(--dart-define=GOOGLE_SERVER_CLIENT_ID="$GOOGLE_SERVER_CLIENT_ID")
fi

# Optional machine-specific overrides (API URL, iOS client ID, etc.).
if [[ -f "$MOBILE_DIR/dart_defines.json" ]]; then
  BUILD_ARGS+=(--dart-define-from-file="$MOBILE_DIR/dart_defines.json")
fi

echo "Building Flutter release ($TARGET) with OAuth dart-defines..."
flutter build "$TARGET" "${BUILD_ARGS[@]}" "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
