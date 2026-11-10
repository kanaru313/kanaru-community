# Database: schema v1

Table-level spec of the app database (`lib/src/database/`). It lists every table group: the groups coded in the schema v1 foundation, and the groups that their module adds before the first release. The code and the reviews check against this file.

> **Status.** The coded groups exist in `lib/src/database/` and this file matches them (a test checks that every table, index and trigger is named here). Spec-only groups are not coded yet; their column lists are proposals. A module that adds a spec-only group updates its section of this file in the same change.

Overview of the database and its place in the app: [ARCHITECTURE.md](../ARCHITECTURE.md#database).

## Contents

- [Requirement map](#requirement-map)
- [Rules](#rules)
- [Foreign key list](#foreign-key-list)
- [Coded groups](#coded-groups)
- [Spec-only groups](#spec-only-groups)
- [Helpers](#helpers)

## Requirement map

| Requirement | Tables and rules |
|---|---|
| DATA-01 Sources, mounts, excluded folders | `sources`, `source_mounts`, `excluded_folders`; [Sources and secrets](#sources-and-secrets) |
| DATA-02 Track key and revision | `tracks.locator`, `tracks.revision`; [Locator and mount roots](#locator-and-mount-roots) |
| DATA-03 One tracks table for every source | `tracks`; [Track status](#track-status) |
| DATA-04 uid, tombstones, device id | [uid](#uid), [Deletes, tombstones and revive](#deletes-tombstones-and-revive) |
| DATA-05 Playlist order | `playlist_entries.sort_key` |
| DATA-06 Song key | `tracks.song_key`, `online_lyrics.cache_key` |
| DATA-09 Track details | `track_details` |
| Artists of a track, play queue, cover colours | `track_artists`, `queue_entries`, `cover_colors` |
| Cover chosen by the user (playlist, album, artist) | `custom_covers`; [custom_covers](#custom_covers-coded-in-wave-1) |
| DATA-10 Rating and mood playlists | `tracks.rating`, `playlists.name_key` |
| DATA-11 Plugin install ids | `plugins.install_id` (spec only) |

## Rules

### Types and constraints

- Times are epoch milliseconds, `INTEGER`.
- Booleans are `INTEGER NOT NULL CHECK (x IN (0, 1))`.
- `CHECK` is used only on fixed sets: track status, rating range, booleans, `custom_covers.kind` (adding a kind after the first release is a table rebuild). Open-ended kinds (`sources.kind`, `playlists.kind`, `saved_items.kind`) are validated by Dart constants, so adding a kind needs no table rebuild.
- `foreign_keys = ON` and `recursive_triggers = ON` on every connection, set by `configureConnection` in `setup:` (runs inside the database isolate, so it must stay a top-level function; register any future custom SQL function or collation there too) and again in `beforeOpen`.
- `AppDatabase.file` uses `NativeDatabase.createInBackground`: SQLite runs on its own isolate. `await appDb.openedConnection()` opens the database and returns the connection extension databases open on (`ProDatabase.connect(await appDb.openedConnection())`); bootstrap hands startup hooks that result. This is enforced in code because the remote executor runs the migration of the last database that touched it: an extension that queried before `AppDatabase` opened would run its own create step. `sharedConnection` is the raw getter, valid only after open. Extension databases, watch streams and transactions behave as on an in-memory database (`test/database/background_isolate_test.dart`). `beforeOpen` and the schema guard run on the calling isolate; their errors and SQLite's reach callers as `DriftRemoteException` (nested for `beforeOpen`). For a SQLite error, `remoteCause` is the `SqliteException` itself (one level), unwrapped by one helper; for `beforeOpen` and guard errors rely only on `toString()` (the original message, so the startup error screen shows the same text). The connection must stay single (no `readPool`): TEMP tables and transactions are per connection. Journal mode is SQLite's default (rollback journal, no WAL), so every commit is durable when it returns and nothing flushes or closes the database on exit.
- The device id is stored in no table. It comes from `dataDir/device_id` (`FileDeviceId`), exposed as `deviceIdProvider`. `play_log.device_id` records it per row; the column is plain text and the database does not check it.

### uid

- Every synced row has `uid TEXT NOT NULL UNIQUE`. Besides the primary key, `uid` is the only unique key of a synced row, except the uniques named in the group tables (the natural key `tracks (source_id, locator)`, the live-row partial uniques of `playlists`, the mount root).
- A deterministic uid is `'<prefix>:' + stableHashHex(parts, 16)`. It is used only for stable natural keys:

| Row | uid |
|---|---|
| Remote or plugin source | `src:` + hash(kind, account ?? '', root) |
| Track | `trk:` + hash(source uid, locator) |
| Excluded folder | `exc:` + hash(source uid, folder key) |
| Favorites playlist | `favorites` |
| Favorites entry | `fav:` + hash(playlist uid, track uid) |
| Saved item | `saved:` + hash(source uid, kind, remote id) |
| Lyrics pin | `pin:` + hash(track uid) |

- Every other row uses a ULID (`newUlid`): local sources, mood, normal and imported playlists and their entries, plays, track merges.
- A uid is computed once, when the row is created.
- uids identify rows; they are not secrets. A uid can confirm that a known path exists, so uids never go to third-party services. No data leaves the device before sync.

### Deletes, tombstones and revive

- Until sync exists, user removals are hard `DELETE`s: clear history, delete a playlist, unfavorite.
- Synced tables keep `updated_at` and `deleted_at` for sync. Every read filters `deleted_at IS NULL`. Every partial index for live rows includes `deleted_at IS NULL`.
- Removing a source is a tombstone (`deleted_at` set), so re-adding the same root revives it.
- Re-adding a row with a deterministic uid is `insertOrRevive`:

  ```sql
  INSERT ... ON CONFLICT(uid) DO UPDATE SET deleted_at = NULL, updated_at = ?, <revive columns>
  ```

  Each group names its revive columns. Reviving a source rewrites `name`, `account`, `config_json`, `credential_ref`.
  Code: `insertOrRevive(db, table, row, now:, reviveColumns:)` in `tombstone_upsert.dart`. It returns the row (same `id` on a conflict) and touches only that row. `deleted_at = NULL` and `updated_at = now` always. `reviveColumns` names columns taken from the new row only when the existing row is a tombstone (`CASE WHEN deleted_at IS NULL THEN old ELSE excluded END`), so a live row keeps its values (a second favorite keeps its place). It throws `ArgumentError` (failed future) for a table without `uid`, `deleted_at` or `updated_at`, an unknown column, `id`/`uid`/`deleted_at`/`updated_at`, or a column absent from the row. Revive columns: Favorites entry `sort_key`, `added_at`; saved item `snapshot_json`, `saved_at`; excluded folder `display_path`.
- Deleting a playlist deletes its entries. Reviving a playlist does not revive its old entries.
- Never use `INSERT OR REPLACE` on `tracks`, `play_log`, or any table with triggers or incoming foreign keys. Use `ON CONFLICT` upserts.

### Foreign keys

- Every foreign key into `tracks` (public and Pro) is `ON DELETE RESTRICT`. No `CASCADE` and no `SET NULL` into `tracks`.
- `CASCADE` only runs from a parent to a pure child outside `tracks`: playlist to entries, source to mount, source to excluded folders.
- Owned one-to-one children of a track (`track_details`, `play_stats`, and `track_artists` once added) are `RESTRICT` too. The track GC deletes them before the track. Nothing may reference an owned child: the GC throws when a foreign key points at one.
- Every `*track_id` column has a foreign key into `tracks` and an index whose first column is that column. A single `INTEGER PRIMARY KEY` counts as that index.
- Every foreign key column is the first column of an index, or the primary key.

The full list is in [Foreign key list](#foreign-key-list).

### Track status

| Status | Meaning | Set by |
|---|---|---|
| `present` | In the library. | Scanner only. |
| `missing` | File of a scanned source that was not seen in a complete scan of a reachable root. `missing_since` is set. | Scanner, on `present` rows only. |
| `hidden` | The user took it out of the library: source removed, mount disabled, or folder excluded. One meaning only. | Lifecycle helpers. |
| `remote` | Row of a reference-only source (`sources.kind = 'plugin'`). Never in the library. | `upsertTrackSnapshot`. |

- A rescan upsert keeps `hidden`.
- The scanner and the lifecycle helpers never touch `remote` rows.
- Hide (`removeSource`, `setMountEnabled(false)`): `present` and `missing` rows become `hidden`, and `scan_cursor` and `last_scan_at` reset, all in one transaction. Excluding a folder hides its rows the same way, through the folder-exclusion helpers (`applyFolderExclusion`, `removeFolderExclusion`), never by hand. Hide-then-unhide paths (`setMountEnabled(true)`, `reviveSource`, `unhideTracks`) leave a row `hidden` while a live exclusion of its source covers it. A new file inserted by `upsertTrackSnapshot` under a live exclusion is inserted `hidden`.
- Folder exclusion has its own helpers (`folder_exclusion.dart`, see Helpers): they hide and unhide by folder range and, unlike `unhideTracks`, never unhide a row that another live exclusion, a disabled mount or a removed source still holds.
- Unhide (`reviveSource`, `setMountEnabled(true)`, `unhideTracks`; rows covered by a live folder exclusion stay hidden): `hidden` rows become `missing` with `missing_since = now`, and the cursor resets. A full scan then decides: files that are still there return to `present`, and deleted files never come back as ghosts.
- Helpers live in `track_lifecycle.dart`: `removeSource(db, sourceId, now)`, `setMountEnabled(db, sourceId, enabled, now)`, `reviveSource(db, sourceId, now, {name, account, configJson, credentialRef})`, `unhideTracks(db, sourceId, now, {locatorFrom, locatorTo})`. Each runs in one transaction and notifies `tracks`, `sources` and `source_mounts` by table name. `locatorFrom` and `locatorTo` (both or neither) mean `locator >= from AND locator < to`; the scanner computes a folder's range bounds. `setMountEnabled(true)` and `unhideTracks` throw `StateError` for a removed source: only `reviveSource` brings one back.
- Reviving a source forces a full scan.
- An unreachable root leaves its rows untouched.

### Track snapshot upsert

- `upsertTrackSnapshot` derives the status from the source kind. Callers never pass a status. `plugin` gives `remote`, on insert and on conflict.
- Otherwise a new row is inserted `present`, or `hidden` when a live folder exclusion of its source covers it. On conflict on `(source_id, locator)`, the status is `hidden` if the row is `hidden`, else `present`.
- On conflict, `missing_since` is set to `NULL` unless the row is `hidden`.
- It writes snapshot and scan columns only. `uid`, `added_at` and the user columns are never touched.
- One statement (`INSERT ... ON CONFLICT (source_id, locator) DO UPDATE ... RETURNING id`); it returns `tracks.id` and notifies `tracks` and `track_search`. Search streams declare `readsFrom` both `tracks` and `track_search`. The source kind is read in the same statement.
- The companion carries `source_id`, `locator`, `uid`, `title`, `rel_path`, `added_at`, `updated_at` (the insert needs them) and any snapshot or scan fields (`trackSnapshotColumns`, `trackScanColumns`). `title` and `title_search`, `genre` and `genre_key`, and `album` with `album_title_key` and `album_artist_key` go together in the same row (the writer derives them: `title_search = searchForm(title)`, `genre_key = groupKey(genre)`, the album keys with `albumKeyFor`, both NULL for an empty album), else `ArgumentError`. Any column outside identity (except `id`), snapshot, `added_at` and `updated_at` (`status`, `missing_since`, user columns) throws `ArgumentError`. On conflict only the snapshot fields present in the companion are rewritten: an absent field keeps the stored value, an explicit null writes null.
- Column classification (SQL names, in `track_snapshot.dart`, each `tracks` column in exactly one set; a test enforces it): `trackIdentityColumns` (`id`, `uid`, `source_id`, `locator`), `trackSnapshotColumns` and `trackScanColumns` (rewritten on conflict), `trackUserColumns` (never touched), `trackLifecycleColumns` (`status`, `missing_since`, `added_at`, `updated_at`; derived or set once).

### Online rows

- A `remote` row is upserted on every reference (playlist, history, queue) and on every successful resolve for playback. The upsert runs in the same transaction as the referencing insert.
- Helpers accept a `DatabaseConnectionUser`, so any database object can call them inside its own transaction.
- Last write wins on snapshot columns. User columns are untouched.

### Garbage collection

`collectOrphanTracks(now)` deletes unreferenced track rows. Rules, in order:

1. Refuse to run when `PRAGMA foreign_keys` is 0.
2. Find every foreign key into `tracks` at run time (`sqlite_master` joined with `pragma_foreign_key_list`). Pro tables are included.
3. Throw if any of them is not `RESTRICT`.
4. Ignore the owned-child tables `trackOwnedChildTables` = `{track_details, play_stats, track_artists}` when deciding whether a track is referenced. Delete their rows before the track rows, in the same transaction.
5. Delete a track only if no other foreign key row points at it (tombstoned rows count), `rating IS NULL AND lyrics_offset_ms = 0`, and one of:

   | Status | Condition |
   |---|---|
   | `missing` | `missing_since <= now - missingGraceMs` (7 days). |
   | `hidden` | `updated_at <= now - hiddenGraceMs` (7 days: undo window for remove and exclude), and not in a live source whose mount is disabled. A disabled NAS mount keeps its rows. |
   | `remote` | `updated_at <= now - remoteGraceMs` (24 h). Keeps the now-playing and queued online track. |

6. `present` rows are never deleted.
7. The helper notifies streams for `tracks`, `track_details`, `play_stats`, `track_artists` and `track_search` (the FTS delete trigger writes it), only when rows were deleted. It returns the number of deleted tracks.

Details: the checks and the candidate set are computed once per run (a `TEMP` table inside the transaction, dropped at the end), so the owned-children delete and the track delete use the same ids. A foreign key whose parent column is not named in the schema refers to `tracks.id`. Only the main schema is inspected. A composite foreign key into `tracks` throws like a non-`RESTRICT` one. Tables are addressed as `main.<table>`, so a temp table of the same name cannot hide a reference. A foreign key into an owned child table throws too. A `missing` row with `missing_since IS NULL` is never collected, so the scanner must set `missing_since` when it marks a row missing. Any failure leaves the database unchanged.

Scheduling is the caller's: the library module runs the GC in the background, debounced on app startup and after each completed scan. This file defines only the helper.

### Library reads and search

- Library views read `status = 'present'` only. The SQL form is `visibleTrackWhere(alias)`, the typed form is `isVisibleTrack(tracks)`. Both must agree (a test checks it).
- History, playlists and Pro views show any referenced row through its snapshot. Whether it can be played comes from the playback resolver, not from `status`.
- Search: the MATCH input goes only through `ftsPrefixQuery(input)`. It splits on whitespace, wraps each token in double quotes (inner `"` doubled) and appends `*`. Example: `ab "cd` becomes `"ab"* """cd"*`. Empty input means no MATCH clause.

### Locator and mount roots

- `tracks.locator` is UTF-8 text as the platform listing API returns it: the path relative to the mount root, `/` as separator, no leading or trailing `/`.
- Locators are never Unicode-normalized. NFC and NFD names are different locators.
- A name that does not decode as UTF-8 is skipped (no row is written); the scan counts and logs it.
- CUE track: `'<cue path>#NN'` (two-digit track number).
- Id-based remotes (Google Drive, OneDrive, Subsonic): the locator is the provider file id. `rel_path` holds the display path. The scanner applies folder exclusions while listing.
- Path-based folder filter: `folderLocatorRange` (`database/folder_range.dart`) returns `[key/, key0)` (`locator >= key || '/' AND locator < key || '0'`), and null for the root (every row). The exclusion and unhide helpers use it. Folder keys come from the same listing API.
- Mount roots are canonicalized (real path, no trailing `/`) by the caller before they are saved (the database only enforces the unique `source_mounts_root`). One mount per chosen folder. An SD card volume root is just a path.

### Sources and secrets

- `sources.root` never contains URL userinfo (`user:pass@`) or a query string. Such a root is rejected (`sourceUidForRemote`).
- Secrets go only through `credential_ref`, a key into the platform secret store. No secret is written to any other column.
- `config_json` holds non-secret options only. Allowed keys per kind:

| Kind | Allowed `config_json` keys |
|---|---|
| `local` | none (`{}`) |
| `webdav` | `path_style` |
| `subsonic` | `api_version` |
| `plugin` | none (`{}`) |
| `s3`, `gdrive`, `onedrive`, `dropbox`, `jellyfin` | none defined in v1 (`{}`). The module that adds the kind lists its keys here before first release. |

- Removing a source or disabling a mount resets `scan_cursor` and `last_scan_at`. Reviving a source rewrites `name`, `account`, `config_json` and `credential_ref`, and forces a full scan.
- Re-adding a local folder whose canonical root already has a mount revives that source instead of creating a new one.

### Play history

- `play_log` is the history. There is no retention limit in v1.
- `play_stats` is maintained by triggers for single changes, and by `runPlayStatsBulk` for bulk changes (see the play group in [Coded groups](#coded-groups)).

### Pro contract

- Stable for `kanaru-pro`: the key columns of `tracks`, `sources`, `playlists`, `playlist_entries` and `play_log`. They are never renamed or dropped.
- `tracks.status` values are `present`, `missing`, `hidden`, `remote`. A new value is an API change.
- Pro views of online tracks expect `remote`. Library-style views use the visibility helper (`present` only).
- Albums are derived, with no table. History is `play_log`.
- Pro tables live in `kanaru-pro` (AI chat, per-track translation config, smart playlists). They are versioned in `extension_schema`, and any foreign key into `tracks` is `RESTRICT`.
- Extensions never add indexes or triggers to public tables.
- `play_stats_ctl` is private to `database/` and is not exported.
- `kanaru-pro` runs the same foreign-key check against `trackOwnedChildTables` in its CI.

### TrackRef mapping

`TrackRef {sourceKind, sourceId, externalId}` maps to `sources.kind`, `sources.uid` and `tracks.locator`. `sourceId` is the source uid, not the integer `sources.id`.

### Schema version

- `schemaVersion` stays 1 until the first release. Developer databases from before this schema are deleted. A debug-only guard (`schema_guard.dart`) compares every table, index and trigger of a fresh in-memory `AppDatabase` with the file, ignoring in-memory databases, FTS5 shadow tables and objects only the file has (extension tables share the file). On a difference it fails with a message to delete the file that names the differing objects.

## Foreign key list

| Child column | Parent | On delete | Group |
|---|---|---|---|
| `source_mounts.source_id` | `sources.id` | CASCADE | sources (coded) |
| `excluded_folders.source_id` | `sources.id` | CASCADE | sources (coded) |
| `tracks.source_id` | `sources.id` | RESTRICT | tracks (coded) |
| `track_details.track_id` | `tracks.id` | RESTRICT | tracks (coded) |
| `play_log.track_id` | `tracks.id` | RESTRICT | play (coded) |
| `play_stats.track_id` | `tracks.id` | RESTRICT | play (coded) |
| `playlists.origin_source_id` | `sources.id` | RESTRICT | collections (coded) |
| `playlist_entries.playlist_id` | `playlists.id` | CASCADE | collections (coded) |
| `playlist_entries.track_id` | `tracks.id` | RESTRICT | collections (coded) |
| `saved_items.source_id` | `sources.id` | RESTRICT | collections (coded) |
| `track_artists.track_id` | `tracks.id` | RESTRICT | library (coded) |
| `queue_entries.track_id` | `tracks.id` | RESTRICT | playback (coded) |
| `custom_covers.item_key` | none | none | library (coded): not a foreign key, see [custom_covers](#custom_covers-coded-in-wave-1) |
| `lyrics_pins.track_id` | `tracks.id` | RESTRICT | lyrics (spec only) |
| Any other track reference (lyrics, Pro) | `tracks.id` | RESTRICT | rule |

## Coded groups

Each group lists its file, owner and sync class. Sync classes: **synced** (travels with sync, has a uid), **per device** (not synced), **derived** (rebuilt from other data), **cache** (may be dropped at any time).

### sources: Coded in schema v1 foundation

Owner: library. File: `tables/library_source_tables.dart`. Sync: `sources` and `excluded_folders` synced; `source_mounts` per device.

#### sources

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | INTEGER | PK | autoincrement | |
| `uid` | TEXT | NOT NULL | | UNIQUE. Remote and plugin: `src:` + hash. Local: ULID. |
| `kind` | TEXT | NOT NULL | | `SourceKind`: `local`, `webdav`, `s3`, `gdrive`, `onedrive`, `dropbox`, `subsonic`, `jellyfin`, `plugin`. No CHECK. |
| `name` | TEXT | NOT NULL | | |
| `account` | TEXT | NULL | | Account identity, remote sources only. |
| `root` | TEXT | NULL | | Remote base URL, bucket or prefix, drive root, or plugin `install_id`. NULL for local. |
| `config_json` | TEXT | NOT NULL | `'{}'` | Non-secret options, see [Sources and secrets](#sources-and-secrets). |
| `credential_ref` | TEXT | NULL | | Key in the platform secret store. |
| `added_at` | INTEGER | NOT NULL | | |
| `updated_at` | INTEGER | NOT NULL | | |
| `deleted_at` | INTEGER | NULL | | Tombstone. |

No UNIQUE besides `uid`.

#### source_mounts

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `source_id` | INTEGER | PK, FK | | `sources.id` CASCADE. |
| `root` | TEXT | NULL | | Canonical local path. NULL for remote sources. |
| `enabled` | INTEGER | NOT NULL | `1` | Boolean. 0 = disabled; its tracks are hidden. |
| `scan_cursor` | TEXT | NULL | | Incremental scan token (for example a Drive changes token). |
| `last_scan_at` | INTEGER | NULL | | |
| `added_at` | INTEGER | NOT NULL | | |

Index `source_mounts_root`: UNIQUE `(root) WHERE root IS NOT NULL`. Plugin sources never get a mount. Removing a local source tombstones the source and sets its mount `enabled = 0`. The mount row stays, so the same root revives the source.

#### excluded_folders

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | INTEGER | PK | autoincrement | |
| `uid` | TEXT | NOT NULL | | UNIQUE. `exc:` + hash(source uid, folder key). |
| `source_id` | INTEGER | NOT NULL | | FK `sources.id` CASCADE. |
| `folder_key` | TEXT | NOT NULL | | Relative path (path-based sources) or folder id (id-based sources). |
| `display_path` | TEXT | NOT NULL | | Path shown in the UI. |
| `added_at` | INTEGER | NOT NULL | | |
| `updated_at` | INTEGER | NOT NULL | | |
| `deleted_at` | INTEGER | NULL | | Tombstone. |

Index `excluded_folders_source` on `(source_id, folder_key)`, not unique.

### tracks: Coded in schema v1 foundation, extended in wave 1

Owner: library. File: `tables/library_track_tables.dart`, with `tables/library_track_search.drift` for the FTS table and triggers. Sync: derived index, rebuilt by the scanner. The user columns (`rating`, `lyrics_offset_ms`) have their own timestamps, so each merges last-write-wins.

#### tracks: identity and keys

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | INTEGER | PK | autoincrement | |
| `uid` | TEXT | NOT NULL | | UNIQUE. `trk:` + hash(source uid, locator). |
| `source_id` | INTEGER | NOT NULL | | FK `sources.id` RESTRICT. |
| `locator` | TEXT | NOT NULL | | See [Locator and mount roots](#locator-and-mount-roots). |

UNIQUE `(source_id, locator)`: the scanner's natural key, and the conflict target of the snapshot upsert.

#### tracks: snapshot (written by the scanner and the snapshot upsert)

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `rel_path` | TEXT | NOT NULL | | Display path. |
| `revision` | TEXT | NULL | | Changes when the file changes. |
| `mtime_ms` | INTEGER | NULL | | |
| `size_bytes` | INTEGER | NULL | | |
| `start_ms` | INTEGER | NULL | | CUE start. NULL = whole file. |
| `end_ms` | INTEGER | NULL | | CUE end. NULL = to end of file. |
| `song_key` | TEXT | NULL | | Hash of normalized metadata (DATA-06). |
| `title` | TEXT | NOT NULL | | |
| `title_sort` | TEXT | NOT NULL | `''` | `sortForm(titleSortTag ?? title)` (a TITLESORT tag may replace the title here). |
| `title_search` | TEXT | NOT NULL | `''` | `searchForm(title)` (never from a TITLESORT tag), indexed by `track_search`. |
| `artist`, `album`, `album_artist`, `genre`, `composer` | TEXT | NULL | | |
| `language` | TEXT | NULL | | `languageKey(tag or detected)`: ISO 639-3, lower case. NULL = unknown (shown as "Chưa rõ"). |
| `album_display_artist` | TEXT | NULL | | |
| `artist_sort`, `album_sort` | TEXT | NULL | | |
| `artist_search`, `album_search`, `album_artist_search`, `genre_search` | TEXT | NULL | | Search forms, indexed by `track_search`: `artist_search = searchForm(artists.join(' '))`, `album_search = searchForm(album)`, `album_artist_search = searchForm(albumArtist ?? first non-blank artist)`, `genre_search = searchForm(genre)`. |
| `genre_key` | TEXT | NULL | | `groupKey(genre)`, grouping key of the Genres list (SQLite `lower()` is ASCII-only, so the key is stored). |
| `album_artist_key`, `album_title_key` | TEXT | NULL | | Album grouping keys, computed by the writer with `albumKeyFor` and written together with `album` (the snapshot upsert rejects a row that sets one without the others). An empty album is stored as NULL in both. |
| `language_detected` | INTEGER | NOT NULL | `0` | `CHECK (language_detected IN (0,1))`. 1 = `language` was detected from the text, not read from a tag. |
| `cover_key` | TEXT | NULL | | |
| `cover_url` | TEXT | NULL | | |
| `track_no`, `track_total`, `disc_no`, `disc_total`, `year` | INTEGER | NULL | | |
| `duration_ms`, `bitrate`, `sample_rate`, `bit_depth`, `channels` | INTEGER | NULL | | |
| `codec` | TEXT | NULL | | Format the decoder reported (`FLAC`, `MP3`), written by the scanner. NULL = derive the format from the extension of `rel_path`. |

#### tracks: scan state (written by the scanner passes)

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `tags_version` | INTEGER | NOT NULL | `0` | Tag pass that produced the snapshot. |
| `keys_version` | INTEGER | NOT NULL | `0` | Version of the key, sort and search derivation. |
| `cover_scan_version` | INTEGER | NOT NULL | `0` | Cover pass version. |
| `lyrics_version` | INTEGER | NOT NULL | `0` | Reserved for the lyrics module; 0 = no lyrics tokens in `lyrics_search`. |
| `scan_error` | TEXT | NULL | | Error kind of the last failed pass (a native error kind name); NULL = ok. |

The snapshot upsert rewrites the scan columns its companion carries, like snapshot columns.

#### tracks: user columns (last write wins per field)

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `rating` | INTEGER | NULL | | `CHECK (rating BETWEEN 0 AND 100)`. |
| `rating_updated_at` | INTEGER | NULL | | |
| `lyrics_offset_ms` | INTEGER | NOT NULL | `0` | Lyrics shift for this track. |
| `lyrics_offset_updated_at` | INTEGER | NULL | | |

User columns survive every snapshot upsert.

#### tracks: lifecycle

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `status` | TEXT | NOT NULL | `'present'` | `CHECK (status IN ('present','missing','hidden','remote'))`. See [Track status](#track-status). |
| `missing_since` | INTEGER | NULL | | Set when a row becomes `missing`. Table `CHECK` `tracks_missing_since`: `(status <> 'missing' OR missing_since IS NOT NULL)`, so the GC can always age a `missing` row. |
| `added_at` | INTEGER | NOT NULL | | |
| `updated_at` | INTEGER | NOT NULL | | |

#### tracks: indexes

| Name | Columns | Notes |
|---|---|---|
| `tracks_present_title` | `(title_sort, id) WHERE status = 'present'` | Library list. |
| `tracks_status` | `(status, source_id)` | Also serves the GC per status. |
| `tracks_added_at` | `(added_at)` | |
| `tracks_album_key` | `(album_artist_key, album_title_key)` | |
| `tracks_song_key` | `(song_key)` | |
| `tracks_rel_path` | `(source_id, rel_path)` | Folder tree. |
| `tracks_language` | `(language)` | |
| `tracks_tags_version` | `(tags_version) WHERE status = 'present'` | Scanner: rows with an old tag pass. |
| `tracks_keys_version` | `(keys_version) WHERE status = 'present'` | Scanner: rows with old keys. |
| `tracks_cover_version` | `(cover_scan_version) WHERE status = 'present'` | Scanner: rows with an old cover pass. |
| `tracks_genre_key` | `(genre_key) WHERE status = 'present'` | Genres list. |

The UNIQUE `(source_id, locator)` also creates an implicit index.

`lyrics_version` gets its index with the lyrics module.

#### track_search (FTS5)

- `CREATE VIRTUAL TABLE track_search USING fts5(...)` (needs `modules: [fts5]` in `build.yaml`): external content on `tracks` (`content='tracks'`, `content_rowid='id'`).
- Indexed columns: `title_search`, `artist_search`, `album_search`, `album_artist_search`, `genre_search`.
- `tokenize='unicode61 remove_diacritics 0'` (accents are kept), `prefix='1 2 3'`.
- Triggers:
  - `tracks_search_insert`: AFTER INSERT on `tracks`, adds the row to the index.
  - `tracks_search_delete`: AFTER DELETE on `tracks`, removes the row from the index.
  - `tracks_search_update`: AFTER UPDATE OF the five indexed columns, `WHEN` any of them `IS NOT` its old value. Its `WHEN` lists every indexed column, so no change to an indexed column is missed.

### track_details: Coded in schema v1 foundation, extended in wave 1

Owner: library. File: `tables/library_track_tables.dart`. Sync: derived. Owned child of `tracks`.

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `track_id` | INTEGER | PK, FK | | `tracks.id` RESTRICT. |
| `comment` | TEXT | NULL | | |
| `extra_tags` | TEXT | NULL | | JSON. |
| `lrc_locator` | TEXT | NULL | | Sidecar `.lrc` locator (path or file id). |
| `lrc_revision` | TEXT | NULL | | Revision of that sidecar file. |
| `cover_src` | TEXT | NULL | | External cover image (locator or server image id). |

No other indexes.

### track_artists: Coded in wave 1

Owner: library. File: `tables/library_track_tables.dart`. Sync: derived. Owned child of `tracks` (joins `trackOwnedChildTables`).

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `track_id` | INTEGER | NOT NULL | | FK `tracks.id` RESTRICT. |
| `artist_key` | TEXT | NOT NULL | | `groupKey(artist_name)`. |
| `artist_name` | TEXT | NOT NULL | | Name as tagged. |
| `position` | INTEGER | NOT NULL | | Order in the tag, from 0 (the "2 artists" chips). |

Primary key `(artist_key, track_id)`; index `track_artists_track` on `(track_id)`. The scanner rewrites a track's rows with `replaceTrackArtists` in the same transaction as its snapshot upsert.

### cover_colors: Coded in wave 1

Owner: library. File: `tables/library_cover_tables.dart`. Sync: cache (may be dropped at any time).

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `cover_key` | TEXT | PK | | Same value as `tracks.cover_key` or `custom_covers.cover_key`. No foreign key: a content hash shared by many tracks (and by a custom cover of the same image). Keys are referenced by `tracks.cover_key` and by `custom_covers.cover_key`: a future sweep of unreferenced colours must keep both. |
| `seed` | INTEGER | NOT NULL | | ARGB seed colour. |
| `colors` | TEXT | NOT NULL | | JSON array of ARGB ints, most dominant first. |
| `version` | INTEGER | NOT NULL | | Version of the algorithm that produced the row. |
| `updated_at` | INTEGER | NOT NULL | | |

### custom_covers: Coded in wave 1

Owner: library. File: `tables/library_cover_tables.dart`, trigger in `tables/custom_cover_triggers.drift`. Sync: per device for now. A synced version needs `uid`, `updated_at` and `deleted_at` (a hard delete for "back to automatic" cannot propagate) and must carry the image files. Songs and the Favorites playlist are not supported (Favorites shows a fixed heart tile; `CustomCoverStore` rejects its uid).

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `kind` | TEXT | NOT NULL | | `CHECK (kind IN ('playlist','album','artist'))` (`CustomCoverKind`). A fixed set, so a CHECK is fine here. |
| `item_key` | TEXT | NOT NULL | | Playlist uid, `AlbumKey.encode()` or `ArtistKey.encode()`. |
| `cover_key` | TEXT | NOT NULL | | Key of the processed cover: `<2 hex>/<32 hex>` (blake3 of the image bytes, made by the Rust import; the same form as `tracks.cover_key`). |
| `updated_at` | INTEGER | NOT NULL | | |

Primary key `(kind, item_key)`; index `custom_covers_cover_key` on `(cover_key)` (is another row using this file?).

- **No foreign key.** Albums and artists have no table (they are derived from `tracks`), so `item_key` cannot reference anything, and a derived album or artist disappearing must not cascade into the user's choice. The playlist side is a real table, but one generic table keeps a single path for the three kinds, so the rule is enforced by a trigger instead of a foreign key.
- **Playlist must exist.** Triggers `custom_covers_playlist_exists_insert` and `custom_covers_playlist_exists_update` abort a `playlist` row whose uid has no `playlists` row, so a delete that lands while an import is copying never leaves an orphan row. Failures arrive as `SqliteException`, wrapped in `DriftRemoteException` on the file database.
- **Playlist delete.** Trigger `custom_covers_playlist_delete`: AFTER DELETE on `playlists` deletes `kind = 'playlist' AND item_key = old.uid`. User deletes are hard `DELETE`s (see [Deletes, tombstones and revive](#deletes-tombstones-and-revive)), so it runs on every delete. A future tombstone (`deleted_at` set) keeps the row: a tombstone is undoable by sync, and the row goes when the tombstone is purged by a hard delete. Reads of a tombstoned playlist never show it, so a kept row is invisible.
- **Key stability.** `item_key` for albums and artists is `AlbumKey.encode()` / `ArtistKey.encode()`, a base64url of `groupKey` output. A change to `groupKey` (normalisation) must migrate `custom_covers.item_key` (and `saved_items`), or the covers are orphaned. `CustomCoverStore` accepts only keys that `AlbumKey.decode` / `ArtistKey.decode` return.
- **Albums and artists.** A row for an album or artist that no longer exists in the library is harmless and kept: the album may come back with a rescan, and the user's choice returns with it. Only the explicit "back to automatic" removes it.
- **Files.** The Rust import (`importCoverFile`, see [library-scan](./system-architecture-library-scan.md#custom-cover-import)) makes the cover like a song cover under `outDir = <dataDir>/custom_covers`: `covers/thumb/<key>.jpg` (256 px) and `covers/full/<key>.jpg` (1024 px), `<key>` = `ab/<32 hex>`. JPEG, PNG and WebP only (content sniffed); size and pixel limits are the native ones (no Dart size cap); regular local files only, `content://` URIs must be copied to a temp `File` first. Never in the cache dir (the OS may clear it) and never as a path to the source. Importing the same image again rewrites both files (repair). On Android `data/custom_covers/` is excluded from cloud backup (`backup_rules.xml`, `data_extraction_rules.xml` `cloud-backup`): images could pass the 25 MB Auto Backup quota and make the whole backup, database included, be skipped; device transfer keeps them. A restored database keeps the rows; their files are missing, `customCoverFileProvider` returns null and the automatic cover shows. Several rows may share a key (same image chosen twice). Files go when their last row goes.
- **One serial step.** `CustomCoverStore` runs the Rust import, the `cover_colors` write and the row write as one operation of its serial queue; `removeCover` and `collectUnreferencedFiles()` use the same queue, so inside one process the GC never runs between an import and its row. Nothing locks the data folder to one app instance, so a second process could be between the two: `collectUnreferencedFiles()` therefore keeps files younger than one hour. It walks `covers/{thumb,full}/<shard>/` and deletes `<key>.jpg` files no row references and `.kanaru-tmp-*` files of the native writer, both only when older than one hour; other files are left alone. `removeCover` and a replaced key delete their files at once when no row uses them. The Rust import is limited to 60 s (`FileSystemException`): the native thread stays busy until a stalled read returns, and files of a late success are removed after it (or by the GC). The scan controller waits at most 30 s for the GC call, so a stuck custom cover queue never holds the scan loop. The library schedules the GC with the track GC (on startup, debounced; not at every change). `fileFor` returns null for a missing or empty file.
- **Import failures.** A permanent native failure (`corrupt`, `unsupported`, `tooLarge`, `notFound`) is a `FormatException`; a native `panic` is also a `FormatException`; a transient one (`io`, failing to write under the data folder), `permissionDenied` and the 60 s import timeout are a `FileSystemException`. Anything else thrown means the native library is unavailable. The previous cover stays on every failure.
- **Colours.** The import returns the seed and palette (none for a near-gray image); the store writes them into `cover_colors` under the cover key, so an album page tints from a custom cover like from a song cover: `customCoverKeyProvider(item)` gives the key, `coverColorsProvider(key)` the colours. `cover_colors` is a cache: a dropped row is rebuilt for song covers by the scanner but not for a custom key, which then shows no tint until the cover is picked again (follow-up).
- **Display precedence.** Custom cover, else the current source (album: embedded cover of its tracks; artist: what the app uses today; playlist: automatic 2x2 / first cover), else the placeholder. The provider `customCoverFileProvider((kind: CustomCoverKind.album, itemKey: ...))` returns the `full` file or null; `customCoverThumbProvider` the `thumb` for lists and grids. Show it through `KCover` (it decodes at display size), not a plain `FileImage`. `CustomCoverKind` is an enum in `library/domain/`; the database keeps its string set `CustomCoverKinds`, and a test keeps the two equal.

### queue_entries: Coded in wave 1

Owner: playback. File: `tables/playback_tables.dart`. Sync: per device, not synced. The current entry, position, shuffle and repeat live in settings, not here.

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | INTEGER | PK | autoincrement | Entry identity; a track may repeat. |
| `track_id` | INTEGER | NOT NULL | | FK `tracks.id` RESTRICT, so a queued track is never collected. |
| `sort_key` | TEXT | NOT NULL | | Fractional key (`generateKeyBetween`): the user's order. |
| `shuffle_key` | TEXT | NULL | | Order while shuffle is on; NULL when it is off. |
| `added_at` | INTEGER | NOT NULL | | |

Indexes: `queue_entries_track` on `(track_id)`, `queue_entries_order` on `(sort_key, id)`, `queue_entries_shuffle` on `(shuffle_key, id) WHERE shuffle_key IS NOT NULL`.

### play: Coded in schema v1 foundation

Owner: playback. File: `tables/playback_tables.dart`, with `tables/playback_stats.drift` for `play_stats_ctl` and the stats triggers. Sync: `play_log` synced; `play_stats` derived per device; `play_stats_ctl` per device.

#### play_log

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | INTEGER | PK | autoincrement | |
| `uid` | TEXT | NOT NULL | | UNIQUE. ULID. |
| `track_id` | INTEGER | NOT NULL | | FK `tracks.id` RESTRICT. |
| `played_at` | INTEGER | NOT NULL | | |
| `listened_ms` | INTEGER | NULL | | |
| `device_id` | TEXT | NOT NULL | | Device that played. See [Rules](#types-and-constraints). |
| `context_kind` | TEXT | NULL | | Where playback started (open text, no CHECK). |
| `context_ref` | TEXT | NULL | | Context identifier (playlist uid, album key). |
| `skipped` | INTEGER | NOT NULL | `0` | Boolean. 1 = skipped early. |
| `updated_at` | INTEGER | NOT NULL | | |
| `deleted_at` | INTEGER | NULL | | Tombstone column for sync. Clearing history uses hard `DELETE`. |

Indexes:

| Name | Columns | Notes |
|---|---|---|
| `play_log_track_played` | `(track_id, deleted_at, played_at, skipped)` | |
| `play_log_played_at` | `(played_at, track_id, skipped, deleted_at) WHERE deleted_at IS NULL` | Recent history. |

#### play_stats (derived per device)

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `track_id` | INTEGER | PK, FK | | `tracks.id` RESTRICT. |
| `play_count` | INTEGER | NOT NULL | | Live plays with `skipped = 0`. |
| `skip_count` | INTEGER | NOT NULL | `0` | Live plays with `skipped = 1`. |
| `first_played_at` | INTEGER | NULL | | Earliest non-skipped play. |
| `last_played_at` | INTEGER | NULL | | Latest non-skipped play. NULL if the track was only skipped. |

Index `play_stats_last`: `(last_played_at) WHERE last_played_at IS NOT NULL`. A "played" query filters `last_played_at IS NOT NULL`.

#### play_stats_ctl (private, in the `.drift` file)

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | INTEGER | PK | | `CHECK (id = 1)`. One row. |
| `bulk` | INTEGER | NOT NULL | `0` | `CHECK (bulk IN (0, 1))`. 1 while a bulk recompute runs. |

The row is seeded by `@create`. The table type is not exported through the barrels. drift generates an internal `playStatsCtl` getter on `AppDatabase`; nothing writes the table outside `play_stats_bulk.dart` and the open-time reset. `beforeOpen` resets a stale `bulk = 1` to 0.

#### play stats triggers

- `play_log_stats_insert`, AFTER INSERT, `WHEN bulk = 0`: adds the play to `play_stats`.
- `play_log_stats_update`, AFTER UPDATE OF `track_id, played_at, skipped, deleted_at`, `WHEN bulk = 0`: removes the old values and adds the new ones.
- `play_log_stats_delete`, AFTER DELETE, `WHEN bulk = 0`: removes the play.
- `first_played_at` and `last_played_at` are looked up again only when the removed play was the first or the last one.
- `play_count` counts live plays with `skipped = 0`. A track with only skips has a row with `play_count` 0 and NULL first/last.
- Bulk changes go through `runPlayStatsBulk(db, write)`. It is re-entrant. While `bulk = 1`, TEMP triggers record the old and new `track_id` of every touched row in a TEMP table. The outer call recomputes those tracks with `GROUP BY` (`playStatsAggregateSql` is the one definition of correct stats), clears the TEMP table, sets `bulk = 0`, all in one transaction; an exception rolls everything back. A nested call only runs its write. TEMP objects are per connection and created by each outer call (`IF NOT EXISTS`); they are not in `sqlite_master`, so the schema guard does not see them. The guard also requires the `play_stats_ctl` row 1.

### collections: Coded in schema v1 foundation

Owner: library. File: `tables/library_collection_tables.dart`. Sync: synced (`playlists`, `playlist_entries`, `saved_items`).

#### playlists

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | INTEGER | PK | autoincrement | |
| `uid` | TEXT | NOT NULL | | UNIQUE. `favorites` for Favorites, ULID otherwise. |
| `name` | TEXT | NOT NULL | | |
| `name_key` | TEXT | NULL | | Mood playlists: lower case, collapsed spaces, NFC, accents kept. |
| `kind` | TEXT | NULL | | `PlaylistKind`: `favorites`, `mood`. NULL = normal or imported. No CHECK. |
| `description` | TEXT | NOT NULL | `''` | |
| `origin_source_id` | INTEGER | NULL | | FK `sources.id` RESTRICT. Set for imported playlists. |
| `origin_locator` | TEXT | NULL | | Imported playlist locator. |
| `origin_revision` | TEXT | NULL | | Revision at the last import. |
| `created_at` | INTEGER | NOT NULL | | |
| `updated_at` | INTEGER | NOT NULL | | |
| `deleted_at` | INTEGER | NULL | | Tombstone. |

Partial unique indexes (live rows only):

| Name | Columns | Rule |
|---|---|---|
| `playlists_favorites_unique` | `(kind) WHERE kind = 'favorites' AND deleted_at IS NULL` | One Favorites playlist. |
| `playlists_mood_name_unique` | `(name_key) WHERE kind = 'mood' AND deleted_at IS NULL` | One mood per name. |
| `playlists_origin_unique` | `(origin_source_id, origin_locator) WHERE origin_source_id IS NOT NULL AND deleted_at IS NULL` | Importing the same file twice does not duplicate it. |

Plain index `playlists_origin_source` on `(origin_source_id)` serves the foreign key check (a partial index cannot). Mood rows must always set `name_key`: NULLs are distinct, so a NULL bypasses `playlists_mood_name_unique`.

Renaming a mood changes `name` and `name_key` only. Its uid stays. Constants: `PlaylistKind` (`favorites`, `mood`), `SavedItemKind` (`album`, `artist`, `playlist_remote`). Uids: `favoritesPlaylistUid`, `favoriteEntryUid(playlistUid, trackUid)`, `savedItemUid(sourceUid, kind, remoteId)` in `row_uids.dart`.

#### playlist_entries

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | INTEGER | PK | autoincrement | |
| `uid` | TEXT | NOT NULL | | UNIQUE. Favorites: `fav:` + hash. Others: ULID, so one track can repeat. |
| `playlist_id` | INTEGER | NOT NULL | | FK `playlists.id` CASCADE. |
| `track_id` | INTEGER | NOT NULL | | FK `tracks.id` RESTRICT. |
| `sort_key` | TEXT | NOT NULL | | Fractional key in base62, compared with SQLite's default binary text order. Read with `ORDER BY sort_key, uid`. |
| `added_at` | INTEGER | NOT NULL | | |
| `updated_at` | INTEGER | NOT NULL | | |
| `deleted_at` | INTEGER | NULL | | Tombstone. |

Indexes: `playlist_entries_order` on `(playlist_id, deleted_at, sort_key, uid, track_id)`; `playlist_entries_track` on `(track_id, deleted_at, playlist_id)`.

#### saved_items

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | INTEGER | PK | autoincrement | |
| `uid` | TEXT | NOT NULL | | UNIQUE. `saved:` + hash(source uid, kind, remote id). |
| `kind` | TEXT | NOT NULL | | `SavedItemKind`: `album`, `artist`, `playlist_remote`. No CHECK. |
| `source_id` | INTEGER | NOT NULL | | FK `sources.id` RESTRICT. |
| `remote_id` | TEXT | NOT NULL | | Identifier on the source. |
| `snapshot_json` | TEXT | NOT NULL | | Last seen remote data. |
| `saved_at` | INTEGER | NOT NULL | | |
| `updated_at` | INTEGER | NOT NULL | | |
| `deleted_at` | INTEGER | NULL | | Tombstone. |

Index `saved_items_lookup` on `(source_id, kind, remote_id)`, not unique.

### extension: Coded before schema v1 foundation

Owner: public database. File: `tables/extension_tables.dart`. Sync: per device (schema bookkeeping).

| Table | Columns | Notes |
|---|---|---|
| `extension_schema` | `extension_id` TEXT PK, `version` INTEGER NOT NULL | Each extension records its own table version here and migrates by hand. |

## Spec-only groups

Each group below is added by its owning module before the first release. The schema version stays 1. Column types and nullability are proposed here; the module's change confirms them. Where a group names only its keys, the module sets the other columns.

### library: Spec only, added by library before first release

**track_merges** (synced). Columns: `uid` TEXT NOT NULL UNIQUE (ULID); `from_track_uid` TEXT NOT NULL; `to_track_uid` TEXT NOT NULL; `at` INTEGER NOT NULL; `moved_row_ids_json` TEXT NOT NULL; `undone_at` INTEGER NULL; `updated_at` INTEGER NOT NULL; `deleted_at` INTEGER NULL. No foreign key (it holds uids). A merge repoints the child rows to the target track and sets the source row to `hidden`.

**Spec-only tracks columns** are listed under `tracks`.

### lyrics: Spec only, added by lyrics before first release

**lyrics_pins** (synced). `uid` TEXT NOT NULL UNIQUE (`pin:` + hash(track uid)). `track_id` INTEGER NOT NULL UNIQUE, FK `tracks.id` RESTRICT (one pin per track). `provider_id` (the lyrics provider's install id). Lyric texts (plain and synced), `instrumental`, `pinned_at`, `mode`.
**lyrics_rejects** (synced). Rejected lyric candidates of a track. Keys and columns set by the lyrics module. Any track reference is `RESTRICT`.

**lyrics_translations** (cache). Keyed by `content_hash`, `provider` and `target_lang`. Safe to drop. Per-track translation settings are not here: they belong to Pro.

**lyrics_search** (derived). FTS5 table, contentless (`contentless_delete = 1`), with stale triggers. Invariant: `tracks.lyrics_version = 0` means the track has no tokens in `lyrics_search`. The stale triggers set `lyrics_version` back to 0 when the audio `revision`, the sidecar `lrc_revision` or the pin changes. This depends on the scanner's `lyrics_version` column (see `tracks`).

### plugins: Spec only, added by plugins before first release

**plugins** (per device: no uid, so not synced). `install_id` TEXT PK, deterministic:
- repository install: `plugin-` + `stableHashHex(['repo', url, slug], 12)`;
- file install: `plugin-` + `stableHashHex(['file', name, author ?? ''], 12)`.

`plugin_data`, `plugin_repos`, `lyrics_source_prefs` (per device). Keys and columns set by the plugins module. A plugin source uses `install_id` as its `sources.root`.

### cache: Spec only, added by the owning module before first release

**online_lyrics** (cache). `cache_key` = `song_key` (DATA-06). Columns set by the lyrics module. Safe to drop.

### Pro: Spec only, added by kanaru-pro before first release

AI chat, per-track translation config and smart playlists. Their spec lives in `kanaru-pro`. They are versioned in `extension_schema`, and any foreign key into `tracks` is `RESTRICT`. See [Pro contract](#pro-contract).

## Helpers

Dart API of the coded groups. `lib/src/database/database.dart` is the barrel; the pure id and order helpers live in `lib/src/foundation/` and are imported from there.

| Area | Names |
|---|---|
| Constants | `TrackStatus`, `SourceKind`, `PlaylistKind` (`favorites`, `mood`), `SavedItemKind`, `favoritesPlaylistUid`, `missingGraceMs`, `hiddenGraceMs`, `remoteGraceMs`, `trackOwnedChildTables`, and the column sets `trackIdentityColumns`, `trackSnapshotColumns`, `trackScanColumns`, `trackUserColumns`, `trackLifecycleColumns` |
| connection | `configureConnection(CommonDatabase)`, `AppDatabase.file(File)`, `AppDatabase.openedConnection()`, `AppDatabase.sharedConnection` |
| uids | `sourceUidForRemote(kind, account, root)` (rejects userinfo and query), `trackUid(sourceUid, locator)`, `excludedFolderUid(sourceUid, folderKey)`, `favoriteEntryUid(playlistUid, trackUid)`, `savedItemUid(sourceUid, kind, remoteId)` |
| ids and order (pure, `lib/src/foundation/`) | `stableHashHex(parts, length)`, `stableUid(prefix, parts)`, `newUlid({nowMs, random})`, `isUlid`, `generateKeyBetween(a, b)`, `generateNKeysBetween(a, b, n)` |
| writes | `upsertTrackSnapshot(db, tracks, companion)`, `insertOrRevive(db, table, row, now:, reviveColumns:)` |
| folders | `folderLocatorRange(folderKey)`, `applyFolderExclusion(db, {sourceId, folderKey, displayPath, now})`, `removeFolderExclusion(db, {sourceId, folderKey, now})`, `excludedFolderKeys(db, sourceId)` |
| scanner writes | `markTracksMissing(db, trackIds, now)`, `replaceTrackArtists(db, trackId, artists)`, `upsertTrackDetails(db, companion)`, `upsertCoverColors(db, {...})`, `coverColorsFor(db, coverKey)` (decoded `({seed, colors, version})?`, null for a missing or malformed row; an upsert with an older `version` is ignored) |
| custom covers | `setCustomCover(db, kind, itemKey, coverKey)` (returns the replaced key), `clearCustomCover(db, kind, itemKey)` (returns the removed key), `customCoverKey(db, kind, itemKey)`, `watchCustomCoverKey(appDb, kind, itemKey)`, `referencedCustomCoverKeys(db)`, `isCustomCoverKeyReferenced(db, coverKey)`; `CustomCoverKind` |
| queue | `readQueue(db, {shuffled})`, `replaceQueue(db, trackIds, now)` |
| source lifecycle | `removeSource(db, sourceId, now)`, `setMountEnabled(db, sourceId, enabled, now)`, `reviveSource(db, sourceId, now, {name, account, configJson, credentialRef})`, `unhideTracks(db, sourceId, now, {locatorFrom, locatorTo})` |
| play stats | `runPlayStatsBulk(db, write)` |
| reads | `visibleTrackWhere(alias)`, `isVisibleTrack(tracks)`, `ftsPrefixQuery(input)` (null for empty input) |
| maintenance | `collectOrphanTracks(db, now:)`; `verifyDevSchema`, `dumpSchema` (`schema_guard.dart`, not exported) |

Database helpers live in `lib/src/database/`. `database.dart` exports the tables (`Sources`, `SourceMounts`, `ExcludedFolders`, `Tracks`, `TrackDetails`, `TrackArtists`, `CoverColors`, `CustomCovers`, `PlayLog`, `PlayStats`, `QueueEntries`, `Playlists`, `PlaylistEntries`, `SavedItems`, `ExtensionSchema`) and the helpers above. It does not export the `play_stats_ctl` type (the generated `playStatsCtl` getter on `AppDatabase` is internal) and exports only `runPlayStatsBulk` from the bulk file.

Contract for every database helper:

- It takes a `DatabaseConnectionUser`, plus the table instance of that same database where a typed statement needs one. So it can run inside a transaction of any database that shares the connection.
- It notifies streams by table name.

Folder, scanner and queue helpers:

- **Folder range.** `folderLocatorRange('a')` is `('a/', 'a0')`: `locator >= 'a/' AND locator < 'a0'` holds exactly the files under `a`. `'/'` is 0x2F and `'0'` is 0x30, so `a b/x`, `a.b/x`, `a-b/x` and `a0` are outside. The root `''` has no bound (null). Path-based sources only; a key with a leading or trailing slash throws `ArgumentError`.
- **Exclusion.** `applyFolderExclusion` inserts or revives the `excluded_folders` row (uid `excludedFolderUid`, built from the source uid read in the same transaction) and hides the `present` and `missing` rows in the range, in one transaction; it throws `StateError` for a removed source. `removeFolderExclusion` tombstones it and turns `hidden` rows of the range into `missing` (`missing_since = now`) except rows another live exclusion of the source still covers, and none at all while the source is removed or its mount is disabled; it resets the mount's scan cursor. Both notify `tracks`, `excluded_folders` and `source_mounts`. `excludedFolderKeys` lists the live keys.
- **`markTracksMissing`** changes only `present` rows (`hidden`, `remote` and already `missing` rows keep their state), 500 ids per statement, one transaction; the caller decides reachability.
- **`replaceTrackArtists`** keeps the first of repeated keys and numbers `position` from 0 without gaps. **`upsertTrackDetails`** is `ON CONFLICT (track_id) DO UPDATE` over the scanner columns present in the companion.
- **`replaceQueue`** deletes the queue and inserts the ids with `generateNKeysBetween` keys, 500 rows per insert, in one transaction. **`readQueue(shuffled: true)`** orders by `shuffle_key IS NULL, shuffle_key, sort_key, id` and never drops a row. Rule: while shuffle is on, every entry has a `shuffle_key`; rows without one sort after, in user order. `replaceQueue(..., shuffleOrder:)` takes a permutation of the indexes of `trackIds` and writes the shuffle keys in that order (invalid permutation: `ArgumentError`, nothing written). Richer queue edits are written by playback against the table.
- **Empty album.** The scanner stores an empty album as NULL in `album_title_key` and `album_artist_key`.
