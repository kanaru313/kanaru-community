import '../../../media/domain/track_id.dart';
import 'history_models.dart';

/// The songs a tap on a Most played row queues: the entries in rank order
/// without the ones that cannot play. Built once per list and shared by its
/// rows; every song is listed once already (one entry per song).
class TopQueue {
  TopQueue(List<TopEntry> entries) {
    final ids = <TrackId>[];
    final index = <int, int>{};
    for (final e in entries) {
      final t = e.track;
      if (!canPlayTrack(t) || index.containsKey(t.id.value)) continue;
      index[t.id.value] = ids.length;
      ids.add(t.id);
    }
    this.ids = ids;
    _index = index;
  }

  late final List<TrackId> ids;
  late final Map<int, int> _index;

  /// Place of [track] in [ids]; 0 for a song that is not in it.
  int indexOf(TrackId track) => _index[track.value] ?? 0;
}
