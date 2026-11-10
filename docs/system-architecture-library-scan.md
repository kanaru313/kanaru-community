# Library scan

> **Contract stub.** Owner: lane A (scanner and first run). The foundation
> declares the database helpers, the cover layout, the Rust plumbing and the
> scan contracts below; they are frozen. Lane A replaces this text with its
> own design (walk, passes, first-run flow, Home scan card) when it lands. The
> consumer side (scan status as shown, folder exclusions, the lists) is in
> [system-architecture-library.md](./system-architecture-library.md).

## Contents

- Pass versions and errors: this file.
- Database helpers and track lifecycle: this file.
- Cover files, marker, misses and colours: this file.
- Scan status as produced, first run and permissions: this file.
- Rust pools, guard, sources and limits: this file.

## Pass versions and errors

Scan state lives on `tracks` (`database/tables/library_track_tables.dart`), next
to the snapshot columns:

| Column | Meaning |
|---|---|
| `tags_version` | Tag pass that produced the snapshot |
| `keys_version` | Version of the key, sort and search derivation (`libraryKeysVersion`) |
| `cover_scan_version` | Cover pass version |
| `lyrics_version` | Reserved for the lyrics module; 0 means no lyrics tokens |
| `scan_error` | Error kind of the last failed pass; NULL means ok |

Indexes: `tracks_tags_version`, `tracks_keys_version`, `tracks_cover_version`.

**Rule.** A pass writes its version only on success or on a permanent error.
On a transient error it writes `scan_error` and leaves the version alone, so the
file is tried again on the next scan.

Errors from Rust (`rust/crates/`):

| Type | Shape |
|---|---|
| `MediaError` (`kanaru_media`) | `Io(ErrorKind)`, `Unsupported`, `Corrupt(String)`, `TooLarge`, `Cancelled`, `Timeout`; `is_transient()` |
| `NativeError` (`kanaru_bridge/src/api/error.rs`) | `{kind: NativeErrorKind, detail: String, transient: bool}` |
| `NativeErrorKind` | `Io`, `NotFound`, `PermissionDenied`, `Unsupported`, `Corrupt`, `TooLarge`, `Cancelled`, `Timeout`, `Panic` |

`is_transient()` is true for `Timeout`, `Cancelled`, and for these `Io` kinds
only: `TimedOut`, `Interrupted`, `WouldBlock`, `ResourceBusy`,
`StaleNetworkFileHandle`, `ConnectionRefused`, `ConnectionReset`,
`ConnectionAborted`, `NotConnected`, `NetworkDown`, `NetworkUnreachable`,
`HostUnreachable`, `BrokenPipe`. Everything else is permanent, including
`Other`, because parsers wrap their failures as `Other`. `Panic` is permanent.

Lane rule: map a parser or decoder failure to `Corrupt` or `Unsupported`, never
to an `Io` error of kind `Other`.

## Database helpers

`lib/src/database/`. Helper code runs on the calling isolate (the SQL itself runs on the database isolate) and takes the database
(or its table instance) explicitly.

| Helper | Purpose |
|---|---|
| `upsertTrackSnapshot(db, tracksTable, TracksCompanion row) → Future<int>` | Insert or refresh one track; returns `tracks.id` |
| `replaceTrackArtists(db, int trackId, List<({String key, String name})> artists)` | Rewrites the artists of a track (deduplicated by key) |
| `upsertTrackDetails(db, TrackDetailsCompanion row)` | Comment, extra tags, `lrc_locator` (the `.lrc` sidecar), cover source |
| `upsertCoverColors(db, {required coverKey, required seed, required colors, required version, required now})` | Stores the colours of one cover |
| `coverColorsFor(db, coverKey)` | `({int seed, List<int> colors, int version})?`, null when missing or malformed |
| `markTracksMissing(db, Iterable<int> trackIds, int now) → Future<int>` | `present` to `missing` for explicit ids only |
| `applyFolderExclusion(db, {required sourceId, required folderKey, required displayPath, required now}) → Future<int>` | Excludes a folder and hides its rows |
| `removeFolderExclusion(db, {required sourceId, required folderKey, required now})` | Undo; rows come back on the next scan |
| `excludedFolderKeys(db, int sourceId) → Future<List<String>>` | Live exclusions of a source |
| `folderLocatorRange(String folderKey)` | `({String from, String to})?`: `[key/, key0)`; null for the root `''` |
| `insertOrRevive(db, table, row, {required now, reviveColumns})` | Insert, or revive a tombstoned row |
| `removeSource`, `reviveSource`, `setMountEnabled`, `unhideTracks` | Source and mount lifecycle, one transaction each |
| `collectOrphanTracks(db, {required now}) → Future<int>` | Track GC |
| `trackUid(sourceUid, locator)`, `sourceUidForRemote(kind, account, root)`, `excludedFolderUid(...)` | Stable uids (`row_uids.dart`) |

### Upsert rules

- The conflict target is `(source_id, locator)`. Identity (`id`, `uid`,
  `source_id`, `locator`), user columns and `added_at` are never rewritten.
- Only the snapshot and scan fields present in the companion are rewritten. An
  absent field keeps the stored value; an explicit null writes null.
- `status` comes from the source kind and the stored row. A new row inside a
  live folder exclusion is inserted `hidden`.
- `title` and `title_search`, `genre` and `genre_key`, `album` and its keys go
  together, else `ArgumentError` (see [system-architecture-library.md](./system-architecture-library.md#stored-column-rule)).

### Track lifecycle rules

- Lane rule: write in batches of at most 200 rows per transaction, and yield
  between batches. The database runs on its own isolate, so other queries can interleave between batches.
- Lane rule: notify the UI at most about every 300 ms during a scan.
- Only `present` rows become `missing`, and only explicit ids.
- Never mark a row missing when its root is unreachable, or when the root lists
  zero files while the database has tracks for it.
- Canonicalize roots. Skip MediaStore entries outside the chosen roots (copies
  under `/sdcard/Library` were seen on the phone).
- Skip non-UTF-8 names with a scan error.
- `collectOrphanTracks` deletes owned child rows (`track_details`, `track_artists`,
  `play_stats`) before a track. It refuses to run when a foreign key into
  `tracks` is not `RESTRICT`. Grace periods: `missing` 7 days, `hidden` 7 days,
  `remote` 24 hours. It finds the referencing tables at run time, so
  `queue_entries` and `playlist_entries` protect their tracks.
- Scheduling: once at startup (debounced) and after each completed scan.

## Cover files

| Item | Value |
|---|---|
| Key | `<2 hex>/<32 hex>`: blake3 of the original image bytes, computed in Rust only (`isCoverKey`) |
| Path | `cacheDir/covers/{thumb,full}/<key>.jpg` (`coverRelativePath(key, size)`; throws `ArgumentError` for a bad key) |
| Sizes | `thumb` 256 px, `full` 1024 px on the longest side, both JPEG |
| Temp files | prefix `.kanaru-tmp-` (`coverTempPrefix`), renamed when complete |
| Layout marker | `cacheDir/covers/.layout-v1` (`coverLayoutMarker`) |

- Missing marker (the cache was cleared by Android or a cleaner app): reset
  `cover_scan_version` to 0 for every row, then rewrite the covers and the marker.
- Evicted file: `TrackCover` reports the key to `coverMissesProvider`. Listen
  on `coverMissesProvider.misses` and re-extract that cover. The sink dedupes
  within 60 s and keeps the newest 256 keys until the first listener.

### Cover colours (write side)

- Computed in the cover pass with the `material-colors` crate (0.4.2), in Rust.
- Stored with `upsertCoverColors`: `seed` (ARGB) and `colors` (JSON array of ARGB
  ints, most dominant first), `version` = `coverColorsVersion` (1).
- A write with an older `version` than the stored row is ignored.
- Read side: [system-architecture-playback.md](./system-architecture-playback.md#cover-colours-read-side).

## Language

`tracks.language_detected` is a boolean, set when the scanner detected the
language from the title (`whatlang`, in Rust).

## Scan status as produced

`lib/src/library/domain/scan_status.dart` declares the values; lane A implements
`scanStatusProvider` and `libraryScanCommandsProvider` (declarations frozen,
bodies lane A's). The seed emits `ScanIdle` and logs `rescan` calls.

- `ScanRunning(phase, done, total)` with `phase` `listing`, `tags` or `covers`,
  at most about every 300 ms.
- `ScanFinished(...)` at the end, with totals and `added`.
- `ScanFailed(kind)` on an error (`permission`, `io`, ...). Failures never throw
  out of `rescan`.
- `rescan({bool full = false})` completes when the request is accepted or
  queued, and absorbs requests while a scan runs. The shell's Rescan button calls it.

## First run

`lib/src/screens/first_run/state/first_run_gate.dart`:

- `firstRunRequiredProvider` (`Provider<bool>`): true until the setting
  `library.setup_done` is set (key owned by lane A). Seed: `false`.
- `firstRunPath` is `/welcome`. While the gate is true, the router redirects
  every location there. The route is registered from
  `screens/first_run/first_run_registration.dart`. If the gate is true and no
  route serves `/welcome`, the router throws `StateError` when it builds.
- Media permissions state: `MediaPermissions` (`platform/domain/media_permissions.dart`,
  provider `mediaPermissionsProvider`) reports `audio` and `images` as
  `granted`, `denied`, `permanentlyDenied`, `limited` or `notApplicable`.
  `allGranted` is false for `limited` (Android 14 partial photo access). The
  screen asks for audio first and for images only after audio is granted.
  Linux uses `NoMediaPermissions` (everything `notApplicable`). Android uses
  `permission_handler` (`Permission.storage` for both rows up to SDK 32,
  `Permission.audio` and `Permission.photos` from SDK 33). The plugin reports a
  permanent denial as `denied` from a status read, so the Android class keeps
  the last `request()` result per row and never downgrades `permanentlyDenied`
  to `denied` until a read returns anything but `denied` (`mergeStatus`); requests are
  serialized and a repeated request shares the one in flight.
- Media permissions (manifest): `READ_MEDIA_AUDIO`, `READ_MEDIA_IMAGES` and
  `READ_MEDIA_VISUAL_USER_SELECTED` (Android 14 partial access counts as not
  granted), `READ_EXTERNAL_STORAGE` up to SDK 32. Never
  `MANAGE_EXTERNAL_STORAGE`. `POST_NOTIFICATIONS` is not declared.

## Audio sources

- Android: MediaStore, through `MediaStoreChannel.kt` (lane A). Linux: a `dart:io` walk.
- Both sit behind `LocalAudioCatalog` (`platform/domain/local_audio_catalog.dart`,
  pure Dart; the provider `localAudioCatalogProvider` picks the implementation
  by OS). One call per root: `listAudio(root, excludedKeys, skipShorterThanMs)`
  returns an `AudioListing` with `audio`, `.lrc` `lyrics`, and what could not be
  seen: `reachable`, `unreadableDirs`, `emptyDirs`, `unstattable`, counts
  (`excludedOut`, `skippedOut`, `shortOut`, `skippedLinks`, `undecodableNames`
  with up to 3 sample folders). `unreachableReason` says `missing`, `timedOut`
  or `busy`. `excludedOut` counts items (files on Android, whole folders on
  Linux, which does not enter them); `skippedOut` counts hidden audio and `.lrc`
  files only; `shortOut` counts files dropped by the Android duration
  pre-filter. `filteredOut = excludedOut + shortOut`: only the user's own
  filters may switch off the empty-root guard (never `skippedOut`, since
  `.stfolder`, `lost+found` or `@eaDir` sit in many roots). Failures are reported there, never thrown.
- The catalog also answers `audioFolders()` (Android MediaStore folders; Linux
  none), `suggestedMusicFolder()`, `canonicalize(path)`, `folderChoice`
  (`systemDialog` or `mediaStoreSheet`) and `pickFolder()` (Linux only).
- Android (`platform/data/media_store/`): `MediaStoreChannel.kt` (channel
  `kanaru/media_store`; queries on a small pool of background threads, replies on the
  main looper, every `Throwable` answered) answers `sdkInt`, `primaryRoot` (shared
  storage of the current user), `listAudio`, `listLyrics` (Files collection,
  `.lrc`) and `audioFolders` as parallel lists. A null cursor is an error, not
  an empty result. The `LIKE` pattern is built and escaped in Dart
  (`mediaStoreLikePattern`: `%`, `_`, `\`) and keeps the root's spelling for
  audio and lyrics alike (SQLite folds ASCII case only, so no lower-casing: a
  root such as `Nhạc Đỏ` must still match). Kotlin binds it and re-checks the
  prefix. `MediaStoreAudioCatalog` re-checks the prefix in Dart with the same
  ASCII-only case rule (rows outside the root, such as copies under
  `/sdcard/Library`, are dropped and logged with 3 samples), drops rows under
  skipped folders, the `<volume>/Android/` tree by absolute path (app data,
  messenger voice notes; a root the user picked inside it is listed as chosen)
  and hidden files (`skippedOut`), excluded keys (`excludedOut`) and short
  rows (`shortOut`, duration known and below `skipShorterThanMs`). Rows with an
  empty `_data` are counted in `skippedOut` and logged.
- The Android catalog never throws for a platform failure: a refused query, a
  failed query or one past the 120 s limit comes back as an unreachable listing
  with `unreachableReason` `permission`, `failed` or `timedOut` (no lyrics query
  starts after the audio query timed out); an absent root
  is `missing`. `audioFolders()` and `suggestedMusicFolder()` return empty/null
  on failure. `canonicalize` only normalises paths that came from `audioFolders()`
  or the suggestion (already in `_data` form); other input has `/sdcard` and
  `/storage/self/primary` mapped to the primary root, then links resolved.
  `suggestedMusicFolder()` is `<primary>/Music` when any audio folder lies in its
  subtree. `audioFolders()` counts only the scanned audio extensions and rows of
  30 s or more, and skips junk, dot and `<volume>/Android/` folders, so the first-run
  estimate matches the scan.
- Rules on both shells: a scan never enters a dot-folder or a junk folder
  (`lost+found`, `@eaDir`, `.Trash*`, `$RECYCLE.BIN`, snapshot and old-version
  folders, `#recycle`, `@Recycle`, `.@__thumb`, `.AppleDouble`) below a root;
  the root itself may be a dot-folder. Hidden files are not listed.
  Extensions: mp3 flac m4a aac alac ogg oga opus wav aif aiff ape wv dsf dff.
- Linux walk (`platform/data/local_files/`): a synchronous walk on a worker
  isolate that is killed after 120 s per root (`WalkIsolateRunner`). The root
  counts as unreachable for that scan. A killed isolate stays in a "busy" set
  until its exit port fires; while a root is busy it is reported unreachable at
  once and no second isolate is spawned. Folder links are not followed but
  counted and logged; file links are followed with `stat`; FIFOs, sockets and
  devices are never listed; a broken file link goes to `unstattable`; a name
  that is not valid UTF-8 is counted, not listed. A listed-empty sub-folder is
  reported in `emptyDirs` only when it is a mount point (`/proc/self/mounts`) or
  lies under `/media`, `/run/media` or `/mnt` (an unplugged drive looks the
  same); otherwise it is an ordinary empty folder. An excluded key matches a
  folder when `relative == key || relative.startsWith('$key/')`; such folders
  are not entered and count once in `excludedOut`.
- Linux suggestion: `XDG_MUSIC_DIR` from `user-dirs.dirs` (absolute
  `XDG_CONFIG_HOME` only, else `~/.config`), falling back to `~/Music`. Values
  that are `$HOME`, `/`, a parent of home, relative, contain `..`, or do not
  exist are dropped.
- Rust reads regular files only. `source::open_source` opens the file with
  `O_NONBLOCK` and checks the type on the open handle, so a FIFO or a socket
  never blocks a scan.
- Network roots get a per-root timeout, and a failing root cannot stop the others.
- Short files: the "skip files under 30 seconds" setting (on by default) is
  declared by lane A. No UI in wave 1.
- A `.lrc` sidecar is stored as `track_details.lrc_locator`.

## Rust

`rust/crates/kanaru_media`:

| Module | Contents |
|---|---|
| `error` | `MediaError` (above) |
| `cancel` | `Cancel::new()`, `with_timeout(Duration)`, `cancel()`, `check() -> Result<(), MediaError>` |
| `limits` | `MAX_FILE_BYTES_UNSEEKABLE` 256 MiB, `MAX_COVER_BYTES` 32 MiB, `MAX_COVER_PIXELS` 40 000 000, `MAX_TAG_FILE_SECONDS` 30 |
| `tags/`, `covers/` | Empty until lane A |

`rust/crates/kanaru_bridge`:

| Module | Contents |
|---|---|
| `pools` | `background()`, `interactive()`, `waveform()`. 8 MiB thread stacks, a panic handler on each pool. Background size from `background_threads(cores, android)`: Android uses half the cores, at most 4; desktop uses all but one |
| `guard` | `guarded(f)`: a panic becomes `NativeError` with kind `Panic`, not transient. Works with `panic = "unwind"`; never set `abort` |
| `source` | `Source::Path(String)`, `open_source(&Source)` |
| `os` | `lower_current_thread_priority()`: the only `unsafe` in the workspace |
| `api/error.rs` | `NativeError` DTO |
| `api/tags.rs`, `api/covers.rs` | Dart API, lane A. Empty until then |

Every file is parsed under `guarded`, on a pool, so one bad file cannot take the
scan down.

## Old app references

The old prototype (retired repo, code only):

| Area | Old code |
|---|---|
| Indexer | `lib/core/indexer/library_indexer.dart`, `walk_audio_files.dart`, `scan_diff.dart`, `scan_rules.dart`, `cover_pass.dart`, `folder_watcher.dart`, `cover_paths.dart` |
| Paths | `lib/core/paths/app_directories.dart` |
| Rust | `rust/src/tag_reader.rs`, `tag_batch.rs`, `cover_batch.rs`, `cover_thumbnail.rs`, `cover_decode_limits.rs`, `webp_exif.rs` |

Pitfalls the old app hit, and where the design answers them:

- A transient I/O error became "no cover" for good. Answer: versions move only on
  a permanent result.
- An empty mount point deleted the whole library. Answer: explicit ids only; no
  missing marks on an unreachable or empty root; the GC keeps its grace period.
- An upsert on the wrong target reset `added_at` and ids. Answer: conflict target
  `(source_id, locator)`; identity never rewritten.
- FIFOs hung `open()`, and network roots hung whole scans. Answer: regular files
  only; per-root timeout.
- Decoder memory blew up, and a 2 MiB thread stack was too small for the tag
  library. Answer: `limits`, 8 MiB pool stacks, `guarded` per file.
- A malformed cover key escaped the cache folder. Answer: `isCoverKey` and
  `coverRelativePath`, which throws.
- Empty or relative XDG variables broke the paths. Answer: `LinuxAppPaths`
  ignores non-absolute values (`platform/data/linux_app_paths.dart`).
- A prefix match hid `Live Albums` when `Live` was excluded. Answer:
  `folderLocatorRange`.
