import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';
import 'package:kanaru/src/playback/state/sleep_estimates.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';

import '../support/sleep_timer_harness.dart';

void main() {
  late SleepHarness s;
  setUp(() async {
    s = await SleepHarness.create();
    // Tracks 0-2 are one album, 3-5 another.
    for (var i = 0; i < 3; i++) {
      s.albumOf(i, 'A');
    }
    for (var i = 3; i < 6; i++) {
      s.albumOf(i, 'B');
    }
  });
  tearDown(() => s.close());

  group('end of album under repeat one', () {
    for (final start in [0, 1, 2]) {
      test(
        'started on album track $start: pauses after the current play',
        () async {
          await s.h.c.setRepeat(RepeatMode.one);
          await s.play(start: start);
          s.timer.startEndOfAlbum();
          await s.h.settle();
          expect(s.state.mode, SleepTimerMode.endOfAlbum);
          // Nothing is handed over: the entry would loop, not move on.
          expect(s.h.engine.nexts.last, isNull);
          await s.end();
          expect(s.state, const SleepTimerState.off());
          expect(s.h.c.intent, PlayIntent.paused);
          expect(s.h.c.queueState.current, start);
          expect(s.controls.cancelledResumes, 1);
        },
      );
    }
  });

  test('Next under repeat one: stops after the new track\'s play', () async {
    await s.h.c.setRepeat(RepeatMode.one);
    await s.play(start: 0);
    s.timer.startEndOfAlbum();
    await s.h.settle();
    await s.h.c.next();
    await s.h.settle();
    expect(s.h.c.queueState.current, 1);
    expect(s.state.mode, SleepTimerMode.endOfAlbum);
    expect(s.h.engine.nexts.last, isNull);
    // The new entry has its own token; it ends by itself.
    final token = s.h.loadedToken;
    s.h.engine.emit(EngineLoaded(token, const Duration(seconds: 10)));
    await s.h.settle();
    s.h.engine.emit(EngineEnded(token));
    await s.h.settle();
    expect(s.state, const SleepTimerState.off());
    expect(s.h.c.intent, PlayIntent.paused);
    expect(s.h.c.queueState.current, 1);
  });

  group('repeat mode changes while the timer runs', () {
    test('repeat one then all: the album goes on to its next track', () async {
      await s.h.c.setRepeat(RepeatMode.one);
      await s.play(start: 0);
      s.timer.startEndOfAlbum();
      await s.h.settle();
      expect(s.h.engine.nexts.last, isNull);
      await s.h.c.setRepeat(RepeatMode.all);
      await s.h.settle();
      // Track 1 is in the same album: it is handed over.
      expect(s.h.engine.nexts.last, isNotNull);
      await s.advance();
      expect(s.h.c.queueState.current, 1);
      expect(s.state.mode, SleepTimerMode.endOfAlbum);
      expect(s.h.c.intent, isNot(PlayIntent.paused));
    });

    test('repeat off then one: stops after the current play', () async {
      await s.h.c.setRepeat(RepeatMode.off);
      await s.play(start: 0);
      s.timer.startEndOfAlbum();
      await s.h.settle();
      expect(s.h.engine.nexts.last, isNotNull);
      await s.h.c.setRepeat(RepeatMode.one);
      await s.h.settle();
      // The hand-over is withdrawn; the entry ends and pauses.
      expect(s.h.engine.nexts.last, isNull);
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.h.c.intent, PlayIntent.paused);
      expect(s.h.c.queueState.current, 0);
    });

    test('repeat one then off: the album walk is back', () async {
      await s.h.c.setRepeat(RepeatMode.one);
      await s.play(start: 2);
      s.timer.startEndOfAlbum();
      await s.h.settle();
      await s.h.c.setRepeat(RepeatMode.off);
      await s.h.settle();
      // Track 3 is another album: stops at the end of track 2, and moves on
      // to track 3, paused.
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.h.c.intent, PlayIntent.paused);
      expect(s.h.c.queueState.current, 3);
    });
  });

  test('the estimate says "stops after this one" and follows repeat', () async {
    await s.play(start: 0);
    s.container.listen(albumRunProvider, (_, _) {});
    await s.h.settle();
    await pumpEventQueue();
    var run = s.container.read(albumRunProvider).requireValue!;
    expect(run.tracks, 3);
    expect(run.repeatsOne, isFalse);
    await s.h.c.setRepeat(RepeatMode.one);
    await s.h.settle();
    await pumpEventQueue();
    run = s.container.read(albumRunProvider).requireValue!;
    expect(run.repeatsOne, isTrue);
    expect(run.tracks, 1);
    expect(run.restDuration, Duration.zero);
    await s.h.c.setRepeat(RepeatMode.off);
    await s.h.settle();
    await pumpEventQueue();
    run = s.container.read(albumRunProvider).requireValue!;
    expect(run.repeatsOne, isFalse);
    expect(run.tracks, 3);
  });
}
