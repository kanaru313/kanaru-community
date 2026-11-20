import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

TrackInfo _t(int id, {TrackAvailability status = TrackAvailability.present}) =>
    TrackInfo(
      id: TrackId(id),
      title: 'T$id',
      status: status,
      relPath: 'a/$id.flac',
    );

HistoryPlay _p(int id, TrackInfo t, DateTime at, {int? ms}) => HistoryPlay(
  id: id,
  uid: 'u$id',
  track: t,
  playedAt: at.millisecondsSinceEpoch,
  listenedMs: ms,
  ordinal: 1,
);

void main() {
  group('groupByDay', () {
    test('splits newest-first plays into local days with header figures', () {
      final a = _t(1);
      final b = _t(2);
      final plays = [
        _p(5, a, DateTime(2026, 11, 19, 23, 59), ms: 1000),
        _p(4, b, DateTime(2026, 11, 19, 8), ms: 2000),
        _p(3, a, DateTime(2026, 11, 19, 0, 0, 1)),
        _p(2, a, DateTime(2026, 11, 18, 22), ms: 500),
        _p(1, b, DateTime(2026, 11, 10, 9)),
      ];
      final days = groupByDay(plays);
      expect(days.map((d) => d.start), [
        DateTime(2026, 11, 19),
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 10),
      ]);
      expect(days[0].playCount, 3);
      expect(days[0].songCount, 2);
      expect(days[0].listenedMs, 3000);
      expect(days[1].songCount, 1);
      expect(days[2].listenedMs, 0);
    });

    test('empty input gives no days', () {
      expect(groupByDay(const []), isEmpty);
    });
  });

  group('playableQueue', () {
    test('dedupes by track, keeps order, starts at the tapped song', () {
      final q = playableQueue([_t(1), _t(2), _t(1), _t(3)], _t(3))!;
      expect([for (final t in q.tracks) t.id.value], [1, 2, 3]);
      expect(q.startIndex, 2);
    });

    test('a repeated song starts at its first appearance', () {
      final q = playableQueue([_t(1), _t(2), _t(1)], _t(1))!;
      expect(q.startIndex, 0);
      expect(q.tracks.length, 2);
    });

    test('missing and hidden songs are skipped', () {
      final shown = [
        _t(1),
        _t(2, status: TrackAvailability.missing),
        _t(3, status: TrackAvailability.hidden),
        _t(4),
      ];
      final q = playableQueue(shown, _t(4))!;
      expect([for (final t in q.tracks) t.id.value], [1, 4]);
      expect(q.startIndex, 1);
    });

    test('tapping a missing song gives null', () {
      final gone = _t(2, status: TrackAvailability.missing);
      expect(playableQueue([_t(1), gone], gone), isNull);
    });

    test('a tapped song that left the list plays alone', () {
      final q = playableQueue([_t(1)], _t(9))!;
      expect([for (final t in q.tracks) t.id.value], [9]);
      expect(q.startIndex, 0);
    });

    test('remote songs play', () {
      final r = _t(1, status: TrackAvailability.remote);
      expect(playableQueue([r], r)!.tracks, [r]);
    });
  });
}
