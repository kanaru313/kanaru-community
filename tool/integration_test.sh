#!/usr/bin/env bash
# Runs the integration tests against the real app on Linux or the test phone.
#
# Usage: tool/integration_test.sh <linux|android> [test file under integration_test/]
#
# Builds nothing by itself that the main-build lock should guard: run it
# through the machine build lock from the main checkout, e.g.
#   .claude/scripts/main-build.sh <branch> sh -c 'tool/integration_test.sh linux'
#
# linux:   XDG_CONFIG_HOME / XDG_DATA_HOME / XDG_CACHE_HOME under
#          /tmp/kanaru-it/ (recreated every run), the fixtures copied there and
#          announced as XDG_MUSIC_DIR, so the app's own first-run default picks
#          them up (no folder picker).
# android: $ANDROID_SERIAL (default 12f5c1bf0505); fixtures pushed to
#          /sdcard/Music/kanaru-it/ and indexed, the debug app installed with
#          `install -r` and READ_MEDIA_AUDIO / READ_MEDIA_IMAGES granted with
#          `pm grant` (no system dialog). Never clears app data.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

PLATFORM=${1:-}
TEST=${2:-}
FIXTURES=$ROOT/integration_test/fixtures/music
APP_ID=io.github.kanaru313.kanaru_community

if [ -n "$TEST" ]; then
  TARGET=integration_test/${TEST#integration_test/}
else
  TARGET=integration_test
fi

case "$PLATFORM" in
  linux)
    IT=/tmp/kanaru-it
    command rm -rf "$IT"
    mkdir -p "$IT/config" "$IT/data" "$IT/cache" "$IT/music"
    cp -a "$FIXTURES/." "$IT/music/"
    printf 'XDG_MUSIC_DIR="%s"\n' "$IT/music" >"$IT/config/user-dirs.dirs"
    export XDG_CONFIG_HOME=$IT/config XDG_DATA_HOME=$IT/data XDG_CACHE_HOME=$IT/cache
    exec flutter test "$TARGET" -d linux
    ;;
  android)
    SERIAL=${ANDROID_SERIAL:-12f5c1bf0505}
    ADB=(adb -s "$SERIAL")
    "${ADB[@]}" get-state >/dev/null
    DIR=/sdcard/Music/kanaru-it
    "${ADB[@]}" shell "rm -rf $DIR && mkdir -p $DIR"
    "${ADB[@]}" push "$FIXTURES/." "$DIR/" >/dev/null
    # Index the files now (shell may call MediaProvider); a broadcast per
    # file is the fallback for builds where the volume scan is refused.
    if ! "${ADB[@]}" shell content call --uri content://media/ \
      --method scan_volume --arg external_primary >/dev/null 2>&1; then
      for f in "$FIXTURES"/*; do
        "${ADB[@]}" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
          -d "file://$DIR/$(basename "$f")" >/dev/null
      done
    fi
    flutter build apk --debug
    "${ADB[@]}" install -r build/app/outputs/flutter-apk/app-debug.apk
    for permission in READ_MEDIA_AUDIO READ_MEDIA_IMAGES; do
      "${ADB[@]}" shell pm grant "$APP_ID" "android.permission.$permission"
    done
    exec flutter test "$TARGET" -d "$SERIAL"
    ;;
  *)
    echo "usage: $0 <linux|android> [test file]" >&2
    exit 64
    ;;
esac
