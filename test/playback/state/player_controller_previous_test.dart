import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';
import 'package:kanaru/src/playback/domain/playback_settings.dart';

import '../support/controller_harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.close());

  Future<void> restartPolicy() => h.settings.write(
    previousButtonSetting.key,
    previousButtonSetting.encode(PreviousButtonPolicy.restartAfter3s),
  );

  /// Plays from [start], loaded and at [at].
  Future<void> playAt(Duration at, {int start = 1}) async {
    await h.play(start: start);
    await h.settle();
    h.engine.emit(EngineLoaded(h.loadedToken, const Duration(minutes: 3)));
    await h.settle();
    h.engine.tickPosition(at);
    await h.settle();
  }

  group('previousPressed', () {
    test('restart policy within 3 s goes to the previous entry', () async {
      await restartPolicy();
      await playAt(const Duration(milliseconds: 2900));
      await h.c.previousPressed();
      await h.settle();
      expect(h.c.queueState.current, 0);
    });

    test('restart policy past 3 s seeks to the start, no notice', () async {
      await restartPolicy();
      await playAt(const Duration(milliseconds: 3100));
      await h.c.previousPressed();
      await h.settle();
      expect(h.c.queueState.current, 1);
      expect(h.engine.commands.last, startsWith('seek:0'));
      expect(h.notices, isEmpty);
    });

    test(
      'restart policy at the first entry past 3 s: seek, no notice',
      () async {
        await restartPolicy();
        await playAt(const Duration(seconds: 10), start: 0);
        await h.c.previousPressed();
        await h.settle();
        expect(h.c.queueState.current, 0);
        expect(h.engine.commands.last, startsWith('seek:0'));
        expect(h.notices.whereType<FirstTrack>(), isEmpty);
      },
    );

    test(
      'restart policy at the first entry within 3 s: notice and seek',
      () async {
        await restartPolicy();
        await playAt(const Duration(seconds: 1), start: 0);
        await h.c.previousPressed();
        await h.settle();
        expect(h.c.queueState.current, 0);
        expect(h.notices.whereType<FirstTrack>(), hasLength(1));
        expect(h.engine.commands.last, startsWith('seek:0'));
      },
    );

    test('policy off (default): same as previous() at any position', () async {
      await playAt(const Duration(seconds: 10));
      await h.c.previousPressed();
      await h.settle();
      expect(h.c.queueState.current, 0);
    });

    test('an empty queue does nothing', () async {
      await restartPolicy();
      await h.c.previousPressed();
      expect(h.c.queueState.items, isEmpty);
      expect(h.engine.commands, isEmpty);
      expect(h.notices, isEmpty);
    });

    test('the policy is read when the command runs', () async {
      await playAt(const Duration(seconds: 10), start: 2);
      await h.c.previousPressed();
      await h.settle();
      expect(h.c.queueState.current, 1, reason: 'default policy');
      await restartPolicy();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(minutes: 3)));
      await h.settle();
      h.engine.tickPosition(const Duration(seconds: 10));
      await h.settle();
      await h.c.previousPressed();
      await h.settle();
      expect(h.c.queueState.current, 1, reason: 'restart policy applied');
    });

    test('previous() ignores the policy (swipes)', () async {
      await restartPolicy();
      await playAt(const Duration(seconds: 10));
      await h.c.previous();
      await h.settle();
      expect(h.c.queueState.current, 0);
    });
  });
}
