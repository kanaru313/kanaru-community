import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/local_lyrics_read.dart';
import 'package:kanaru/src/lyrics/data/lyrics_read_cache.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

LyricsCacheKey _key(int id, [String rev = 'r']) =>
    (TrackId(id), '/m/$id', rev, null);

LocalLyricsRead _read(int chars) => LocalLyricsRead(
  lrc: Lyrics(
    lines: [LyricLine(Duration.zero, 'x' * chars)],
    synced: false,
    origin: LyricsOrigin.lrc,
  ),
);

void main() {
  test('count bound evicts the least recently used', () {
    final cache = LyricsReadCache(maxEntries: 3);
    for (var i = 1; i <= 3; i++) {
      cache.put(_key(i), _read(1));
    }
    cache.get(_key(1)); // touch: 2 is now the oldest
    cache.put(_key(4), _read(1));
    expect(cache.get(_key(2)), isNull);
    expect(cache.get(_key(1)), isNotNull);
    expect(cache.length, 3);
  });

  test('byte budget evicts the oldest entries until it fits', () {
    final cache = LyricsReadCache(maxTextChars: 1000);
    cache.put(_key(1), _read(400));
    cache.put(_key(2), _read(400));
    cache.put(_key(3), _read(400));
    expect(cache.get(_key(1)), isNull);
    expect(cache.get(_key(2)), isNotNull);
    expect(cache.get(_key(3)), isNotNull);
    expect(cache.textChars, 800);
  });

  test('one entry over the budget on its own is kept, alone', () {
    final cache = LyricsReadCache(maxTextChars: 100);
    cache.put(_key(1), _read(50));
    cache.put(_key(2), _read(500));
    expect(cache.length, 1);
    expect(cache.get(_key(2)), isNotNull);
    expect(cache.textChars, 500);
  });

  test('replacing a key recounts its size', () {
    final cache = LyricsReadCache(maxTextChars: 1000);
    cache.put(_key(1), _read(300));
    cache.put(_key(1), _read(100));
    expect(cache.textChars, 100);
    expect(cache.length, 1);
  });

  test('peek returns the newest read of a track without touching recency', () {
    final cache = LyricsReadCache(maxEntries: 2);
    cache.put(_key(1, 'a'), _read(1));
    cache.put(_key(1, 'b'), _read(2));
    expect(cache.peek(const TrackId(1))!.textLength, 2);
    expect(cache.peek(const TrackId(2)), isNull);
    cache.put(_key(2), _read(1));
    // 1/'a' was the oldest and went; peek did not refresh anything.
    expect(cache.get(_key(1, 'a')), isNull);
  });
}
