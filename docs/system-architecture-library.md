# Library

> **Contract stub.** Owner: lane C (library UI). The foundation declares the
> contracts below; they are frozen. Lane C replaces this text with its own
> design (lists, detail pages, menus, selection, sub-tabs) when it lands. The
> library scanner that fills the data is described in
> [system-architecture-library-scan.md](./system-architecture-library-scan.md).

## Contents

- Keys and the stored-column rule: this file.
- Track identity and info: this file.
- Locations, favorites, tabs, folders, exclusions: this file.
- Scan status as consumed: this file.
- Lists, detail pages and menus: lane C adds the sections.

## Keys

`lib/src/media/domain/library_keys.dart`. Pure functions; the scanner writes
them, the library reads the stored columns.

| Function | Result |
|---|---|
| `groupKey(String name)` | Control characters become spaces; NFC; lower case; trimmed; inner whitespace collapsed. Accents kept: "Hà" and "Ha" are different artists. |
| `searchForm(String text)` | `groupKey` with diacritics folded (`foldDiacritics`). Used for FTS columns and the in-list filter. |
| `sortForm(String text)` | Same as `searchForm`. A leading "the" or "a" is not removed. |
| `albumArtistKeyFor({String? albumArtist, required List<String> artists})` | Raw (apply `groupKey` yourself): album artist, else first non-empty track artist, else `''`. |
| `songKey({required String title, required List<String> artists})` | Stable 16-hex hash of `groupKey(title)` and `groupKey(first artist)`. |
| `albumKeyFor({String? album, String? albumArtist, required List<String> artists})` | `AlbumKey?`; null when the album is empty. Both parts go through `groupKey`. |
| `languageKey(String? raw)` | ISO 639-3 key of a language code: trims, lower-cases, maps ISO 639-1 and ISO 639-2/B codes of common languages (`vi` to `vie`, `chi` to `zho`, `fre` to `fra`), keeps any other three-letter `[a-z]` code. `und`, `zxx`, `mul`, empty and anything else give null (unknown). |
| `encodeKey(String)` / `decodeKey(String)` | base64url of UTF-8, no padding. `decodeKey` returns null for anything that is not the canonical encoding. |

- `AlbumKey(artistKey, titleKey)`: `encode()` and `static decode(String)`.
  `ArtistKey(key)`: `encode()` and `static decode(String)`. Both decoders return
  null for a malformed or non-canonical id.
- `libraryKeysVersion` (1): bump it when any function changes. The scanner
  recomputes the keys of rows whose `tracks.keys_version` is lower.

### Stored-column rule

Each derived column has one writer. The scanner calls the function, and the
database helper checks the pairs. Readers use the stored column and never
recompute it, so a writer and a reader cannot disagree.

| Stored column | Written from |
|---|---|
| `title_sort` | `sortForm(titleSortTag ?? title)` |
| `title_search` | `searchForm(title)` |
| `artist_search` | `searchForm(artists.join(' '))` |
| `album_search` | `searchForm(album)` |
| `album_artist_search` | `searchForm(albumArtist ?? first non-blank artist)` |
| `genre_search` | `searchForm(genre)` |
| `genre_key` | `groupKey(genre)` |
| `album_artist_key`, `album_title_key` | `albumKeyFor`; both NULL for an empty album |
| `song_key` | `songKey` |
| `language` | `languageKey(tag or detected)`: ISO 639-3 lower case, NULL = unknown ("Chưa rõ") |
| `language_detected` | 1 when `language` comes from detection, 0 when read from a tag |

`upsertTrackSnapshot` throws `ArgumentError` when `title` and `title_search`,
`genre` and `genre_key`, or `album` and its keys do not go together.

## Track identity and info

`lib/src/media/domain/`:

- `TrackId`: `extension type const TrackId(int)`, the value of `tracks.id`.
- `TrackAvailability`: `present`, `missing`, `hidden`, `remote`.
- `TrackInfo`: what every list, the player and the media controls show.
  Fields: `id`, `title`, `status`, `relPath`, `artist`, `album`, `albumArtist`,
  `artists` (from `track_artists`, tag order; empty means use `artist`), `year`,
  `trackNo`, `discNo`, `durationMs`, `coverKey`, `albumKey` (null without an
  album), `genre`, `language`, `languageDetected`, `format`, `sampleRate`,
  `bitrate`, `bitDepth`, `playCount`.
- `format` is the `codec` column, else `formatFromLocator(relPath)`: the
  extension in upper case. A CUE suffix (`#NN`) is stripped; a `.cue` sheet
  gives null.
- `PlayContext(kind, {ref, label})`: where playback started. `kind` is one of
  `songs`, `album`, `artist`, `genre`, `language`, `folder`, `favorites`,
  `selection`, `queue`. `ref` is the encoded key, or `'<sourceUid>:<folderKey>'`
  for a folder. `label` is captured at play time.

### Building rows

`lib/src/playback/data/track_info_rows.dart` (foundation, the only mapping):

```dart
TrackInfo trackInfoFromRow(Track row, {List<String> artists = const [], int playCount = 0});
Future<List<TrackInfo>> loadTrackInfos(AppDatabase db, List<TrackId> ids);
```

- `loadTrackInfos` queries in chunks of `trackInfoChunkSize` (500), yields
  between chunks, keeps the input order (a repeated id repeats), drops ids with
  no row, and returns every status (`missing` and `hidden` included; the caller
  decides).
- Lists build their rows from their own query with `trackInfoFromRow`. They
  never watch a per-row stream.
- `trackInfoProvider`: `StreamProvider.family<TrackInfo?, TrackId>`,
  `isAutoDispose`. For single-item screens only.
- Rule: list queries are debounced (at least 300 ms) while a scan writes, so
  each scan batch does not re-query every list.

### Cover widget

`lib/src/playback/ui/track_cover.dart`: `TrackCover({coverKey, seed, size, dimension, radius, circle})`.
`size` is `CoverSize.thumb` for tiles and `CoverSize.full` for Now Playing. The
placeholder colour comes from `seed` (album key or title). A missing file is
reported to `coverMissesProvider`. The widget does not read the file path from
the database; it builds it from `cacheDir` and the key.

## Locations

`lib/src/library/ui/library_locations.dart`: `LibraryLocations`, static only.
The library registers the matching routes. Other modules navigate through
these functions and never build the paths themselves.

| Function | Location |
|---|---|
| `root` | `/library` |
| `list(LibraryTab tab)` | `/library/<tab.name>`: `songs`, `albums`, `artists`, `genres`, `languages`, `folders` |
| `album(AlbumKey key)` | `/library/albums/<key.encode()>` |
| `artist(ArtistKey key)` | `/library/artists/<key.encode()>` |
| `genre(String genreKey)` | `/library/genres/<encodeKey(genreKey)>` |
| `language(String? languageKey)` | `/library/languages/<encodeKey>`, or `/library/languages/_unknown` for null |

## Favorites

`lib/src/library/domain/favorites.dart` (interface), `lib/src/library/data/favorites_repository.dart` (implementation), `lib/src/library/state/favorites_providers.dart`.
Favorites is the playlist with uid `favorites`. Unfavorite is a hard delete of
the entry; a tombstoned Favorites playlist is revived by the next favorite.

| Symbol | Type | Notes |
|---|---|---|
| `FavoritesController.setFavorite(List<TrackId> tracks, bool favorite)` | `Future<void>` | One transaction; idempotent; `ArgumentError` (nothing changed) for an unknown track when favoriting |
| `FavoritesController.toggle(TrackId track)` | `Future<void>` | |
| `favoriteTrackIdsProvider` | `StreamProvider<Set<TrackId>>` | One query for the whole set |
| `isFavoriteProvider(id)` | `Provider.family<bool, TrackId>`, `isAutoDispose` | Selects from the set |
| `favoritesControllerProvider` | `Provider<FavoritesController>` | |

## Library tabs

`lib/src/library/domain/library_tabs.dart`, `lib/src/library/state/library_tabs_providers.dart`.

- `LibraryTab`: `songs`, `albums`, `artists`, `genres`, `languages`, `folders`.
- `LibraryTabsConfig(order, enabled)`: `order` lists every tab once; at least one
  tab is enabled. `visible` is the enabled tabs in order. `reorder(from, to)`
  and `withEnabled(tab, on)` return a new config; the second throws `StateError`
  when it would leave no tab enabled.
- JSON: `{"order": [names], "disabled": [names]}`. A tab missing from `order` is
  appended in default order, so a later tab starts enabled.
- Setting `library.tabs`: `libraryTabsSetting`. Provider: `libraryTabsProvider`
  (`NotifierProvider<LibraryTabsNotifier, LibraryTabsConfig>`) with
  `reorder(from, to)` and `setEnabled(tab, enabled)`.

## Music folders

`lib/src/library/domain/music_folder.dart`, `lib/src/library/state/music_folders_providers.dart`.

- `MusicFolder({sourceId, sourceUid, root, volume, name})`. `root` is the absolute
  path; `volume` is the `StorageVolume` that holds it.
- `musicFoldersProvider`: `StreamProvider<List<MusicFolder>>`. Live local sources
  with an enabled mount and a root, ordered by root. Written by the scanner, read
  here.
- Volumes (`platform/domain/storage_volumes.dart`): `StorageVolumes.list()`
  refreshes the list; `volumeOf(path)` returns the volume with the longest root
  that contains the path (by path segment), else `otherVolume`.
  `StorageVolume(root, kind)`, `kind` is `StorageVolumeKind` (`internal`,
  `sdCard`, `usb`, `home`, `other`).

## Exclusions

`lib/src/library/domain/folder_exclusions.dart` (interface), `lib/src/library/data/folder_exclusion_repository.dart` (implementation), `lib/src/library/state/folder_exclusion_providers.dart`.

| Symbol | Behaviour |
|---|---|
| `FolderExclusions.exclude(MusicFolder folder, String folderKey, {required String displayPath})` | Excludes the folder and hides its tracks now. No question asked; the UI shows a toast with undo. |
| `FolderExclusions.include(MusicFolder folder, String folderKey)` | Removes the exclusion and requests a rescan. The rescan is not awaited; a failure is logged. |
| `FolderExclusions.watch(MusicFolder folder)` | `Stream<List<({String folderKey, String displayPath})>>` |
| `folderExclusionsProvider` | `Provider<FolderExclusions>` |

Storage: `excluded_folders`. `folderLocatorRange(folderKey)` (`database/folder_range.dart`)
gives the bounds `[key/, key0)`, so `Live` never matches `Live Albums`. The root
key `''` has no range and covers the whole source.

## Scan status as consumed

`lib/src/library/domain/scan_status.dart` (frozen). The scanner produces the
values (see [system-architecture-library-scan.md](./system-architecture-library-scan.md)).

| Symbol | Meaning |
|---|---|
| `ScanIdle` | No scan running |
| `ScanRunning(phase, done, total)` | `phase` is `ScanPhase.listing`, `tags` or `covers`; `total` 0 means not known yet |
| `ScanFinished(tracks, albums, artists, added, at)` | Totals; `added` is the tracks new since the previous scan |
| `ScanFailed(kind)` | `kind` such as `permission` or `io`; the UI maps it to a message |
| `scanStatusProvider` | `StreamProvider<ScanStatus>`; seed: `ScanIdle` |
| `libraryScanCommandsProvider` | `Provider<LibraryScanCommands>`; seed logs and returns |
| `LibraryScanCommands.rescan({bool full = false})` | Completes when the request is accepted or queued. Never waits for the scan. Failures come through `ScanFailed`. |

## Selection bar slot

`lib/src/library/ui/selection/selection_bar.dart`: `LibrarySelectionBar`, an
empty slot until lane C fills it. Both shells render it above the player.

## Navigation items

`lib/src/library/ui/library_browse_registration.dart`:

| Item | Order | Notes |
|---|---|---|
| Library | 105 (mobile 20) | Tab, route `/library` |
| Songs to Folders | 110-160 | Children of `library` (`parentId`); reserved for the library UI lane, not registered yet |
| Playlists | 210 (mobile 30) | Tab, route `/playlists` |
| Favorites, History, Most played | 220, 240, 250 | `comingSoon`, `mobileTab: false` until their mockup exists |

## kanaru_ui widgets used

`SelectionRow`, `showSelectionPicker` (`options`, `selected`, `title`, `header`,
`confirm`, `anchor`), `showKSheet`, `showAppSnackBar`, `showKDialog`,
`confirmAction`, `KPressable`, `KCover`, `KEqualizerIcon`, `KContextRegion`,
`KListRow`, `KChip`, `PageHeaderScope`, `KIcons`. A width-based layout (for
example the album page at 840 px and up) goes into a `collections` widget of
`kanaru_ui`, not into `library/ui`.

## Old app references

The old prototype (retired repo, code only):

| Area | Old code |
|---|---|
| Song, album, artist and genre menus | `lib/shared/song_modal/`, `lib/shared/album_modal/`, `lib/shared/artist_modal/`, `lib/shared/genre_modal/` |
| Folder links | `lib/shared/folder_links/folder_link_row.dart` |
| Library pages | `lib/features/library/` |

Pitfalls the old app hit, and where the design answers them:

- Wide providers rebuilt every tile on each change. Answer: per-tile families
  are `isAutoDispose`; tiles select from one set.
- Exclusion matched by prefix, so `Live` also hid `Live Albums`. Answer:
  `folderLocatorRange` bounds whole path components.
- "Play next" meant move in one menu and copy in another. Answer: `playNext`
  always inserts new entries.
- The queue row menu and the song menu are two implementations of one menu.
  Keep their item sets in sync by review; a shared menu model is a follow-up.
- Accents folded in the group key merged different artists. Answer: `groupKey`
  keeps accents; only `searchForm` folds them.
