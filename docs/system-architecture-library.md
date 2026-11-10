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
- Browse data: refresh and sort.
- List queries: song scopes, sort and filter SQL, aggregates, providers.
- Folder tree, detail data, menu data, selection state.
- File manager and the `kanaru_ui` collection widgets (parts 1 and 2).

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
| `scanStatusProvider` | `StreamProvider<ScanStatus>`; the status stream of the `ScanController` (starts at `ScanIdle`) |
| `libraryScanCommandsProvider` | `Provider<LibraryScanCommands>`; the `ScanController` |
| `LibraryScanCommands.rescan({bool full = false})` | Completes when the request is accepted or queued. Never waits for the scan. Failures come through `ScanFailed`. |

## Browse data: refresh and sort

`lib/src/library/domain/browse/` (no Flutter) and
`lib/src/library/data/browse/throttled_query.dart`.

- `BrowseList` (songs, albums, artists, genres, languages, folders,
  albumTracks, detailSongs), `SortCriterion` (`isNumeric` picks the direction
  wording: "Tăng dần/Giảm dần" vs "A → Z / Z → A"), `SortSpec(criterion,
  descending)`. `criteriaOf(list)` lists the criteria in menu order; the first
  is the default (`defaultSortOf`; detail songs default to play count and
  languages to track count, both descending).
- `LibraryListViews`: sort and `CollectionView` (grid/list) per list plus
  `FolderView` (tree/flat). `toJson`/`fromJson` ignore unknown lists,
  criteria the list does not offer and unknown views (defaults); only a
  non-map throws `FormatException`. Albums default to a grid, the rest to rows.
- `AlbumSummary`, `ArtistSummary`, `GenreSummary`, `LanguageSummary` (code
  null = unknown): value types the list queries return.
- `naturalCompare`: digit runs by value (any length), then folded text, then
  the raw strings, so names sort "2" before "10".
- `languageNameOf(code)`: native, English and Vietnamese names for about 40
  ISO 639-3 codes (also `cmn`, the detector's Mandarin); null for others (the UI shows the code).
- `throttledQuery(db, tables, load, {interval})`: lists are reloaded through
  it, not drift's `.watch()` (which restarts per write and never emits during
  a scan). The first load runs on listen; a write only marks the result dirty;
  a running load is never cancelled and two never overlap; the next load
  starts after the previous ended, at least `interval` later (`browseRefreshInterval`
  1 s, `folderRefreshInterval` 3 s) and at least 4 times as long as that load
  took, at most 5 s: the database runs on the UI isolate, so a slow
  whole-library query (albums: 200-600 ms on 20k tracks) may use only about a
  fifth of it. A result equal to the previous one (`equals`, default `==`) is
  not emitted; an error resets that memory. Errors are emitted and later writes still
  load. Pause defers loading, cancel stops the timer and drops a late result.

## List queries

`lib/src/library/domain/browse/song_scope.dart`,
`lib/src/library/data/browse/{song_ids_query,scope_sql,album_artist_queries,genre_language_queries}.dart`,
`lib/src/library/state/browse/{song_list_providers,collection_providers,track_window,list_prefs_providers}.dart`.

- `SongScope` (value type): `all`, `album(AlbumKey)`, `artist(ArtistKey)`
  (any `track_artists` row), `genre(genreKey)`, `language(code?)` (null = no
  language), `folder(sourceId, folderKey, direct:)` (a locator range from
  `folderLocatorRange`; `direct` = no further `/`, so `Live` never matches
  `Live Albums`). `addScope` in `scope_sql.dart` turns a scope into `WHERE`
  clauses on `tracks t`; every value is a bound variable.
- `songIds(db, scope, sort, filter)`: ids of visible (`present`) tracks. Sort
  keys: title `title_sort`, artist `artist_search`, album `album_search`, year,
  date added, play count (`LEFT JOIN play_stats`, only for this criterion),
  duration, track number (`disc_no, track_no`, both flip when descending).
  Every nullable key sorts NULL last in both directions
  (`(col IS NULL), col`). Ties end with `title_sort, id`; only the main key
  flips when descending.
- Filter: tokens of `searchForm(input)`; each must occur (`instr`, so `%` and
  `_` are literal) in `title_search + char(31) + artist_search + char(31) +
  album_search`. `songCount(db, scope)` is the unfiltered count ("6 / 34").
- Aggregates, name order (stored `album_search` / `genre_search`; artists by
  `sortKeyOf(name)`, a memoized `sortForm`): `albumSummaries` (grouped by album
  artist key and title key; albums without an album tag are not listed;
  display artist = `album_display_artist`, else `album_artist`, else the first
  `track_artists` entry of the group's lowest track id; optional `scope`,
  `ownedBy`, `notOwnedBy`, `newestFirst`), `artistSummaries` (one row per
  `track_artists` key; album count = own albums, photo = cover of the newest
  own album that has one), `genreSummaries`, `languageSummaries` (null code =
  unknown).
- Providers: every stream goes through `throttledQuery`. `songIdsProvider`
  watches `tracks`, `track_artists`, and `play_stats` only when sorted by play
  count, so playback does not refresh other lists. `albumSummariesProvider`,
  `artistSummariesProvider`, `genreSummariesProvider`,
  `languageSummariesProvider` watch the tables their query reads. An emission
  equal to the previous one is dropped. `albumListProvider` and its siblings
  return the sorted, filtered `AsyncValue` for a `CollectionViewKey`; "Chưa
  rõ" is last in both directions and shown only without a filter. All family
  providers are `isAutoDispose`. One-shot readers (play buttons) call
  `songIds` directly. `browseRefreshIntervalProvider` and
  `folderRefreshIntervalProvider` let tests shorten the interval.
- `TrackWindow`: rows of a song list keyed by `TrackId`, pages of 100, at most
  1200 cached (LRU by id), at most 2 reads in flight. The list calls
  `viewport(first, last)` each build with the whole range it has built, cache
  extent included (not only the painted rows, or the first row of each new
  page paints as a placeholder); only the pages of that range are read,
  nearest the centre first, and a queued page that left the range is dropped.
  `rowAt(i)` is `ids[i]`'s row or null, never another index's row. After
  `setIds`, cached rows of ids still listed stay and are read again when in
  view; rows delivered by a read that began before the last `setIds` are also
  marked for a re-read. Ids with no row, and rows that are not `present`, are absent. A failed read is exposed
  as `error` and not retried until the next `setIds`. `invalidate()` marks
  every cached row stale and re-reads the pages in view: the list calls it on
  each tick of `songRowsRevisionProvider`, a throttled counter over `tracks`
  and `track_artists` that is never deduplicated, because a cover or title
  can change while the id order stays the same and `songIdsProvider` then
  emits nothing.
- Settings: `library.list_views` (`libraryListViewsProvider`: `setSort`,
  `setView`, `setFolderView`), `library.compact_folders` (default true, no UI
  yet).

## Folder tree

`lib/src/library/domain/browse/folder_tree.dart`,
`lib/src/library/data/browse/folder_rows_query.dart`,
`lib/src/library/state/browse/folder_providers.dart`.

- Input: the visible files as `FolderRow` records `(sourceId, locator,
  coverKey)`; locators are `/`-separated paths relative to the music folder.
  `buildFolderTrees(musicFolders, rows)` returns one `FolderRoot` per music
  folder: `folder`, `node`, `ambiguous` (another root has the same name).
- `FolderNode`: `key` (`''` = root), `name`, `directSongs`, `deepSongs`,
  `subfolders`, `children` in `naturalCompare` order, `directCoverKey` (the
  cover of most direct files, ties to the smaller key), `coverKey` (direct,
  else the subfolder with most files that has one, ties to the first).
  Excluded folders are absent because their tracks are hidden.
- `compactChain(child)`: the child plus, while the last one has no files and
  exactly one subfolder, that subfolder (the row joins the names with ` › `
  and opens the last). The switch is `library.compact_folders`.
- `flatFolders(roots)`: every folder with direct files, root included, with
  its ancestor names (the music folder's name first).
- `folderTreesProvider` combines `musicFoldersProvider` with a throttled read
  of the rows (folder refresh interval, 3 s). From `folderIsolateThreshold`
  (5000) rows the tree is built with `Isolate.run`, decided on the row count.
  The provider is autoDispose, so nothing reloads once the page is gone, and
  a paused subscription does not reload either. It depends on the music
  folders by value: a rewrite of `sources` or `source_mounts` that leaves
  the folders equal (scan cursor, timestamps) does not rebuild the stream.

## Detail data

`lib/src/library/data/browse/detail_queries.dart`,
`lib/src/library/domain/browse/detail_data.dart`,
`lib/src/library/state/browse/detail_providers.dart`.

- `artistAlbums(db, artist)` returns `ArtistAlbums`: `own` (album artist key =
  the artist, newest first, no year last) and `appears` (other album artists'
  albums with a track by the artist; the count is the whole album, as the
  mockup shows).
- `groupShelves(db, scope)` (genre or language): artists, most tracks first,
  and albums, newest first, counted inside the scope. The page shows a shelf
  from two items up and caps it.
- `groupTotals(db, scope)`: tracks, distinct artists, duration, tracks whose
  language was detected.
- The providers are throttled streams (`artistAlbumsProvider`,
  `groupShelvesProvider`, `groupTotalsProvider`), deduplicated.

## Menu data

`lib/src/library/data/browse/menu_queries.dart`,
`lib/src/library/domain/browse/menu_targets.dart`,
`lib/src/library/state/browse/menu_providers.dart`.

Loaded once when a menu opens (`FutureProvider.family`, autoDispose), never
live: a menu acts on what it showed.

- `trackLinks(db, id)`: album key and title (null without an album), track
  artists in tag order, the album artist when its stored key is not among
  theirs (name = display artist if any; empty otherwise), and the folder as a `FolderRef` (`sourceId`, `sourceUid`,
  `folderKey`, `name`, direct file count; the music folder itself is named
  after its source). Null for a gone or hidden track.
- `foldersOf(db, scope)`: the distinct folders holding the scope's tracks with
  how many sit directly in each, most first.
- `songInfo(db, id)`: format (codec, else the file extension), bitrate, sample
  rate, bit depth, `size_bytes` (null when unknown), absolute path (mount root
  + locator without a CUE `#n` suffix; null without a local root), play count.
- `selectionDuration(db, ids)`: one chunked (500) read of `id, duration_ms`;
  returns the total and the ids that are not visible.

## Selection state

`lib/src/library/state/browse/selection_providers.dart`.

- `SelectionState`: ordered `ids`, a `Set` index (O(1) `contains`), `anchor`
  (last track toggled on), `expanded`. Never mutated.
- `librarySelectionProvider` (app lifetime): `toggle`, `addRange`,
  `selectRangeTo(order, to)` (Shift-range from the anchor), `selectAll` (20k
  ids in one change, no row loads), `remove`, `removeAll`, `reorder(from, to)`
  (`to` = index after removal), `clear`, `setExpanded` (opens only with a
  selection; removing the last track resets everything).
- `isSelectedProvider(id)` selects `set.contains(id)`, so a tile rebuilds only
  when its own answer flips; `hasSelectionProvider`.
- `activeTrackListProvider`: the ordered ids of the list on screen for "select
  all"; `clear(ids)` only clears when `ids` is still the registered list.
- `selectionSummaryProvider`: duration of the selection, computed 60 ms after
  the last change; ids that are no longer visible are removed from the
  selection.

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

## File manager

"Open in file manager" is a platform service, so `library/ui` never touches
D-Bus or processes.

| File | Role |
|---|---|
| `platform/domain/file_manager.dart` | `FileManager { canReveal; reveal(absolutePath) -> Result<void, FileManagerError> }`; errors `unsupported`, `notFound`, `failed` |
| `platform/data/file_manager_linux.dart` | `LinuxFileManager`: `org.freedesktop.FileManager1` on the session bus |
| `platform/data/file_manager_unsupported.dart` | `UnsupportedFileManager`: `canReveal` false, `reveal` gives `unsupported` (Android; the menu row is dimmed) |
| `platform/state/file_manager_provider.dart` | `fileManagerProvider`, by platform; tests override it |

Linux rules: a file calls `ShowItems`, a directory calls `ShowFolders` (`ShowItems`
on a directory would select it inside its parent). URIs come from `Uri.file`
(percent-encoded). The bus connection is created per call and closed after it,
also on error. Any bus failure (no session bus, no service) falls back to
`xdg-open` on the parent folder of a file, or on the directory itself,
started detached. A missing path is `notFound` before anything is called. The
bus and the process start are injected (`FileManagerBus`, `DetachedStarter`),
so the tests need no bus. A Flatpak portal (`OpenDirectory`) is a later
packaging step.

## kanaru_ui collections, part 1: lists

`packages/kanaru_ui/lib/src/widgets/collections/`, exported by
`collection_widgets.dart`. Presentational, no music types: strings, covers and
callbacks come from the caller. Width-based layout lives here.

| Widget | Notes |
|---|---|
| `KMediaCard` | Row card of song, album, artist and folder lists. Three text lines always reserved; `leading`, right column (`top` duration, `bottom` heart), `trailing`, optional round `onAction` (always on mobile, hover or focus on desktop), `revealTrailingOnHover`; states `current`, `selected` (check over the leading), `dimmed`. `KMediaCard.extentOf(TextScaler)` is the exact height with its bottom gap, for fixed list extents (it assumes a 56 dp leading; `hasLeading: false` for cards without one); `currentLabel` gives the playing state a screen-reader value; a test pins it to the laid-out height at 1.0, 1.3 and 1.5 |
| `KListSortFilterBar` | `leading` group, criterion chip (label and direction arrow) and filter toggle. The chip is announced as `<tooltip>: <criterion>`; it passes an anchor key to `onSortPressed`; 52 tall on mobile, 48 on desktop |
| `showKSortPopover<T>` | Anchored under the chip on both shells. Order buttons keep it open (`onAscendingChanged`); a criterion (`KSortCriterion`, shown as a `SelectionRow`) closes it and is the result. Criteria scroll, the order row stays. Root navigator; Esc closes. Its anchored layout copies the private one of `selection_picker.dart` (follow-up: export one helper) |
| `KFilterField` | Outlined, 48 tall, autofocus; the cross and Esc clear the controller and call `onClose` |
| `KBreadcrumb` | `KBreadcrumbSegment`s, last one bold. Desktop above four levels: first and last three, rest behind "..."; mobile above two levels: tonal "..." then the open level. `onShowHidden` gets the hidden levels; the caller opens a `showSelectionPicker` |
| `KShelf` | Titled horizontal list of fixed-width items; the `>` on the title row opens "see all" (`seeAllLabel` is its semantics label) |
| `KCollectionGrid` | Sliver; column count from the width and the shell's minimum tile width (`mobileMinTileWidth`, `desktopMinTileWidth`); tile height is width times `tileAspect` plus `footerExtent` |
| `KColorTile`, `KColorBanner` | Pastel tile or banner for genres and languages; hue from the same hash as the cover placeholder |
| `KSubTabBar` | Scrolling tab row, underline on the selected tab, which scrolls to the centre. `initialOffset` and `onOffsetChanged` let the next page start where this row was |

Sizes that the mockups give and the tokens lack (card radius 14, panel radius
22) are constants inside the widget.

## kanaru_ui collections, part 2: menu, detail, selection

| Widget | Notes |
|---|---|
| `KDetailLayout` | `header` plus list `slivers`. Under 840 px of page width (measured on the page, not the window) the header sits above the list; from 840 the header is a fixed 320 column, bottom aligned and scrolling on its own when the window is short. `tint` washes the background (alpha at most 0.18 light, 0.24 dark) |
| `KBlurredBar`, `KStickyBarSliver` | Translucent blurred background and a pinned sliver bar over it, so the tint is not cut by a flat bar. Blur only on these bars |
| `showKLayeredMenu` | `KMenuPage` (header, groups of `KMenuRow`, footer of two `KMenuButton`s, note). A row either runs `onTap`, opens a sub-page (`opens`), or folds chips (`chips`); `soonLabel` or `enabled: false` dims it and makes it inert; `danger`, `proLabel`, `trailing` icon button. A chosen row closes the menu first and then runs its callback. Back, the arrow and Esc on a sub-page return one page; on the root they close |
| `KSelectionPanel` | Frame of the multi-select panel: `header`, optional expanded `body` clamped to 460 dp (`bodyHeight`), no state. Mobile: full width minus 8, radius 20. Desktop: 440 wide, centred, radius 22, shadow. The frame is only as high as its content, so a full-width slot does not take taps beside it |

`showKLayeredMenu` on the mobile shell is a bottom sheet (at most 85 % of the
height, grip, sticky footer); on desktop a centred dialog 400 wide and at most
640 tall on a 45 % barrier, first row focused, arrow keys move. Both open on
the root navigator, so the shortcut guard and the selection Back handling see
a modal route. It builds its own sheet instead of `showKSheet`, which cannot
target the root navigator.

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
