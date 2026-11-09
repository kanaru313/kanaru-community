# Codebase summary

Map of what exists. Module rules: [ARCHITECTURE.md](../ARCHITECTURE.md).

## Entry and composition root (`lib/`)

| File | What |
|---|---|
| `main.dart` | `runKanaru(extensions: bundledExtensions)` |
| `kanaru.dart` | `runKanaru`, `builtInExtensions`; exports extension, database, license and registry types |
| `kanaru_bootstrap.dart` | `bootstrap(...)` startup sequence, `BootstrapResult` |
| `kanaru_error_app.dart` | `KanaruErrorApp`, shown on startup failure |
| `l10n/parts/<part>_<locale>.arb` | Hand-written strings per part; merged by `tool/merge_arb.dart` into `l10n/app_<locale>.arb`, then `l10n/gen/` (both committed) |

## Modules (`lib/src/`)

| Module | Contents |
|---|---|
| `foundation/` | `result.dart` (sealed `Ok`/`Err`), `app_logger.dart` (`setupLogging`); `ids/` (`stableHashHex`, `stableUid`, `newUlid`, `isUlid`); `ordering/` (`generateKeyBetween`, `generateNKeysBetween`); `text/` (`foldDiacritics`, `foldedMatcher`, `foldedContains`) |
| `media/domain/` | plain-Dart shared types: `TrackId`, `TrackInfo` (+`formatFromLocator`), `PlayContext`, `CoverColors`; `library_keys.dart` (`groupKey`, `searchForm`, `sortForm`, `songKey`, `albumKeyFor`, `AlbumKey`/`ArtistKey` encode/decode, `libraryKeysVersion`); `cover_files.dart` (`isCoverKey`, `coverRelativePath`, marker/temp names). One writer function per derived column; readers use the same function or the stored column. |
| `platform/` | `domain/app_paths.dart` (`AppPaths`, `kanaruDirName = 'kanaru'`); `data/` `linux_app_paths.dart` (XDG), `android_app_paths.dart` (`path_provider`), `app_paths_factory.dart`, `native_library.dart` (loads Rust, the only importer of `lib/src/rust`), `json_settings_store.dart` (`settings.json` in the config dir), `file_device_id.dart` (`device_id` in the data dir), `atomic_file.dart`; `domain/` also `settings_store.dart` (`SettingsStore`), `setting.dart` (`Setting<T>`), `device_id.dart` (`DeviceIdSource`); `state/` `platform_providers.dart`, `settings_providers.dart` (`settingsStoreProvider`, `settingNotifierProvider`), `device_id_provider.dart` (`deviceIdProvider`); storage volumes: `domain/storage_volumes.dart` (`StorageVolumes`, `StorageVolume`, `volumeForPath`), `data/{android,linux}_storage_volumes.dart`, `state/storage_volumes_provider.dart` |
| `database/` | `app_database.dart` (`AppDatabase`, `schemaVersion` 1, `sharedConnection`, `configureConnection`); `tables/` `library_source_tables.dart` (`sources`, `source_mounts`, `excluded_folders`), `library_track_tables.dart` (`tracks`, `track_details`) + `library_track_search.drift` (`track_search` FTS5, triggers), `playback_tables.dart` (`play_log`, `play_stats`) + `playback_stats.drift` (`play_stats_ctl`, stats triggers), `library_collection_tables.dart` (`playlists`, `playlist_entries`, `saved_items`), `extension_tables.dart` (`ExtensionSchema`); helpers `row_uids.dart`, `tombstone_upsert.dart` (`insertOrRevive`), `track_snapshot.dart` (`upsertTrackSnapshot`), `track_lifecycle.dart`, `track_gc.dart` (`collectOrphanTracks`), `track_visibility.dart`, `fts_query.dart` (`ftsPrefixQuery`), `play_stats_bulk.dart` (`runPlayStatsBulk`), `schema_guard.dart` (debug schema check); `tables.dart`, `database.dart` (barrel), `state/database_providers.dart`; generated `*.drift.dart`. Spec: [system-architecture-database.md](./system-architecture-database.md) |
| `extension/` | `kanaru_extension.dart`; `domain/license.dart` (`ProFeature`, `LicenseStatus`, `LicenseService`, `FreeLicenseService`); `state/extension_registry.dart`, `registry_entries.dart` (`NavItem`, `SettingsSection`, `TopBarAction`, `StartupContext`, `StartupHook`), `extension_providers.dart` |
| `playback/` | Cross-lane contracts only (the player is not built yet): `domain/` `playback_commands.dart` (`PlaybackCommands`), `now_playing.dart` (`NowPlaying`); `data/` `track_info_rows.dart` (`trackInfoFromRow`, `loadTrackInfos` in chunks of 500, `watchTrackInfo`), `cover_colors_rows.dart`, `unavailable_playback.dart` (seed: throws `StateError`); `state/` `playback_providers.dart` (`playbackCommandsProvider` seed, `nowPlayingProvider`, narrow `isCurrentTrackProvider`/`hasCurrentTrackProvider`/`isPlayingProvider`), `track_info_providers.dart`, `cover_providers.dart` (`coverMissesProvider`, `coverColorsProvider`); `ui/track_cover.dart` (`TrackCover`). Every `.family` here is `isAutoDispose: true` |
| `library/` | `library_extension.dart`; `ui/` Library and Playlists placeholder pages; `domain/` `library_tabs.dart`, `music_folder.dart`, `scan_status.dart` (`ScanStatus`, `LibraryScanCommands`); `data/` `favorites_repository.dart`, `folder_exclusion_repository.dart`, `music_folders_repository.dart`; `state/` `library_tabs_providers.dart` (setting `library.tabs`), `favorites_providers.dart` (one `Set<TrackId>` stream + `isFavoriteProvider` select), `music_folders_providers.dart`, `folder_exclusion_providers.dart`, `scan_providers.dart` (seeds: idle status, `NoLibraryScanner`) |
| `online/` | `online_extension.dart`; `ui/online_page.dart` |
| `screens/` | `screens_extension.dart`; `ui/` Home, Search, Settings; `settings/state/appearance_settings.dart` (`themeChoiceProvider` `app.theme`, `appLanguageProvider` `app.language`, read by `KanaruApp`); `first_run/state/first_run_gate.dart` (`firstRunRequiredProvider` seed false, `firstRunPath`) |
| `shell/` | `ui/` `app_shell.dart` (the one place that picks desktop or mobile), `mobile_shell.dart`, `desktop_shell.dart`, `desktop_top_bar.dart`, `desktop_sidebar.dart`; `state/nav_history.dart` (desktop back and forward) |
| `router/` | `app_router.dart` (`buildRouter` from the registry), `state/router_provider.dart`, `ui/kanaru_app.dart` |
| `rust/` | Generated flutter_rust_bridge Dart code (do not edit) |

Not yet present: `plugins`, `storage`, `lyrics`. Seeds (`UnavailablePlaybackCommands`, `NoLibraryScanner`, the idle scan status, the first-run gate) are replaced by the lane that builds the real thing; their declarations stay.

## Packages

- `packages/kanaru_ui`: `KSpace`, `KRadius`, `KShape`, `KLayout`, `KBreakpoints`,
  `KMotion`, `KIcons`, `buildKanaruTheme`, `FormFactor`, widgets `KPage`,
  `PageHeader`, `KEmpty`, `KEmptyPage`, `ProBadge`; shared widgets
  `SelectionRow`, `showSelectionPicker`, `showKSheet`, `showKDialog`,
  `confirmAction`, `showAppSnackBar`, `KPressable`, `KCover`,
  `KEqualizerIcon`, `KContextRegion`, `KListRow`, `KChip`, `PageHeaderScope`,
  `KGap`. Lane widgets go in the group folders `widgets/{setup,media,
  collections}/` and are exported from their barrel. Tests in
  `packages/kanaru_ui/test/` (shared helper `test/support/host.dart`).
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

`bootstrap/` (startup order, failure cleanup), `database/` (schema shape and
constraints, foreign keys, snapshot upsert, lifecycle, GC, play stats, search,
collections, spec-vs-schema check; `support/` has the shared test database),
`foundation/` (ids, fractional keys), `extension/` (registry, license), `platform/` (Linux paths, settings, storage volumes), `playback/` (track info rows, narrow providers, `TrackCover`), `library/` (tabs, favorites, folder exclusion, music folders), `screens/` (appearance), `support/` (fake `PlaybackCommands`, memory settings store), `shell/` (shells,
router, nav).
