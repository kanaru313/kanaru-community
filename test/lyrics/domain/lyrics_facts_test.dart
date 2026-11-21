import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_facts.dart';

void main() {
  test('the .lrc path is the audio folder plus the locator file name', () {
    expect(
      lrcPathBeside('/m/a/b/song.flac', 'a/b/Song.LRC'),
      '/m/a/b/Song.LRC',
    );
    expect(lrcPathBeside('/m/song.mp3', 'song.lrc'), '/m/song.lrc');
  });

  test('probe candidates keep a stem without extension whole', () {
    expect(lrcProbeCandidates('/m/a.b/song.flac'), [
      '/m/a.b/song.lrc',
      '/m/a.b/song.LRC',
    ]);
    expect(lrcProbeCandidates('/m/a.b/song'), [
      '/m/a.b/song.lrc',
      '/m/a.b/song.LRC',
    ]);
    expect(lrcProbeCandidates('/m/.hidden'), [
      '/m/.hidden.lrc',
      '/m/.hidden.LRC',
    ]);
  });
}
