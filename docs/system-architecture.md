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
  above the shell. Desktop keeps its own back/forward history.
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

## Layout

Two shells, chosen only in `lib/src/shell/ui/app_shell.dart` by form factor
from `packages/kanaru_ui`. Pages are shell-agnostic and use `KPage` /
`PageHeader`.

## Toolchain and CI

`flake.nix` pins the toolchain. `.github/workflows/ci.yml` runs the Dart gate
(`tool/check`) and the Rust checks on every push and pull request.
