import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

void main() {
  test('PlayContext equality', () {
    const a = PlayContext(PlayContextKind.album, ref: 'x', label: 'L');
    const b = PlayContext(PlayContextKind.album, ref: 'x', label: 'L');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const PlayContext(PlayContextKind.songs)));
  });

  test('CoverColors equality', () {
    const a = CoverColors(seed: 1, palette: [2, 3]);
    expect(a, const CoverColors(seed: 1, palette: [2, 3]));
    expect(a.hashCode, const CoverColors(seed: 1, palette: [2, 3]).hashCode);
    expect(a, isNot(const CoverColors(seed: 1, palette: [2])));
  });

  test('TrackInfo equality incl. artists and albumKey', () {
    TrackInfo make(List<String> artists) => TrackInfo(
      id: const TrackId(1),
      title: 't',
      status: TrackAvailability.present,
      relPath: 'a/b.flac',
      artists: artists,
      albumKey: AlbumKey('a', 'b'),
    );
    expect(make(['x', 'y']), make(['x', 'y']));
    expect(make(['x', 'y']).hashCode, make(['x', 'y']).hashCode);
    expect(make(['x']), isNot(make(['y'])));
  });

  test('formatFromLocator strips CUE suffix', () {
    expect(formatFromLocator('Music/a/b.flac'), 'FLAC');
    expect(formatFromLocator('Music/album.cue#03'), isNull);
    expect(formatFromLocator('Music/album.flac#03'), 'FLAC');
    expect(formatFromLocator('Music/C# Minor.flac'), 'FLAC');
    expect(formatFromLocator('Music/#1 Hits/a.mp3'), 'MP3');
    expect(formatFromLocator('Music.d/noext'), isNull);
    expect(formatFromLocator('x/.hidden'), isNull);
    expect(formatFromLocator('x/a.'), isNull);
  });
}
