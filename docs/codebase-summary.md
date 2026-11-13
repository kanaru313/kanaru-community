# Codebase summary

Map of what exists. Module rules: [ARCHITECTURE.md](../ARCHITECTURE.md).
Generated from the source tree; the file names here are the real ones.

## Entry and composition root (`lib/`)

| File | What |
|---|---|
| `main.dart` | `runKanaru(extensions: bundledExtensions)` |
| `kanaru.dart` | `runKanaru`, `builtInExtensions`; exports the database, extension, license and registry types |
| `kanaru_bootstrap.dart` | `bootstrap(...)`: native library, paths, settings, device id, database, registry, startup hooks; `BootstrapResult`; `databaseFileName = 'kanaru.db'` |
| `kanaru_error_app.dart` | `KanaruErrorApp`, shown on startup failure |
| `l10n/parts/<part>_<locale>.arb` | Strings per part (`app`, `scan`, `playback`, `library`); merged by `tool/merge_arb.dart` into `l10n/app_<locale>.arb`, then generated into `l10n/gen/` (both committed) |

## Modules (`lib/src/`)

| Module | Contents |
|---|---|
| `foundation/` | `result.dart` (sealed `Ok`/`Err`), `app_logger.dart` (`setupLogging`); `ids/` (`stableHashHex`, `stableUid`, `newUlid`, `isUlid`); `ordering/fractional_keys.dart` (`generateKeyBetween`, `generateNKeysBetween`); `text/text_fold.dart` (`foldDiacritics`, `foldedMatcher`, `foldedContains`) |
| `media/domain/` | Plain-Dart shared types, no Flutter: `track_id.dart` (`TrackId`), `track_info.dart` (`TrackInfo`, `TrackAvailability`, `formatFromLocator`), `play_context.dart` (`PlayContext`, `PlayContextKind`), `cover_colors.dart` (`CoverColors`, `coverColorsVersion`), `library_keys.dart` (`groupKey`, `searchForm`, `sortForm`, `songKey`, `albumKeyFor`, `albumArtistKeyFor`, `encodeKey`/`decodeKey`, `AlbumKey`, `ArtistKey`, `libraryKeysVersion`), `cover_files.dart` (`isCoverKey`, `coverRelativePath`, `CoverSize`, `coverTempPrefix`, `coverLayoutMarker`) |
| `platform/` | `domain/`: `app_paths.dart` (`AppPaths`, `kanaruDirName = 'kanaru'`), `settings_store.dart` (`SettingsStore`), `setting.dart` (`Setting<T>`), `device_id.dart` (`DeviceIdSource`), `storage_volumes.dart` (`StorageVolumes`, `StorageVolume`, `StorageVolumeKind`, `volumeForPath`). Window close: `domain/window_close.dart` (`WindowCloseGuard`), `data/linux_window_close_guard.dart`, `data/noop_window_close_guard.dart`, `state/window_close_provider.dart`. `data/`: `linux_app_paths.dart` (XDG), `android_app_paths.dart` (`path_provider`), `app_paths_factory.dart` (`createAppPaths`), `native_library.dart` (loads Rust; the only importer of `lib/src/rust`), `json_settings_store.dart` (`JsonSettingsStore`), `file_device_id.dart` (`FileDeviceId`), `atomic_file.dart`, `linux_storage_volumes.dart`, `android_storage_volumes.dart`. `state/`: `platform_providers.dart` (`appPathsProvider`, `nativeVersionsProvider`), `settings_providers.dart` (`settingsStoreProvider`, `settingNotifierProvider`, `SettingNotifier`), `device_id_provider.dart` (`deviceIdProvider`), `storage_volumes_provider.dart` (`storageVolumesProvider`) |
| `database/` | `app_database.dart` (`AppDatabase`, `schemaVersion` 1, `AppDatabase.file`, `sharedConnection`). `tables/`: `library_source_tables.dart` (`sources`, `source_mounts`, `excluded_folders`), `library_track_tables.dart` (`tracks`, `track_details`) with `library_track_search.drift` (`track_search` FTS5, triggers), `library_cover_tables.dart` (`cover_colors`), `playback_tables.dart` (`play_log`, `play_stats`, `queue_entries`) with `playback_stats.drift`, `library_collection_tables.dart` (`playlists`, `playlist_entries`, `saved_items`), `extension_tables.dart` (`extension_schema`). Helpers: `track_snapshot.dart` (`upsertTrackSnapshot`), `track_artists_write.dart` (`replaceTrackArtists`), `track_details_write.dart` (`upsertTrackDetails`), `track_missing.dart` (`markTracksMissing`), `track_lifecycle.dart` (`removeSource`, `reviveSource`, `setMountEnabled`, `unhideTracks`), `track_gc.dart` (`collectOrphanTracks`), `track_visibility.dart` (`visibleTrackWhere`, `isVisibleTrack`), `tombstone_upsert.dart` (`insertOrRevive`), `folder_exclusion.dart` (`applyFolderExclusion`, `removeFolderExclusion`, `excludedFolderKeys`), `folder_range.dart` (`folderLocatorRange`), `exclusion_sql.dart`, `queue_store.dart` (`readQueue`, `replaceQueue`), `cover_colors_store.dart` (`upsertCoverColors`, `coverColorsFor`), `fts_query.dart` (`ftsPrefixQuery`), `play_stats_bulk.dart` (`runPlayStatsBulk`), `row_uids.dart`, `schema_guard.dart` (debug schema check); `tables.dart` and `database.dart` (barrels), `state/database_providers.dart` (`appDatabaseProvider`). Generated `*.drift.dart`. Spec: [system-architecture-database.md](./system-architecture-database.md) |
| `extension/` | `kanaru_extension.dart` (`KanaruExtension`); `domain/license.dart` (`ProFeature`, `LicenseStatus`, `LicenseService`, `FreeLicenseService`); `state/extension_registry.dart` (`ExtensionRegistry`); `state/registry_entries.dart` (`NavItem`, `SettingsSection`, `TopBarAction`, `StartupContext`, `StartupHook`, `FlushHook`); `state/extension_providers.dart` (`extensionRegistryProvider`) |
| `playback/` | Contracts, seeds at the lane boundary. `domain/`: `playback_commands.dart` (`PlaybackCommands`), `now_playing.dart` (`NowPlaying`). `data/`: `track_info_rows.dart` (`trackInfoFromRow`, `loadTrackInfos`, `watchTrackInfo`), `cover_colors_rows.dart` (`loadCoverColors`, `watchCoverColors`), `unavailable_playback.dart` (seed, throws `StateError`). `state/`: `playback_providers.dart` (`playbackCommandsProvider`, `nowPlayingProvider`, `isCurrentTrackProvider`, `hasCurrentTrackProvider`, `isPlayingProvider`), `track_info_providers.dart` (`trackInfoProvider`), `cover_providers.dart` (`coverMissesProvider`, `CoverMissSink`, `coverColorsProvider`). `ui/track_cover.dart` (`TrackCover`). Every `.family` is `isAutoDispose: true`. Contract: [system-architecture-playback.md](./system-architecture-playback.md) |
| `library/` | `library_extension.dart` (`LibraryExtension`). `domain/`: `library_tabs.dart` (`LibraryTab`, `LibraryTabsConfig`), `music_folder.dart` (`MusicFolder`), `scan_status.dart` (`ScanStatus` and its variants, `ScanPhase`, `LibraryScanCommands`), `favorites.dart` (`FavoritesController`), `folder_exclusions.dart` (`FolderExclusions`). `data/`: `favorites_repository.dart` (`FavoritesRepository`), `folder_exclusion_repository.dart` (`FolderExclusionRepository`), `music_folders_repository.dart` (`watchMusicFolders`), `custom_cover_store.dart` (`CustomCoverStore`: custom covers through the Rust import), `scan/` (lane A: cover pass, tag pass, scan pipeline, writers, native wrappers incl. `native_cover_import.dart`). `state/`: `library_tabs_providers.dart` (`libraryTabsSetting`, `libraryTabsProvider`), `favorites_providers.dart` (`favoriteTrackIdsProvider`, `isFavoriteProvider`, `favoritesControllerProvider`), `music_folders_providers.dart` (`musicFoldersProvider`), `folder_exclusion_providers.dart` (`folderExclusionsProvider`), `custom_cover_providers.dart` (`customCoverControllerProvider`, `customCoverFileProvider`, `customCoverThumbProvider`, `customCoverKeyProvider`), `scan_providers.dart` (`scanStatusProvider`, `libraryScanCommandsProvider`, both read the controller), `scan/` (lane A: `ScanController` and its provider, music folder editor, scan settings, startup work). `domain/scan/` holds the pure scan rules. `ui/`: `library_browse_registration.dart` (nav items and routes of Library and Playlists), `library_locations.dart` (`LibraryLocations`), `library_page.dart` and `playlists_page.dart` (placeholders), `scan/` (Home scan card, folder display path, `library_scan_registration.dart` empty), `selection/selection_bar.dart` (`LibrarySelectionBar`, empty slot). Contract: [system-architecture-library.md](./system-architecture-library.md) |
| `online/` | `online_extension.dart`; `ui/online_page.dart` (placeholder) |
| `screens/` | `screens_extension.dart` (`ScreensExtension`); `ui/`: `home_page.dart`, `search_page.dart`, `settings_page.dart`; `settings/state/appearance_settings.dart` (`themeChoiceProvider` for `app.theme`, `appLanguageProvider` for `app.language`, read by `KanaruApp`); `first_run/state/first_run_gate.dart` (`firstRunRequiredProvider` reads `library.setup_done`, `firstRunPath`); `first_run/ui/` (first-run page and its sections); `first_run/first_run_registration.dart` (empty); `now_playing/now_playing_registration.dart` (Queue nav item, `comingSoon`) |
| `shell/` | `ui/app_shell.dart` (the one place that picks desktop or mobile), `mobile_shell.dart`, `desktop_shell.dart` (Ctrl+F / Ctrl+K), `desktop_top_bar.dart` (Rescan, placeholders), `desktop_sidebar.dart` (sidebar grouped by order band, footer); `state/nav_history.dart` (desktop back and forward) |
| `router/` | `app_router.dart` (`buildRouter` from the registry, first-run redirect), `state/router_provider.dart` (`routerProvider`), `state/app_flush.dart` (`flushApp`, `FlushCoordinator`, `exitFlushCap`), `ui/kanaru_app.dart` (`KanaruApp`: theme, locale, router, lifecycle listener) |
| `rust/` | Generated flutter_rust_bridge Dart code (do not edit) |

Not yet present: `plugins`, `storage`, `lyrics`, and the scanner, playback and
library UI bodies (their seeds are in the table above).

## Packages

- `packages/kanaru_ui` (no music types, imports no app code):
  - Tokens and theme: `KSpace`, `KRadius`, `KShape`, `KLayout`, `KBreakpoints`, `KMotion`, `buildKanaruTheme`, `FormFactor`.
  - Icons: `KIcons` (the only file that names `Icons`).
  - Pages and headers: `KPage`, `PageHeader`, `PageHeaderScope`, `KEmpty`, `KEmptyPage`, `ProBadge`.
  - Choice and feedback: `SelectionRow`, `SelectionOption`, `showSelectionPicker` (with `confirm`, `header`, `anchor`), `showKSheet`, `showKDialog`, `confirmAction`, `showAppSnackBar`.
  - Rows and tiles: `KListRow`, `KChip`, `KPressable`, `KContextRegion`, `KCover`, `KEqualizerIcon`, `KGap` (typedef of `Gap`).
  - Group folders, exported from their barrels and owned by the lanes: `widgets/setup/` (scanner lane), `widgets/media/` (playback lane), `widgets/collections/` (library lane). Empty in the foundation.
  - Tests in `packages/kanaru_ui/test/`, with a shared host helper in `test/support/`.
- `packages/kanaru_extensions`: `bundledExtensions`, empty by default in this repo.

## Gate (`tool/`)

- `check`: bash script running the full gate (`--rust` adds fmt, the `unsafe` grep, cargo test and clippy).
- `merge_arb.dart`: merges the l10n parts (`--check` for the gate).
- `check_architecture.dart`: wrapper that runs the CLI of the lint package.
- `architecture_lint/`: pure Dart package, analyzer plugin (`lib/main.dart`)
  and CLI (`bin/check_architecture.dart`); rules in `lib/src/`; tests in
  `test/`. Has its own `pubspec.lock`, keep it committed.
- `architecture.yaml` (repo root): module DAG and the `domain_forbidden` list.

## Rust (`rust/`, `rust_builder/`)

Cargo workspace with `kanaru_media`, `kanaru_plugin_runtime` and
`kanaru_bridge` (the only cdylib).

- `kanaru_media`: `error.rs` (`MediaError`, `is_transient`), `cancel.rs` (`Cancel`),
  `limits.rs` (size, pixel and duration caps), `lib.rs` (`CRATE_VERSION`). Empty
  modules that lanes fill: `tags/`, `covers/`, `waveform/`.
- `kanaru_plugin_runtime`: runs plugin JavaScript (QuickJS via `rquickjs`). No FFI
  and no dependency on `kanaru_media`. `PluginRuntime` / `RuntimeConfig` (`runtime.rs`;
  `run`, `begin_job`, `cancel_job`, `reset`, `shutdown`, `check_script`) owns the
  worker pool (`pool.rs`), the job registry (`jobs.rs`) and the late-answers drain
  (`host/late.rs`). `PluginHost` (`host/mod.rs`) is what answers `fetch` and stream
  calls; the bridge implements it, `NoNetwork` is the default. `engine/` runs one
  job on a fresh `Runtime` and `Context` and maps every ending to a `ScriptResult`;
  `globals/` has `Response`, `execute` and `load`; `host/` has the budget,
  `callback` (park and wake while waiting for the host), `console`, `sleep`,
  `storage` (`localConfig`, `localStorage`) and `quiet` (panic hook); `js/` holds
  `host_prelude.js` and CryptoJS 4.2.0; `memory.rs` is the limited allocator and
  `compile_check.rs` the compile-only check (the two files with `unsafe`);
  `limits.rs` has every cap; `types.rs` the runtime types. Not ported yet: the
  fetch, stream and `emit` natives and `Html`. Integration tests are in
  `crates/kanaru_plugin_runtime/tests/` (`common/mod.rs` shares one runtime per test
  binary behind a lock; `contract`, `crypto`, `failure_data`, `limits`, `storage`,
  `hostile`, `lifecycle`, `prelude_drift`); the feature `test-hooks` adds the
  `__testLog` and `__testPanic` script globals.
- `kanaru_bridge`: `guard.rs` (`guarded`, panic to `NativeError`), `pools.rs`
  (`background`, `interactive`, `waveform`; 8 MiB stacks), `os.rs` (thread
  priority, the only `unsafe`), `source.rs` (`Source`, `open_source`: regular
  files only), `api/{native_info,error,tags,covers,waveform}.rs` (`native_versions`,
  `NativeError` DTO; `tags`, `covers` and `waveform` are empty until their lanes).
  `api/lyrics.rs` (`read_embedded_lyrics`, own thread per call, 10 s timeout,
  at most 2 stuck threads; reader in `kanaru_media` `tags/lyrics_reader.rs` and `tags/lyrics_sylt.rs`).
  `frb_generated.rs` is generated.
- Third-party versions are in `rust/Cargo.toml`, with the reason beside each.
- `rust_builder/` is the cargokit glue that builds `kanaru_bridge` for the
  host and the Android ABIs. Generated bindings: `rust/crates/kanaru_bridge/src/frb_generated.rs`
  and `lib/src/rust/`.

## Platform runners

`android/` (`MainActivity.kt` registers the `kanaru/media_store` channel from
`MediaStoreChannel.kt` (`listAudio`, `listLyrics`, `audioFolders`); the manifest declares the `READ_MEDIA_*` permissions and the
backup rules exclude the device id) and `linux/` (GTK runner). `MainActivity.kt`
and the manifest are hotspots: no lane edits them.

## Tests (`test/`)

| Folder | Covers |
|---|---|
| `bootstrap/` | Startup order and failure cleanup |
| `database/` | Schema shape and constraints, foreign keys, snapshot upsert, lifecycle, GC, play stats, search, collections, queue store, cover colours, folder exclusions and ranges, spec-versus-schema check; `support/` holds the shared test database |
| `extension/` | Registry (duplicates, nav rules, flush hooks), license |
| `foundation/` | ids, fractional keys, diacritic folding |
| `library/` | Tabs, favorites, music folders, folder exclusion |
| `media/` | Library keys, cover file layout, play context |
| `platform/` | Linux paths, settings store, device id, storage volumes, `Setting` |
| `playback/` | Track info rows, narrow providers, `TrackCover` |
| `router/` | Router build, nested routes, first-run redirect |
| `screens/` | Appearance settings |
| `shell/` | Shells, seams, nav, selection bar slot |
| `tool/` | The l10n merge tool |
| `support/` | Fake `PlaybackCommands`, memory settings store |
