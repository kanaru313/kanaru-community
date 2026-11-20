import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';
import 'package:kanaru/src/playback/domain/sleep_policies.dart';

import '../support/queue_fixtures.dart';

void main() {
  late Map<int, AlbumLookupResult> known;
  late List<int> asked;

  AlbumLookupResult keyOf(TrackId id) {
    asked.add(id.value);
    return known[id.value] ?? const AlbumUnknown();
  }

  void setAlbums(List<String?> titles) {
    for (var i = 0; i < titles.length; i++) {
      final t = titles[i];
      known[i] = AlbumKnown(t == null ? null : AlbumKey('a', t));
    }
  }

  List<int> run(AlbumWalk w) => [for (final e in w.entries) e.trackId.value];

  setUp(() {
    known = {};
    asked = [];
  });

  test('collects the entries of the current album in play order', () {
    setAlbums(['x', 'x', 'x', 'y', 'x']);
    final w = albumRunFrom(makeQueue(5, current: 0), keyOf);
    expect(run(w), [0, 1, 2]);
    expect(w.unknown, isEmpty);
    expect(w.capped, isFalse);
  });

  test('starts from the current entry, not from the first', () {
    setAlbums(['x', 'x', 'y', 'y', 'y']);
    expect(run(albumRunFrom(makeQueue(5, current: 3), keyOf)), [3, 4]);
  });

  test('stops at an entry without an album, which is an album of its own', () {
    setAlbums(['x', 'x', null, 'x']);
    expect(run(albumRunFrom(makeQueue(4, current: 0), keyOf)), [0, 1]);
    // A current track without an album is a run of one.
    setAlbums([null, null]);
    expect(run(albumRunFrom(makeQueue(2, current: 0), keyOf)), [0]);
  });

  test('stops at the first unknown key and reports it', () {
    setAlbums(['x', 'x']);
    final w = albumRunFrom(makeQueue(4, current: 0), keyOf);
    expect(run(w), [0, 1]);
    expect(w.unknown.map((t) => t.value), [2]);
  });

  test('an unknown current and next are both reported, once each', () {
    final w = albumRunFrom(makeQueue(3, current: 1), keyOf);
    expect(run(w), [1]);
    expect(w.unknown.map((t) => t.value), [1, 2]);
  });

  test('no neighbour: a run of one and no lookup at all', () {
    setAlbums(['x', 'x']);
    for (final q in [
      makeQueue(2, current: 1),
      makeQueue(1, current: 0),
      makeQueue(3, current: 2, repeat: RepeatMode.allShuffled),
    ]) {
      expect(albumRunFrom(q, keyOf).length, 1);
    }
    expect(asked, isEmpty);
  });

  test('nothing current is an empty run', () {
    final w = albumRunFrom(makeQueue(3), keyOf);
    expect(w.entries, isEmpty);
    expect(w.length, 0);
  });

  test('the end of a reshuffled pass ends the run', () {
    setAlbums(['x', 'x', 'x']);
    final q = makeQueue(3, current: 1, repeat: RepeatMode.allShuffled);
    expect(run(albumRunFrom(q, keyOf)), [1, 2]);
  });

  test('repeat all wraps, and one album never goes past the queue length', () {
    setAlbums(['x', 'y', 'x']);
    expect(
      run(
        albumRunFrom(makeQueue(3, current: 2, repeat: RepeatMode.all), keyOf),
      ),
      [2, 0],
    );
    setAlbums(['x', 'x', 'x']);
    final w = albumRunFrom(
      makeQueue(3, current: 1, repeat: RepeatMode.all),
      keyOf,
    );
    expect(run(w), [1, 2, 0]);
    expect(w.capped, isTrue);
  });

  test('repeat one is the current entry alone: it plays again', () {
    setAlbums(['x', 'x', 'y']);
    final q = makeQueue(3, current: 0, repeat: RepeatMode.one);
    expect(run(albumRunFrom(q, keyOf)), [0]);
  });

  test('a shuffled queue is read in play order', () {
    setAlbums(['y', 'x', 'x']); // play order is 2, 1, 0
    final q = makeQueue(3, current: 0, shuffled: true);
    expect(run(albumRunFrom(q, keyOf)), [2, 1]);
  });

  test('the limit cuts the walk and says so', () {
    setAlbums(['x', 'x', 'x', 'x']);
    final w = albumRunFrom(makeQueue(4, current: 0), keyOf, limit: 2);
    expect(run(w), [0, 1]);
    expect(w.capped, isTrue);
    // A limit above the run changes nothing.
    final all = albumRunFrom(makeQueue(4, current: 0), keyOf, limit: 9);
    expect(all.length, 4);
    expect(all.capped, isFalse);
  });
}
