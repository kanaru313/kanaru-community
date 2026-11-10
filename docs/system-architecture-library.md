# Library

> Owner: lane C (library UI). The foundation contracts below are frozen; lane C
> documents its own design (lists, detail pages, menus, selection, sub-tabs)
> after them as it lands. The library scanner that fills the data is described in
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
- Navigation and routes, the Songs list, collection lists, detail pages, the Folders tab (UI).
- Context menus (models, link rules, rendering, actions, song info) and multi-select (UI).

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
  1 s, `folderRefreshInterval` 3 s) and at least as long as that load
  took, at most 5 s: the database runs on a background isolate (frames stay
  free) but it is one serial worker shared with the scanner's writes, so
  back-to-back whole-library reloads (albums: 200-600 ms on 20k tracks) of one
  query may use only about half of it (several lists reload on their own
  timers, so the total can be higher). A result equal to the previous one
  (`equals`, default `==`) is not emitted; an error resets that memory. Errors
  are emitted and later writes still load. Pause defers loading, cancel stops the timer and drops a late result.

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

## Context menus

`lib/src/library/ui/menus/`. One menu model per kind of item, one renderer for
both shells. The builders are pure functions of loaded data (no
`BuildContext`, no providers), so they are unit-tested without widgets.

| File | Role |
|---|---|
| `menu_origin.dart` | `MenuOrigin`: `list`, `album(key)`, `artist(key)`, `genre(key)`, `language(code)`, `folder(sourceId, key)`, `own`. `MenuOrigin.ofScope(scope)` gives the origin of the songs of a list. It travels page -> tile -> builder |
| `menu_model.dart` | `MenuSpec` (header, groups, `advanced` groups, named `pages`, `queueIds`), `MenuItemSpec` (id, icon, title, subtitle, `action` or `page` or `chips`, `trailing`, `enabled`, `soon`, `danger`, `pro`), `MenuAction` (`go`, `favorite`, `exclude`, `copy`, `reveal`, `select`, `play`), `MenuEnv` (l10n, `canReveal`, folder paths, Trash wording) |
| `link_rows.dart` | The "Go to ..." rules in one place (below) |
| `{song,album,artist,group,folder,selection}_menu.dart` | The builder of each kind (`group` = genre and language) |
| `menu_items.dart` | Shared rows: Play / Shuffle, add all to favorites, the dimmed rows, the "Advanced" row |

**Link rules** (`contextModalLinksPageFrom = 4`, `linkPageFrom`): no target ->
a dimmed row saying "No album" / "No artist"; one -> a plain row with the name
that goes there; several -> a count line with the names as chips, open while
fewer than four; four or more -> a sub-page (album, artist, genre and language
targets). A song's artists are always chips (folded from four) and its
"Go to album artist" appears only when the album artists are not all among the
song's. The folder row: none -> no row; one -> the folder's path and a trailing
"Show in file manager" button; several -> `N songs in M folders` opening a page
with an intro and one row per folder. An artist's albums list its own albums
first, then the ones it appears on, under two headings on the page.

**Origins**: a menu never links to the page it was opened from. A song on its
album page has no "Go to album"; on its folder's page "Show in file manager"
replaces "Go to folder"; on an artist's page that artist is left out of the
artist chips (the row goes when none is left). An album card on an artist's
page leaves that artist out of its artist link. On an item's own page (`own`,
the page's ⋮) the self link, Play and Shuffle are left out.

**Items per kind** follow mockup 04c. Rows that are not built yet are dimmed
with "Coming soon" (`appComingSoon`) and inert: add to playlist, edit info,
find lyrics online, ask AI (with the Pro badge), remove from library, delete
files (Trash wording on desktop), split or merge artists / genres, "how
languages are detected". "Exclude from
library" of a folder (not on a music folder) is real, with undo. "Show in
file manager" is dimmed where `FileManager.canReveal` is false (Android).
`queueIds` are captured when the menu is built, so the footer buttons act on
what the menu showed.

### Opening and acting

- `open_menu.dart`: `openSongMenu`, `openAlbumMenu`, `openArtistMenu`,
  `openGenreMenu`, `openLanguageMenu`, `openFolderMenu`, `openSelectionMenu`.
  Each loads its data once (`menu_loaders.dart`: direct one-shot reads), builds
  the spec, and shows it with `showKLayeredMenu` on the root navigator (sheet
  on the mobile shell, centred dialog on desktop). A second tap while one is
  loading opens nothing; a failed load is a toast.
- `menu_renderer.dart` maps a `MenuSpec` to `KMenuPage`s (`menu_header.dart`
  draws the picture and names). `KMenuPage` got `groupTitles` (headings) and
  `headerOpens` (the song header opens the song info page).
- Triggers: a ⋮ on every tile, card and page (`LibraryMoreButton`, on desktop
  shown on hover or focus), right click / Menu / Shift+F10 (`KContextRegion`),
  and a long press on an album, artist, genre, language or folder card on the
  mobile shell. A long press on a song selects it instead. The page ⋮ opens
  the same centred dialog on desktop.
- `menu_action_runner.dart` holds the `ProviderContainer` and a context of the
  root navigator, so an action chosen after its tile scrolled away still runs
  and its toast still shows. Every call is awaited; a failure is logged and
  shown as a toast. Navigation is a push (Back returns to the page the menu
  was opened from). Exclusion is immediate with a toast whose undo holds the
  `FolderExclusions` instance and the key, not the page.
- `song_info_page.dart`: the song info sub-page (format, bitrate, sample rate,
  bit depth, size, copyable path, play count) built from `songInfo`.

## Multi-select

`lib/src/library/ui/selection/`. The selection lives in
`librarySelectionProvider` (see Selection state), so it follows the user
between screens.

- Enter: a long press on a song (mobile, with a light tick), Ctrl / ⌘ click or
  Shift click (desktop; Shift extends from the last clicked row in the order on
  screen), Ctrl+A, or "Select" in a song's menu. While a selection exists a tap
  on any `SongTile` toggles it instead of playing. A selected tile is tinted
  `secondaryContainer` with a check over its cover.
- Ctrl+A (`SelectAllShortcut`): a global key handler registered by the song
  list that is on screen, so it works right after a click on the sidebar. It
  adds the songs of `activeTrackListProvider` to the selection (it does not
  replace what other screens contributed) and stays quiet while a dialog,
  sheet or page covers the app or a text field has focus.
- `LibrarySelectionBar` (const, in both shells' slot) shows `SelectionPanel`
  when something is selected. The panel is a `KSelectionPanel`: clear, `N songs`
  (and the length when open), play all (replaces the queue with the selection
  in panel order; the selection stays), edit and add to playlist (dimmed), the
  selection's menu, "select all songs of this screen" (off without a list), and
  open / collapse. Open, it lists the selected songs in play order with a drag
  handle, a ♥ and the song's menu; that list is a `ReorderableListView.builder`
  over a `TrackWindow` that exists only while the panel is open, so a selection
  of thousands loads only the rows in view. The length is the chunked read of
  `selectionSummaryProvider`, also what drops tracks that vanished.
- Back and Esc (`SelectionBackScope`): they collapse the panel and never clear
  the selection (only the panel's ✕ does). Back is a `BackButtonListener`: the
  root dispatcher asks listeners before the router pops a sheet or dialog, so
  it answers only when the panel is open and its route is the current one
  (`ModalRoute.isCurrent`), else the modal closes first. Esc is a key handler
  with the same two conditions that also yields to a focused text field.
  Because the listener sits at the root, an open panel collapses before a page
  filter field or a folder level takes Back.
- Desktop slot: the shell puts the bar in a `Center` over the page, so the
  empty slot and the space beside the 440 wide panel pass clicks to the page.
  `SelectionInsetSliver` ends every library scroll view (lists, folders,
  see-all grids, the songs of detail pages) with room as high as the panel
  (`KSelectionPanel.heightFor`, which includes the cap at half the window), so
  the last row scrolls clear of it while the page keeps its full height and the
  rows beside the panel stay reachable. On the mobile shell the panel sits in
  the bottom bar and pushes the page up by itself.

## Navigation and routes

`lib/src/library/ui/library_browse_registration.dart`,
`lib/src/library/ui/browse/{library_routes,library_navigation}.dart`.

| Item | Order | Notes |
|---|---|---|
| Library | 105 (mobile 20) | Tab, route `/library`; `sidebar: false` (the six lists replace it in the desktop sidebar) |
| Songs to Folders | 110-160 | Children of `library` (`parentId`, `mobileTab: false`), paths `LibraryLocations.list(tab)`; always all six in the sidebar, in default order (the tab setting steers the mobile sub-tabs only) |
| Playlists | 210 (mobile 30) | Tab, route `/playlists` |
| Favorites, History, Most played | 220, 240, 250 | `comingSoon`, `mobileTab: false` until their mockup exists |

- `libraryRoute()` is `/library` with six sibling list routes under it
  (`songs` ... `folders`, `NoTransitionPage`, `state.pageKey`). The parent has
  no page: its redirect returns the last visited visible list (or the first
  visible one) **only when `state.uri.path == '/library'`**. go_router runs the
  redirect of every route in a matched chain, parents included, so an unguarded
  redirect would rewrite every `/library/...` location. It reads Riverpod with
  `ProviderScope.containerOf(context, listen: false)`.
- `openLibraryPage(context, location)` is `context.push`: every open of a
  detail, see-all or folder page from another page uses it, so Back steps one
  page at a time. Switching list (sub-tab tap, swipe, sidebar) is `go`; folder
  levels are `replace` (see Folders tab).
- `lastLibraryTabProvider` (memory) holds the list shown last;
  `subTabOffsetProvider` the scroll offset of the mobile sub-tab row.

### List page frame

`LibraryListScaffold(tab, child)` is the frame of a list page. `PageHeader`
without `onBack` (a root page, so the shell's `PageHeaderScope` slots show);
the title is "Library" on the mobile shell and the list name on desktop. The
mobile shell adds `KSubTabBar` (the visible tabs from `libraryTabsProvider`;
a disabled tab's route still works, with no tab selected) and a horizontal
drag of more than 60 px moves to the next or previous visible tab. Only the
body slides in (from the side the new tab lies on, by the index change from
the last visited tab); the header and tab row do not move and the tab row
keeps its offset. `ScanBanner` shows under the tabs while a scan runs:
`listing` "Scanning…", `tags` "Scanning · done / total songs" with a
determinate bar (count only when the total is 0), `covers` "Fetching covers ·
done / total". A library with no visible track (and no scan running) shows
`LibraryEmptyState` in place of the body; its "Choose music folders" button is
dimmed with "Coming soon" until Settings has the folders screen.

`LibraryListFrame(list, filterHint, builder)` adds the list bar
(`KListSortFilterBar`: the page's left group, the sort chip, the filter
toggle) and the filter field. The builder gets `LibraryListInput` (remembered
sort and view, filter text, whether the field is open) and returns the left
group and the body. The sort chip opens `showKSortPopover` (order buttons keep
it open) and stores the choice in `libraryListViewsProvider`. The filter text
is the page's own state and is never stored; closing the field clears it. On
the mobile shell Back closes the field first.

`play_actions.dart`: `playFrom`, `playAll`, `shuffleAll` (shuffle with a random
start) and `playScope` / `shuffleScope` (read the ids of a scope with a direct
`songIds` call, then play; for a ▶ on a tile that does not hold its ids).
Every call is awaited; a failure is logged and shows a snack bar.

## Songs list

`lib/src/library/ui/songs/{song_tile,song_list,songs_page}.dart`.

- `SongTile(info, index, ids, playContext, {showNumber})` on `KMediaCard`:
  cover (`TrackCover`, seed album key else title), title, artists joined with
  ", " (else the artist tag), `album • year`, duration `m:ss` over the heart.
  Tap = `playTracks(ids, startIndex: index)`. The playing row is
  `primaryContainer` with the equalizer over the cover (over the number with
  `showNumber`, which replaces the cover with the track number). The tile
  watches only `isCurrentTrackProvider(id)` and `isFavoriteProvider(id)`; the
  equalizer widget alone watches play / pause. No per-row stream provider.
- `SongList(scope, sort, filter, playContext, {showNumber, leadingSlivers})`
  is a `CustomScrollView` with a `SliverFixedExtentList`. `songIdsProvider`
  gives the ids; a `TrackWindow` reads the rows. The list tells the window the
  range it has **built** (`didFinishLayout`, cache extent included), calls
  `setIds` on every ids emission and `invalidate` on every
  `songRowsRevisionProvider` tick (a cover or title changed, the order did
  not). A page not read yet is a same-size placeholder card. The tap handler
  passes `window.ids`, so `ids[index]` is the painted row. `trackRowLoaderProvider`
  is the window's loader (tests override it).
- Select-all target: while its page is the current route and not offstage
  (`ModalRoute.isCurrentOf` and `TickerMode`), the list registers its ids in
  `activeTrackListProvider`; it clears them when the page goes under another
  one or is disposed. A notifier that is already disposed ignores `set` and
  `clear`.
- Songs page: left group is shuffle and play all (icons on the mobile shell,
  labelled buttons on desktop) and the count (`36 songs`, `6 / 34 songs` while
  filtering). The context is `PlayContext(songs, label)`.

## Collection lists

`lib/src/library/ui/collections/`.

- Albums and Artists: a grid (`KCollectionGrid` of `KGridCard`; albums 150 /
  160 px minimum, artists 100 / 160) or rows (`AlbumTile`, `ArtistTile` on
  `KMediaCard`, ▶ always on mobile and on hover or focus on desktop). The view
  switch (`LibraryViewToggle`: one icon on mobile, a double button on desktop)
  is stored per list. Albums open as a grid, every other list as rows, on both
  shells. Tiles get their summary by value and watch nothing.
- Album ▶ plays the album in track order (`playScope` with the `albumTracks`
  default sort), artist ▶ plays every song of the artist (`detailSongs`
  default); both with the album / artist `PlayContext`.
- Artist photo: the `coverKey` of `ArtistSummary` (the cover of the newest own
  album that has one), a round `TrackCover`, else a letter placeholder seeded
  by the name.
- Genres: `KColorTile` in a grid (150 / 200 px minimum); the tile height is
  88 times the text scale.
- Languages: `KListRow` per language with `languages` (`help` for "unknown",
  always last), `N songs · M auto-detected` (the second part only when
  nonzero), and the note above the list. `languageDisplayName`: the native
  name, plus the name in the app language when it differs; an unknown code
  shows as the code.
- A tap on an item is `openLibraryPage` to the album, artist, genre or
  language location. A long press opens the item's menu (menus are a later
  phase), not multi-select.
- Counts: `34 albums`, or `6 / 34 albums` while filtering (the total is the
  unfiltered summary count).

## Detail pages

`lib/src/library/ui/detail/{album_page,artist_page,group_page,see_all_page,detail_header,detail_songs}.dart`,
routes in `ui/browse/library_routes.dart`.

- Routes are flat siblings of the six list routes (a nested route would stack
  its parent page under it): `albums/:album`, `artists/:artist`,
  `artists/:artist/{albums,appears}`, `genres/:genre`,
  `genres/:genre/{artists,albums}`, `languages/:language` (`_unknown` = songs
  without a language) and `languages/:language/{artists,albums}`. They match
  `LibraryLocations` exactly, so Now Playing and the queue menus open the same
  pages. An id that does not decode, or an item no visible track has, shows
  "Not found" with a back button. Every open from a page is `openLibraryPage`
  (push): Back returns one page at a time. A page that was the first of the
  stack (a link from outside) goes back to its list.
- `DetailFrame`: `PageHeader(title: name, onBack)` and the page. No ⋮ in the
  header. `DetailActions`: Play (filled), shuffle (tonal), ⋮ (the page's own menu: a sheet on the mobile shell, a centred dialog on desktop). Play and shuffle take every song of the
  page in the page's current sort, ignoring its filter; the context carries the
  encoded key and the name.
- `DetailSongsHost(list, scope, ...)` owns the page's filter and builds the
  song slivers: a `KStickyBarSliver` list bar (`N songs · length`, or `6 / 34
  songs` while filtering; sort chip through `openListSort`; filter toggle), the
  filter field and `SongSlivers` (the rows of `SongList` as one sliver, same
  `TrackWindow` built-range rule). The sort starts at the remembered default
  of the page kind (`albumTracks`, `detailSongs`); a sort chosen on a page is
  kept for the session for that page only (`detailSortProvider`, keyed by kind
  and item id; not persisted). The host stays in the tree when an artist has no
  songs yet (`hasSongs: false` only drops the songs part), so a first song
  arriving keeps the filter and scroll. The sort popover is
  `openListSort` (`ui/browse/list_sort_popover.dart`). On the mobile shell Back
  closes the filter first.
- Album: `KDetailLayout` (wide from 840 px of page width) with `KDetailHero`:
  cover and, bottom aligned or under it, the album artist (primary colour, opens
  the artist page; plain text for the unknown artist), the year and the
  buttons. The page tint is `coverColorsProvider(coverKey).seed`. Rows are
  `SongTile(showNumber: true)`; no disc headers and no "other albums".
- Artist: round photo (not faded), `N albums` (own; the line is left out when
  the artist owns none), shelves Albums (newest
  first) and Appears on, then the songs. A shelf with no item and the songs
  part of an artist with no `track_artists` row are left out. Play and shuffle
  of such an album-artist-only page play `SongScope.albumArtist(key)` (tracks
  whose stored album artist key is the artist's); `ArtistSongs` is not widened. Name:
  `artistNameProvider` (tag name, else the display artist of its first album).
- Genre / language: `KColorBanner` (colour from the name, big `N songs`,
  `M artists · length`, language adds `· K auto-detected`), artist shelf and
  album shelf from two items up, capped at 10 (mobile shell) or 8 (desktop),
  then the songs (`detailSongs`, most played first). Language pages note what
  "auto-detected" means when the page has detected songs (the unknown group
  always has its own note) and
  `SongTile(showDetected)` tags songs whose language was detected.
- See all: `ArtistAlbumsPage(appears)` and `GroupSeeAllPage(artists)` are
  `KCollectionGrid`s of `AlbumCard` / `ArtistCard`, titled `Albums · name`,
  `Appears on · name`, `Artists · name`. `SeeAllLocations` builds the paths. A
  group that does not exist (or has no track) is "Not found" here too.
- Data: `albumDetailProvider`, `artistDetailProvider`, `artistNameProvider`,
  `genreNameProvider` on top of the throttled summaries; the shelves and totals
  are in "Detail data".
- Covers: `ui/browse/item_covers.dart` has `AlbumCover` and `ArtistCover`, the
  one place that decides which picture an album or artist shows (tiles, grid
  cards and page headers all use them). Order: the cover the user chose (a file
  drawn through `KCover`, so it decodes at display size), else the cover of the
  tracks (`coverKey`), else a placeholder. `itemKey` is the encoded `AlbumKey` /
  `ArtistKey`. A list holds thousands of covers, so they never watch the
  per-item `customCoverFileProvider` directly: `hasCustomCoverProvider` selects
  the item's answer from ONE stream per kind (`customCoverIndexProvider`, in
  `state/browse/custom_cover_index_providers.dart`, a watch of the item keys in
  `custom_covers`), and only an item in that set watches its file. While the
  file resolves, or when it is gone (a restored backup), the automatic cover
  stays. `customCoverFileProvider` stays loaded 5 s after its last listener
  (`customCoverKeepAliveProvider`), so a tile scrolled back in within that time
  shows its custom cover at once instead of flashing the automatic one. A file
  that exists but cannot be decoded shows the automatic cover too (passed to
  `KCover` as `errorFallback`).

## Folders tab

`lib/src/library/ui/folders/`.

- Location (`FolderLocation`): `/library/folders` (top),
  `?at=<encodeKey('<sourceUid>/<folderKey>')>` for a level and `&view=flat` for
  a level opened from the flat list. Anything malformed is the top.
  `resolveFolderPlace` turns a location and the trees into a place: the list
  of music folders (several), the only music folder (one), a level, the flat
  list, or one flat folder. A level that is gone opens its nearest ancestor;
  an unknown music folder is the top. `folderPlaceProvider` caches it.
- Moving between levels is `context.replace(location)`: the page stays the same
  page, so a Folders page that was pushed from elsewhere keeps the page below
  it. Entering from another page is `openLibraryPage`.
- Tree level: sub-folder rows first (`FolderTile`: `FolderArt`, name, counts;
  a merged chain is one row of up to two lines and opens its last folder; a
  chevron on mobile), then "Songs in this folder · N" and a `SongList` of the
  direct songs by title. The sort chip orders the folders (name in natural
  order, or number of songs below); the filter narrows folders by name (chain
  included) and the songs. Several music folders: a first level of rows with
  their location. Mobile names the location ("Internal storage", "SD card",
  "USB drive"); desktop shows the path with the home folder as `~`.
- Breadcrumb (`folderSegments`, `FolderBreadcrumb`): "All folders" first with
  several music folders; with one it starts at its location (desktop `~/Music`;
  mobile "Internal storage › Music"). Music folders that share a name are told
  apart by location. `KBreadcrumb` collapses deep paths; "…" opens a
  `showSelectionPicker` of the hidden levels and the open one, indented by
  depth, and choosing one replaces to it.
- Flat view (`FolderView.flat`, remembered): every folder with songs of its
  own; row = name, the folders above (mobile keeps the first and the two
  nearest), `N songs`. Opening one shows its direct songs only under "N songs
  in this folder (not including subfolders)", with the full path dim above and
  the breadcrumb "All folders › name". The view switch replaces to the top.
- Play and shuffle in the bar play the songs below the level (tree) or its
  direct songs (flat), with `PlayContext(folder, ref: '<sourceUid>:<folderKey>')`;
  a tap on a song plays the level's direct songs with the same context.
- Back (mobile): `FolderBackGuard`. The page leaves at the top of the tab and at
  the level it was opened at; elsewhere Back replaces to the parent level
  (the music-folder list above a root, the flat list above a flat folder).
  While the filter field is open Back only closes it. A Folders page pushed
  from an album and drilled two levels deep needs three presses to return to
  the album. Desktop has the in-app back button and the breadcrumb; Alt+←,
  mouse buttons and Esc as history keys belong to the shell.

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
| `KMediaCard` | Row card of song, album, artist and folder lists. Three text lines always reserved (`titleLines: 2` lets a long name wrap over the title and second line, which is then not shown, in the same height); `leading`, right column (`top` duration, `bottom` heart), `trailing`, optional round `onAction` (always on mobile, hover or focus on desktop), `revealTrailingOnHover`; states `current`, `selected` (check over the leading), `dimmed`. `KMediaCard.extentOf(TextScaler)` is the exact height with its bottom gap, for fixed list extents (it assumes a 56 dp leading; `hasLeading: false` for cards without one); `currentLabel` gives the playing state a screen-reader value; a test pins it to the laid-out height at 1.0, 1.3 and 1.5 |
| `KListSortFilterBar` | `leading` group, criterion chip (label and direction arrow) and filter toggle. The chip is announced as `<tooltip>: <criterion>`; it passes an anchor key to `onSortPressed`; 52 tall on mobile, 48 on desktop |
| `showKSortPopover<T>` | Anchored under the chip on both shells. Order buttons keep it open (`onAscendingChanged`); a criterion (`KSortCriterion`, shown as a `SelectionRow`) closes it and is the result. Criteria scroll, the order row stays. Root navigator; Esc closes. Its anchored layout copies the private one of `selection_picker.dart` (follow-up: export one helper) |
| `KFilterField` | Outlined, 48 tall, autofocus; the cross and Esc clear the controller and call `onClose` |
| `KBreadcrumb` | `KBreadcrumbSegment`s, last one bold. Desktop above four levels: first and last three, rest behind "..."; mobile above two levels: tonal "..." then the open level. `onShowHidden` gets the hidden levels; the caller opens a `showSelectionPicker` |
| `KShelf` | Titled horizontal list of fixed-width items; the `>` on the title row opens "see all" (`seeAllLabel` is its semantics label) |
| `KCollectionGrid` | Sliver; column count from the width and the shell's minimum tile width (`mobileMinTileWidth`, `desktopMinTileWidth`); tile height is width times `tileAspect` plus `footerExtent` |
| `KGridCard` | Tile of an album or artist grid: a cover as wide as the tile (drawn by `coverBuilder(context, side)`), one title line, one subtitle line; `footerExtent(scaler)` is the height under the cover for `KCollectionGrid`; `circle` centres the texts for round photos |
| `KColorTile`, `KColorBanner` | Pastel tile or banner for genres and languages; fill and ink from `KCoverPlaceholderColors.of(seed, brightness)`, so a tile matches the cover placeholder of the same seed |
| `KSubTabBar` | Scrolling tab row, underline on the selected tab, which scrolls to the centre. `initialOffset` and `onOffsetChanged` let the next page start where this row was |

Sizes that the mockups give and the tokens lack (card radius 14, panel radius
22) are constants inside the widget.

## kanaru_ui collections, part 2: menu, detail, selection

`KGridCard` and `KColorTile` take a `more` widget (the ⋮ of the item) laid over a corner of the card: always visible on the mobile shell, on hover or focus on desktop (`KEngageRegion`, `KCardCorner`).

| Widget | Notes |
|---|---|
| `KDetailLayout` | `header` plus list `slivers`. Under 840 px of page width (measured on the page, not the window) the header sits above the list; from 840 the header is a fixed 320 column, bottom aligned and scrolling on its own when the window is short. `tint` washes the background (alpha at most 0.18 light, 0.24 dark) |
| `KDetailHero` | Top of an album or artist page for the `header` slot: narrow = 132 cover on the left, text and buttons aligned to its bottom; wide (asked of `KDetailLayout.isWide`) = cover as wide as the column, faded at the bottom and right edges (a round photo is not), text below |
| `KBlurredBar`, `KStickyBarSliver` | Translucent blurred background and a pinned sliver bar over it, so the tint is not cut by a flat bar. Blur only on these bars |
| `showKLayeredMenu` | `KMenuPage` (header, groups of `KMenuRow`, footer of two `KMenuButton`s, note). A row either runs `onTap`, opens a sub-page (`opens`), or folds chips (`chips`); `soonLabel` or `enabled: false` dims it and makes it inert; `danger`, `proLabel`, `trailing` icon button. A chosen row closes the menu first and then runs its callback. Back, the arrow and Esc on a sub-page return one page; on the root they close |
| `KMenuRow.leading` | A picture (an album cover) in place of the row's icon |
| `KMenuPage` extras | `groupTitles` (a heading above each group; an empty group loses its heading) and `headerOpens` (the header becomes a button with a `›` that shows that page) |
| `KSelectionPanel` | Frame of the multi-select panel: `header`, optional expanded `body` clamped to 460 dp (`bodyHeight`), no state. Mobile: full width minus 8, radius 20. Desktop: 440 wide, centred, radius 22, shadow. The frame is only as high as its content, so a full-width slot does not take taps beside it |

`showKLayeredMenu` on the mobile shell is a bottom sheet (at most 85 % of the
height, grip, sticky footer); on desktop a centred dialog 400 wide and at most
640 tall on a 45 % barrier, first row focused, arrow keys move. Both open on
the root navigator, so the shortcut guard and the selection Back handling see
a modal route. It builds its own sheet instead of `showKSheet` (which can target the
root navigator since `useRootNavigator`): `showKSheet` turns into a 640 wide
dialog from 600 px, but this menu stays a sheet up to the desktop form factor
(1200 px) and is a 400 wide dialog above it.

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
