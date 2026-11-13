# System architecture

Short overview. The module rules, DAG, startup order, registry and database
rules are in [ARCHITECTURE.md](../ARCHITECTURE.md); this file shows how the
pieces fit at runtime.

```
main.dart
  runKanaru(extensions)
    bootstrap
      native library      (Rust via flutter_rust_bridge)
      AppPaths            (platform/)
      SettingsStore       (configDir/settings.json)
      device id           (dataDir/device_id)
      AppDatabase         (database/, dataDir/kanaru.db, migrated)
      ExtensionRegistry   (extension/): built-in extensions, then bundled ones
      startup hooks       (receive the database connection)
    ProviderScope(overrides: paths, settings, device id, database, registry, native versions)
      KanaruApp           (router/)
        GoRouter built from the registry
          AppShell        (shell/): desktop sidebar + top bar, or mobile bottom bar
            pages         (screens/, library/, online/, extensions)
```

## Contents

- [ARCHITECTURE.md](../ARCHITECTURE.md): modules, frozen and seeded files, nav bands, settings keys, l10n parts.
- [system-architecture-database.md](./system-architecture-database.md): tables, keys and helpers of schema v1.
- [system-architecture-playback.md](./system-architecture-playback.md): playback commands, now playing, queue, media controls (contract stub until lane B lands).
- [system-architecture-library.md](./system-architecture-library.md): library keys, track info, lists, favorites, tabs, folders, exclusions (contract stub until lane C lands).
- [system-architecture-library-scan.md](./system-architecture-library-scan.md): scanner, pass versions, covers, first run, Rust pools, custom cover import (lane A, merged).
- [system-architecture-lyrics.md](./system-architecture-lyrics.md): embedded lyrics reader and its bridge API.

## Runtime pieces

- **State**: Riverpod. Startup results are provider overrides, so tests can
  replace any of them.
- **Navigation**: go_router; one shell branch per tab nav item, other routes
  above the shell; child nav items nest under their tab's route. Every
  location redirects to `/welcome` while `firstRunRequiredProvider` is true.
  Desktop keeps its own back/forward history, a sidebar grouped by order band
  (ARCHITECTURE.md), Rescan in the top bar, a page-header search icon and
  Ctrl+F / Ctrl+K. Both shells render the library selection bar slot.
- **Flush and exit**: `KanaruApp` owns one `AppLifecycleListener`. On hidden or
  paused it flushes the settings store, then the registry's flush hooks. On an
  exit request it first runs the registry's before-exit hooks (pause), then does
  the same, capped at 2 s in total. On Linux the window close goes
  through `WindowCloseGuard` (`window_manager` close callbacks), installed by
  `KanaruApp` after the first frame, because the plugin disconnects the
  engine's exit request.
- **Settings**: per-device JSON file `configDir/settings.json`, one
  `Setting<T>` per key (`<module>.<name>`). Sync reads from memory, writes are
  coalesced and atomic, and a file that is unusable is moved aside to
  `settings.json.bad-<epoch ms>` while the store starts from defaults.
  Details in ARCHITECTURE.md.
- **Device id**: a ULID in `dataDir/device_id`, outside the database,
  excluded from Android backup. Loaded at bootstrap and exposed as
  `deviceIdProvider`.
- **Persistence**: one SQLite file through drift, `kanaru.db` in `AppPaths.dataDir`.
  On Linux `dataDir` is `$XDG_DATA_HOME/kanaru` (default `~/.local/share/kanaru`);
  the file is `~/.local/share/kanaru/kanaru.db`. Tables and rules:
  [system-architecture-database.md](./system-architecture-database.md).
- **Covers**: image files under `cacheDir/covers/` (Linux `cacheDir` is
  `$XDG_CACHE_HOME/kanaru`), one size per file (`thumb` for tiles, `full` for
  Now Playing and the media session). The database keeps only the cover key.
- **Native**: Rust crates behind one FFI crate, built by cargokit for the
  Linux host and the Android ABIs. The bridge owns the media worker pools
  (background, interactive, waveform), the panic guard and the error DTO
  (`NativeError`), and holds the plugin runtime, which owns its JS threads;
  `kanaru_media` and `kanaru_plugin_runtime` stay plain Rust.
- **Extensions**: contribute through `ExtensionRegistry`; downstream builds
  can supply more through `packages/kanaru_extensions`.

## Cross-module contracts

Modules talk through narrow Riverpod providers so a position tick or a ♥
never rebuilds a list:

- Playback: `playbackCommandsProvider` (`PlaybackCommands`: `playTracks`,
  `playNext`, `enqueue`; validated before any state change) and
  `nowPlayingProvider` (`NowPlaying`, identity is the queue entry). Tiles use
  `isCurrentTrackProvider(id)`, `hasCurrentTrackProvider`, `isPlayingProvider`.
  Details: [system-architecture-playback.md](./system-architecture-playback.md).
- Favorites: one `Set<TrackId>` stream (`favoriteTrackIdsProvider`); each tile
  selects from it (`isFavoriteProvider(id)`).
- Lists build `TrackInfo` from their own query (`trackInfoFromRow`); only
  single-item screens use `trackInfoProvider`.
- Covers: `TrackCover` reports a missing file to `coverMissesProvider`, and
  the scanner re-extracts it. Cover colours come from
  `coverColorsProvider` and tint pages and the Now Playing background only.
- Scan: `scanStatusProvider` and `libraryScanCommandsProvider`. The scan
  request completes when it is accepted; failures arrive as `ScanFailed`.
  Details: [system-architecture-library-scan.md](./system-architecture-library-scan.md).
- Settings are read through one top-level provider per key: `libraryTabsProvider`
  (`library.tabs`), `themeChoiceProvider` (`app.theme`), `appLanguageProvider`
  (`app.language`). Theme and language apply at once; nothing else in the app
  theme changes at runtime.
- Seeds stand in until the real part exists: `UnavailablePlaybackCommands`
  (throws `StateError`; the playback lane replaces it). The scanner is real:
  `scanStatusProvider` and `libraryScanCommandsProvider` read the
  `ScanController` (`scanControllerProvider`), and the first-run gate reads the
  `library.setup_done` setting. A seed fails loudly or is a no-op by design,
  and its owner lane deletes it.

## Layout

Two shells, chosen only in `lib/src/shell/ui/app_shell.dart` by form factor
from `packages/kanaru_ui`. Pages are shell-agnostic and use `KPage` /
`PageHeader`.

## Toolchain and CI

`flake.nix` pins the toolchain. `.github/workflows/ci.yml` runs the Dart gate
(`tool/check`) and the Rust checks on every push and pull request.
