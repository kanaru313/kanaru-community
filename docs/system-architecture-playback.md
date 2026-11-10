# Playback

> **Contract stub.** Owner: lane B (playback). The foundation declares the
> contracts below; they are frozen. Lane B replaces this text with its own
> design (player, queue operations, media controls, Now Playing) when it lands.
> Until then the commands throw `StateError` and nothing plays.

## Contents

- Commands and now playing: this file.
- Queue table and its helpers: this file.
- Settings keys and restore rules: this file.
- Media controls (MPRIS, `audio_service`): lane B adds the section.

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

| Provider | Type | Seed (until lane B) |
|---|---|---|
| `playbackCommandsProvider` | `Provider<PlaybackCommands>` | `UnavailablePlaybackCommands`, every call fails with `StateError` |
| `nowPlayingProvider` | `StreamProvider<NowPlaying>` | `NowPlaying.none` |
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
- Richer edits (remove, move, undo) are written by lane B against the table.

## Settings keys (reserved)

Declared by lane B, in `playback/state/`. Keys are reserved here so no other
module takes them.

| Key | Holds |
|---|---|
| `playback.queue.current_entry` | `entryId` of the loaded entry |
| `playback.position_ms` | Last saved position |
| `playback.shuffle` | Shuffle on or off |
| `playback.repeat` | Repeat mode (type decided by lane B) |

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
