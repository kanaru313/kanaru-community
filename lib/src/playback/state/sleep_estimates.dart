import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../media/domain/track_id.dart';
import '../../media/domain/track_info.dart';
import '../domain/queue_logic.dart';
import '../domain/sleep_policies.dart';
import 'playback_position_provider.dart';
import 'playback_providers.dart';
import 'player_ready.dart';
import 'queue_row_infos.dart';
import 'queue_totals_provider.dart';
import 'queue_view_provider.dart';

final _log = Logger('SleepEstimates');

/// Most entries of the end-of-album run that are counted; a longer run shows
/// as "100+" ([AlbumRun.capped]).
const int albumRunWindow = 100;

/// Whole seconds left in the loaded entry, null while nothing is loaded, its
/// length is not known or the player is not created yet. It rebuilds once a
/// second, not on every position tick, like the time labels.
final currentTrackLeftProvider = Provider.autoDispose<int?>((ref) {
  final played = ref.watch(currentTrackPlayedProvider);
  if (played == null) return null;
  final left = played.total - played.played;
  return left < 0 ? 0 : left;
});

/// Whole seconds played and in total of the loaded entry (the same rounding
/// as the time labels), null as [currentTrackLeftProvider]. Rebuilds once a
/// second.
final currentTrackPlayedProvider =
    Provider.autoDispose<({int played, int total})?>((ref) {
      if (!ref.watch(playerCreatedProvider)) return null;
      return ref.watch(
        playbackPositionProvider.select((p) {
          final duration = p.value?.duration;
          if (duration == null) return null;
          return (
            played: p.requireValue.position.inSeconds,
            total: duration.inSeconds,
          );
        }),
      );
    });

/// The end-of-album run as the user sees it before starting it.
class AlbumRun {
  const AlbumRun({
    required this.tracks,
    required this.restDuration,
    required this.noAlbum,
    required this.capped,
  });

  /// Entries of the run, the current one included; at most [albumRunWindow].
  final int tracks;

  /// Length of the run's entries after the current one.
  final Duration restDuration;

  /// The current track has no album: it stops after itself.
  final bool noAlbum;

  /// The run is longer than [albumRunWindow] ("100+"), or the queue is one
  /// album under repeat all, which has no end.
  final bool capped;

  @override
  bool operator ==(Object other) =>
      other is AlbumRun &&
      other.tracks == tracks &&
      other.restDuration == restDuration &&
      other.noAlbum == noAlbum &&
      other.capped == capped;

  @override
  int get hashCode => Object.hash(tracks, restDuration, noAlbum, capped);
}

/// The run the end-of-album timer would play, or null while the player is not
/// created or nothing is current. Albums come from the same source as the
/// timer ([queueRowInfosProvider] first, the loader for the rest) and the run
/// from the same walk ([albumRunFrom]), so the two cannot disagree. It looks
/// again when the queue or the infos change and when `tracks` changes; it
/// never reacts to the position. A failure is an `AsyncError`: no figure.
final albumRunProvider = StreamProvider.autoDispose<AlbumRun?>((ref) {
  if (!ref.watch(playerCreatedProvider)) return Stream.value(null);
  final controller = ref.watch(playerControllerProvider);
  final out = StreamController<AlbumRun?>();
  var running = false;
  var again = false;
  var hasLast = false;
  AlbumRun? last;

  Future<AlbumRun?> compute() async {
    final queue = controller.queueState;
    final current = queue.currentItem;
    if (current == null) return null;
    // One more than the window tells "exactly 100" from "more".
    final ids = _playOrderWindow(queue, albumRunWindow + 1);
    final known = ref.read(queueRowInfosProvider);
    final missing = [
      for (final id in ids)
        if (!known.containsKey(id)) id,
    ];
    final loaded = <TrackId, TrackInfo>{};
    if (missing.isNotEmpty) {
      for (final info in await ref.read(queueRowInfoLoaderProvider)(missing)) {
        loaded[info.id] = info;
      }
    }
    // A track the database no longer has is an album of its own.
    TrackInfo? infoOf(TrackId id) => known[id] ?? loaded[id];
    final walk = albumRunFrom(
      queue,
      (id) => AlbumKnown(infoOf(id)?.albumKey),
      limit: albumRunWindow + 1,
    );
    final tooLong = walk.length > albumRunWindow;
    final counted = tooLong
        ? walk.entries.take(albumRunWindow).toList()
        : walk.entries;
    var rest = 0;
    for (final item in counted.skip(1)) {
      rest += infoOf(item.trackId)?.durationMs ?? 0;
    }
    return AlbumRun(
      tracks: counted.length,
      restDuration: Duration(milliseconds: rest),
      noAlbum: infoOf(current.trackId)?.albumKey == null,
      capped: tooLong || walk.capped,
    );
  }

  Future<void> run() async {
    if (running) {
      again = true;
      return;
    }
    running = true;
    try {
      do {
        again = false;
        try {
          final next = await compute();
          if (out.isClosed) return;
          if (again) continue; // stale: decide again on the newer queue
          if (!hasLast || next != last) {
            hasLast = true;
            last = next;
            out.add(next);
          }
        } on Object catch (e, st) {
          if (out.isClosed) return;
          _log.warning('album run not loaded: ${e.runtimeType}');
          hasLast = false;
          out.addError(e, st);
        }
      } while (again);
    } finally {
      running = false;
    }
  }

  final view = controller.queueView.listen((_) => unawaited(run()));
  ref.listen<AsyncValue<int>>(queueTracksChangedProvider, (_, next) {
    if (next is AsyncData<int>) unawaited(run());
  });
  ref.listen(queueRowInfosProvider, (_, _) => unawaited(run()));
  ref.onDispose(() {
    unawaited(view.cancel());
    unawaited(out.close());
  });
  return out.stream;
});

/// Time left in the end-of-album run: the loaded entry's seconds plus the
/// rest of the run. Null until both are known. Cheap: no query.
final albumLeftProvider = Provider.autoDispose<Duration?>((ref) {
  final left = ref.watch(currentTrackLeftProvider);
  final run = ref.watch(albumRunProvider).value;
  if (left == null || run == null) return null;
  return Duration(seconds: left) + run.restDuration;
});

/// Entries in the queue from the loaded one on (it included) and the time
/// they take; [time] is null until both parts are known.
typedef QueueLeft = ({int tracks, Duration? time});

final queueLeftProvider = Provider.autoDispose<QueueLeft?>((ref) {
  if (!ref.watch(playerCreatedProvider)) return null;
  final tracks = ref.watch(
    queueViewProvider.select((v) {
      final view = v.value;
      final current = view?.current;
      return view == null || current == null ? null : view.length - current;
    }),
  );
  if (tracks == null) return null;
  final left = ref.watch(currentTrackLeftProvider);
  final rest = ref.watch(queueRemainingProvider).value;
  return (
    tracks: tracks,
    time: left == null || rest == null ? null : Duration(seconds: left) + rest,
  );
});

/// Up to [count] track ids from the current entry on, in play order. Stops
/// where play order would come back to the current entry.
List<TrackId> _playOrderWindow(QueueState queue, int count) {
  final start = queue.current;
  if (start == null) return const [];
  final ids = <TrackId>[];
  var at = start;
  while (ids.length < count) {
    ids.add(queue.items[at].trackId);
    final next = nextIndex(queue.copyWith(current: at), auto: false);
    if (next == null || next == start) break;
    at = next;
  }
  return ids;
}
