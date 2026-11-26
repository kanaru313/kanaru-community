import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/playlists/page/playlist_reorder.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

PlaylistEntryView _entry(String uid, int track, {bool available = true}) =>
    PlaylistEntryView(
      id: 0,
      uid: uid,
      info: TrackInfo(
        id: TrackId(track),
        title: 't$track',
        status: available
            ? TrackAvailability.present
            : TrackAvailability.missing,
        relPath: 't$track.flac',
      ),
    );

/// Rows `a b c d`, the track of each is its own.
final _rows = [
  for (final (i, u) in ['a', 'b', 'c', 'd'].indexed) _entry(u, i),
];

void main() {
  group('afterEntryFor (final index, no adjustment)', () {
    test('down by one goes behind the row it passes', () {
      expect(afterEntryFor(_rows, 'a', 1)?.after, 'b');
    });

    test('up by one goes behind the row two above, or to the top', () {
      expect(afterEntryFor(_rows, 'c', 1)?.after, 'a');
      expect(afterEntryFor(_rows, 'b', 0)?.after, isNull);
      expect(afterEntryFor(_rows, 'b', 0), isNotNull, reason: 'a real move');
    });

    test('to the last row goes behind the last of the others', () {
      expect(afterEntryFor(_rows, 'a', 3)?.after, 'd');
    });

    test('to the first row is a move to the top', () {
      expect(afterEntryFor(_rows, 'd', 0), (after: null));
    });

    test('the same place, an unknown entry and a bad index write nothing', () {
      expect(afterEntryFor(_rows, 'b', 1), isNull);
      expect(afterEntryFor(_rows, 'zz', 0), isNull);
      expect(afterEntryFor(_rows, 'a', 4), isNull);
      expect(afterEntryFor(_rows, 'a', -1), isNull);
    });

    test('a missing row counts as a row (down and up over it)', () {
      final rows = [
        _entry('a', 0),
        _entry('m', 1, available: false),
        _entry('c', 2),
      ];
      // a -> index 1 lands behind the missing row.
      expect(afterEntryFor(rows, 'a', 1)?.after, 'm');
      expect(afterEntryFor(rows, 'a', 2)?.after, 'c');
      // c -> index 1 lands between a and the missing row.
      expect(afterEntryFor(rows, 'c', 1)?.after, 'a');
      expect(afterEntryFor(rows, 'c', 0), (after: null));
      // The missing row itself can move.
      expect(afterEntryFor(rows, 'm', 2)?.after, 'c');
    });

    test('two copies of one track move independently', () {
      final rows = [_entry('x1', 7), _entry('y', 8), _entry('x2', 7)];
      expect(afterEntryFor(rows, 'x2', 0), (after: null));
      expect(afterEntryFor(rows, 'x1', 2)?.after, 'x2');
      expect(afterEntryFor(rows, 'x2', 1)?.after, 'x1');
    });
  });

  group('afterEntryForStep', () {
    test('up and down one row; nothing at the ends or for a gone entry', () {
      expect(afterEntryForStep(_rows, 'c', -1)?.after, 'a');
      expect(afterEntryForStep(_rows, 'b', -1), (after: null));
      expect(afterEntryForStep(_rows, 'b', 1)?.after, 'c');
      expect(afterEntryForStep(_rows, 'a', -1), isNull);
      expect(afterEntryForStep(_rows, 'd', 1), isNull);
      expect(afterEntryForStep(_rows, 'gone', 1), isNull);
    });
  });
}
