# System architecture

Short overview. The module rules, DAG, startup order, registry, extension
mechanism and database rules are in [ARCHITECTURE.md](../ARCHITECTURE.md);
this file shows how the pieces fit at runtime.

```
main.dart
  runKanaru(extensions)
    bootstrap
      native library (Rust via flutter_rust_bridge)
      AppPaths            (platform/)
      AppDatabase         (database/, kanaru.db, migrated)
      ExtensionRegistry   (extension/): built-in extensions, then bundled ones
      startup hooks       (receive the database connection)
    ProviderScope(overrides: paths, database, registry, native versions)
      KanaruApp           (router/)
        GoRouter built from the registry
          AppShell        (shell/): desktop sidebar + top bar, or mobile bottom bar
            pages         (screens/, library/, online/, extensions)
```

## Runtime pieces

- **State**: Riverpod. Startup results are provider overrides, so tests can
  replace any of them.
- **Navigation**: go_router; one shell branch per tab nav item, other routes
  above the shell; child nav items nest under their tab's route. Every
  location redirects to `/welcome` while `firstRunRequiredProvider` is true.
  Desktop keeps its own back/forward history, a sidebar grouped by order band
  (ARCHITECTURE.md), Rescan in the top bar, a page-header search icon and
  Ctrl+F / Ctrl+K. Both shells render the library selection bar slot.
- **Flush and exit**: `KanaruApp` owns one `AppLifecycleListener`; on
  hidden/paused it flushes the settings store then the registry's flush hooks,
  and on an exit request does the same capped at 2 s. Linux with a custom title
  bar must later move exit handling to `window_manager`'s close callbacks.
- **Persistence**: one SQLite file through drift, in
  `<data dir>/kanaru/kanaru.db`. Tables and rules:
  [system-architecture-database.md](./system-architecture-database.md).
- **Settings and device id**: per-device settings are one JSON file,
  `<config dir>/settings.json` (`SettingsStore`: sync reads from memory,
  coalesced atomic writes with a bounded retry after a failed save; `flush()` is
  meant to be called on pause/exit by the app lifecycle seam, added with the
  router/`KanaruApp` work of this wave, not wired by the store itself). A file that is unreadable,
  has another `format` or a newer `version` is copied to
  `settings.json.bad-<epoch ms>` and the store starts from defaults. The device
  id is a ULID in `<data dir>/device_id`, outside the database, excluded from
  Android backup. Both load at startup and reach the UI as provider overrides.
- **Native**: Rust crates behind one FFI crate, built by cargokit for the
  Linux host and the Android ABIs.
- **Extensions**: contribute through `ExtensionRegistry`; downstream builds
  can supply more through `packages/kanaru_extensions`.

## Cross-module contracts

Modules talk through narrow Riverpod providers so a position tick or a ♥
never rebuilds a list:

- `nowPlayingProvider` (entry, track, playing flag, index) with
  `isCurrentTrackProvider(id)`; commands go through `PlaybackCommands`
  (`playTracks`, `playNext`, `enqueue`; validated before any state change).
- Favorites are one `Set<TrackId>` stream; each tile selects from it
  (`isFavoriteProvider(id)`). Every per-tile `.family` is `isAutoDispose`.
- Lists build `TrackInfo` from their own query (`trackInfoFromRow`); only
  single-item screens use `trackInfoProvider`.
- Covers: `TrackCover` reports a missing file to `coverMissesProvider`, the
  scanner re-extracts it. Cover colours come from `coverColorsProvider`.
- Scan: `scanStatusProvider`, `libraryScanCommandsProvider`. Settings
  `library.tabs`, `app.theme`, `app.language` are read through
  `SettingNotifier`; theme and language apply at once.
- Seeds stand in until the real part exists (playback, scanner, first-run
  gate); a seed fails loudly or is a no-op by design.

## Layout

Two shells, chosen only in `lib/src/shell/ui/app_shell.dart` by form factor
from `packages/kanaru_ui`. Pages are shell-agnostic and use `KPage` /
`PageHeader`.

## Toolchain and CI

`flake.nix` pins the toolchain. `.github/workflows/ci.yml` runs the Dart gate
(`tool/check`) and the Rust checks on every push and pull request.
