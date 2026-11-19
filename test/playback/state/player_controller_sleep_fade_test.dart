import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/cleanup_kind.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/playback_settings.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';
import 'package:logging/logging.dart';

import '../support/controller_harness.dart';

void main() {
  late Harness h;
  setUp(() async {
    h = await Harness.create();
  });
  tearDown(() => h.close());

  const ten = Duration(seconds: 10);

  /// Playing and loaded, with the command log cleared.
  Future<void> playing() async {
    await h.play();
    await h.settle();
    h.engine.emit(EngineLoaded(h.loadedToken, const Duration(minutes: 3)));
    await h.settle();
    h.engine.commands.clear();
  }

  List<String> volumes() =>
      h.engine.commands.where((c) => c.startsWith('volume:')).toList();

  /// Moves the clock and fires one tick of the ramp.
  Future<void> tick(int ms) async {
    h.now += ms;
    h.ticker.fire();
    await h.settle();
  }

  /// Lets queued microtasks run without waiting for the chain to be idle
  /// (it is not, while an engine call is held).
  Future<void> spin() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('ramp', () {
    test('falls to silence over the length, play state untouched', () async {
      await playing();
      await h.c.fadeOutForSleep(ten);
      expect(h.ticker.active, 1);
      for (var i = 0; i < 5; i++) {
        await tick(2000);
      }
      expect(volumes(), [
        'volume:80',
        'volume:60',
        'volume:40',
        'volume:20',
        'volume:0',
      ]);
      expect(h.engine.commands.contains('pause'), isFalse);
      expect(h.c.intent, PlayIntent.playing);
      expect(h.ticker.active, 0);
    });

    test('a late step jumps to the level of the clock', () async {
      await playing();
      await h.c.fadeOutForSleep(ten);
      await tick(7500);
      expect(volumes(), ['volume:25']);
    });

    test('is ignored while not playing', () async {
      await playing();
      await h.c.pause();
      await h.settle();
      h.engine.commands.clear();
      await h.c.fadeOutForSleep(ten);
      expect(h.ticker.active, 0);
      expect(h.engine.commands, isEmpty);
    });

    test(
      'a muted user hears 0 during the ramp and after the restore',
      () async {
        await playing();
        await h.c.setVolume(0);
        h.engine.commands.clear();
        await h.c.fadeOutForSleep(ten);
        await tick(5000);
        await h.c.sleepPause();
        await h.settle();
        expect(volumes(), ['volume:0', 'volume:0']);
        expect(h.engine.commands, ['volume:0', 'pause', 'volume:0']);
      },
    );

    test('a natural advance keeps fading', () async {
      await playing();
      await h.c.fadeOutForSleep(ten);
      await tick(2000);
      final next = h.engine.nexts.last!.token;
      h.engine.emit(EngineAdvanced(next));
      h.engine.emit(EngineLoaded(next, const Duration(minutes: 3)));
      await h.settle();
      expect(h.ticker.active, 1);
      await tick(2000);
      expect(volumes(), ['volume:80', 'volume:60']);
    });

    test('never writes the volume setting', () async {
      final changed = <String>[];
      h.settings.changes.listen(changed.add);
      await playing();
      await h.c.fadeOutForSleep(ten);
      await tick(10000);
      await h.c.endSleepFade();
      await h.c.fadeOutForSleep(ten);
      await tick(10000);
      await h.c.sleepPause();
      await h.settle();
      expect(changed.where((k) => k == volumeSetting.key), isEmpty);
      expect(h.settings.read(volumeSetting.key), isNull);
    });
  });

  group('endSleepFade', () {
    test('gives the volume back at once, playback goes on', () async {
      await playing();
      await h.c.fadeOutForSleep(ten);
      await tick(5000);
      h.engine.commands.clear();
      await h.c.endSleepFade();
      expect(h.engine.commands, ['volume:100']);
      expect(h.ticker.active, 0);
      expect(h.c.intent, PlayIntent.playing);
    });

    test('does nothing without a fade', () async {
      await playing();
      await h.c.endSleepFade();
      expect(h.engine.commands, isEmpty);
    });
  });

  group('sleepPause', () {
    test('pauses, saves the position, then restores the volume', () async {
      await playing();
      h.engine.tickPosition(const Duration(seconds: 42));
      await h.pumpTicks();
      await h.c.fadeOutForSleep(ten);
      await tick(10000);
      h.engine.commands.clear();
      await h.c.sleepPause();
      await h.settle();
      expect(h.engine.commands, ['pause', 'volume:100']);
      expect(h.c.intent, PlayIntent.paused);
      expect(h.settings.read(positionMsSetting.key), 42000);
      expect(h.ticker.active, 0);
    });

    test('while already paused: no pause, volume restored', () async {
      await h.c.playTracks([h.tracks.first], context: ctx);
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(minutes: 3)));
      await h.settle();
      await h.c.fadeOutForSleep(ten);
      await tick(10000);
      // The queue ran out: the engine paused itself, the fade goes on.
      h.engine.emit(EngineEnded(h.loadedToken));
      await h.settle();
      expect(h.c.intent, PlayIntent.paused);
      h.engine.commands.clear();
      await h.c.sleepPause();
      await h.settle();
      expect(h.engine.commands, ['volume:100']);
    });

    test('pause throws: no loud restore, the next reconcile retries', () async {
      final logs = <LogRecord>[];
      Logger.root.level = Level.ALL;
      final sub = Logger.root.onRecord.listen(logs.add);
      addTearDown(sub.cancel);
      await playing();
      await h.c.fadeOutForSleep(ten);
      await tick(10000);
      h.engine.commands.clear();
      h.engine.pauseError = StateError('engine gone');
      await h.c.sleepPause();
      await h.settle();
      expect(h.engine.commands, ['pause']);
      expect(logs.any((r) => r.message.startsWith('reconcile failed')), isTrue);

      h.engine.pauseError = null;
      h.engine.commands.clear();
      await h.c.setRepeat(RepeatMode.all);
      await h.settle();
      expect(h.engine.commands, ['pause', 'volume:100']);
    });
  });

  group('other commands end the fade', () {
    test(
      'a user pause: pause first, then the volume, even when held',
      () async {
        await playing();
        await h.c.fadeOutForSleep(ten);
        await tick(4000);
        final held = Completer<void>();
        h.engine.pauseGate = held.future;
        h.engine.commands.clear();
        final done = h.c.pause();
        await spin();
        expect(h.engine.commands, ['pause']);
        held.complete();
        await done;
        await h.settle();
        expect(h.engine.commands, ['pause', 'volume:100']);
        expect(h.ticker.active, 0);
      },
    );

    test(
      'setVolume ends the ramp; a step queued behind it is dropped',
      () async {
        await playing();
        await h.c.fadeOutForSleep(ten);
        final gate = Completer<void>();
        h.engine.volumeGate = gate.future;
        h.now += 2000;
        h.ticker.fire();
        await spin();
        expect(volumes(), ['volume:80']);
        final set = h.c.setVolume(50);
        h.now += 2000;
        h.ticker.fire();
        await spin();
        gate.complete();
        await set;
        await h.settle();
        expect(volumes(), ['volume:80', 'volume:50']);
        expect(h.settings.read(volumeSetting.key), 50);
      },
    );

    test('the volume comes back after a reload burst, not before', () async {
      await playing();
      await h.c.fadeOutForSleep(ten);
      await tick(4000);
      h.engine.commands.clear();
      await h.c.next();
      await h.settle();
      expect(h.engine.commands, ['load', 'volume:100']);
    });

    /// Every command of the controller, with what it needs to run. The
    /// source scan below keeps this list complete.
    final ending = <String, Future<void> Function(UndoToken token)>{
      'playTracks': (_) =>
          h.c.playTracks(h.tracks, startIndex: 2, context: ctx),
      'playNext': (_) => h.c.playNext([h.tracks.first]),
      'enqueue': (_) => h.c.enqueue([h.tracks.first]),
      'play': (_) => h.c.play(),
      'pause': (_) => h.c.pause(),
      'playPause': (_) => h.c.playPause(),
      'stop': (_) => h.c.stop(),
      'next': (_) => h.c.next(),
      'previous': (_) => h.c.previous(),
      'previousPressed': (_) => h.c.previousPressed(),
      'playEntry': (_) => h.c.playEntry(h.c.queueState.items.last.entryId),
      'seek': (_) => h.c.seek(const Duration(seconds: 30)),
      'seekRelative': (_) => h.c.seekRelative(const Duration(seconds: 5)),
      'setVolume': (_) => h.c.setVolume(70),
      'toggleMute': (_) => h.c.toggleMute(),
      'changeVolumeBy': (_) => h.c.changeVolumeBy(-10),
      'setRepeat': (_) => h.c.setRepeat(RepeatMode.all),
      'setRepeatTimes': (_) => h.c.setRepeatTimes(2),
      'setShuffle': (_) => h.c.setShuffle(true),
      'reshuffleUpcoming': (_) => h.c.reshuffleUpcoming(),
      'remove': (_) => h.c.remove({h.c.queueState.currentItem!.entryId}),
      'clearQueue': (_) => h.c.clearQueue(),
      'cleanup': (_) => h.c.cleanup(CleanupKind.allButCurrent),
      'undo': (t) => h.c.undo(t),
      'move': (_) => h.c.move(h.c.queueState.items.first.entryId, 3),
      'sleepPause': (_) => h.c.sleepPause(),
    };

    /// Commands of the sleep timer that leave a running fade alone.
    final keeping = <String, Future<void> Function()>{
      'setSleepStopPolicy': () => h.c.setSleepStopPolicy(null),
      'sleepPolicyChanged': () => h.c.sleepPolicyChanged(),
      'fadeOutForSleep': () => h.c.fadeOutForSleep(ten),
    };

    /// `endSleepFade` ends the fade itself; the rest are not commands.
    const others = {
      'endSleepFade',
      'settled',
      'flushPlayback',
      'flushListens',
      'dispose',
    };

    Future<UndoToken> fadingWithToken() async {
      await h.c.setVolume(100);
      await h.play();
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(minutes: 3)));
      await h.settle();
      final token = (await h.c.remove({h.c.queueState.items.last.entryId}))!;
      await h.c.fadeOutForSleep(ten);
      await tick(3000);
      expect(volumes().last, 'volume:70');
      h.engine.commands.clear();
      return token;
    }

    test('every public command of the controller ends the fade', () async {
      for (final entry in ending.entries) {
        final token = await fadingWithToken();
        await entry.value(token);
        await h.settle();
        expect(h.ticker.active, 0, reason: '${entry.key} left the ramp');
        final user = h.engine.commands.where((c) => c.startsWith('volume:'));
        expect(user.isNotEmpty, isTrue, reason: '${entry.key}: no restore');
        final level = entry.key == 'setVolume' ? 'volume:70' : null;
        if (level != null) {
          expect(user.last, level, reason: entry.key);
        }
        final before = h.engine.commands.length;
        await tick(5000);
        expect(h.engine.commands.length, before, reason: entry.key);
      }
    });

    test('the sleep commands that keep a fade leave it running', () async {
      for (final entry in keeping.entries) {
        await fadingWithToken();
        await entry.value();
        await h.settle();
        expect(h.ticker.active, 1, reason: entry.key);
        expect(volumes(), isEmpty, reason: entry.key);
      }
    });

    test('the table lists every public command of the controller', () {
      final source = File('lib/src/playback/state/player_controller.dart')
          .readAsStringSync();
      final found = RegExp(
        r'^  Future<[^\n]*?> ([a-z]\w*)\(',
        multiLine: true,
      ).allMatches(source).map((m) => m.group(1)!).toSet();
      final listed = {...ending.keys, ...keeping.keys, ...others};
      expect(found.difference(listed), isEmpty, reason: 'not in the table');
      expect(listed.difference(found), isEmpty, reason: 'not a command');
    });
  });

  group('dispose', () {
    test('leaves no live ticker and no volume after it', () async {
      await playing();
      await h.c.fadeOutForSleep(ten);
      await tick(2000);
      expect(h.ticker.active, 1);
      final dispose = h.c.dispose();
      h.now += 2000;
      h.ticker.fire();
      await dispose;
      final after = h.engine.commands.length;
      h.now += 5000;
      h.ticker.fire();
      await spin();
      expect(h.ticker.active, 0);
      expect(h.engine.commands.length, after);
    });

    test('sleep methods after it complete without error', () async {
      await playing();
      await h.c.dispose();
      final errors = <Object>[];
      await runZonedGuarded(() async {
        await h.c.fadeOutForSleep(ten);
        await h.c.endSleepFade();
        await h.c.sleepPause();
        await h.c.setSleepStopPolicy(null);
        await h.c.sleepPolicyChanged();
      }, (e, _) => errors.add(e));
      expect(errors, isEmpty);
    });
  });
}
