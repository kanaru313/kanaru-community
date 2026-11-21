import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/embedded_lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/state/playback_position_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/player_ready.dart';

import '../support/lyrics_harness.dart';

NowPlaying _np(int entry, TrackId track) => NowPlaying(
  entryId: entry,
  trackId: track,
  playing: true,
  index: 0,
  length: 2,
);

PlaybackPosition _at(int entry, int ms) => PlaybackPosition(
  entryId: entry,
  position: Duration(milliseconds: ms),
);

void main() {
  late LyricsHarness h;
  late StreamController<NowPlaying> nowPlaying;
  late StreamController<PlaybackPosition> position;
  var positionListens = 0;

  setUp(() {
    positionListens = 0;
    nowPlaying = StreamController<NowPlaying>.broadcast();
    position = StreamController<PlaybackPosition>.broadcast(
      onListen: () => positionListens++,
    );
    h = LyricsHarness(
      extra: [
        nowPlayingProvider.overrideWith((ref) => nowPlaying.stream),
        playbackPositionProvider.overrideWith((ref) => position.stream),
      ],
    );
  });
  tearDown(() async {
    await h.dispose();
    await nowPlaying.close();
    await position.close();
  });

  const synced = '[00:01.00]a\n[00:02.00]b\n[00:03.00]c';

  test('nothing loaded gives no lyrics and no reads', () async {
    final sub = h.container.listen(playingLyricsProvider, (_, _) {});
    await pumpEventQueue();
    expect(sub.read(), PlayingLyrics.none);
    expect(h.reader.tagReads, isEmpty);
  });

  test('the line index notifies only when the line changes', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: synced);
    final seen = <int>[];
    h.container.listen(
      playingLyricsLineProvider,
      (_, n) => seen.add(n),
      fireImmediately: true,
    );
    nowPlaying.add(_np(10, id));
    await h.until(
      () => h.container.read(playingLyricsProvider).lyrics is LyricsShown,
    );
    for (final ms in [
      0,
      500,
      999,
      1000,
      1500,
      1999,
      2000,
      2001,
      2999,
      3000,
      9000,
    ]) {
      position.add(_at(10, ms));
      await pumpEventQueue();
    }
    expect(seen, [-1, 0, 1, 2]);
  });

  test('a position of another entry is -1', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: synced);
    final sub = h.container.listen(playingLyricsLineProvider, (_, _) {});
    nowPlaying.add(_np(10, id));
    await h.until(
      () => h.container.read(playingLyricsProvider).lyrics is LyricsShown,
    );
    position.add(_at(99, 2500));
    await pumpEventQueue();
    expect(sub.read(), -1);
    position.add(_at(10, 2500));
    await pumpEventQueue();
    expect(sub.read(), 1);
  });

  test('plain lyrics never subscribe to the position', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(
      text: 'one\ntwo',
    );
    final sub = h.container.listen(playingLyricsLineProvider, (_, _) {});
    nowPlaying.add(_np(10, id));
    await h.until(
      () => h.container.read(playingLyricsProvider).lyrics is LyricsShown,
    );
    expect(sub.read(), -1);
    expect(positionListens, 0);
  });

  test('synced lyrics do subscribe to the position', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: synced);
    h.container.listen(playingLyricsLineProvider, (_, _) {});
    nowPlaying.add(_np(10, id));
    await h.until(
      () => h.container.read(playingLyricsProvider).lyrics is LyricsShown,
    );
    expect(positionListens, 1);
  });

  test('an entry change is loading and -1 until the new read lands', () async {
    final a = await h.addTrackRow('a.flac');
    final b = await h.addTrackRow('b.flac');
    h.reader.tags['/m/${a.value}.flac'] = const EmbeddedLyrics(text: synced);
    h.reader.tags['/m/${b.value}.flac'] = const EmbeddedLyrics(
      text: '[00:00.50]other',
    );
    h.reader.holdTags.add('/m/${b.value}.flac');
    final line = h.container.listen(playingLyricsLineProvider, (_, _) {});
    nowPlaying.add(_np(10, a));
    await h.until(
      () => h.container.read(playingLyricsProvider).lyrics is LyricsShown,
    );
    position.add(_at(10, 2500));
    await pumpEventQueue();
    expect(line.read(), 1);

    nowPlaying.add(_np(20, b));
    await pumpEventQueue();
    var playing = h.container.read(playingLyricsProvider);
    expect(playing.entryId, 20);
    expect(playing.lyrics, isA<LyricsLoading>(), reason: 'never track a lines');
    position.add(_at(20, 2500));
    await pumpEventQueue();
    expect(line.read(), -1);

    h.reader.releaseTag('/m/${b.value}.flac');
    await h.until(
      () => h.container.read(playingLyricsProvider).lyrics is LyricsShown,
    );
    position.add(_at(20, 700));
    await pumpEventQueue();
    expect(line.read(), 0);
    playing = h.container.read(playingLyricsProvider);
    expect((playing.lyrics as LyricsShown).lyrics.lines.single.text, 'other');
  });

  test('the same track queued twice has lyrics for both entries', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: synced);
    final sub = h.container.listen(playingLyricsProvider, (_, _) {});
    nowPlaying.add(_np(10, id));
    await h.until(() => sub.read().lyrics is LyricsShown);
    nowPlaying.add(_np(11, id));
    await pumpEventQueue();
    expect(sub.read().entryId, 11);
    expect(sub.read().lyrics, isA<LyricsShown>());
    expect(h.reader.tagReads, hasLength(1));
  });

  test('nothing is read before the player exists', () async {
    final early = LyricsHarness(
      phase: PlayerPhase.notCreated,
      extra: [
        nowPlayingProvider.overrideWith((ref) => nowPlaying.stream),
        playbackPositionProvider.overrideWith((ref) => position.stream),
      ],
    );
    addTearDown(early.dispose);
    final id = await early.addTrackRow('a.flac');
    early.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(
      text: synced,
    );
    final sub = early.container.listen(playingLyricsProvider, (_, _) {});
    nowPlaying.add(_np(10, id));
    await pumpEventQueue();
    expect(sub.read(), PlayingLyrics.none);
    expect(early.reader.tagReads, isEmpty);
    expect(early.resolver.calls, 0);
  });

  test('closing the last listener releases the lyrics of the track', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: synced);
    final sub = h.container.listen(playingLyricsLineProvider, (_, _) {});
    nowPlaying.add(_np(10, id));
    await h.until(
      () => h.container.read(playingLyricsProvider).lyrics is LyricsShown,
    );
    sub.close();
    await pumpEventQueue();
    expect(h.container.read(trackLyricsProvider(id).exists), isFalse);
    expect(h.container.read(playingLyricsProvider.exists), isFalse);
  });
}
