#!/usr/bin/env bash
# Runs the integration tests against the real app on Linux or the test phone.
#
# Usage: tool/integration_test.sh [--clear] [--keep-fixtures] <linux|android> [test file under integration_test/]
#   --clear          android only: `pm clear` the app first, if installed (dev
#                    data; for when the schema guard refuses an older database).
#   --keep-fixtures  android only: leave /sdcard/Music/kanaru-it on the phone
#                    after the run (by default it is removed and MediaStore
#                    is rescanned).
#
# Run it through the machine build lock from the main checkout, e.g.
#   .claude/scripts/main-build.sh <branch> sh -c 'tool/integration_test.sh linux'
#
# linux:   XDG_CONFIG_HOME / XDG_DATA_HOME / XDG_CACHE_HOME under
#          /tmp/kanaru-it/ (recreated for every test file), the fixtures copied
#          there and announced as XDG_MUSIC_DIR, so the app's own first-run
#          default picks them up (no folder picker). Waits (30 s) for a
#          previous `kanaru` process to exit; it never kills one.
# android: $ANDROID_SERIAL (default 12f5c1bf0505). WARNING: `flutter test`
#          installs the debug app fresh for every file and UNINSTALLS it
#          afterwards, so the installed Kanaru build and ALL its data on the
#          phone are removed (the user allows wiping Kanaru dev data). Fixtures
#          are pushed to /sdcard/Music/kanaru-it/ and indexed; a background
#          loop keeps granting READ_MEDIA_AUDIO / READ_MEDIA_IMAGES with
#          `pm grant` until the test ends (no system dialog). The Nix SDK
#          package is copied through a temporary pubspec_overrides.yaml (the
#          script refuses to start if one exists; tool/android_writable_sdk.sh).
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
# shellcheck source=tool/android_writable_sdk.sh
. "$ROOT/tool/android_writable_sdk.sh"

CLEAR=0
KEEP=0
while [ $# -gt 0 ]; do
  case "$1" in
    --clear) CLEAR=1 ;;
    --keep-fixtures) KEEP=1 ;;
    *) break ;;
  esac
  shift
done
PLATFORM=${1:-}
TEST=${2:-}
FIXTURES=$ROOT/integration_test/fixtures/music
APP_ID=io.github.kanaru313.kanaru_community

# One `flutter test` per file: each launches the app once (one `runKanaru`
# per process), and a second launch right after the first can fail while the
# previous window is still closing.
if [ -n "$TEST" ]; then
  FILES=("integration_test/${TEST#integration_test/}")
else
  FILES=(integration_test/*_test.dart)
fi

case "$PLATFORM" in
  linux)
    IT=/tmp/kanaru-it
    failed=0
    for file in "${FILES[@]}"; do
      waited=0
      while pgrep -x kanaru >/dev/null; do
        if [ "$waited" -ge 30 ]; then
          echo "integration_test: a kanaru process is still running (pid $(pgrep -x kanaru | tr '\n' ' ')); not started by this script, not killing it" >&2
          exit 1
        fi
        sleep 1
        waited=$((waited + 1))
      done
      command rm -rf "$IT"
      mkdir -p "$IT/config" "$IT/data" "$IT/cache" "$IT/music"
      cp -a "$FIXTURES/." "$IT/music/"
      printf 'XDG_MUSIC_DIR="%s"\n' "$IT/music" >"$IT/config/user-dirs.dirs"
      XDG_CONFIG_HOME=$IT/config XDG_DATA_HOME=$IT/data XDG_CACHE_HOME=$IT/cache \
        flutter test "$file" -d linux || failed=1
    done
    exit $failed
    ;;
  android)
    SERIAL=${ANDROID_SERIAL:-12f5c1bf0505}
    ADB=(adb -s "$SERIAL")
    "${ADB[@]}" get-state >/dev/null
    echo "integration_test: WARNING: the installed Kanaru app and its data on $SERIAL will be removed" >&2

    DIR=/sdcard/Music/kanaru-it
    scan_media() {
      # The shell may call MediaProvider; a broadcast per file is the fallback.
      "${ADB[@]}" shell content call --uri content://media/ \
        --method scan_volume --arg external_primary >/dev/null 2>&1 ||
        "${ADB[@]}" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
          -d "file://$DIR" >/dev/null 2>&1 || true
    }
    granter=""
    cleanup() {
      rc=$?
      trap - EXIT
      [ -n "$granter" ] && kill "$granter" 2>/dev/null
      kanaru_sdk_restore
      if [ "$KEEP" = 0 ]; then
        "${ADB[@]}" shell "rm -rf $DIR" >/dev/null 2>&1 || true
        scan_media
      fi
      exit $rc
    }
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    # The Nix Flutter SDK is read-only and Gradle 9 refuses it: use a writable
    # copy of the integration_test package for this run (tool/android_writable_sdk.sh).
    kanaru_sdk_setup

    "${ADB[@]}" shell "rm -rf $DIR && mkdir -p $DIR"
    "${ADB[@]}" push "$FIXTURES/." "$DIR/" >/dev/null
    scan_media
    if [ "$CLEAR" = 1 ] && "${ADB[@]}" shell pm path "$APP_ID" | grep -q package; then
      "${ADB[@]}" shell pm clear "$APP_ID"
    fi
    failed=0
    for file in "${FILES[@]}"; do
      # Permissions cannot be granted beforehand (the app is not installed
      # yet, and every file reinstalls it), so a loop grants them again and
      # again until the test ends; the harness re-reads the permission state.
      (
        while true; do
          "${ADB[@]}" shell pm grant "$APP_ID" android.permission.READ_MEDIA_AUDIO >/dev/null 2>&1 || true
          "${ADB[@]}" shell pm grant "$APP_ID" android.permission.READ_MEDIA_IMAGES >/dev/null 2>&1 || true
          sleep 1
        done
      ) &
      granter=$!
      flutter test "$file" -d "$SERIAL" || failed=1
      kill "$granter" 2>/dev/null || true
      granter=""
    done
    exit $failed
    ;;
  *)
    echo "usage: $0 [--clear] [--keep-fixtures] <linux|android> [test file]" >&2
    exit 64
    ;;
esac
