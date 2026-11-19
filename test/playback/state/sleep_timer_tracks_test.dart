import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';

import '../support/sleep_timer_harness.dart';

void main() {
  late SleepHarness s;
  setUp(() async {
    s = await SleepHarness.create();
  });
  tearDown(() => s.close());

  int tracksLeft() => s.state.tracksLeft;

  group('ranges', () {
    test('the count is kept within 1 to 20', () {
      s.timer.startTracks(0);
      expect(tracksLeft(), 1);
      s.timer.startTracks(-3);
      expect(tracksLeft(), 1);
      s.timer.startTracks(21);
      expect(tracksLeft(), 20);
      s.timer.startTracks(20);
      expect(tracksLeft(), 20);
    });

    test('adding is capped at 20 and taking off is refused below 1', () {
      s.timer.startTracks(19);
      s.timer.addTracks(5);
      expect(tracksLeft(), 20);
      s.timer.addTracks(1);
      expect(tracksLeft(), 20);
      s.timer.startTracks(2);
      s.timer.addTracks(-5);
      expect(tracksLeft(), 2);
      s.timer.addTracks(-1);
      expect(tracksLeft(), 1);
      s.timer.addTracks(-1);
      expect(tracksLeft(), 1);
      s.timer.addTracks(0);
      expect(tracksLeft(), 1);
    });
  });

  group('counting natural ends', () {
    test('three ends pause after the third, the next loaded paused', () async {
      await s.play();
      s.timer.startTracks(3);
      await s.h.settle();
      expect(tracksLeft(), 3);
      await s.advance();
      expect(tracksLeft(), 2);
      await s.advance();
      expect(tracksLeft(), 1);
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.h.c.intent, PlayIntent.paused);
      expect(s.h.c.queueState.current, 3);
      expect(s.h.engine.lastLoadPlay, isFalse);
      expect(s.controls.cancelledResumes, 1);
    });

    test('next does not use a track up', () async {
      await s.play();
      s.timer.startTracks(3);
      await s.h.c.next();
      await s.h.c.next();
      await s.h.settle();
      expect(tracksLeft(), 3);
      expect(s.h.c.queueState.current, 2);
    });

    test('a loop of repeat one counts', () async {
      await s.h.c.setRepeat(RepeatMode.one);
      await s.play();
      s.timer.startTracks(2);
      await s.h.settle();
      await s.advance();
      expect(tracksLeft(), 1);
      expect(s.h.c.queueState.current, 0);
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.h.c.intent, PlayIntent.paused);
    });

    test('plus and minus change when it stops', () async {
      await s.play();
      s.timer.startTracks(2);
      await s.h.settle();
      s.timer.addTracks(1);
      await s.h.settle();
      await s.advance();
      await s.advance();
      expect(tracksLeft(), 1);
      s.timer.addTracks(1);
      await s.h.settle();
      expect(tracksLeft(), 2);
      // Not stopping any more: a next is handed over again.
      expect(s.h.engine.nexts.last, isNotNull);
      s.timer.addTracks(-1);
      await s.h.settle();
      expect(s.h.engine.nexts.last, isNull);
    });

    test('the queue running out first turns it off', () async {
      await s.play(start: 5);
      s.timer.startTracks(3);
      await s.h.settle();
      await s.end();
      expect(s.state, const SleepTimerState.off());
      expect(s.controls.cancelledResumes, 0);
      // The policy is gone: a later queue plays on.
      await s.h.play();
      await s.h.settle();
      expect(s.h.engine.nexts.last, isNotNull);
    });
  });

  group('replace and cancel', () {
    test(
      'a minutes timer replaces a track mode and removes its stop',
      () async {
        await s.play();
        s.timer.startEndOfTrack();
        await s.h.settle();
        expect(s.h.engine.nexts.last, isNull);
        s.timer.startMinutes(10);
        await s.h.settle();
        expect(s.state.mode, SleepTimerMode.minutes);
        expect(s.h.engine.nexts.last, isNotNull);
      },
    );

    test('a track mode replaces a running countdown', () async {
      await s.play();
      s.timer.startMinutes(10);
      s.timer.startTracks(2);
      await s.h.settle();
      expect(s.state.mode, SleepTimerMode.tracks);
      expect(s.state.remaining, Duration.zero);
      expect(s.state.endsAt, isNull);
      expect(s.h.ticker.active, 0);
    });

    test('one track mode replaces another', () async {
      await s.play();
      s.timer.startTracks(3);
      s.timer.startEndOfQueue();
      await s.h.settle();
      expect(s.state.mode, SleepTimerMode.endOfQueue);
      expect(s.h.engine.nexts.last, isNotNull);
      await s.advance();
      expect(s.state.mode, SleepTimerMode.endOfQueue);
    });

    test('cancel from every mode removes the policy and the fade', () async {
      final starts = <String, void Function()>{
        'minutes': () => s.timer.startMinutes(1),
        'tracks': () => s.timer.startTracks(1),
        'end of track': s.timer.startEndOfTrack,
        'end of album': s.timer.startEndOfAlbum,
        'end of queue': s.timer.startEndOfQueue,
      };
      for (final entry in starts.entries) {
        await s.h.c.stop();
        await s.play();
        entry.value();
        await s.pass(const Duration(seconds: 55));
        await s.pass(const Duration(seconds: 1));
        s.timer.cancel();
        await s.h.settle();
        expect(s.state, const SleepTimerState.off(), reason: entry.key);
        expect(s.h.ticker.active, 0, reason: entry.key);
        expect(
          s.volumes().isEmpty || s.volumes().last == 100,
          isTrue,
          reason: entry.key,
        );
        // No stop is left behind: the engine is handed the next entry.
        await s.h.c.play();
        await s.h.settle();
        expect(s.h.engine.nexts.last, isNotNull, reason: entry.key);
        expect(s.controls.cancelledResumes, 0, reason: entry.key);
      }
    });

    test('a new controller drops the mode and has no stop', () async {
      await s.play();
      s.timer.startEndOfTrack();
      await s.h.settle();
      await s.h.restart();
      s.container.invalidate(playerControllerProvider);
      expect(s.state, const SleepTimerState.off());
      await s.attachPlayer();
      await s.play();
      expect(s.h.engine.nexts.last, isNotNull);
      expect(s.state, const SleepTimerState.off());
    });
  });

  group('clearing the queue', () {
    test('clearQueue turns the tracks mode off', () async {
      await s.play();
      s.timer.startTracks(3);
      await s.h.settle();
      await s.h.c.clearQueue();
      await s.h.settle();
      expect(s.state, const SleepTimerState.off());
      await s.h.play();
      await s.h.settle();
      expect(s.h.engine.nexts.last, isNotNull);
    });

    test('the minutes mode keeps counting', () async {
      await s.play();
      s.timer.startMinutes(10);
      await s.h.settle();
      await s.h.c.clearQueue();
      await s.pass(const Duration(minutes: 1));
      expect(s.state.mode, SleepTimerMode.minutes);
      expect(s.state.remaining, const Duration(minutes: 9));
    });
  });
}
