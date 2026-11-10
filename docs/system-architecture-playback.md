# Playback

> Owner: lane B (playback). The command, now-playing and provider
> declarations below are frozen contracts; the bodies are the player.

## Contents

- Commands and now playing: this file.
- Queue table and its helpers: this file.
- Queue model, persistence, playable resolver, play log writer, settings keys: this file.
- Restore, position saves, listens and the exit flush: this file.
- Media controls (MPRIS, `audio_service`) and audio focus: this file.
- Waveform (Rust decode, cache, loader, seek bar): this file, section Waveform.
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
- **`setNext`:** promote first if mpv already moved on, then append with `loadfile <uri> append` (`mpv_append.dart`), the only form valid on every mpv: 0.35 (Android's libmpv) reads the third argument as options and rejects `append -1 start=0`, and from 0.38 it is the index, which rejects `append start=0`. mpv reports a rejected command through its log, never by throwing, so the append is verified: `playlist-count` must grow by exactly one and the new entry id must differ from the current one (the tracker refuses such a next too). The resume offset of the entry before the append can leak into the appended one (it has no media_kit counterpart), so after the first advance `undoLeakedStart` seeks back to 0 when the position is at the offset and the user did not seek. Re-read: idle drops the append; the old next is removed only after the new one is in. After each promotion the entries before the playing one are removed, so the playlist holds at most two.
- **Failed append:** logged at WARNING, no next is handed, and the current entry is not failed (it plays fine). A previous next still in mpv is removed so it cannot advance. At the end of the current entry the tracker reports `Ended`, and the controller loads the entry that follows (a non-gapless advance) instead of finishing the queue.
- **mpv log:** the engine logs mpv's `warn`/`error`/`fatal` messages and its error stream at WARNING (`PlayerConfiguration.logLevel` is `warn`), so a rejected command shows in logcat.
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
  Denied: the intent stays paused and `FocusDenied` is posted. The focus is the media-session bridge
  (see Media controls); a test overrides `playbackFocusProvider`.
- **Undo:** `remove`/`cleanup` return an `UndoToken`; `undo` works for 4 s and only for the latest
  token; replacing the queue drops it. It restores ids, keys, the current entry and the position. If
  the removal emptied the player (intent stopped), the intent comes back from the token.
- **Streams:** `nowPlaying`, `queueView` and `transport` (`TransportView`: intent and volume, which tell
  a stop from a pause) are replay-1 and distinct; `position` ticks apart from `nowPlaying`; `seeks`
  carries the position after each explicit seek; `notices` is a broadcast stream of `PlaybackNotice`.
- **Providers:** `playerControllerProvider` (reads, not watches, its dependencies, so a rebuild of the
  focus provider cannot dispose the controller; it asks focus through the provider's current value and
  attaches a rebuilt media bridge again; created by `nowPlayingProvider` or a command; the engine is made
  on the first load), `playbackPositionProvider`, `queueViewProvider`,
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
(`shuffleSettingProvider`, `repeatSettingProvider`, `volumeSettingProvider`).
The UI only reads them. (`shell.right_panel` is the shell's own key, see UI: widgets and shell.) Every change goes through a player controller command, which writes
`SettingsStore` (single writer). A bad stored value reads as the default.

| Key | Setting | Holds |
|---|---|---|
| `playback.queue.current_entry` | `currentEntrySetting` | `entryId` of the loaded entry (null = none) |
| `playback.position_ms` | `positionMsSetting` | Last saved position, ms (default 0) |
| `playback.shuffle` | `shuffleSetting` | Shuffle on or off |
| `playback.repeat` | `repeatSetting` | `'off'`, `'all'` or `'one'` |
| `playback.context` | `contextSetting` | `{kind, ref, label}` of the `PlayContext`; an unknown kind reads as `queue` |
| `playback.volume` | `volumeSetting` | 0-100 (default 100; out of range is clamped) |

## Restore

The controller's first chain task (`player_controller_session.dart`, `session_restore.dart`) reads the
saved session; commands made meanwhile queue behind it and apply to the restored state.

- `loadSession(repo, settings)` returns null for an empty queue. It reads `queue_entries` in the saved
  shuffle order and the `playback.*` keys; it never writes. The current entry is the saved one; an id
  that no longer exists falls back to the first entry at position 0. A position at or after
  `duration_ms - 1 s` restores as 0. A context that cannot be read becomes the plain `queue`. The
  volume comes back with the session.
- The entry loads **paused**, `Media(uri, start: position)`, through the normal reconcile.
- **Frozen:** until the restored file reports a duration, or the user starts something (play, a new
  queue, next/previous, a seek on a loaded file, undo, removing the current entry), nothing about the
  position, the current entry or the context is written (`PositionSaver.frozen`, the controller's
  `restoring`). An unplayable restored current stays current: no skip, no write, no notice. The same holds
  when the library lists the file but the engine cannot open it (drive unplugged, file moved): the
  failure is swallowed, the rest of that load's events are dropped, and nothing walks through the queue.
  A user Play lifts the freeze, retries the file once, then skips forward with a notice. A missing drive therefore keeps the good session.

## Position saves

`state/position_saver.dart` keeps the controller's last entry, context and position, and writes
`playback.position_ms` right away on pause, seek, track change and stop, and again every 15 s of progress
while playing (tick-driven, no timer, on every platform; the store coalesces writes). A crash or an OEM
kill therefore loses at most 15 s; a normal Linux close is covered by the exit flush.
The controller's position follows engine ticks only while playing (a paused open reports a stray 0).

## Listens

`domain/listen_accumulator.dart` (pure) and `state/listen_recorder.dart`.

- One accumulator per full `EngineToken` (entry, generation, handoff), so each loop of repeat one, each
  pass over a one-entry queue with repeat all and each side of a gapless advance is its own listen.
- Time counts between two playing samples whose position moved forward; a position jump beyond the
  clock by more than 1 s (a seek) counts only the clock time. The track length is locked at the first
  value seen (gapless reports the next track's length at the end).
- A listen counts when the track is longer than 30 s and was heard for half of it, at most 4 min
  (kept below the length minus 1 s). `played_at` is the wall time of the load's first playing sample.
- The row is inserted when the listen counts; `listened_ms` is updated every 10 s of listening, on
  pause, when the load changes (final value) and on flush. `context_kind`/`context_ref` come from the
  `PlayContext`, `device_id` from `deviceIdProvider` (read when a row is written).
- Writes run on the recorder's own `SerialChain`, are never awaited by a command, and a failed write is
  logged; a row is never inserted twice. Skips write nothing.

## Flush and exit

`screens/now_playing/now_playing_registration.dart` registers three hooks:

- `addBeforeExitHook(pausePlaybackOnExitHook)`: pauses the controller (exit only, before the normal
  flush, within half the 2 s cap). It goes through the chain, so a command stuck on the engine leaves
  it running in the background; a pause racing the flush is harmless.
- `addFlushHook(playbackFlushHook)`: does nothing (and creates nothing) if the controller does not
  exist. Otherwise it writes `playback.position_ms`, `current_entry` and `context` from the saver's
  last snapshot (not when frozen), calls `SettingsStore.flush()`, then flushes the open listen through
  the recorder's own chain (so a busy database cannot delay the position). It never waits on the
  command chain.
- `addStartupHook(mediaSessionStartHook())`: `initAndroidMediaSession()` with a 3 s timeout and a
  catch; Android only, returns at once elsewhere; a failure is logged and never stops bootstrap.

On Linux the window-close guard runs the exit flush on close (hide, flush within 2 s, destroy).
Flushes also run on pause and hide (see [ARCHITECTURE.md](../ARCHITECTURE.md#flush-and-exit)).

`play_log` has no entry column (it holds `track_id`, `context_kind`, `context_ref`): the listen belongs
to the track of the entry whose token the accumulator was made for.

## Media controls

`platform/domain/media_controls.dart` (pure): `MediaControls` with `start`, `update(item, state)`,
`updatePosition`, `seeked`, `commands`, `activate`, `deactivate`, `dispose`; `MediaControlsItem`
(id = queue entry id, title, artists, album, duration, `file:` art), `MediaControlsState` (equality
ignores the position) and the sealed `MediaCommand` (`Play`, `Pause`, `PlayPause`, `Stop`, `Next`,
`Previous`, `Seek(offset)`, `SetPosition(id, position)`, `SetShuffle`, `SetRepeat`, `SetVolume`).
`updatePosition` is silent: the live position for readers that ask (MPRIS `Position`); it is never
signalled.

`playback/state/media_session_bridge.dart` (`MediaSessionBridge`, also the `PlaybackFocus`):

- Follows the controller's plain streams (`nowPlaying`, `queueView`, `transport`, `position`,
  `seeks`), not Riverpod providers. Changes are coalesced (150 ms) into one `update`, diffed against
  the last one. Ticks update the stored position only. A seek waits for any update already running, sends the pending
  changes, then calls `seeked`.
- The item comes from `loadTrackInfos`; the art is the `full` cover file under the cache folder, only
  when the file exists. The length is the engine's once loaded.
- `start()` runs on Linux as soon as the restored session has a current entry (media keys and
  `playerctl` work after launch), and on any platform at the first play. `AppShell` creates the
  controller after its first frame (an explicit `ref.read(playerControllerProvider)` in a post-frame
  callback, for both shells), so the restore and MPRIS start at launch without a tap on the mini player.
  Android keeps
  `processingState: idle` (no notification) until something played.
- Commands go through the controller's chain (`Seek` is `seekRelative`; `SetPosition` is ignored for
  an entry that is no longer current). A request that came before the controller existed is held by the
  platform's command buffer (Android) and arrives after the attach.
- Focus: `activate()` asks the controls with a 2 s timeout (timeout = denied); `deactivate()` on stop.
- `mediaSessionBridgeProvider` builds it; `playbackFocusProvider` is the bridge; `mediaControlsProvider`
  picks the implementation (MPRIS on Linux, the audio service on Android after its startup hook, a no-op
  elsewhere and under `flutter test`).

### Linux: MPRIS (`platform/data/media_controls/mpris/`)

- `org.mpris.MediaPlayer2` and `.Player` on `/org/mpris/MediaPlayer2` over `dbus`. Bus name
  `org.mpris.MediaPlayer2.kanaru_community`, then `.instance<pid>`, then `.instance<pid>_1` to `_5`,
  always with `doNotQueue` (without it the bus queues and never refuses). None free: idle and one
  log line.
- Root: `Identity` Kanaru, `DesktopEntry` `io.github.kanaru313.kanaru_community`, `CanRaise`,
  `CanQuit`, `HasTrackList` false, empty scheme and MIME lists.
- Player: `PlaybackStatus` (Stopped comes from the app state), `LoopStatus`, `Shuffle`, `Volume`,
  `Rate`/`MinimumRate`/`MaximumRate` 1, `Position` (microseconds, live), `Can*`, `CanControl`.
  Metadata keys: `mpris:trackid` (object path of the entry), `mpris:length` (only when > 0),
  `xesam:title`, `xesam:artist` (array), `xesam:album`, `mpris:artUrl` (`file://` only, `#` and other
  characters escaped); empty strings are left out.
- Every handler is guarded and replies at once; a throw answers `Failed`. Methods check their
  signatures (`InvalidArgs`) and post a command. `Seek` past the end is `Next`, before the start goes
  to the start, `SetPosition` is ignored for another track id or a position outside the track.
  `Set`: `LoopStatus`, `Shuffle`, `Volume` are validated; `Rate` 1 is accepted, 0 pauses, anything else
  is `InvalidArgs`; other properties are read-only.
- Introspection marks `Position` and `CanControl` with `EmitsChangedSignal=false`; `Position` is never
  in `PropertiesChanged`. `Seeked` goes out after pending properties.
- `start()` never throws: the connect is bounded to 3 s, a client that cannot be built or a missing bus
  leave the controls idle. A connection that finishes after the timeout releases its name and closes. The first failed send marks the bus as lost. Dispose bounds each step to 1 s
  and is never awaited on the exit path.

### Android: `audio_service` and `audio_session`

- `initAndroidMediaSession()` (startup hook, once per process) runs `AudioService.init` with the
  `drawable/ic_stat_kanaru` icon, channel `io.github.kanaru313.kanaru_community.playback`, and
  configures the audio session for music. `AndroidMediaHandler` maps `play/pause/stop/skip*/seek/
  setShuffleMode/setRepeatMode/click` to commands; headset `click` is `PlayPause`.
- `AndroidMediaControls.update` publishes the `MediaItem` and a `PlaybackState` (previous, play or
  pause, next; the seek action; `idle` until started). Identical updates publish nothing.
- **Audio focus:** `activate()` = `setActive(true)`, before every transition to playing (denied: stay
  paused with a `FocusDenied` notice); `deactivate()` on stop. Becoming noisy pauses. An interruption
  that asks for a pause pauses and remembers it only if playback was running; its end with "resume"
  plays again. A user pause before or during the interruption is never undone. Ducking is left to
  the system.
- Commands that arrive before anyone listens are held (the last, if younger than 10 s) and replayed to
  the first listener (`CommandBuffer`).
- Not covered by tests, checked on the phone later: the notification on Android 13, lock screen,
  headset and Bluetooth buttons, focus taken from another app, calls and alarms, cold start from the
  notification.

## UI: widgets and shell

Playback widgets and where each lives (UI layers import `state/`, never `data/`; no width APIs in
`playback/ui` or `screens/`, width logic is in `kanaru_ui` and `shell/`):

| Widget | Where | Notes |
|---|---|---|
| `KProgressLine`, `KSeekBar`, `KToggleIconButton`, `CoverTintBackground` | `packages/kanaru_ui/.../widgets/media/` | Flat 2 dp line; flat 4 dp seek bar (tap, drag, Left/Right 5 s, `onSeek` once per drag); toggle with a dot when on; cover gradient (alpha-only fade when the colours go). No app imports. |
| `MiniPlayer({onOpen, onOpenQueue})` | `playback/ui/mini_player.dart` | Mobile, 64 dp. Tap/Enter/Space or swipe up > 30 dp open; long press 500 ms (cancelled by a 10 dp move) gives a haptic and opens the queue. Only `_Progress` listens to the position. |
| `PlayPauseButton`, `NextButton`, `PreviousButton`, `ShuffleButton`, `RepeatButton` | `playback/ui/` | Watch narrow providers; call the controller with `ref.read` on tap. |
| `PlaybackTimeLabel`, `PlaybackSeekBar`, `VolumeControl` | `playback/ui/` | Labels select whole seconds. Volume is the persisted setting; mute remembers the last level. `PlaybackSeekBar` is the flat bar (mini player, player bar); `PlaybackWaveformSeekBar` is the Now Playing one (see Waveform). |
| `FavoriteButton(trackId)` | `screens/now_playing/ui/` | `isFavoriteProvider` + `favoritesControllerProvider`. |
| `PlayerBar` | `shell/ui/player_bar.dart` | Desktop, 88 dp, under the page. Left part < 1000 dp: no volume, sleep timer, heart; < 760: no shuffle/repeat. Lyrics, cover and expand open Now Playing (the bar is offstage while it is open); Queue toggles the shell's right panel and is tonal while it is open. The heart sits right after the title/artist block (the text takes only the width it needs; user decision, matches 02) and goes with the volume and sleep timer under 1000 dp. |
| `PlaybackNoticeListener` | `shell/ui/` | Wraps both shells. `AppShell` creates the player and calls `start()` in the same post-frame callback, so no notice falls between the two (a test or another host leaves `autoStart` on and it starts after its first frame). Listens for good, track or not, so a notice raised as the last track goes is not lost; the child never moves. Only the remove/undo toast belongs to the UI action (the controller emits no notice for it). "Queue is empty" (Play or play/pause with nothing queued, also from media keys and MPRIS) comes from the controller like the other notices. The listener subscribes to the controller's `notices` stream directly, so the same notice twice in a row shows twice. |
| `NowPlayingPanel` | `playback/state/now_playing_panel.dart` (one import path; no re-export) | `{open, covered}`. `covered` makes the desktop left region `Offstage`; `close()` clears it. |
| `RightPanel` | `shell/state/right_panel.dart` | `closed`, `queue` or `chat`; one at a time. `show`, `toggle`, `close`; every change is stored in `shell.right_panel` and read back at the next launch (chat last time but no chat surface in this build: starts closed; a chat request without a surface is ignored). `chatPanelSurfaceProvider` is the extension registry's `PanelSurface` with id `chat` (`registry.panelSurface('chat')`); the public build registers none, so it is null there and the AI button is dimmed; a Pro extension adds the surface with `addPanelSurface(PanelSurface(id: 'chat', order, body, menu?))`. |
| `RightPanelHost` | `shell/ui/right_panel/` | 420 dp, no drag handle, header (name, the chat's own ⋮, ✕) over `QueuePanel(host: panel)` or the chat body. Opening from closed and closing do not animate; switching slides the content sideways in top-bar button order (Queue to Chat left, Chat to Queue right, 340 ms, `AnimatedSwitcher`; none under reduced motion). |
| `DesktopHistoryInput` | `shell/ui/desktop_history_input.dart` | Alt+Left/Right and mouse Back/Forward walk `NavHistory`; Esc goes back unless a text field is focused. `interceptBack` is asked first for Esc and the mouse Back button: the shell passes "close Now Playing", so an open screen closes before history moves. |
| `MobilePushLayout`, `MobileSidebar` | `shell/ui/` | Push sidebar (256 dp) driven by `KSpring.gentle`; open state in `mobileSidebarOpenProvider`. |

Rules:
- Nothing in `shell/` reads `playerControllerProvider` while building. The shell reads it once, after the
  first frame, and buttons read it on tap.
- `MiniPlayer` appears when `hasCurrentTrackProvider` is true; with no track there is no mini player and
  no player bar.
- Desktop layout: `DesktopHistoryInput > Column[top bar, Row[Expanded(Stack[Offstage(left region),
  Now Playing overlay]), RightPanelHost]]`. Now Playing covers only the left region; the right panel is a
  sibling of that Stack and stays visible and tappable while the left region is covered. The left part
  shrinks by 420 dp and stays the desktop layout (the form factor follows the whole window). When the
  left part is under 1000 dp the sidebar is forced to its 72 dp rail whatever the toggle says, and the top bar sidebar toggle is dimmed meanwhile (it would flip a state that shows nothing; the ☰ drawer is not built yet).
  Top bar: a Queue button (tonal while the queue panel is open, Ctrl+Shift+Q) next to the AI button (tonal
  while the chat is open, Ctrl+J; dimmed "Coming soon" when the build has no chat and no registered top
  bar action). The shortcuts are taken by the shell's global key handler and work while Now Playing is open.
- Key handling: Alt+arrows are taken by the shell's global key handler (a text field would keep them);
  Esc is taken there only when nothing in the shell has focus, otherwise by the focus-tree handler. Focus in
  a dialog, sheet or popup menu route disables both, and the mouse buttons too. A `MenuAnchor` menu that
  has not taken focus is not detected for the mouse buttons.
- `MobilePushLayout` starts where `mobileSidebarOpenProvider` is (the state outlives the shell across the 1200 dp swap). While `covered`, the left region is also `ExcludeFocus` and Ctrl+F/K do nothing. Only the mini player body takes the long press; it also exposes "open Now Playing" and "queue" as custom semantics actions.
- Mobile Back order: sidebar, top layer, child page, tab root to Home (`MobileShell` listener), then exit.
- Widget tests that run controller commands from a widget callback must alternate real delays and pumps
  (`UiHost.tap` runs the tap in the real zone and settles; `UiHost.letStreamsArrive` alternates for streams); the controller keeps the zone it was built in.

## Queue UI

The queue content is shared by the mobile sheet and the desktop right panel. Widgets live in
`playback/ui/queue/` (no library imports); the row menu, the ♥ and navigation to the library live in
`screens/now_playing/ui/` (`queue_row_menu.dart`, `queue_row_trailing.dart`, `track_navigation.dart`) and are handed
to the list as hooks (`QueueRowMenu`, `QueueRowTrailing`). `QueuePanel(host: sheet | panel)` composes them. On the panel the shell draws the header ("Queue" and ✕); `QueuePanel` adds the line under it: counts left (`N tracks · time left`; the tooltip has the playing position, and the whole line first when the panel cut it short; 40 dp action buttons with 8 dp between them, about 164 dp for the line), Shuffle, Add tracks (soon), Clean up, Save as playlist (soon) | ⋮ right, no footer.

- **List** (`queue_list.dart`): one `ReorderableListView.builder`, fixed row extent (mobile 60, desktop 72), keys by
  entry id, `buildDefaultDragHandles: false`, bottom padding 72. A drop is resolved by the dragged entry's id, not by
  the index the list reports, so an edit during the drag cannot move another entry. `QueueScrollController` keeps the
  start offset inside the content (a short queue starts at the top). On open the current row is the second visible.
- **Rows** (`queue_row.dart`): current = `secondaryContainer` fill plus `KEqualizerIcon` over the cover (pause glyph
  when paused); played rows have text and cover at 50 %; tap plays (the current row ignores it); Enter and Delete on a
  focused desktop row play and remove. A row whose info has not loaded draws a placeholder of the same height.
- **Row infos** (`state/queue_row_infos.dart`): `TrackInfo`s are loaded for the viewport ± 50 rows into a 1 000-entry
  LRU; the window is O(1) from the scroll offset. A `tracks` change reloads only the last window, 1 s after the last
  change. Rows read their own entry with a `select`. The header time ("còn …") is `queueRemainingProvider`.
- **Remove** (`queue_swipe_remove.dart`, `queue_remove_action.dart`): a horizontal drag past 40 % of the row (either way)
  slides the row out and removes it; the row fades, a red `delete` icon shows on the free side. Trackpad pans are
  ignored. It is not a `Dismissible` because that one wants the row gone in the same frame while the removal is
  persisted first. The toast ("Removed …" / "Removed N tracks", Undo, 4 s) is shown from the root navigator's context,
  so it survives the host closing; undo never reopens a closed host. The player emits no notice for a removal, so there is
  one toast. Removing the last entry calls `onEmptied`.
- **Locate button** (`queue_locate_button.dart`): 48 dp, bottom right, only while the current row is out of view; arrow by
  direction; rebuilds only when the side changes.
- **Actions** (`queue_actions.dart`, `queue_header.dart`): Shuffle (reshuffles the upcoming and turns shuffle on), Add
  tracks and Save as playlist (dimmed "Coming soon"), Clean up (`MenuAnchor`, four choices with counts worked out when
  it opens; 0 = dimmed; opens up on the sheet, down on the panel; the toast counts what the controller removed when the choice ran, not what the menu promised), ⋮ (only a dimmed "Select several").
- **Row menu** (`screens/now_playing/ui/queue_row_menu.dart`): Play this | Play next (queues a **copy**) | Go to album,
  Go to artist (a `showSelectionPicker` when the track has several artists), Ask AI (dimmed) | Remove. A popup at the
  pointer on the panel, a sheet on mobile (long press). Every action first checks the entry is still queued ("That track is
  no longer in the queue"). Keep its item set in line with lane C's song menu.
- **Undo** restores the entry that was current at removal time only if that removal took it out; if the player moved on
  meanwhile, the live current entry stays.

## Now Playing mobile

Route `/now-playing` (`screens/now_playing/now_playing_registration.dart`, path in `now_playing_path.dart`), a top-level
route above the shell. It slides up with the `bouncy` spring played as a curve over a 500 ms route, stopped at the top edge (an overshoot would uncover the page below); it slides down on an ease-in curve over 300 ms (a fade under reduced motion). The mini player opens it by `context.push`; the mini player's own tap, swipe and Enter all call the same
`onOpen`.

- `NowPlayingPage` picks what to show. At desktop width, or with no track, it leaves once (guarded by a flag, after
  the frame); at desktop width it first calls `nowPlayingPanelProvider.open()`, so a resize drag across 1200 dp ends
  with the panel open and no route. While the player has not answered yet it does not leave. The panel state lives in
  `playback/state/now_playing_panel.dart` so `screens/` can reach it.
- `MobileNowPlaying` (`ui/mobile/`): header (56) with a drag-to-close title area (release past 120 dp closes, less
  springs back), cover, title row, `NowPlayingSeekSlot` (48 dp; flat bar for now), controls, button row, dimmed lyrics
  card, info card. It sits on `CoverTintBackground` fed by `coverColorsProvider`; the colours never reach the app theme.
  It owns a `FlightSource` (cover, text, play, next pieces) for the queue flights.
- The cover box is `kanaru_ui` `NowPlayingCoverBox` (`min(420, width - 64)`, radius 20); the page gives it the full
  width and pads the other rows.
- `CoverSwiper` is a plain widget (entry id, has previous/next, callbacks): left = next, right = previous; 25 % of the
  cover width or a fling over 160 dp/s commits; where there is no track to go to the cover moves at most 30 % and
  springs back (the buttons raise the notices). With repeat all the last entry's left swipe wraps to the first, like Next. The new cover slides in when the entry id changes; if it never does, the
  cover comes back after 800 ms.
- `NowPlayingMoreSheet` (⋮): the head and `nowPlayingMoreItems`, shared with the desktop dropdown. Only Go to album and Go
  to artist work; the rest is dimmed "Coming soon", Visual effects carries the Pro badge. `track_navigation.dart` goes
  through `LibraryLocations` with `context.go`, and asks which artist first through `showSelectionPicker`.
- The source line is `playContextText`: kind prefix plus the label captured when playback started. It opens nothing.

## Queue sheet and flights (mobile)

`showQueueSheet(context, from: FlightSource)` (`screens/now_playing/ui/mobile/queue_sheet.dart`) pushes a `PopupRoute`
on the root navigator, so Back pops the sheet before Now Playing, and Now Playing before the shell. The route covers the
screen: the cover tint, a strip at the top (cover 72, title and artist, play/pause 56, next 48), and the sheet below it
(radius 28, grip, `QueuePanel(host: sheet)`), fixed height from under the strip to the bottom. Opened by the Queue button
of Now Playing and by a long press on the mini player (any screen; Now Playing is not opened). The Queue nav item is a dimmed "Coming soon" on both shells (saved queues).

- **Flight** (`KSharedFlight`, `kanaru_ui`): four layers (cover, text, play, next) go from the source's rects to the strip
  rects as the progress goes 0 to 1. Progress = route animation (420 ms) x (1 - pull); a pull on the grip or head is
  `pulled / 240`. A layer with no readable source rect, or any layer under reduced motion, fades in instead. Layers live in
  one `Stack` with a `RepaintBoundary` each. The strip geometry and the page measurement are `kanaru_ui`
  (`KQueueStripGeometry`, `KFlightStage`), because `screens/` has no width APIs.
- **Source** (`playback/ui/flight_source.dart`): `FlightSource` has a key per piece and a `hidden` flag. The surface wraps
  its pieces in `FlightPieceHost`, which draws them invisible (still laid out, so the rect stays readable) while the
  route exists. Under reduced motion the sheet fades in place instead of sliding. Now Playing makes its own source; the mini player's is `miniPlayerFlightProvider`.
- **Close**: chevron, a tap on the strip (cover, title or empty), Back, or a pull on the head of more than 100 dp (99 dp
  springs back with `KSpring.gentle`). The flight runs in reverse with the route; a pull in progress carries on from where
  the finger left it. Scrolling the list never moves the sheet (only the grip and head are drag handles).
- **Last entry removed**: `onEmptied` closes the sheet; Now Playing leaves by itself (no track) and the mini player
  disappears. Undo does not reopen anything.
- **Not measured yet**: frame times of the flight in profile mode on Linux and on the phone (only the widget tests ran).

## Now Playing desktop

A port of the old app's screen (`~/dev/kanaru/lib/features/player/now_playing/`), as an overlay of the desktop shell.

- **Overlay** (`shell/ui/desktop_now_playing_overlay.dart`): a child of `DesktopShell`'s left `Stack`, after the left region, so
  it covers the sidebar, the page and the player bar's place, under the top bar, and never the right panel (a sibling of that
  `Stack`). It slides up in 500 ms with the old curve `Cubic(0.65, 0.05, 0.36, 1)` (the one timed curve kept over a spring).
  The screen exists only while the panel is open or leaving. When the slide ends it sets `covered`, and the shell takes the left
  region `Offstage` (state kept, nothing painted); when closing starts `covered` is cleared in the same frame. Under reduced motion
  both are instant. The overlay is pointer-opaque and gives focus back to what had it before. The screen has its own `Scaffold`,
  so toasts show on top of it.
- **Closing**: the chevron, Esc (handled inside the screen's focus scope, before the history input), the mouse Back button and
  Esc with no focus (`interceptBack`), a location change (`DesktopShell` closes the panel after the frame), the shell turning mobile
  (`AppShell` closes the panel and pushes the mobile page once, guarded by a flag; `DesktopShell.dispose` does nothing).
  Widening with the mobile page open is the page's job (see Now Playing mobile).
- **Screen** (`screens/now_playing/ui/desktop/`): `DesktopNowPlaying` (focus, Esc, `V`, tint, transparent `Scaffold`) over
  `DesktopNowPlayingBody` (auto-hiding header, then the split or the side pane alone, 300 ms cross-fade, the outgoing body ignores
  pointer and focus). `V` flips the cover column only with no modifier, no menu open and no text field focused; the choice lives in
  `coverColumnShownProvider` for the session.
- **Header** (`desktop_now_playing_header.dart`, 64 dp): `[⌄] [cover column] | [♥] [add to playlist, soon] [Translate chip, soon]`
  and `[repeat] [sleep timer, soon] [volume] [⋮]`. No Shuffle, no window buttons. The ⋮ menu (`desktop_more_menu.dart`) is the head row
  plus the shared items; while it is open the header stays shown (`floatingOpen`). `now_playing_auto_hide.dart` is the old controller
  as it was: hides after 3 s still, shows on a move (throttled to 300 ms) or any key, pinned while the pointer is on the header or the
  track column or a menu is open, hidden at once when the pointer leaves the window.
- **Split geometry** (`kanaru_ui` `now_playing_split_geometry.dart`, `now_playing_split_layout.dart`): column 42 % of the body clamped
  to 300..600; padding 24 / 16; cover side = min(column inner width, 500, body height - reserve - padding), at least 96; gaps 24 / 16 / 8;
  transport row 52; the text reserve counts two title lines (26 bold), an artist line and an album line under the text scale. The
  reserve is fixed, so a wrapping title or a late album moves nothing; a window too short even for 96 scales the block down
  (`FittedBox`). `DesktopTrackColumn` draws cover (radius 32, shadow), title, artist and album lines (each a link to the library),
  the 48 dp seek slot, and elapsed | previous, play, next | total.
- **Side pane** (`desktop_side_pane.dart`): only the lyrics, titled like one tab with no other tab; the body is a "coming soon"
  placeholder. The queue is not here: it is the shell's right panel (see UI: widgets and shell). The player bar's Lyrics, cover and
  expand buttons open the screen.
- **Queue nav item**: a dimmed "Coming soon" on both shells (saved queues, no mockup yet). The live queue is the right panel (desktop;
  top bar or player bar button) and the sheet (mobile; mini player long press, Queue button of Now Playing).
- **Left out of the port**: the cover-only mode, the lyrics keys `L` and `T`, the narrow tabs layout (it is the mobile page).
- **Waveform**: `NowPlayingSeekSlot` holds `PlaybackWaveformSeekBar` in the same 48 dp slot (see Waveform).

## Waveform

Levels for the Now Playing seek bar on both shells. The mini player and the player bar keep the flat `KSeekBar`.

**Decode** (`rust/crates/kanaru_media/src/waveform/`, no FFI). `compute(source, ext_hint, cancel) -> Waveform { levels, duration_ms }`
with symphonia 0.6 (`next_packet() -> Result<Option<Packet>>`), codecs of the Cargo features: MP3, FLAC, Ogg Vorbis, AAC and
ALAC in MP4, WAV/PCM.
- `decode.rs`: refuses APE, WavPack, DSD, AIFF and Opus before probing (extension, or the first four bytes: `MAC `, `wvpk`,
  `DSD `, `FRM8`, `FORM`); probes with the extension as a hint; first audio track that has a decoder; `Cancel::check()` before
  every packet; a truncated file gives the levels up to its end; `ResetRequired` re-opens the decoder.
- `limits.rs`: sample rate 8 kHz to 768 kHz, 1 to 32 channels, at most 24 h (`TooLarge`), shape fixed for the whole stream, at
  most 32 failed packets in a row and 1000 in total (`Corrupt`). The 60 s deadline of the bridge ends as `Timeout`.
- `levels.rs`: an 8192-slot accumulator, 10 ms per slot at the start; when the slots are full neighbours merge and the window
  doubles, so memory is constant for any length. `finish()`: at most 1000 buckets, RMS per bucket, normalised to the loudest,
  square-rooted, 0..=255 (`u8`); silence is all zeros; under 10 ms is empty.
- Measured: a 5-minute stereo 44.1 kHz FLAC decodes in about 0.28 s on the dev machine (`decode_time_of_a_real_file`, ignored
  test, `KANARU_WAVEFORM_FILE`).

**Bridge** (`kanaru_bridge/src/api/waveform.rs`). `WaveformJob` is an opaque handle (`new()` and `cancel()`, both sync);
`waveform_levels(path, &job) -> WaveformDto { levels, duration_ms }` opens the path with `open_source`, then decodes on
`pools::waveform()` (one thread) inside `guarded`, with the job's flag plus a 60 s deadline. A job cancelled while it waits for
the pool ends before it opens the file. `Cancelled` and `Timeout` are transient; `Unsupported`, `Corrupt`, `TooLarge` and
`Panic` are permanent.

**Cache** (`playback/data/waveform_{codec,cache,repository}.dart`). Folder `<cache>/waveforms/v1/`, one `<sha1>.kwf` per file
version, key `sha1("$path\0$size\0$mtimeMs")` from a `stat`. Layout (little endian): `KWF1` | kind u8 (0 ready, 1 negative, 2 negative from timeouts) |
duration ms u32 | count u16 | levels, so about 1 KB. Written to a temporary name and renamed; a damaged file is a miss and is
rewritten; a hit touches the mtime ("last used"). Sweep once per run, at the first load: above 20 000 files delete the least
recently used down to 18 000. The sweep also deletes `.kwf.tmp*` files older than an hour (a write that never finished).
`WaveformRepository.load(path)` returns a `WaveformLoad { result, cancel() }`:
- `Ready(levels, durationMs)`: cached. A track under 10 ms (no levels) becomes `NoWaveform`.
- `NoWaveform`: a permanent kind (`Unsupported`, `Corrupt`, `TooLarge`, `Panic`), cached as a negative so the file is not decoded again.
- `RetryLater`: never cached. Cancelled, timed out, a transient error, a missing or unreadable file, a library that did not start.
- A Dart-side timeout (20 s plus the file size at 8 MiB/s, capped at 55 s, under the native 60 s deadline; the size stands for the duration) calls `job.cancel()` (frees the native thread at the next packet) and gives `RetryLater`. Two timeouts in a row for the same file version (a native `Timeout` counts like a Dart one) cache a negative of kind 2, which stores its write time (in the duration field) and is a miss after 7 days, so a later view tries again. Negatives from `Unsupported`, `Corrupt`, `TooLarge` and `Panic` never expire.
- One native job at a time: the next one starts only after the previous one ended (finished, or cancelled and returned). A job stuck in a kernel read (a dead mount) therefore holds one FRB worker and one waveform thread, never more; later loads wait up to their own timeout and give `RetryLater`.
- Only the error kind is logged; paths are personal data.

**Loader** (`playback/state/waveform_{loader,providers}.dart`). `waveformProvider` is an auto-dispose `StreamProvider<WaveformView>`
(`entryId`, `levels?`, `durationMs`, `instant`) fed by the queue view: the current entry, then the next in play order (none under
repeat one; the first entry under repeat all). It runs jobs **only while a seek bar watches it**: with Now Playing closed nothing is
decoded. One native job at a time, current first, then next; a job for an entry that is neither is cancelled, and every job when
the last watcher goes (Riverpod disposes an unwatched provider after the frame, so a same-frame remount keeps the job). An 8-entry
memory LRU (by cache key, so a changed file misses) survives the views. `instant` is decided at the entry change: levels in the memory or on disk show at once,
levels that arrive from a decode fade in. A retry waits for a new entry or a new view; an entry dropped because the queue moved on
may be tried again.

**Display** (`packages/kanaru_ui/lib/src/widgets/media/`). `KWaveformSeekBar` has the input of `KSeekBar` (`KSeekGestureArea`: tap,
drag, left/right 5 s, slider semantics) at 48 dp. Mirrored rounded bars 3 dp wide, 2 dp apart, 2 to 32 dp tall, centred; played
bars `primary` at 85 %, the rest at 35 %; an upright 4 x 36 dp thumb with 6 dp cleared on each side. `waveform_bars.dart` (pure):
bars map time, not index (mean of the levels inside the bar's share of the duration; a shorter waveform leaves minimal bars; a
longer one is cut), after a contrast stretch (the quietest tenth to 0, the loudest percent to full; a steady tone stays full;
silence stays flat). The two colours are recorded once as pictures; a position tick only moves two clips and the thumb. Flat
`KFlatSeekTrack` while there are no levels or no duration; the bars fade in over 200 ms (none with `instant` or reduced motion).
`PlaybackWaveformSeekBar` draws the levels of the playing entry only, never the previous track's.

## Rules lane B keeps

- Validate before any state change.
- Restore the queue paused. Clamp the saved position against `tracks.duration_ms`.
  Do not rewrite the queue, the position, the current entry or the context until a track loads or the
  user acts.
- A dangling `playback.queue.current_entry` falls back to the first entry.
- A queued track that became `missing` or `hidden` is skipped, with a toast.
- The engine owns the advance after an error, one error per entry.
- Media controls: one coalesced `update` per change with the complete tag set;
  drop empty strings; `artUri` is `file://` only (the `full` cover file); never signal `Position`.
- Keep the Rescan, Keymap and AI buttons, the page-header search scope, the
  flush seam and the selection bar slot in the shell.

## Old app references

The old prototype (retired repo, code only) implemented the same pieces. Read
these before changing the design:

| Area | Old code |
|---|---|
| Player and queue | `lib/core/player/player_service.dart`, `play_queue.dart`, `player_queue_commands.dart`, `mpv_playlist_tracker.dart`, `gapless_sync.dart` |
| Media controls | `lib/core/media_controls/media_controls.dart`, `lib/core/media_controls/mpris/` (`mpris_media_controls.dart`, `mpris_properties.dart`, `mpris_bus_name.dart`) |
| Waveform | `rust/src/{waveform_levels,waveform_decode,waveform_decode_limits,waveform_job}.rs`, `lib/features/player/waveform/` |

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
