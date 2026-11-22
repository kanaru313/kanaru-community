#!/usr/bin/env bash
# Builds the Android APK with a writable copy of the integration_test SDK
# package (the Nix SDK is read-only and Gradle 9 refuses it; see
# tool/android_writable_sdk.sh).
#
# Usage: tool/build_apk.sh [--release|--profile|--debug] [extra flutter build args]
# Default mode: release. Run it through the machine build lock from the main
# checkout, e.g.
#   .claude/scripts/main-build.sh <branch> tool/build_apk.sh --release
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

MODE=--release
case "${1:-}" in
  --release | --profile | --debug)
    MODE=$1
    shift
    ;;
esac

# shellcheck source=tool/android_writable_sdk.sh
. "$ROOT/tool/android_writable_sdk.sh"

cleanup() {
  rc=$?
  trap - EXIT INT TERM
  kanaru_sdk_restore
  exit $rc
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

kanaru_sdk_setup
flutter build apk "$MODE" "$@"

APK_DIR=$ROOT/build/app/outputs/flutter-apk
echo "APK: $APK_DIR/app-${MODE#--}.apk"
