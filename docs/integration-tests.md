# Integration tests

Tests in `integration_test/` start the **real app** (real `runKanaru`
bootstrap, Rust library, libmpv, drift database on disk) and drive it inside
its own window. They complement the widget tests, which never touch FFI, files
or the audio engine.

## Running

Builds happen only in the main checkout, one at a time, so go through the
machine build lock (it needs a committed branch):

```bash
/home/hieunm/dev/apps/kanaru/.claude/scripts/main-build.sh <branch> sh -c 'tool/integration_test.sh linux'
/home/hieunm/dev/apps/kanaru/.claude/scripts/main-build.sh <branch> sh -c 'tool/integration_test.sh android'
tool/integration_test.sh linux app_smoke_test.dart     # one file
```

Debug mode is fine for these runs. `tool/integration_test.sh` itself:

- **linux:** recreates `/tmp/kanaru-it/{config,data,cache,music}` (fresh for every test file, one app launch per file), points
  `XDG_CONFIG_HOME` / `XDG_DATA_HOME` / `XDG_CACHE_HOME` at it, copies the
  fixtures into `music/` and writes `user-dirs.dirs` with `XDG_MUSIC_DIR`
  there, then runs `flutter test <file> -d linux` for each file.
- **android:** serial from `$ANDROID_SERIAL` (default `12f5c1bf0505`); pushes
  the fixtures to `/sdcard/Music/kanaru-it/`, indexes them, installs the debug
  build with `install -r` and runs `pm grant` for `READ_MEDIA_AUDIO` and
  `READ_MEDIA_IMAGES`. It never clears app data: an older dev database may be
  refused by the schema guard ("created by an older build of schema v1"); then
  clear the app data by hand (`pm clear`) and run again.

## What the harness does

`integration_test/support/harness.dart` (`startKanaru`):

1. writes `library.min_duration_ms = 0` into `settings.json` (the fixtures are
   3 s long; the default minimum is 30 s), keeping other values;
2. calls `runKanaru` (no test-only seam in `lib/`);
3. on a first run, waits for the first-run page to add the platform's default
   music folder (the fixtures) and presses its arrow; an already set-up data
   folder skips this;
4. opens `/library/songs` and waits until every fixture track is in the
   database (the scan);
5. returns a `RunningApp` with the `ProviderContainer`, `pumpUntil` (real-time
   waiting with a timeout and a message) and `trackIdsByTitle`.

Each test file starts the app once (one `runKanaru` per process). Tests assert
state (providers, finders), never pixels.

## Fixtures

`tool/make_fixtures.sh` generates short synthetic tones (ffmpeg, plus a small
python3 writer for the ID3 `SYLT` frame) into `integration_test/fixtures/music/`
(about 80 KiB, committed): MP3 with `SYLT`, MP3 with `USLT`, FLAC with LRC text
in `LYRICS`, Ogg with plain `LYRICS`, three MP3s with `.lrc` sidecars (UTF-8,
UTF-16 with BOM, uppercase `.LRC`) and one with no lyrics. The expectations
live in `integration_test/support/fixtures.dart`; change both together.

## Limits

- No system dialogs and no native pickers: the library is set up through the
  first-run page and `pm grant`, never the folder picker or permission prompt.
- Linux input comes from the test framework inside the app window, never
  synthetic desktop input; no full-screen captures.
- Not run on CI yet (needs a display and libmpv: xvfb job, follow-up).
- One run at a time on the machine (the build lock); the window size decides
  the shell (mobile < 1200 px, desktop above), and the smoke test handles both.
