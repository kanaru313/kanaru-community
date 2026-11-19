import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/covers/album_cover_candidates.dart';

import 'cover_test_support.dart';

void main() {
  test('distinct albums in order, skipping no-album and no-cover tracks', () {
    final found = albumCoverCandidates([
      track(1, album: 'A', cover: coverKeyOf(1), year: 2001),
      track(2), // no album
      track(3, album: 'B'), // no cover
      track(4, album: 'A', cover: coverKeyOf(9)), // A again
      track(5, album: 'C', cover: coverKeyOf(3)),
    ], 6);
    expect(found.map((c) => c.title), ['A', 'C']);
    expect(found.first.year, 2001);
    expect(found.first.coverKey, coverKeyOf(1), reason: 'first track wins');
  });

  test('an album whose first track has no cover uses a later track cover', () {
    final found = albumCoverCandidates([
      track(1, album: 'A'),
      track(2, album: 'A', cover: coverKeyOf(2)),
    ], 6);
    expect(found.single.coverKey, coverKeyOf(2));
  });

  test('stops at the limit', () {
    final tracks = [
      for (var i = 1; i <= 9; i++) track(i, album: 'A$i', cover: coverKeyOf(i)),
    ];
    expect(albumCoverCandidates(tracks, 6), hasLength(6));
    expect(albumCoverCandidates(tracks, 0), isEmpty);
    expect(albumCoverCandidates(const [], 6), isEmpty);
  });
}
