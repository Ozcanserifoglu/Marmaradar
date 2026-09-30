#!/usr/bin/env bash
# Prepare an iOS release build with OAuth dart-defines, then open Xcode for Archive.
#
# Usage (from repo root):
#   ./scripts/prepare-ios-xcode-archive.sh
#   ./scripts/prepare-ios-xcode-archive.sh --no-open   # build only, do not open Xcode
#
# After it finishes: in Xcode → Product → Archive
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$ROOT_DIR/mobile"
OAUTH_DEFINES_FILE="$MOBILE_DIR/dart_defines.oauth.json"
GOOGLE_SECRETS="$MOBILE_DIR/ios/Flutter/GoogleSignInSecrets.xcconfig"
WORKSPACE="$MOBILE_DIR/ios/Runner.xcworkspace"
OPEN_XCODE=1

for arg in "$@"; do
  case "$arg" in
    --no-open)
      OPEN_XCODE=0
      ;;
    -h|--help)
      sed -n '2,10p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: $0 [--no-open]"
      exit 1
      ;;
  esac
done

if [[ ! -f "$OAUTH_DEFINES_FILE" ]]; then
  echo "Missing $OAUTH_DEFINES_FILE"
  exit 1
fi

if [[ ! -f "$GOOGLE_SECRETS" ]]; then
  echo "Missing $GOOGLE_SECRETS"
  echo "Copy ios/Flutter/GoogleSignInSecrets.xcconfig.example and fill GOOGLE_IOS_CLIENT_ID / GOOGLE_IOS_URL_SCHEME."
  exit 1
fi

if ! grep -q '^GOOGLE_IOS_CLIENT_ID=.\+' "$GOOGLE_SECRETS" || \
   ! grep -q '^GOOGLE_IOS_URL_SCHEME=.\+' "$GOOGLE_SECRETS"; then
  echo "GoogleSignInSecrets.xcconfig looks incomplete (empty client ID or URL scheme)."
  echo "Edit: $GOOGLE_SECRETS"
  exit 1
fi

cd "$MOBILE_DIR"
flutter pub get

BUILD_ARGS=(
  --release
  --dart-define-from-file="$OAUTH_DEFINES_FILE"
)

if [[ -f "$MOBILE_DIR/dart_defines.json" ]]; then
  BUILD_ARGS+=(--dart-define-from-file="$MOBILE_DIR/dart_defines.json")
fi

echo "Building iOS release with OAuth dart-defines..."
flutter build ios "${BUILD_ARGS[@]}"

echo
echo "Done. OAuth defines are baked into this build."
echo "Next in Xcode: Product → Archive (scheme Runner, Any iOS Device)."

if [[ "$OPEN_XCODE" -eq 1 ]]; then
  if [[ ! -d "$WORKSPACE" ]]; then
    echo "Workspace not found: $WORKSPACE"
    exit 1
  fi
  echo "Opening $WORKSPACE ..."
  open "$WORKSPACE"
fi
