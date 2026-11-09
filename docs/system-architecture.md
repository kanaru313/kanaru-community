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
  `<data dir>/kanaru-community/kanaru.db`.
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
