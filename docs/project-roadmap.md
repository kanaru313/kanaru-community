# Roadmap

## Order

1. **Repository skeleton** (done): pub workspace, `kanaru_ui`, architecture
   gate, module DAG, two shells, router, registry, empty database, docs, CI.
2. **Storage design and schema v1** (tables and helpers done; groups below are
   spec only): Android storage spike results, then the final schema as one
   `schemaVersion`.
3. **Core modules**, one at a time, each working on both shells: player,
   library (scan and index), lyrics, plugins.
4. **Extensions**: licensing support in an extension package, then its features
   one by one. Streaming runtime and remote sources live in this repo.

An offline local player ships before any streaming or remote-source work.

## Open follow-ups from the skeleton

Registry and platform:
- Missing registry points: `nowPlayingActions`, `contextActions`,
  `songDetailSections`, `homeSections`, `searchShelves`, `lyricLineDecorators`,
  `pluginKinds`. Add each with the module that uses it (`lib/src/extension/`).
- `platform/` has `AppPaths` and the native loader only. MediaControls (MPRIS,
  `audio_service`), Secrets, FileAccess (MediaStore) and Window come with
  playback, library and licensing.
- `AndroidAppPaths` has only been built, not run on a device.

Database:
- Background isolate (`createInBackground`) shared with an extension database
  is not proven; the UI isolate runs SQLite until then
  (`lib/src/database/app_database.dart`).
- `schemaVersion` stays 1 until the first release; `AppDatabase` has no
  `onUpgrade` or downgrade guard yet. Add them with the first release that
  must migrate user data (debug builds use the schema guard meanwhile).
- Spec-only groups, added by their module before first release (spec:
  `docs/system-architecture-database.md`): library `track_artists` and
  `track_merges`; playback `queue_entries` and the device id file; lyrics
  `lyrics_pins`, `lyrics_rejects`, `lyrics_translations`, `lyrics_search`;
  plugins `plugins`, `plugin_data`, `plugin_repos`, `lyrics_source_prefs`;
  cache `cover_colors`, `online_lyrics`.
- Scanner (library module): pass-version columns on `tracks` (`tags_version`,
  `keys_version`, `lyrics_version`, `cover_scan_version`, `scan_error`) with
  their indexes; folder range filter on locators (feeds `unhideTracks`);
  marking absent files `missing` with `missing_since` (the GC never collects a
  `missing` row without it); scheduling `collectOrphanTracks` (debounced at
  startup and after each scan).
- Mood playlists: callers must set `name_key` (lower case, collapsed spaces,
  NFC); the database does not compute it.
- A failing startup hook of an extension stops the app at the error screen;
  per-extension disable is undecided (`lib/kanaru_bootstrap.dart`).

UI:
- Desktop: drawer for narrow windows, custom title bar (`window_manager`), top
  bar Rescan, Keymap and AI buttons (`lib/src/shell/ui/`).
- Mobile: the Settings entry (icon in the Home header) is a placeholder
  (`lib/src/screens/ui/`).
- Icon set undecided; `KIcons` wraps Material Icons so the choice is one file.

Gate and tooling:
- UI rules (no `Colors.*`, numeric `EdgeInsets`, `Divider`, `ListTile`, ...)
  are not in the gate yet (`tool/architecture_lint`).
- Window screenshots on Wayland (skill `kanaru-run`).
