# Roadmap

## Order

1. **Repository skeleton** (done): pub workspace, `kanaru_ui`, architecture
   gate, module DAG, two shells, router, registry, empty database, docs, CI.
2. **Storage design and schema v1** (done): tables and helpers of schema v1
   (spec: `docs/system-architecture-database.md`). Groups that belong to later
   modules stay spec-only until those modules land.
3. **Wave 1: an offline local player** (in progress). Shared contracts first,
   then three parallel lanes, each working on both shells:
   - **Foundation** (done in its PR): platform base (settings store, device id,
     storage volumes), schema additions (scan columns, `track_artists`,
     `queue_entries`, `cover_colors`, folder exclusions), media domain types and
     library keys, cross-lane contracts with seeds, router registry with nav
     bands and flush hooks, shared `kanaru_ui` widgets, Rust base crates
     (error DTO, panic guard, worker pools).
   - **Lane A, scanner and first run**: media permissions, music folders,
     tag and cover passes in Rust, the scan itself, the first-run screen and the
     Home scan card.
   - **Lane B, playback**: the player behind `PlaybackCommands`, the queue,
     media controls (MPRIS on Linux, audio_service on Android), the mini player,
     the player bar, Now Playing, and the waveform.
   - **Lane C, library UI**: the six library lists, album and artist pages,
     menus, multi-select, favorites, folder exclusions, and the Linux "open in
     file manager" action. It merges last, after the scanner and the player.
4. **Core modules after wave 1**, one at a time, each working on both shells:
   lyrics, plugins.
5. **Extensions**: licensing support in an extension package, then its features
   one by one. Streaming runtime and remote sources live in this repo.

An offline local player ships before any streaming or remote-source work.

## Open follow-ups from the skeleton

Registry and platform:
- Missing registry points: `nowPlayingActions`, `contextActions`,
  `songDetailSections`, `homeSections`, `searchShelves`, `lyricLineDecorators`,
  `pluginKinds`. Add each with the module that uses it (`lib/src/extension/`).
- `platform/` has `AppPaths`, the native loader, settings, device id and storage
  volumes. MediaControls (MPRIS, `audio_service`), FileAccess (MediaStore) and
  Window come with playback and the library. Secrets come with licensing.
- `AndroidAppPaths` has only been built, not run on a device.

Database:
- Background isolate (`createInBackground`) shared with an extension database
  is not proven; the UI isolate runs SQLite until then
  (`lib/src/database/app_database.dart`).
- `schemaVersion` stays 1 until the first release; `AppDatabase` has no
  `onUpgrade` or downgrade guard yet. Add them with the first release that
  must migrate user data (debug builds use the schema guard meanwhile).
- Spec-only groups, added by their module before first release (spec:
  `docs/system-architecture-database.md`): library `track_merges`; lyrics
  `lyrics_pins`, `lyrics_rejects`, `lyrics_translations`, `lyrics_search`;
  plugins `plugins`, `plugin_data`, `plugin_repos`, `lyrics_source_prefs`;
  cache `online_lyrics`.
- Mood playlists: callers must set `name_key` (lower case, collapsed spaces,
  NFC); the database does not compute it.
- A failing startup hook of an extension stops the app at the error screen;
  per-extension disable is undecided (`lib/kanaru_bootstrap.dart`).
- Cover colour rows are never collected (`cover_colors`, `lib/src/database/cover_colors_store.dart`).

Scanner (lane A, on the foundation's columns and helpers):
- GC scheduling (`collectOrphanTracks`) at startup and after each scan.
- Pass versions, missing marks and exclusion helpers exist (foundation); the
  passes that write them are lane A.

UI:
- Desktop: drawer for narrow windows, custom title bar (`window_manager`), top
  bar Keymap and AI buttons (`lib/src/shell/ui/`).
- Mobile: the Settings entry (icon in the Home header) is a placeholder
  (`lib/src/screens/ui/`).
- Icon set undecided; `KIcons` wraps Material Icons so the choice is one file.

Wave 1 follow-ups (not in wave 1 by decision; each needs its own design):
- Hide a single track or album ("Loại khỏi thư viện"): needs a schema decision,
  `hidden` has one meaning today (the user took the row out of the library: source removed, mount disabled or folder excluded), and the unhide helpers turn every `hidden` row back, so a per-track hide needs its own marker.
- Delete file: needs platform work in both shells and an undo design.
- Favorites, History and Most played pages: placeholders until their mockup.
- Android "Open in file manager": needs a `MainActivity` change.
- Settings › Library screen (tabs, folders, exclusions, short-file skip).
- Lyrics card and tab, sleep timer, add-to-playlist.
- Golden tests for `kanaru_ui` widgets once a golden setup exists.
- `cargo deny` license and duplicate check.
- Linux packaging with an LGPL libmpv build before any Pro Linux build.
- Shared menu model for the queue row and the song menu.

Gate and tooling:
- UI rules (no `Colors.*`, numeric `EdgeInsets`, `Divider`, `ListTile`, ...)
  are not in the gate yet (`tool/architecture_lint`).
- Window screenshots on Wayland (skill `kanaru-run`).
