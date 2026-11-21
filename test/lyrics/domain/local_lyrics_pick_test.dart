import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/local_lyrics_pick.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';

enum _Kind { none, plain, synced }

Lyrics? _make(_Kind kind, LyricsOrigin origin) => switch (kind) {
  _Kind.none => null,
  _Kind.plain => Lyrics(
    lines: const [LyricLine(Duration.zero, 'p')],
    synced: false,
    origin: origin,
  ),
  _Kind.synced => Lyrics(
    lines: const [LyricLine(Duration(seconds: 1), 's')],
    synced: true,
    origin: origin,
  ),
};

/// The expected winner by D4: synced in preferred, synced in other, plain in
/// preferred, plain in other.
LyricsOrigin? _expected(_Kind tag, _Kind lrc, LocalFirst first) {
  final order = first == LocalFirst.tag
      ? [(LyricsOrigin.tag, tag), (LyricsOrigin.lrc, lrc)]
      : [(LyricsOrigin.lrc, lrc), (LyricsOrigin.tag, tag)];
  for (final want in [_Kind.synced, _Kind.plain]) {
    for (final (origin, kind) in order) {
      if (kind == want) return origin;
    }
  }
  return null;
}

void main() {
  for (final tag in _Kind.values) {
    for (final lrc in _Kind.values) {
      for (final first in LocalFirst.values) {
        test('tag ${tag.name}, lrc ${lrc.name}, first ${first.name}', () {
          final pick = pickLocalLyrics(
            tag: _make(tag, LyricsOrigin.tag),
            lrc: _make(lrc, LyricsOrigin.lrc),
            first: first,
          );
          expect(pick.shown?.origin, _expected(tag, lrc, first));
          expect(pick.tag, _make(tag, LyricsOrigin.tag));
          expect(pick.lrc, _make(lrc, LyricsOrigin.lrc));
        });
      }
    }
  }

  test('plain tag loses to a synced .lrc even when the tag is preferred', () {
    final pick = pickLocalLyrics(
      tag: _make(_Kind.plain, LyricsOrigin.tag),
      lrc: _make(_Kind.synced, LyricsOrigin.lrc),
      first: LocalFirst.tag,
    );
    expect(pick.shown!.origin, LyricsOrigin.lrc);
  });
}
