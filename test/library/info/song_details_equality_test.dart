import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/menu_targets.dart';
import 'package:kanaru/src/library/domain/info/song_details.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

SongDetails make({List<ArtistRef>? artists, int playCount = 0}) => SongDetails(
  id: const TrackId(1),
  title: 'T',
  status: SongFileStatus.present,
  addedAt: 10,
  folder: const FolderRef(
    sourceId: 1,
    sourceUid: 's',
    folderKey: '',
    name: 'M',
    songCount: 0,
  ),
  artists: artists ?? [ArtistRef(ArtistKey('a'), 'A')],
  playCount: playCount,
);

void main() {
  test('equal values with separate artist lists are equal', () {
    final a = make(), b = make();
    expect(identical(a.artists, b.artists), isFalse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('a different artist, order or count differs', () {
    final x = ArtistRef(ArtistKey('x'), 'X'),
        y = ArtistRef(ArtistKey('y'), 'Y');
    expect(make(artists: [x, y]), isNot(make(artists: [y, x])));
    expect(make(artists: [x]), isNot(make(artists: [x, y])));
    expect(make(artists: [x]), isNot(make(artists: [y])));
  });

  test('a scalar field changes equality', () {
    expect(make(playCount: 1), isNot(make()));
  });
}
