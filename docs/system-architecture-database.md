# Database: schema v1

Table-level spec of the app database (`lib/src/database/`). It lists every table group: the groups coded in the schema v1 foundation, and the groups that their module adds before the first release. The code and the reviews check against this file.

> **Status: target.** The coded groups land with the schema v1 foundation PR. Until it merges, `lib/src/database/` holds only `extension_schema`. A module that adds a spec-only group updates its section of this file in the same change.

Overview of the database and its place in the app: [ARCHITECTURE.md](../ARCHITECTURE.md#database).

## Contents

- [Requirement map](#requirement-map)
- [Rules](#rules)
- [Foreign keys](#foreign-keys)
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
| DATA-10 Rating and mood playlists | `tracks.rating`, `playlists.name_key` |
| DATA-11 Plugin install ids | `plugins.install_id` (spec only) |

## Rules

### Types and constraints

- Times are epoch milliseconds, `INTEGER`.
- Booleans are `INTEGER NOT NULL CHECK (x IN (0, 1))`.
- `CHECK` is used only on fixed sets: track status, rating range, booleans. Open-ended kinds (`sources.kind`, `playlists.kind`, `saved_items.kind`) are validated by Dart constants, so adding a kind needs no table rebuild.
- `foreign_keys = ON` and `recursive_triggers = ON` on every connection, set by `configureConnection` in `NativeDatabase(setup:)` and again in `beforeOpen`.
- The device id is stored in no table. It comes from a file outside the database (the helper arrives with playback). `play_log.device_id` records it per row.

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
- Owned one-to-one children of a track (`track_details`, `play_stats`, and `track_artists` once added) are `RESTRICT` too. The track GC deletes them before the track.
- Every `*track_id` column has a foreign key into `tracks` and an index whose first column is that column. A single `INTEGER PRIMARY KEY` counts as that index.
- Every foreign key column is the first column of an index, or the primary key.

The full list is in [Foreign keys](#foreign-keys).

### Track status

| Status | Meaning | Set by |
|---|---|---|
| `present` | In the library. | Scanner only. |
| `missing` | File of a scanned source that was not seen in a complete scan of a reachable root. `missing_since` is set. | Scanner, on `present` rows only. |
| `hidden` | The user took it out of the library: source removed, mount disabled, or folder excluded. One meaning only. | Lifecycle helpers. |
| `remote` | Row of a reference-only source (`sources.kind = 'plugin'`). Never in the library. | `upsertTrackSnapshot`. |

- A rescan upsert keeps `hidden`.
- The scanner and the lifecycle helpers never touch `remote` rows.
- Hide (`removeSource`, `setMountEnabled(false)`): `present` and `missing` rows become `hidden`, and `scan_cursor` and `last_scan_at` reset, all in one transaction. Excluding a folder hides its rows the same way (applied by the scanner).
- Unhide (`reviveSource`, `setMountEnabled(true)`, `unhideTracks`): `hidden` rows become `missing` with `missing_since = now`, and the cursor resets. A full scan then decides: files that are still there return to `present`, and deleted files never come back as ghosts.
- Helpers live in `track_lifecycle.dart`: `removeSource(db, sourceId, now)`, `setMountEnabled(db, sourceId, enabled, now)`, `reviveSource(db, sourceId, now, {name, account, configJson, credentialRef})`, `unhideTracks(db, sourceId, now, {locatorFrom, locatorTo})`. Each runs in one transaction and notifies `tracks`, `sources` and `source_mounts` by table name. `locatorFrom` and `locatorTo` (both or neither) mean `locator >= from AND locator < to`; the scanner computes a folder's range bounds. `setMountEnabled(true)` and `unhideTracks` throw `StateError` for a removed source: only `reviveSource` brings one back.
- Reviving a source forces a full scan.
- An unreachable root leaves its rows untouched.

### Track snapshot upsert

- `upsertTrackSnapshot` derives the status from the source kind. Callers never pass a status. `plugin` gives `remote`, on insert and on conflict.
- Otherwise it inserts `present`. On conflict on `(source_id, locator)`, the status is `hidden` if the row is `hidden`, else `present`.
- On conflict, `missing_since` is set to `NULL` unless the row is `hidden`.
- It writes snapshot columns only. `uid`, `added_at` and the user columns are never touched.
- One statement (`INSERT ... ON CONFLICT (source_id, locator) DO UPDATE ... RETURNING id`); it returns `tracks.id` and notifies `tracks` and `track_search`. Search streams declare `readsFrom` both `tracks` and `track_search`. The source kind is read in the same statement.
- The companion carries `source_id`, `locator`, `uid`, `title`, `rel_path`, `added_at`, `updated_at` (the insert needs them) and any snapshot fields. Any column outside identity (except `id`), snapshot, `added_at` and `updated_at` (`status`, `missing_since`, user columns) throws `ArgumentError`. On conflict only the snapshot fields present in the companion are rewritten: an absent field keeps the stored value, an explicit null writes null.
- Column classification (SQL names, in `track_snapshot.dart`, each `tracks` column in exactly one set; a test enforces it): `trackIdentityColumns` (`id`, `uid`, `source_id`, `locator`), `trackSnapshotColumns` (rewritten on conflict), `trackUserColumns` (never touched), `trackLifecycleColumns` (`status`, `missing_since`, `added_at`, `updated_at`; derived or set once).

### Online rows

- A `remote` row is upserted on every reference (playlist, history, queue) and on every successful resolve for playback. The upsert runs in the same transaction as the referencing insert.
- Helpers accept a `DatabaseConnectionUser`, so any database object can call them inside its own transaction.
- Last write wins on snapshot columns. User columns are untouched.

### Garbage collection

`collectOrphanTracks(now)` deletes unreferenced track rows. Rules, in order:

1. Refuse to run when `PRAGMA foreign_keys` is 0.
2. Find every foreign key into `tracks` at run time (`sqlite_master` joined with `pragma_foreign_key_list`). Pro tables are included.
3. Throw if any of them is not `RESTRICT`.
4. Ignore the owned-child tables `trackOwnedChildTables` = `{track_details, play_stats}` (plus `track_artists` once added) when deciding whether a track is referenced. Delete their rows before the track rows, in the same transaction.
5. Delete a track only if no other foreign key row points at it (tombstoned rows count), `rating IS NULL AND lyrics_offset_ms = 0`, and one of:

   | Status | Condition |
   |---|---|
   | `missing` | `missing_since <= now - missingGraceMs` (7 days). |
   | `hidden` | `updated_at <= now - hiddenGraceMs` (7 days: undo window for remove and exclude), and not in a live source whose mount is disabled. A disabled NAS mount keeps its rows. |
   | `remote` | `updated_at <= now - remoteGraceMs` (24 h). Keeps the now-playing and queued online track. |

6. `present` rows are never deleted.
7. The helper notifies streams for `tracks`, `track_details` and `play_stats`.

When the GC runs (startup, after a scan) is set by the library module. This file defines only the helper.

### Library reads and search

- Library views read `status = 'present'` only. The SQL form is `visibleTrackWhere(alias)`, the typed form is `isVisibleTrack(tracks)`. Both must agree (a test checks it).
- History, playlists and Pro views show any referenced row through its snapshot. Whether it can be played comes from the playback resolver, not from `status`.
- Search: the MATCH input goes only through `ftsPrefixQuery(input)`. It splits on whitespace, wraps each token in double quotes (inner `"` doubled) and appends `*`. Example: `ab "cd` becomes `"ab"* """cd"*`. Empty input means no MATCH clause.

### Locator and mount roots

- `tracks.locator` is UTF-8 text as the platform listing API returns it: the path relative to the mount root, `/` as separator, no leading or trailing `/`.
- Locators are never Unicode-normalized. NFC and NFD names are different locators.
- A name that does not decode as UTF-8 is skipped and reported as a scan error.
- CUE track: `'<cue path>#NN'` (two-digit track number).
- Id-based remotes (Google Drive, OneDrive, Subsonic): the locator is the provider file id. `rel_path` holds the display path. The scanner applies folder exclusions while listing.
- Path-based folder filter (scanner module, spec only): `locator >= key || '/' AND locator < key || '0'`. Folder keys come from the same listing API.
- Mount roots are canonicalized (real path, no trailing `/`) before they are saved. One mount per chosen folder. An SD card volume root is just a path.

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

## Foreign keys

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
| `track_artists.track_id` | `tracks.id` | RESTRICT | library (spec only) |
| `queue_entries.track_id` | `tracks.id` | RESTRICT | playback (spec only) |
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

### tracks: Coded in schema v1 foundation

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
| `title_sort` | TEXT | NOT NULL | `''` | Sort form of the title. |
| `artist`, `album`, `album_artist`, `genre`, `composer`, `language` | TEXT | NULL | | |
| `album_display_artist` | TEXT | NULL | | |
| `artist_sort`, `album_sort` | TEXT | NULL | | |
| `artist_search`, `album_search`, `album_artist_search`, `genre_search` | TEXT | NULL | | Search forms, indexed by `track_search`. |
| `album_artist_key`, `album_title_key` | TEXT | NULL | | Album grouping keys. |
| `cover_key` | TEXT | NULL | | |
| `cover_url` | TEXT | NULL | | |
| `track_no`, `track_total`, `disc_no`, `disc_total`, `year` | INTEGER | NULL | | |
| `duration_ms`, `bitrate`, `sample_rate`, `bit_depth`, `channels` | INTEGER | NULL | | |

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
| `missing_since` | INTEGER | NULL | | Set when a row becomes `missing`. |
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

The UNIQUE `(source_id, locator)` also creates an implicit index.

**Spec only, added by the scanner (library) before first release:** the pass-version columns `tags_version`, `keys_version`, `lyrics_version`, `cover_scan_version` (`INTEGER NOT NULL DEFAULT 0`), and `scan_error` (TEXT NULL), with the indexes the scanner needs on them.

#### track_search (FTS5)

- `CREATE VIRTUAL TABLE track_search USING fts5(...)` (needs `modules: [fts5]` in `build.yaml`): external content on `tracks` (`content='tracks'`, `content_rowid='id'`).
- Indexed columns: `title_sort`, `artist_search`, `album_search`, `album_artist_search`, `genre_search`.
- `tokenize='unicode61 remove_diacritics 0'` (accents are kept), `prefix='1 2 3'`.
- Triggers:
  - `tracks_search_insert`: AFTER INSERT on `tracks`, adds the row to the index.
  - `tracks_search_delete`: AFTER DELETE on `tracks`, removes the row from the index.
  - `tracks_search_update`: AFTER UPDATE OF the five indexed columns, `WHEN` any of them `IS NOT` its old value. Its `WHEN` lists every indexed column, so no change to an indexed column is missed.

### track_details: Coded in schema v1 foundation

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
| `sort_key` | TEXT | NOT NULL | | Fractional key in base62, compared in binary order (`COLLATE BINARY`). Read with `ORDER BY sort_key, uid`. |
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

**track_artists** (owned child of `tracks`, derived). Columns: `track_id` INTEGER NOT NULL, FK `tracks.id` RESTRICT; `artist_key` TEXT NOT NULL; `artist_name` TEXT NOT NULL. Primary key `(artist_key, track_id)`; index `track_artists_track` on `(track_id)`. When added, `track_artists` joins `trackOwnedChildTables`.

**track_merges** (synced). Columns: `uid` TEXT NOT NULL UNIQUE (ULID); `from_track_uid` TEXT NOT NULL; `to_track_uid` TEXT NOT NULL; `at` INTEGER NOT NULL; `moved_row_ids_json` TEXT NOT NULL; `undone_at` INTEGER NULL; `updated_at` INTEGER NOT NULL; `deleted_at` INTEGER NULL. No foreign key (it holds uids). A merge repoints the child rows to the target track and sets the source row to `hidden`.

**Spec-only tracks columns** are listed under `tracks`.

### playback: Spec only, added by playback before first release

**queue_entries** (per device, not synced). Columns: `id` INTEGER PK autoincrement; `track_id` INTEGER NOT NULL, FK `tracks.id` RESTRICT; `sort_key` TEXT NOT NULL (fractional, as in `playlist_entries`); `added_at` INTEGER NOT NULL. Index `queue_entries_track` on `(track_id)`.

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

**cover_colors** (cache). Cover colour data keyed by the cover key. Columns set by the library module.

**online_lyrics** (cache). `cache_key` = `song_key` (DATA-06). Columns set by the lyrics module. Safe to drop.

### Pro: Spec only, added by kanaru-pro before first release

AI chat, per-track translation config and smart playlists. Their spec lives in `kanaru-pro`. They are versioned in `extension_schema`, and any foreign key into `tracks` is `RESTRICT`. See [Pro contract](#pro-contract).

## Helpers

Target Dart API. Later phases refine this list here. Names are final only when the code lands.

| Area | Names |
|---|---|
| Constants | `TrackStatus`, `SourceKind`, `PlaylistKind` (`favorites`, `mood`), `SavedItemKind`, `favoritesPlaylistUid`, `missingGraceMs`, `hiddenGraceMs`, `remoteGraceMs`, `trackOwnedChildTables` |
| uids | `sourceUidForRemote` (rejects userinfo and query), `trackUid`, `excludedFolderUid`, `favoriteEntryUid`, `savedItemUid` |
| ids and order (pure, `lib/src/foundation/`) | `stableHashHex`, `stableUid`, `newUlid`, `isUlid`, `generateKeyBetween`, `generateNKeysBetween` |
| writes | `upsertTrackSnapshot`, `insertOrRevive` |
| source lifecycle | `removeSource`, `setMountEnabled`, `reviveSource`, `unhideTracks` |
| play stats | `runPlayStatsBulk` |
| reads | `visibleTrackWhere`, `isVisibleTrack`, `ftsPrefixQuery` |
| maintenance | `collectOrphanTracks` |

Database helpers live in `lib/src/database/`. `database.dart` exports the tables (`Sources`, `SourceMounts`, `ExcludedFolders`, `Tracks`, `TrackDetails`, `PlayLog`, `PlayStats`, `Playlists`, `PlaylistEntries`, `SavedItems`, `ExtensionSchema`) and the helpers above. It does not export the `play_stats_ctl` type (the generated `playStatsCtl` getter on `AppDatabase` is internal) and exports only `runPlayStatsBulk` from the bulk file.

Contract for every database helper:

- It takes a `DatabaseConnectionUser`, plus the table instance of that same database where a typed statement needs one. So it can run inside a transaction of any database that shares the connection.
- It notifies streams by table name.
