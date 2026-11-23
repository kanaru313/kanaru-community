import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_summary.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_outcome.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';

const _ref = OnlineLyricsRef(
  providerId: 'p',
  providerName: 'P',
  remoteId: 'r',
  how: OnlineHow.auto,
);

Lyrics _online({required bool synced, OnlineLyricsRef ref = _ref}) => Lyrics(
  lines: const [LyricLine(Duration.zero, 'a')],
  synced: synced,
  origin: LyricsOrigin.online,
  online: ref,
);

void main() {
  test('online lyrics summarise as online synced or plain', () {
    expect(summaryOfLyrics(_online(synced: true)), LyricsSummary.onlineSynced);
    expect(summaryOfLyrics(_online(synced: false)), LyricsSummary.onlinePlain);
  });

  test('every new state has a summary', () {
    expect(summaryOf(const LyricsSearching(2)), LyricsSummary.searching);
    expect(
      summaryOf(const LyricsInstrumental(_ref)),
      LyricsSummary.instrumental,
    );
    for (final state in <TrackLyrics>[
      const LyricsNotFound(asked: 1, off: 0),
      const LyricsNoSource(),
      const LyricsLookupFailed(reason: LookupFailReason.network, asked: 1),
      LyricsLookupPaused(DateTime.utc(2026)),
    ]) {
      expect(summaryOf(state), LyricsSummary.none, reason: '$state');
    }
  });

  test('the origin and the reference are part of the equality', () {
    expect(_online(synced: true), _online(synced: true));
    const other = OnlineLyricsRef(
      providerId: 'p',
      providerName: 'P',
      remoteId: 'r',
      how: OnlineHow.kept,
    );
    expect(_online(synced: true, ref: other), isNot(_online(synced: true)));
    expect(_online(synced: true).hashCode, _online(synced: true).hashCode);
  });

  test('online lyrics must carry a reference and others must not', () {
    expect(
      () => Lyrics(lines: const [], synced: false, origin: LyricsOrigin.online),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => Lyrics(
        lines: const [],
        synced: false,
        origin: LyricsOrigin.tag,
        online: _ref,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('isEmpty names the states that show nothing to read', () {
    expect(const LyricsNone().isEmpty, isTrue);
    expect(const LyricsNoSource().isEmpty, isTrue);
    expect(const LyricsSearching(1).isEmpty, isFalse);
    expect(const LyricsLoading().isEmpty, isFalse);
    expect(LyricsShown(_online(synced: true)).isEmpty, isFalse);
  });
}
