import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

TrackInfo _info({AlbumKey? albumKey}) => TrackInfo(
  id: const TrackId(1),
  title: 'Song',
  status: TrackAvailability.present,
  relPath: 'a.mp3',
  albumKey: albumKey,
);

void main() {
  test('coverSeed is the encoded album key when the track has an album', () {
    final key = AlbumKey('artist', 'album');
    expect(_info(albumKey: key).coverSeed, key.encode());
  });

  test('coverSeed falls back to the title without an album', () {
    expect(_info().coverSeed, 'Song');
  });
}
