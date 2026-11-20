import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';

import '../support/sleep_timer_harness.dart';

/// A call pauses the music (the system controls post a plain `Pause`, which
/// the bridge turns into `controller.pause()`, so `userPause` is the same
/// path); the timer then runs out. Expiry must not stop or reload the track.
void main() {
  late SleepHarness s;
  late PlaybackPosition last;
  setUp(() async {
    s = await SleepHarness.create();
    s.h.c.position.listen((p) => last = p);
    await s.play();
    s.h.engine.tickPosition(const Duration(seconds: 30));
    await s.h.settle();
  });
  tearDown(() => s.close());

  const sec = Duration(seconds: 1);
  const kept = Duration(seconds: 30);
  const length = Duration(minutes: 3);

  void expectUntouched() {
    expect(s.state, const SleepTimerState.off());
    expect(last.position, kept);
    expect(last.duration, length);
    final cmds = s.h.engine.commands;
    expect(cmds, isNot(contains('stop')));
    expect(cmds, isNot(contains('load')));
    expect(cmds, isNot(contains('play')));
    expect(cmds.where((c) => c.startsWith('seek:')), isEmpty);
    expect(s.h.c.intent, PlayIntent.paused);
    expect(s.h.focus.deactivations, 0);
  }

  test('deadline passing while paused by a call keeps position and '
      'duration', () async {
    s.timer.startMinutes(1);
    await s.pass(const Duration(seconds: 20));
    expect(last.position, kept);
    await s.userPause();
    await s.pass(const Duration(seconds: 60));
    expectUntouched();
  });

  test('paused inside the fade window: volume back, position kept', () async {
    s.timer.startMinutes(1);
    await s.pass(const Duration(seconds: 55));
    await s.pass(sec * 2);
    expect(s.volumes().last, lessThan(100));
    // Not `userPause`: its log reset would hide the volume restore.
    await s.h.c.pause();
    await s.h.settle();
    await s.pass(const Duration(seconds: 10));
    expectUntouched();
    expect(s.volumes().last, 100);
    expect(s.h.ticker.active, 0);
  });
}
