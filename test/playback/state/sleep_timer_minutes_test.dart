import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';

import '../support/sleep_timer_harness.dart';

import 'package:kanaru/src/playback/state/playback_providers.dart';

void main() {
  late SleepHarness s;
  setUp(() async {
    s = await SleepHarness.create();
  });
  tearDown(() => s.close());

  const sec = Duration(seconds: 1);
  const min = Duration(minutes: 1);

  List<String> pauses() =>
      s.h.engine.commands.where((c) => c == 'pause').toList();

  group('gate', () {
    test('nothing is built or touched before the player exists', () async {
      final late = await SleepHarness.create(playerCreated: false);
      addTearDown(late.close);
      expect(late.state, const SleepTimerState.off());
      expect(late.controllerReads, 0);
      late.timer.startMinutes(5);
      late.timer.startTracks(3);
      late.timer.startEndOfTrack();
      expect(late.state, const SleepTimerState.off());
      expect(late.h.ticker.active, 0);

      await late.attachPlayer();
      expect(late.state, const SleepTimerState.off());
      expect(late.controllerReads, 1);
      late.timer.startMinutes(5);
      expect(late.state.mode, SleepTimerMode.minutes);
    });
  });

  group('ranges', () {
    test('minutes are kept within 1 to 720', () {
      s.timer.startMinutes(0);
      expect(s.state.remaining, min);
      s.timer.startMinutes(-1);
      expect(s.state.remaining, min);
      s.timer.startMinutes(721);
      expect(s.state.remaining, const Duration(minutes: 720));
      s.timer.startMinutes(720);
      expect(s.state.remaining, const Duration(minutes: 720));
    });

    test('adding is capped at 720 and taking off is refused at 5', () {
      s.timer.startMinutes(718);
      s.timer.addMinutes(5);
      expect(s.state.remaining, const Duration(minutes: 720));
      s.timer.addMinutes(5);
      expect(s.state.remaining, const Duration(minutes: 720));
      s.timer.startMinutes(5);
      s.timer.addMinutes(-5);
      expect(s.state.remaining, const Duration(minutes: 5));
      s.timer.startMinutes(4);
      s.timer.addMinutes(-5);
      expect(s.state.remaining, const Duration(minutes: 4));
      s.timer.startMinutes(6);
      s.timer.addMinutes(-5);
      expect(s.state.remaining, min);
    });

    test('adding nothing changes nothing', () {
      s.timer.startMinutes(10);
      s.timer.addMinutes(0);
      expect(s.state.remaining, const Duration(minutes: 10));
    });

    test('add is for the running mode only', () async {
      s.timer.startTracks(3);
      s.timer.addMinutes(5);
      expect(s.state.mode, SleepTimerMode.tracks);
      expect(s.state.remaining, Duration.zero);
      s.timer.startMinutes(10);
      s.timer.addTracks(1);
      expect(s.state.mode, SleepTimerMode.minutes);
      expect(s.state.tracksLeft, 0);
      s.timer.cancel();
      s.timer.addMinutes(5);
      expect(s.state, const SleepTimerState.off());
    });
  });

  group('counting', () {
    test('state follows the clock, rounded up to whole seconds', () async {
      await s.play();
      s.timer.startMinutes(2);
      expect(s.state.mode, SleepTimerMode.minutes);
      expect(s.state.remaining, const Duration(minutes: 2));
      expect(
        s.state.endsAt,
        DateTime.fromMillisecondsSinceEpoch(s.h.now + 120000),
      );
      await s.pass(const Duration(milliseconds: 500));
      expect(s.state.remaining, const Duration(minutes: 2));
      await s.pass(const Duration(milliseconds: 600));
      expect(s.state.remaining, const Duration(seconds: 119));
      await s.pass(const Duration(seconds: 59));
      expect(s.state.remaining, const Duration(seconds: 60));
      expect(s.state.countingPaused, isFalse);
    });

    test('counts also while playback is paused', () async {
      await s.play();
      await s.userPause();
      s.timer.startMinutes(2);
      await s.pass(const Duration(seconds: 30));
      expect(s.state.remaining, const Duration(seconds: 90));
    });

    test('starting again replaces the countdown', () async {
      s.timer.startMinutes(10);
      await s.pass(min);
      s.timer.startMinutes(3);
      expect(s.state.remaining, const Duration(minutes: 3));
      expect(s.h.ticker.active, 1);
    });
  });

  group('fade and pause', () {
    test('one fade at 10 s left, then a pause with the volume back', () async {
      await s.play();
      s.timer.startMinutes(1);
      await s.pass(const Duration(seconds: 49));
      expect(s.volumes(), isEmpty);
      await s.pass(sec);
      expect(s.h.ticker.active, 2);
      for (var i = 0; i < 4; i++) {
        await s.pass(sec * 2);
      }
      final falling = s.volumes();
      expect(falling, isNotEmpty);
      expect(falling.first, lessThan(100));
      expect([
        for (var i = 1; i < falling.length; i++) falling[i] <= falling[i - 1],
      ], everyElement(isTrue));
      expect(pauses(), isEmpty);
      await s.pass(sec * 2);
      expect(s.state, const SleepTimerState.off());
      expect(pauses(), hasLength(1));
      expect(s.volumes().last, 100);
      expect(s.h.c.intent, PlayIntent.paused);
      expect(s.h.ticker.active, 0);
      expect(s.controls.cancelledResumes, 1);
    });

    test(
      'no fade while paused inside the window; expiry only ends it',
      () async {
        await s.play();
        s.timer.startMinutes(1);
        await s.userPause();
        await s.pass(const Duration(seconds: 52));
        expect(s.state.remaining, const Duration(seconds: 8));
        expect(s.volumes(), isEmpty);
        await s.pass(sec * 10);
        expect(s.state, const SleepTimerState.off());
        expect(s.h.engine.commands, isNot(contains('pause')));
        expect(s.volumes(), isEmpty);
        expect(s.controls.cancelledResumes, 1);
        expect(s.h.ticker.active, 0);
      },
    );

    test('playing starts the fade late with what is left', () async {
      await s.play();
      s.timer.startMinutes(1);
      await s.userPause();
      await s.pass(const Duration(seconds: 55));
      await s.userPlay();
      await s.pass(sec);
      expect(s.h.ticker.active, 2);
      await s.pass(sec * 2);
      expect(s.volumes().last, lessThan(100));
    });

    test('an interrupted fade is not started again', () async {
      await s.play();
      s.timer.startMinutes(1);
      await s.pass(const Duration(seconds: 52));
      await s.userPause();
      await s.userPlay();
      await s.pass(sec);
      await s.pass(sec);
      expect(s.volumes().where((v) => v < 100), isEmpty);
      await s.pass(sec * 10);
      expect(s.state, const SleepTimerState.off());
      expect(pauses(), hasLength(1));
      expect(s.volumes().where((v) => v < 100), isEmpty);
      expect(s.controls.cancelledResumes, 1);
    });

    test('time added above 10 s ends the fade and arms it again', () async {
      await s.play();
      s.timer.startMinutes(1);
      await s.pass(const Duration(seconds: 55));
      await s.pass(sec * 2);
      expect(s.volumes().last, lessThan(100));
      s.timer.addMinutes(5);
      await s.h.settle();
      expect(s.volumes().last, 100);
      expect(s.h.ticker.active, 1);
      expect(s.state.remaining.inSeconds, greaterThan(300));
      // A new window fades again.
      await s.pass(const Duration(seconds: 300));
      await s.pass(sec * 2);
      expect(s.volumes().last, lessThan(100));
    });
  });

  group('wall clock', () {
    test(
      'a deadline found long past while playing fades 10 s, then pauses',
      () async {
        await s.play();
        s.timer.startMinutes(30);
        await s.pass(const Duration(hours: 2));
        expect(s.state.mode, SleepTimerMode.minutes);
        expect(s.state.remaining, const Duration(seconds: 10));
        expect(s.h.ticker.active, 2);
        expect(pauses(), isEmpty);
        await s.pass(sec * 5);
        expect(s.volumes().last, lessThan(100));
        expect(pauses(), isEmpty);
        await s.pass(sec * 6);
        expect(s.state, const SleepTimerState.off());
        expect(pauses(), hasLength(1));
        expect(s.volumes().last, 100);
        expect(s.controls.cancelledResumes, 1);
      },
    );

    test('a deadline found past while paused turns it off', () async {
      await s.play();
      await s.userPause();
      s.timer.startMinutes(30);
      await s.pass(const Duration(hours: 2));
      expect(s.state, const SleepTimerState.off());
      expect(s.h.engine.commands, isNot(contains('pause')));
      expect(s.controls.cancelledResumes, 1);
    });

    test('the app coming back to the foreground checks at once', () async {
      await s.play();
      s.timer.startMinutes(30);
      s.h.now += const Duration(hours: 2).inMilliseconds;
      expect(s.state.remaining, const Duration(minutes: 30));
      s.resumeApp();
      await s.h.settle();
      expect(s.state.remaining, const Duration(seconds: 10));
      expect(s.h.ticker.active, 2);
    });

    test('the foreground check does nothing when no countdown runs', () async {
      s.resumeApp();
      expect(s.state, const SleepTimerState.off());
      s.timer.startMinutes(5);
      s.timer.pauseCounting();
      s.h.now += const Duration(hours: 2).inMilliseconds;
      s.resumeApp();
      expect(s.state.countingPaused, isTrue);
      expect(s.state.remaining, const Duration(minutes: 5));
    });
  });

  group('hold', () {
    test('pausing keeps the time left, resuming sets a new deadline', () async {
      s.timer.startMinutes(10);
      await s.pass(min * 3);
      s.timer.pauseCounting();
      expect(s.state.countingPaused, isTrue);
      expect(s.state.remaining, const Duration(minutes: 7));
      expect(s.state.endsAt, isNull);
      expect(s.h.ticker.active, 0);
      s.h.now += const Duration(hours: 1).inMilliseconds;
      s.h.ticker.fire();
      expect(s.state.remaining, const Duration(minutes: 7));
      s.timer.resumeCounting();
      expect(s.state.countingPaused, isFalse);
      expect(s.state.remaining, const Duration(minutes: 7));
      expect(
        s.state.endsAt,
        DateTime.fromMillisecondsSinceEpoch(s.h.now + 7 * 60000),
      );
      await s.pass(min);
      expect(s.state.remaining, const Duration(minutes: 6));
    });

    test('a hold can be changed with the buttons', () async {
      s.timer.startMinutes(10);
      s.timer.pauseCounting();
      s.timer.addMinutes(5);
      expect(s.state.remaining, const Duration(minutes: 15));
      expect(s.state.countingPaused, isTrue);
      s.timer.addMinutes(-5);
      expect(s.state.remaining, const Duration(minutes: 10));
    });

    test('pausing ends a fade; resuming arms it again', () async {
      await s.play();
      s.timer.startMinutes(1);
      await s.pass(const Duration(seconds: 54));
      await s.pass(sec);
      expect(s.h.ticker.active, 2);
      s.timer.pauseCounting();
      await s.h.settle();
      expect(s.volumes().last, 100);
      expect(s.h.ticker.active, 0);
      expect(s.state.remaining, const Duration(seconds: 5));
      s.timer.resumeCounting();
      await s.h.settle();
      await s.pass(sec * 2);
      expect(s.volumes().last, lessThan(100));
    });

    test('pause and resume outside their mode do nothing', () {
      s.timer.pauseCounting();
      s.timer.resumeCounting();
      expect(s.state, const SleepTimerState.off());
      s.timer.startMinutes(5);
      s.timer.resumeCounting();
      expect(s.state.countingPaused, isFalse);
    });
  });

  group('cancel and teardown', () {
    test(
      'cancel in a fade gives the volume back and stops the ticker',
      () async {
        await s.play();
        s.timer.startMinutes(1);
        await s.pass(const Duration(seconds: 55));
        await s.pass(sec);
        s.timer.cancel();
        await s.h.settle();
        expect(s.state, const SleepTimerState.off());
        expect(s.volumes().last, 100);
        expect(s.h.ticker.active, 0);
        expect(s.controls.cancelledResumes, 0);
        expect(s.h.c.intent, PlayIntent.playing);
      },
    );

    test('a new controller turns the timer off', () async {
      await s.play();
      s.timer.startMinutes(10);
      await s.h.restart();
      s.container.invalidate(playerControllerProvider);
      expect(s.state, const SleepTimerState.off());
      expect(s.h.ticker.active, 0);
      await s.attachPlayer();
      s.timer.startMinutes(2);
      expect(s.state.remaining, const Duration(minutes: 2));
    });

    test('the container going away mid fade leaves nothing running', () async {
      final errors = <Object>[];
      await runZonedGuarded(() async {
        await s.play();
        s.timer.startMinutes(1);
        await s.pass(const Duration(seconds: 55));
        await s.pass(sec);
        expect(s.h.ticker.active, 2);
        s.disposeContainer();
        await s.h.settle();
        expect(s.h.ticker.active, 0);
        expect(s.volumes().last, 100);
        s.h.now += const Duration(hours: 1).inMilliseconds;
        s.h.ticker.fire();
        s.resumeApp();
        await s.end();
        await s.h.settle();
      }, (e, _) => errors.add(e));
      expect(errors, isEmpty);
      expect(s.tracksChanged.hasListener, isFalse);
    });
  });
}
