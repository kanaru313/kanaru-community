#!/usr/bin/env bash
# Sourced helper (not run directly): lets Gradle build the Android app when the
# Flutter SDK is read-only (Nix).
#
# `integration_test` is a dev dependency from the Flutter SDK. Gradle 9 refuses
# to configure the plugin project ':integration_test' when its directory
# (<sdk>/packages/integration_test/android) cannot be written, which is the case
# in the Nix store: every `flutter build apk` and every Android integration run
# fails. The workaround is a writable copy of the SDK package, wired in through
# a temporary, gitignored pubspec_overrides.yaml.
#
#   source tool/android_writable_sdk.sh
#   kanaru_sdk_setup      # from the repo root; no-op when the SDK is writable
#   ...flutter build / flutter test...
#   kanaru_sdk_restore    # removes the override, `pub get`, keeps pubspec.lock as it was
#
# Callers must trap kanaru_sdk_restore on EXIT / INT / TERM. It is safe to call
# more than once and when setup did nothing. Needs `flutter` on PATH.

KANARU_SDK_OVERRIDE_MADE=0
KANARU_SDK_LOCK_BACKUP=""

kanaru_sdk_setup() {
  [ -f pubspec.yaml ] || { echo "android_writable_sdk: run from the repo root" >&2; return 1; }
  local sdk_pkg
  sdk_pkg=$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")/packages/integration_test
  [ -d "$sdk_pkg" ] || { echo "android_writable_sdk: $sdk_pkg not found" >&2; return 1; }
  if [ -w "$sdk_pkg" ] && [ -w "$sdk_pkg/android" ]; then
    return 0 # normal writable SDK: nothing to do
  fi
  if [ -e pubspec_overrides.yaml ]; then
    echo "android_writable_sdk: pubspec_overrides.yaml already exists; remove it first" >&2
    return 1
  fi

  # One copy per checkout, so two checkouts never clobber each other.
  local key base copy
  key=$(pwd -P | cksum | cut -d' ' -f1)
  base=${TMPDIR:-/tmp}/kanaru-sdk-$(id -u)/$key
  copy=$base/integration_test
  command rm -rf "$base"
  mkdir -p "$base"
  cp -rL "$sdk_pkg" "$copy" && chmod -R u+w "$copy" || return 1

  # Remember pubspec.lock: pub rewrites it with the override and again on restore.
  KANARU_SDK_LOCK_BACKUP=$base/pubspec.lock.orig
  if [ -f pubspec.lock ]; then cp pubspec.lock "$KANARU_SDK_LOCK_BACKUP"; else KANARU_SDK_LOCK_BACKUP=""; fi

  printf 'dependency_overrides:\n  integration_test:\n    path: %s\n' "$copy" >pubspec_overrides.yaml
  KANARU_SDK_OVERRIDE_MADE=1
  flutter pub get >/dev/null
}

kanaru_sdk_restore() {
  [ "$KANARU_SDK_OVERRIDE_MADE" = 1 ] || return 0
  KANARU_SDK_OVERRIDE_MADE=0
  command rm -f pubspec_overrides.yaml
  flutter pub get >/dev/null || echo "android_writable_sdk: pub get failed while restoring" >&2
  if [ -n "$KANARU_SDK_LOCK_BACKUP" ] && [ -f "$KANARU_SDK_LOCK_BACKUP" ] &&
    ! cmp -s "$KANARU_SDK_LOCK_BACKUP" pubspec.lock; then
    cp "$KANARU_SDK_LOCK_BACKUP" pubspec.lock
  fi
  return 0
}
