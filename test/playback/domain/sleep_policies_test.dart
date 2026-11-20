import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';
import 'package:kanaru/src/playback/domain/sleep_policies.dart';

import '../support/queue_fixtures.dart';

void main() {
  group('end of track', () {
    test('always stops', () {
      final p = EndOfTrackPolicy();
      expect(p.stopsAfterCurrent(makeQueue(3, current: 0), 0), isTrue);
      expect(p.stopsAfterCurrent(makeQueue(3, current: 2), 2), isTrue);
    });
  });

  group('end of queue', () {
    final p = EndOfQueuePolicy();

    test('stops on the last entry only', () {
      expect(p.stopsAfterCurrent(makeQueue(3, current: 1), 0), isFalse);
      expect(p.stopsAfterCurrent(makeQueue(3, current: 2), 0), isTrue);
    });

    test('whatever repeat says', () {
      for (final repeat in RepeatMode.values) {
        expect(
          p.stopsAfterCurrent(makeQueue(3, current: 2, repeat: repeat), 0),
          isTrue,
          reason: '$repeat',
        );
        expect(
          p.stopsAfterCurrent(makeQueue(3, current: 0, repeat: repeat), 0),
          isFalse,
          reason: '$repeat',
        );
      }
    });

    test('follows the play order of a shuffled queue', () {
      final q = makeQueue(3, current: 2, shuffled: true);
      expect(p.stopsAfterCurrent(q, 0), isTrue);
    });

    test('nothing current never stops', () {
      expect(p.stopsAfterCurrent(makeQueue(3), 0), isFalse);
    });
  });

  group('tracks', () {
    test('stops when one is left', () {
      expect(
        TracksPolicy(1).stopsAfterCurrent(makeQueue(3, current: 0), 0),
        isTrue,
      );
      expect(
        TracksPolicy(2).stopsAfterCurrent(makeQueue(3, current: 0), 0),
        isFalse,
      );
    });

    test('every natural end counts one off, down to one', () {
      final p = TracksPolicy(3);
      p.trackEnded();
      expect(p.left, 2);
      p.trackEnded();
      expect(p.left, 1);
      p.trackEnded();
      expect(p.left, 1);
    });

    test('the count is kept within 1 to 20', () {
      expect(TracksPolicy(0).left, 1);
      expect(TracksPolicy(-4).left, 1);
      expect(TracksPolicy(99).left, 20);
    });
  });

  group('end of album', () {
    // Track i is in the album named by albums[i]; '' = no album.
    late Map<int, AlbumLookupResult> known;
    late List<List<TrackId>> wanted;

    setUp(() {
      known = {};
      wanted = [];
    });

    void setAlbums(List<String?> titles) {
      for (var i = 0; i < titles.length; i++) {
        final t = titles[i];
        known[i] = AlbumKnown(t == null ? null : AlbumKey('a', t));
      }
    }

    EndOfAlbumPolicy policy() => EndOfAlbumPolicy(
      albumOf: (id) => known[id.value] ?? const AlbumUnknown(),
      want: wanted.add,
    );

    bool stops(QueueState q) => policy().stopsAfterCurrent(q, 0);

    test('same album as the next goes on', () {
      setAlbums(['x', 'x', 'y']);
      expect(stops(makeQueue(3, current: 0)), isFalse);
    });

    test('another album stops', () {
      setAlbums(['x', 'x', 'y']);
      expect(stops(makeQueue(3, current: 1)), isTrue);
    });

    test('a track without an album is an album of its own', () {
      setAlbums([null, null, 'y']);
      expect(stops(makeQueue(3, current: 0)), isTrue);
      setAlbums(['x', null, 'y']);
      expect(stops(makeQueue(3, current: 0)), isTrue);
    });

    test('unknown keys stop and ask for the entry and the two after it', () {
      expect(stops(makeQueue(5, current: 1)), isTrue);
      expect(wanted.single.map((t) => t.value), [1, 2, 3]);
    });

    test('only what is missing is asked for', () {
      known[1] = const AlbumKnown(null);
      known[2] = const AlbumKnown(null);
      stops(makeQueue(5, current: 1));
      expect(wanted.single.map((t) => t.value), [3]);
    });

    test('after the answer the decision is the real one', () {
      final p = policy();
      final q = makeQueue(3, current: 0);
      expect(p.stopsAfterCurrent(q, 0), isTrue);
      setAlbums(['x', 'x', 'x']);
      expect(p.stopsAfterCurrent(q, 0), isFalse);
      expect(wanted, hasLength(1));
    });

    test('a known pair with an unknown third asks only for the third', () {
      setAlbums(['x', 'x']);
      expect(stops(makeQueue(4, current: 0)), isFalse);
      expect(wanted.single.map((t) => t.value), [2]);
    });

    test('no neighbour stops: last entry, one entry, nothing current', () {
      setAlbums(['x', 'x', 'x']);
      expect(stops(makeQueue(3, current: 2)), isTrue);
      expect(stops(makeQueue(1, current: 0)), isTrue);
      expect(stops(makeQueue(3)), isTrue);
      expect(wanted, isEmpty);
    });

    test('the end of a reshuffled pass stops', () {
      setAlbums(['x', 'x', 'x']);
      expect(
        stops(makeQueue(3, current: 2, repeat: RepeatMode.allShuffled)),
        isTrue,
      );
      // Inside the pass the album goes on.
      expect(
        stops(makeQueue(3, current: 0, repeat: RepeatMode.allShuffled)),
        isFalse,
      );
    });

    test('repeat one stops after the current play, wherever it is', () {
      // First, middle and last entry of an album: the entry plays again, so
      // the run is that one play.
      setAlbums(['x', 'x', 'x', 'y']);
      for (final at in [0, 1, 2]) {
        expect(
          stops(makeQueue(4, current: at, repeat: RepeatMode.one)),
          isTrue,
          reason: 'entry $at',
        );
      }
      expect(wanted, isEmpty);
    });

    test('albumRunFrom under repeat one is the current entry alone', () {
      setAlbums(['x', 'x', 'x']);
      final walk = albumRunFrom(
        makeQueue(3, current: 0, repeat: RepeatMode.one),
        (id) => known[id.value] ?? const AlbumUnknown(),
      );
      expect(walk.length, 1);
      expect(walk.capped, isFalse);
      expect(walk.unknown, isEmpty);
    });

    test('repeat all wraps to the first entry', () {
      setAlbums(['x', 'y', 'x']);
      expect(stops(makeQueue(3, current: 2, repeat: RepeatMode.all)), isFalse);
      setAlbums(['x', 'y', 'z']);
      expect(stops(makeQueue(3, current: 2, repeat: RepeatMode.all)), isTrue);
    });

    test('a shuffled queue is read in play order', () {
      // Play order is tracks 2, 1, 0.
      setAlbums(['y', 'x', 'x']);
      final q = makeQueue(3, current: 0, shuffled: true);
      expect(stops(q), isFalse);
      final q2 = makeQueue(3, current: 1, shuffled: true);
      expect(stops(q2), isTrue);
    });
  });
}
