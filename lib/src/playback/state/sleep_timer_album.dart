import 'dart:async';

import 'package:logging/logging.dart';

import '../../media/domain/library_keys.dart';
import '../../media/domain/track_id.dart';
import '../../media/domain/track_info.dart';
import '../domain/sleep_policies.dart';

final _log = Logger('SleepTimerAlbum');

/// Most answers kept; past it the map starts over and asks again.
const _mostKeys = 32;

/// Album keys for the end-of-album policy. Rows the queue list already loaded
/// answer first ([loaded]); the rest are fetched with [load] and kept in a
/// small map of the last answers. An answer calls [onAnswer], which makes the
/// player decide again. A failure leaves the key unknown, which stops
/// (the safe side), and the ids are not asked again until [reset].
class SleepAlbumKeys {
  SleepAlbumKeys({
    required this.loaded,
    required this.load,
    required this.onAnswer,
  });

  /// The infos already in memory.
  final Map<TrackId, TrackInfo> Function() loaded;

  /// Loads infos from the database, one query.
  final Future<List<TrackInfo>> Function(List<TrackId> ids) load;

  /// Fresh keys are in; the player should decide again.
  final void Function() onAnswer;

  /// The zone the keys were made in. The policy asks from inside the player's
  /// command chain; an answer run in that zone would call the chain from one
  /// of its own tasks.
  final Zone _zone = Zone.current;

  final Map<TrackId, AlbumKey?> _answers = {};
  final Set<TrackId> _asked = {};
  int _generation = 0;

  AlbumLookupResult lookup(TrackId id) {
    final info = loaded()[id];
    if (info != null) return AlbumKnown(info.albumKey);
    if (_answers.containsKey(id)) return AlbumKnown(_answers[id]);
    return const AlbumUnknown();
  }

  /// Asks for [ids] not asked before.
  void want(List<TrackId> ids) {
    final fresh = [
      for (final id in ids)
        if (_asked.add(id)) id,
    ];
    if (fresh.isEmpty) return;
    _zone.run(() => unawaited(_fetch(fresh, _generation)));
  }

  Future<void> _fetch(List<TrackId> ids, int generation) async {
    try {
      final infos = await load(ids);
      if (generation != _generation) return;
      if (_answers.length + ids.length > _mostKeys) {
        _answers.clear();
        _asked
          ..clear()
          ..addAll(ids);
      }
      // A track the database no longer has counts as an album of its own.
      for (final id in ids) {
        _answers[id] = null;
      }
      for (final info in infos) {
        _answers[info.id] = info.albumKey;
      }
      onAnswer();
    } on Object catch (e, st) {
      if (generation != _generation) return;
      _log.warning('album keys not loaded: ${e.runtimeType}', null, st);
    }
  }

  /// Forgets every answer and drops the requests still running.
  void reset() {
    _generation++;
    _answers.clear();
    _asked.clear();
  }

  void dispose() => reset();
}
