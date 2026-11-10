# Playback

> Owner: lane B (playback). The command, now-playing and provider
> declarations below are frozen contracts; the bodies are the player.

## Contents

- Commands and now playing: this file.
- Queue table and its helpers: this file.
- Queue model, persistence, playable resolver, play log writer, settings keys: this file.
- Restore rules: this file.
- Media controls (MPRIS, `audio_service`): lane B adds the section.
- Android notification icon: `android/app/src/main/res/drawable/ic_stat_kanaru.xml` is the monochrome (white) status-bar icon. `AudioServiceConfig.androidNotificationIcon` must be `'drawable/ic_stat_kanaru'`; the launcher icon is coloured and shows as a grey square in the status bar.

## Commands

`lib/src/playback/domain/playback_commands.dart`:

```dart
abstract interface class PlaybackCommands {
  Future<void> playTracks(
    List<TrackId> tracks, {
    int startIndex = 0,
    bool shuffle = false,
    required PlayContext context,
  });
  Future<void> playNext(List<TrackId> tracks);
  Future<void> enqueue(List<TrackId> tracks);
}
```

- `playTracks` replaces the queue with new entries in `tracks` order and starts
  `tracks[startIndex]`. With `shuffle`, the queue is shuffled and the started
  track comes first. Throws `ArgumentError` (no state change) when `tracks` is
  empty or `startIndex` is out of range.
- `playNext` inserts new entries right after the current one, keeping their
  order. Consecutive calls queue up behind each other.
- `enqueue` appends new entries at the end.
- With an empty queue, `playNext` and `enqueue` behave like
  `playTracks(tracks, context: queue)`.
- The implementation runs every call, and every media-control command, through
  one serial command queue, in call order.
- Library menus call `playNext` and `enqueue`; a tap calls `playTracks` with the
  visible ids and the index of the tapped row.

## Now playing

`lib/src/playback/domain/now_playing.dart`. `NowPlaying` is the snapshot of what
is loaded. Identity is the queue entry: the same track can be queued twice.

| Field | Type | Meaning |
|---|---|---|
| `entryId` | `int?` | `queue_entries.id` of the loaded entry; null when nothing is loaded |
| `trackId` | `TrackId?` | The track of that entry |
| `playing` | `bool` | Playing or paused |
| `index` | `int?` | Zero-based position in the queue |
| `length` | `int` | Queue size |
| `context` | `PlayContext?` | Where playback started (source line on Now Playing) |

`NowPlaying.none` is the empty state. Position and duration are not part of
the snapshot: they tick, so they live on the player's own provider.

## Providers

`lib/src/playback/state/playback_providers.dart` (declarations are frozen; the
bodies are lane B's):

| Provider | Type | Body |
|---|---|---|
| `playbackCommandsProvider` | `Provider<PlaybackCommands>` | the `PlayerController` |
| `nowPlayingProvider` | `StreamProvider<NowPlaying>` | the controller's replay-1 stream |
| `isCurrentTrackProvider(id)` | `Provider.family<bool, TrackId>`, `isAutoDispose` | reads `nowPlayingProvider` |
| `hasCurrentTrackProvider` | `Provider<bool>` | reads `nowPlayingProvider` |
| `isPlayingProvider` | `Provider<bool>` | reads `nowPlayingProvider` |

Lists and tiles watch only the narrow providers. Watching `nowPlayingProvider`
in a list rebuilds every row on every change.

`trackInfoProvider` (single-item screens only) and `TrackCover` are foundation
contracts; their description is in
[system-architecture-library.md](./system-architecture-library.md).

## Cover colours (read side)

`lib/src/playback/state/cover_providers.dart`:

- `coverColorsProvider`: `StreamProvider.family<CoverColors?, String>`,
  `isAutoDispose`. Argument is the cover key; the value is null until the
  scanner computed the colours.
- `CoverColors` (`media/domain/cover_colors.dart`): `seed` (ARGB) and `palette`
  (ARGB ints, most dominant first). `coverColorsVersion` is the algorithm version.
- Used for the Now Playing gradient and the queue strip. Never drives
  `MaterialApp.theme`: the appearance providers are the only app-theme inputs.

## Cover misses (write side)

`coverMissesProvider` (`Provider<CoverMissSink>`): `TrackCover` calls
`report(coverKey)` when a valid key has no file. The sink drops a repeat of the
same key within 60 s, keeps the newest 256 keys while nobody listens, and
exposes them as `misses`. The scanner listens and re-extracts the cover.

## Queue table

`queue_entries` (`database/tables/playback_tables.dart`):

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK autoincrement | Entry identity; never reused |
| `track_id` | INTEGER | FK to `tracks.id`, `ON DELETE RESTRICT` |
| `sort_key` | TEXT | Fractional key: the order the user sees |
| `shuffle_key` | TEXT, nullable | Order while shuffle is on; NULL when off |
| `added_at` | INTEGER | Epoch ms |

Indexes: `queue_entries_track` on `(track_id)`, `queue_entries_order` on
`(sort_key, id)`, `queue_entries_shuffle` on `(shuffle_key, id)` where
`shuffle_key IS NOT NULL`.

Helpers (`database/queue_store.dart`):

```dart
Future<List<QueueEntryRow>> readQueue(DatabaseConnectionUser db, {required bool shuffled});
Future<void> replaceQueue(DatabaseConnectionUser db, List<int> trackIds, int now,
    {List<int>? shuffleOrder});
```

- `replaceQueue` replaces the whole queue in one transaction, 500 rows per
  insert. An unknown track id fails the foreign key and leaves the old queue
  untouched. `shuffleOrder` is a permutation of the indexes of `trackIds`: `shuffleOrder[k]` is the index in `trackIds` of the track that plays k-th; an
  invalid one throws `ArgumentError` and writes nothing.
- `readQueue(shuffled: true)` orders by `shuffle_key IS NULL, shuffle_key,
  sort_key, id`. A row without a shuffle key sorts after the others, so no row
  is dropped.
- Richer edits (remove, move, undo) are written by `QueueRepository` (see below).

## Queue model (pure domain)

`lib/src/playback/domain/` (plain Dart, no Flutter, no `media_kit`):

| File | Holds |
|---|---|
| `queue_state.dart` | `QueueItem` (entry id, track id, `sortKey`, `shuffleKey`), `QueueState` (`items` in play order, `current` index, `shuffled`, `repeat`, `playNextRun`) |
| `queue_logic.dart` | `insertPlayNext`, `enqueue`, `remove`, `move`, `nextIndex`, `previousIndex`; re-exports the rest |
| `queue_shuffle.dart` | `shuffleUpcoming`, `unshuffle` |
| `queue_cleanup.dart` | `cleanupCounts`, `duplicateEntryIds`, `entriesBefore`, `entriesAfter`, `allButCurrent` |
| `queue_undo.dart`, `undo_token.dart` | `undo`, `UndoToken` |
| `queue_edit.dart` | `QueueEdit`: next state plus the rows to write |
| `queue_keys.dart` | `KeyGen`, `placeKeys` |

- `items` is in play order: `shuffle_key` order while `shuffled`, else `sort_key` order. Every
  function returns a `QueueEdit {next, inserted, removedIds, rekeyed, clearShuffleKeys, undo}`;
  the repository writes exactly that.
- New entries carry a negative provisional `entryId`; `QueueEdit.withRealIds` swaps in the
  table's ids. A restored entry (undo) keeps its positive id.
- **Play next:** new entries go right after the current one and behind the earlier "play next"
  entries (`playNextRun`, a contiguous run). Moving an entry into the run or out of it, removing
  run entries, or changing the current entry recomputes the run as the run entries that still follow
  the current one without a gap. Shuffled: the sort key goes between the key of the entry before
  and the next larger sort key; the shuffle key goes between the neighbours in shuffle order.
- **Enqueue:** keys after the last key of each order.
- **Remove:** the current entry hands over to the next one; the last entry to the previous one;
  the only entry leaves `current` null.
- **Move:** changes only the key of the active order (sort key, or shuffle key while shuffled). A
  played entry moved below the current one becomes upcoming and the reverse.
- **Shuffle:** `shuffleUpcoming` shuffles only the entries after the current one (the play-next
  run included) and turns shuffle on. The first time, played entries and the current one get keys in
  their present order; a reshuffle writes keys for upcoming rows only. `unshuffle` returns to
  `sort_key` order, keeps the current entry and clears every `shuffle_key`.
- **Repeat:** `nextIndex(auto: true)` repeats the current entry with repeat one; a manual Next ignores
  repeat one. Repeat all wraps to the first entry. `previousIndex` returns null at the first
  entry: the caller seeks to 0.
- **Cleanup:** duplicates keep the first entry of each track in play order; the current entry is
  always kept and stands for its track (every other entry of that track counts as a duplicate).
- **Keys never collide.** `placeKeys` gives entries that sit next to equal or unordered keys fresh
  keys right after the new ones instead of asking the generator for an empty range. `undo` keeps a
  restored key only when no live entry has it in that order (a "play next" in the 4 s window can
  regenerate the same deterministic key); otherwise the row gets a key between its live neighbours.
  Undo also copes with shuffle toggled inside the window.

## Queue persistence (`playback/data/queue_repository.dart`)

`QueueRepository(DatabaseConnectionUser)` is the only writer of `queue_entries` for the player.

- `load(shuffled:)`: wraps `readQueue`.
- `replace(trackIds, now, {shuffleOrder})`: own SQL, not `replaceQueue`. One transaction:
  `DELETE`, then `INSERT … VALUES (…),(…) RETURNING id` per 500 rows. Keys come from one
  `generateNKeysBetween` call per order, ids from `RETURNING` (sorted ascending, because ids of one
  statement ascend in VALUES order), so nothing is read back. Returns the entries in play order.
- `apply(edit, now)`: one transaction: `DELETE … WHERE id IN (…)`, `shuffle_key = NULL` when
  asked, inserts (restored rows with their id, new rows with `RETURNING`), then key updates as
  multi-row statements, 500 per statement:
  `WITH v(id, k) AS (VALUES …) UPDATE queue_entries SET shuffle_key = (SELECT k FROM v WHERE v.id = queue_entries.id) WHERE id IN (SELECT id FROM v)`
  (same for `sort_key`). Returns the edit with real ids. A failure (unknown track: foreign key)
  rolls the whole edit back.
- Both notify `queue_entries` by table name. No `INSERT OR REPLACE`.

## Playable resolver

`domain/playable.dart`: `Playable` is `LocalFile(path, durationMs)` or `Unplayable(reason)`;
`UnplayableReason` is `missing | hidden | remote | cue | noMount | removedSource | unknownTrack`.
`PlayableResolver.resolve(ids)` returns one entry per distinct id.

`data/playable_resolver.dart` (`LocalPlayableResolver`) joins `tracks`, `sources` and
`source_mounts` (500 ids per query) and decides in this order (`decidePlayable`, pure):

1. no track row: `unknownTrack`;
2. `sources.deleted_at` set: `removedSource`;
3. status `missing`, `hidden`, `remote`: the same reason;
4. locator ending in `#\d+` (the foundation CUE rule): `cue`;
5. source kind not `local`: `remote`;
6. no mount, mount without a root, or mount disabled: `noMount`;
7. else `LocalFile(join(root, locator segments))`. The locator is used byte for byte (no Unicode
   normalisation).

## Play log writer

`data/play_log_writer.dart`: `insertListen(trackId, playedAt, listenedMs, deviceId, context, now)`
returns the row id (ULID `uid`, `skipped = 0`, `updated_at = now`); `updateListened(id, listenedMs, now)`
sets `listened_ms`. Rows are only inserted and updated, never replaced; the triggers keep
`play_stats` in step. Both notify `play_log`.

## Audio engine

`domain/audio_engine.dart` (no media_kit import): `AudioEngine` with `load(current, next?, play, start)`,
`setNext`, `play`, `pause`, `stop`, `seek`, `setVolume`, and streams `events`, `position`, `playing`.
Events: `EngineAdvanced`, `EngineLoaded(token, duration)`, `EngineFailed`, `EngineEnded`, `EngineSeeked`.
`EngineToken{entryId, generation, handoff}`: `generation` grows on every `load`, `handoff` on every
`load` and `setNext`, so two loops of one entry (repeat one) carry different tokens.

- **`MediaKitEngine`** (`data/media_kit_engine.dart`): mpv holds only `[current, next]`. The queue
  stays in Dart. Commands run on one internal chain; a failing command does not block the next.
  Property callbacks (`playlist-playing-pos`, `playlist-count`, `duration`, `idle-active`,
  `eof-reached`) trigger a fresh read of mpv (never `player.state.playlist`, which lags) that
  `MpvPlaylistTracker` turns into events.
- **Options** (`mpv_options.dart`): `sub-auto=no`, `gapless-audio=weak`, `cache-on-disk=no`,
  `demuxer=lavf`, `demuxer-lavf-o=protocol_whitelist=file`, `ytdl=no`, `vid=no`; read back with
  a warning: `gapless-audio`, `demuxer-lavf-o`, `keep-open` (must be `yes`, media_kit's own).
- **keep-open / end of file:** at the end of the last entry mpv pauses with `eof-reached` instead of
  going idle. `Ended` fires once for that entry when nothing is handed after it; the pause flip is
  not a user pause. A `setNext` that arrives after the end of file appends, then `playlist-next`,
  and unpauses mpv directly if the last request was play. media_kit's `play()` is not used there: while its
  `completed` flag is still set it seeks back to the first playlist entry, which would replay the finished
  one. The controller pauses the engine when the queue ends, so a song added later waits, paused.
- **Resume:** `Media(uri, start:)`. media_kit applies it in its `on_load` hook and resets mpv's
  `start` in `on_unload`, so the `start` property is never set directly. A raw-appended entry has
  no media_kit counterpart; its `on_load` lookup is out of range and swallowed there, harmless
  because only `open` ever reloads an entry.
- **`setNext`:** the append carries `start=0` (`loadfile … append -1 start=0`): an appended entry has no media_kit
  counterpart, so the previous entry's resume offset would otherwise apply to it. Promote first if mpv already moved on; `loadfile append`; re-read: idle drops the
  append; the old next is removed only after the new one is in. After each promotion the entries
  before the playing one are removed, so the playlist holds at most two.
- **Tracker rules** (`mpv_playlist_tracker.dart`, pure, driven by `MpvSnapshot`): entries are matched
  by mpv entry id, never by path. Promote only when mpv plays the handed-over id. An entry failed iff
  mpv left it without ever reporting a duration; idle with a next queued fails the current only if
  it never loaded, and the next. A promoted entry re-reports its duration.
- **Test engines:** `SilentAudioEngine` (no native library, synthetic 180 s duration, ticks only
  while playing) is the default under `flutter test` (`FLUTTER_TEST=true`) through
  `audioEngineFactoryProvider`. `test/playback/support/fake_audio_engine.dart` is the scripted one.
  The libmpv smoke test runs only with `KANARU_MPV_SMOKE=1` (`ao=null`).

## Player controller

`state/player_controller.dart` implements `PlaybackCommands` and adds transport (`play`, `pause`,
`playPause`, `stop`, `next`, `previous`, `playEntry`, `seek`, `seekRelative`, `setVolume`,
`setShuffle`, `reshuffleUpcoming`, `setRepeat`, `cycleRepeat`) and queue edits (`remove`,
`cleanup`, `undo`, `move`).

- **One chain** (`command_chain.dart`): UI commands, media-control commands and engine events run in
  call order. A task that runs another task of the same chain asserts in debug. After the last
  queued task the chain runs the reconcile once, so ten taps on Next give one `load`.
- **Completion:** a command's future completes after validation and persistence, never after the
  engine load. Validation errors (`ArgumentError`, `RangeError`) leave the state untouched. Memory
  changes only after the database accepted the edit. `playNext([])` and `enqueue([])` do nothing;
  on an empty queue they behave like `playTracks(context: queue)`.
- **Reconcile:** resolve the current entry (unplayable entries are skipped forward, one
  `TrackSkipped` notice per run; not while `restoring`), then `load(current, next)` when the entry
  changed or a reload is forced, else `setNext` when the wanted next differs from `_handedNext`, then
  play or pause to match the intent. Entries are resolved in windows of 50 (one query), so skipping
  many dead entries costs a few lookups. The next entry is the following one (the same entry under
  repeat one, the first one under repeat all); unplayable or failed entries after the current are
  passed over (looking at most 50 ahead), and the skip is announced when the engine arrives. `seek`
  and `setVolume` do not trigger a reconcile.
- **Position:** a load starts at `_startAt`, set by commands (a jump, an undo, a restore), never at the
  live position. Ticks are ignored while a reload is pending and until the new token reports it
  opened, so an old file's tick cannot become the next start.
- **Tokens:** `_generation` and `_handoff` are the controller's counters; `_loaded` is the token the
  engine plays, `_handedNext` the last next given to the engine. Events of another generation are
  dropped. `Advanced(t)` means the current entry C finished. It is accepted when `t` is the handed
  next, or the entry that now follows C. Otherwise the entry after C in the queue as it is now loads at
  position 0 (a next that was replaced or removed meanwhile). C is never played again. A pending
  reload (a jump, a removal of C) wins over the event.
- **Failures:** `Failed` posts `TrackFailed`. A failed current entry moves on to the next one. A failed
  next means mpv is empty: the failed entry becomes current, is skipped, and the one after it loads, so
  playback continues. After one failure per queue entry in a row the intent becomes stopped. A user
  action resets the counter. `Ended` with repeat off pauses the engine and the intent at the end of the
  last entry (the entry stays current; Play starts it over; an entry added later waits paused). A seek
  back from the end makes a second `Ended` possible.
- **Intent** (`PlayIntent`: playing, paused, stopped) is the only source of play/pause. Stop empties
  the engine and gives focus back; the entry stays.
- **Audio focus:** every transition to playing awaits `PlaybackFocus.activate()` (2 s timeout = denied).
  Denied: the intent stays paused and `FocusDenied` is posted. `playbackFocusProvider` grants
  everything until the media-controls bridge overrides it.
- **Undo:** `remove`/`cleanup` return an `UndoToken`; `undo` works for 4 s and only for the latest
  token; replacing the queue drops it. It restores ids, keys, the current entry and the position. If
  the removal emptied the player (intent stopped), the intent comes back from the token.
- **Streams:** `nowPlaying` and `queueView` are replay-1 and distinct; `position` ticks apart from
  `nowPlaying`; `notices` is a broadcast stream of `PlaybackNotice`.
- **Providers:** `playerControllerProvider` (reads, not watches, its dependencies, so a later override of
  the focus provider cannot dispose the controller; created by `nowPlayingProvider` or a command; the engine is made
  on the first load), `playbackPositionProvider`, `queueViewProvider`, `playbackNoticesProvider`,
  `queueRemainingProvider` (one `SUM(duration_ms)` query after the current entry; re-run on queue
  changes at once and on `tracks` changes after 1 s).
- **Tests without a database:** a bare `ProviderContainer` has no `appDatabaseProvider`, so
  `nowPlayingProvider` is in an error state, `isCurrentTrackProvider` is false and no engine is made.
  Widget tests that need playback state override `nowPlayingProvider` or use the app harness.
- **Debug bound:** `playTracks` with 20 000 entries stays under 2 s in debug (test). The profile-mode
  budget (150 ms of UI-isolate work) is not measured yet.

## Settings keys

Pure `Setting<T>` constants in `playback/domain/playback_settings.dart`; one top-level
`settingNotifierProvider` per key a widget watches in `playback/state/playback_settings_providers.dart`
(`shuffleSettingProvider`, `repeatSettingProvider`, `volumeSettingProvider`, `npTabSettingProvider`).
The UI only reads them. Every change goes through a player controller command, which writes
`SettingsStore` (single writer). A bad stored value reads as the default.

| Key | Setting | Holds |
|---|---|---|
| `playback.queue.current_entry` | `currentEntrySetting` | `entryId` of the loaded entry (null = none) |
| `playback.position_ms` | `positionMsSetting` | Last saved position, ms (default 0) |
| `playback.shuffle` | `shuffleSetting` | Shuffle on or off |
| `playback.repeat` | `repeatSetting` | `'off'`, `'all'` or `'one'` |
| `playback.context` | `contextSetting` | `{kind, ref, label}` of the `PlayContext`; an unknown kind reads as `queue` |
| `playback.volume` | `volumeSetting` | 0-100 (default 100; out of range is clamped) |
| `playback.np_tab` | `npTabSetting` | `'lyrics'` (default) or `'queue'` (last tab of the Now Playing panel) |

## Flush

Lane B registers one flush hook from `screens/now_playing/now_playing_registration.dart`
with `registry.addFlushHook`. It saves the position and writes the in-flight
listen to `play_log`. Flushes run on pause and on exit (see
[ARCHITECTURE.md](../ARCHITECTURE.md#flush-and-exit)).

`play_log` has no entry column (it holds `track_id`, `context_kind`, `context_ref`): attribute the listen to the track of the entry current at event time. `device_id` comes
from `deviceIdProvider`, which is fixed at bootstrap.

## Rules lane B keeps

- Validate before any state change.
- Restore the queue paused. Clamp the saved position against `tracks.duration_ms`.
  Do not rewrite the queue until a track loads or the user acts.
- A dangling `playback.queue.current_entry` falls back to the first entry.
- A queued track that became `missing` or `hidden` is skipped, with a toast.
- The engine owns the advance after an error, one error per entry.
- Media controls: one `update` call per track change with the complete tag set;
  drop empty strings; `artUri` is `file://` only (the `full` cover file).
- Keep the Rescan, Keymap and AI buttons, the page-header search scope, the
  flush seam and the selection bar slot in the shell.

## Old app references

The old prototype (retired repo, code only) implemented the same pieces. Read
these before changing the design:

| Area | Old code |
|---|---|
| Player and queue | `lib/core/player/player_service.dart`, `play_queue.dart`, `player_queue_commands.dart`, `mpv_playlist_tracker.dart`, `gapless_sync.dart` |
| Media controls | `lib/core/media_controls/media_controls.dart`, `lib/core/media_controls/mpris/` (`mpris_media_controls.dart`, `mpris_properties.dart`, `mpris_bus_name.dart`) |
| Waveform | `rust/src/waveform_job.rs` |

Pitfalls the old app hit, and where the design answers them:

- First play stalled on a whole-tree rebuild. Answer: narrow `select` providers;
  no position in `NowPlaying`.
- Shuffle re-sent the whole list and cut the current track. Answer: the queue is
  owned in Dart; `shuffle_key` reorders only upcoming entries.
- The same file queued twice broke "current"; "play next" meant move in one menu
  and copy in another. Answer: entry identity; `playNext` always inserts.
- An engine error skipped two or more tracks. Answer: the engine owns the advance.
- Restore raced user commands; a saved position at or past the end hit EOF at
  once; a missing drive wiped the saved session. Answer: restore paused, clamp,
  never rewrite the queue before a load.
- Exit lost the position and the in-flight listen. Answer: the flush hook.
- Listen rows keyed by "current" got the wrong track in gapless playback. Answer:
  key by the entry at event time.
- MPRIS commands overlapped and D-Bus handlers threw. Answer: one serial queue.
- Metadata was sent twice per change, `xesam:album` was missing and empty
  strings were published. Answer: one snapshot call, a complete key test.
- `artUri` leaked a proxy URL and token. Answer: `file://` only.
- The bus name clashed between debug and release builds and hot restarts.
  Answer: `org.mpris.MediaPlayer2.kanaru_community`, with the `.instance<pid>`
  fallback (see [ARCHITECTURE.md](../ARCHITECTURE.md#platform-identifiers)).
