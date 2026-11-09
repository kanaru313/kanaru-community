# Codebase summary

Map of what exists. Module rules: [ARCHITECTURE.md](../ARCHITECTURE.md).

## Entry and composition root (`lib/`)

| File | What |
|---|---|
| `main.dart` | `runKanaru(extensions: bundledExtensions)` |
| `kanaru.dart` | `runKanaru`, `builtInExtensions`; exports extension, database, license and registry types |
| `kanaru_bootstrap.dart` | `bootstrap(...)` startup sequence, `BootstrapResult` |
| `kanaru_error_app.dart` | `KanaruErrorApp`, shown on startup failure |
| `l10n/app_en.arb`, `app_vi.arb` | Strings; generated `l10n/gen/` (committed) |

## Modules (`lib/src/`)

| Module | Contents |
|---|---|
| `foundation/` | `result.dart` (sealed `Ok`/`Err`), `app_logger.dart` (`setupLogging`) |
| `platform/` | `domain/app_paths.dart` (`AppPaths`, `kanaruDirName = 'kanaru-community'`); `data/` `linux_app_paths.dart` (XDG), `android_app_paths.dart` (`path_provider`), `app_paths_factory.dart`, `native_library.dart` (loads Rust, the only importer of `lib/src/rust`); `state/platform_providers.dart` |
| `database/` | `app_database.dart` (`AppDatabase`, `schemaVersion` 1, `sharedConnection`), `tables/extension_tables.dart` (`ExtensionSchema`), `tables.dart`, `database.dart` (barrel), `state/database_providers.dart`; generated `*.drift.dart` |
| `extension/` | `kanaru_extension.dart`; `domain/license.dart` (`ProFeature`, `LicenseStatus`, `LicenseService`, `FreeLicenseService`); `state/extension_registry.dart`, `registry_entries.dart` (`NavItem`, `SettingsSection`, `TopBarAction`, `StartupContext`, `StartupHook`), `extension_providers.dart` |
| `library/` | `library_extension.dart`; `ui/` Library and Playlists placeholder pages |
| `online/` | `online_extension.dart`; `ui/online_page.dart` |
| `screens/` | `screens_extension.dart`; `ui/` Home, Search, Settings |
| `shell/` | `ui/` `app_shell.dart` (the one place that picks desktop or mobile), `mobile_shell.dart`, `desktop_shell.dart`, `desktop_top_bar.dart`, `desktop_sidebar.dart`; `state/nav_history.dart` (desktop back and forward) |
| `router/` | `app_router.dart` (`buildRouter` from the registry), `state/router_provider.dart`, `ui/kanaru_app.dart` |
| `rust/` | Generated flutter_rust_bridge Dart code (do not edit) |

Not yet present: `media`, `plugins`, `playback`, `storage`, `lyrics`.

## Packages

- `packages/kanaru_ui`: `KSpace`, `KRadius`, `KShape`, `KLayout`, `KBreakpoints`,
  `KMotion`, `KIcons`, `buildKanaruTheme`, `FormFactor`, widgets `KPage`,
  `PageHeader`, `KEmpty`, `KEmptyPage`, `ProBadge`. Tests in
  `packages/kanaru_ui/test/`.
- `packages/kanaru_extensions`: `bundledExtensions`, empty by default in this repo.

## Gate (`tool/`)

- `check`: bash script running the full gate (`--rust` adds cargo).
- `check_architecture.dart`: wrapper that runs the CLI of the lint package.
- `architecture_lint/`: pure Dart package, analyzer plugin (`lib/main.dart`)
  and CLI (`bin/check_architecture.dart`); rules in `lib/src/`; tests in
  `test/`. Has its own `pubspec.lock`, keep it committed.
- `architecture.yaml` (repo root): module DAG and `domain_forbidden` list.

## Rust (`rust/`, `rust_builder/`)

Cargo workspace with `kanaru_media`, `kanaru_plugin_runtime` and
`kanaru_bridge` (the only cdylib; `src/api/native_info.rs` is the one API so
far). `rust_builder/` is the cargokit glue; generated bindings are
`rust/crates/kanaru_bridge/src/frb_generated.rs` and `lib/src/rust/`.

## Tests (`test/`)

`bootstrap/` (startup order, failure cleanup), `database/` (reopen keeps data),
`extension/` (registry, license), `platform/` (Linux paths), `shell/` (shells,
router, nav).
