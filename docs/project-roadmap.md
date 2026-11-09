# Roadmap

## Order

1. **Repository skeleton** (done): pub workspace, `kanaru_ui`, architecture
   gate, module DAG, two shells, router, registry, empty database, docs, CI.
2. **Storage design and schema v1**: Android storage spike results, then the
   final schema (`tracks` and the tables around it) as one `schemaVersion`.
3. **Core modules**, one at a time, each working on both shells: player,
   library (scan and index), lyrics, plugins.
4. **Extensions**: real licensing in the private package, then its features
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
- `AppDatabase` has no downgrade guard or `onUpgrade`; add with the first
  schema bump.
- Schema v1 (`tracks`...) does not exist; only `extension_schema` does.
- A failing startup hook of an extension stops the app at the error screen;
  per-extension disable is undecided (`lib/kanaru_bootstrap.dart`).

UI:
- Desktop: drawer for narrow windows, custom title bar (`window_manager`), top
  bar Rescan, Keymap and AI buttons (`lib/src/shell/ui/`).
- Mobile: the Settings entry (icon in the Home header) is a placeholder
  (`lib/src/screens/ui/`).
- `SelectionRow` and `SelectionPicker` are not in `kanaru_ui` yet; add with
  the first screen that picks a value.
- Icon set undecided; `KIcons` wraps Material Icons so the choice is one file.

Gate and tooling:
- UI rules (no `Colors.*`, numeric `EdgeInsets`, `Divider`, `ListTile`, ...)
  are not in the gate yet (`tool/architecture_lint`).
- Window screenshots on Wayland (skill `kanaru-run`).
