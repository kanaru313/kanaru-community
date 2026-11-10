import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';

import '../support/controller_harness.dart';

void main() {
  late Harness h;
  setUp(() async => h = await Harness.create());
  tearDown(() => h.close());

  group('commands', () {
    test('invalid input throws and leaves the state untouched', () async {
      await expectLater(
        h.c.playTracks(const [], context: ctx),
        throwsArgumentError,
      );
      await expectLater(
        h.c.playTracks(h.tracks, startIndex: 6, context: ctx),
        throwsRangeError,
      );
      await expectLater(
        h.c.playTracks(h.tracks, startIndex: -1, context: ctx),
        throwsRangeError,
      );
      expect(h.c.queueState.items, isEmpty);
      expect(h.engineCreations, 0);
    });

    test('empty playNext and enqueue are no-ops', () async {
      await h.c.playNext(const []);
      await h.c.enqueue(const []);
      expect(h.c.queueState.items, isEmpty);
    });

    test('playTracks starts the chosen track and loads the next one', () async {
      await h.play(start: 2);
      await h.settle();
      expect(h.c.queueState.currentItem?.trackId, h.tracks[2]);
      expect(h.engine.loads.single.path, '/music/t2.mp3');
      expect(h.engine.nexts.single?.path, '/music/t3.mp3');
      expect(h.engine.lastLoadPlay, isTrue);
      expect(h.focus.activations, 1);
    });

    test('playTracks completes while the engine load is pending', () async {
      final gate = Completer<void>();
      h.engine.loadGate = gate.future;
      await h.play(); // returns although load() waits
      await pumpEventQueue();
      expect(h.engine.loads, hasLength(1));
      gate.complete();
      await h.settle();
    });

    test('shuffle starts with the chosen track first', () async {
      await h.play(start: 3, shuffle: true);
      await h.settle();
      expect(h.c.queueState.shuffled, isTrue);
      expect(h.c.queueState.current, 0);
      expect(h.c.queueState.currentItem?.trackId, h.tracks[3]);
      expect(h.settings.read('playback.shuffle'), true);
    });

    test(
      'playNext and enqueue on an empty queue behave like playTracks',
      () async {
        await h.c.playNext(h.tracks.sublist(0, 2));
        await h.settle();
        expect(h.c.queueState.length, 2);
        expect(h.c.intent, PlayIntent.playing);
        expect(h.c.context, const PlayContext(PlayContextKind.queue));
        expect(h.engine.loads, hasLength(1));
      },
    );

    test(
      'playNext lands after the current entry, enqueue at the end',
      () async {
        await h.play(start: 1);
        await h.c.playNext([h.tracks[5]]);
        await h.c.playNext([h.tracks[4]]);
        await h.c.enqueue([h.tracks[0]]);
        await h.settle();
        expect(h.order(), [0, 1, 5, 4, 2, 3, 4, 5, 0]);
        // The new next entry was handed to the engine.
        expect(h.engine.commands, contains('setNext'));
      },
    );

    test('the settings reflect the queue', () async {
      await h.play(start: 1);
      await h.settle();
      expect(
        h.settings.read('playback.queue.current_entry'),
        h.c.queueState.currentItem!.entryId,
      );
      expect(h.settings.read('playback.context'), isA<Map<String, Object?>>());
    });
  });

  group('transport', () {
    test('pause, play and stop follow the intent', () async {
      await h.play();
      await h.settle();
      await h.c.pause();
      await h.settle();
      expect(h.engine.commands.last, 'pause');
      await h.c.play();
      await h.settle();
      expect(h.engine.commands.last, 'play');
      await h.c.stop();
      await h.settle();
      expect(h.engine.commands.last, 'stop');
      expect(h.c.queueState.current, 0, reason: 'the entry stays');
      expect(h.focus.deactivations, 1);
      await h.c.play();
      await h.settle();
      expect(
        h.engine.loads,
        hasLength(2),
        reason: 'a stopped engine loads again',
      );
    });

    test('playPause toggles', () async {
      await h.play();
      await h.c.playPause();
      expect(h.c.intent, PlayIntent.paused);
      await h.c.playPause();
      expect(h.c.intent, PlayIntent.playing);
    });

    test(
      'next and previous move; previous at the first entry restarts',
      () async {
        await h.play(start: 1);
        await h.settle();
        await h.c.next();
        await h.settle();
        expect(h.c.queueState.current, 2);
        await h.c.previous();
        await h.c.previous();
        await h.settle();
        expect(h.c.queueState.current, 0);
        await h.c.previous();
        await h.settle();
        expect(h.c.queueState.current, 0);
        expect(h.notices.whereType<FirstTrack>(), hasLength(1));
        expect(h.engine.commands.last, startsWith('seek:0'));
      },
    );

    test('next at the last entry posts the end notice and stays', () async {
      await h.play(start: 5);
      await h.settle();
      await h.c.next();
      expect(h.notices.single, isA<QueueEnd>());
      expect(h.c.queueState.current, 5);
    });

    test('next while paused loads the next entry paused', () async {
      await h.play();
      await h.settle();
      await h.c.pause();
      await h.c.next();
      await h.settle();
      expect(h.engine.loads, hasLength(2));
      expect(h.engine.lastLoadPlay, isFalse);
    });

    test(
      '4 parallel next calls and a stop end stopped with one load',
      () async {
        await h.play();
        await h.settle();
        final all = <Future<void>>[
          for (var i = 0; i < 4; i++) h.c.next(),
          h.c.stop(),
        ];
        await Future.wait(all);
        await h.settle();
        expect(h.c.intent, PlayIntent.stopped);
        expect(h.engine.loads, hasLength(1));
        expect(h.engine.commands.last, 'stop');
      },
    );

    test('a burst of nexts gives one load', () async {
      await h.play();
      await h.settle();
      await Future.wait([for (var i = 0; i < 4; i++) h.c.next()]);
      await h.settle();
      expect(h.engine.loads, hasLength(2));
      expect(h.engine.loads.last.path, '/music/t4.mp3');
    });

    test('seek clamps to the duration and is sent to the engine', () async {
      await h.play();
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 100)));
      await h.settle();
      await h.c.seek(const Duration(seconds: 500));
      await h.c.seek(const Duration(seconds: -5));
      await h.c.seek(const Duration(seconds: 30));
      await h.c.seekRelative(const Duration(seconds: 10));
      expect(h.engine.commands.where((c) => c.startsWith('seek')), [
        'seek:100000',
        'seek:0',
        'seek:30000',
        'seek:40000',
      ]);
    });

    group('position ticks around a seek', () {
      late Completer<void> gate;
      late Future<void> seek;

      // Not h.pumpTicks()/settle(): they wait for the chain, which the
      // pending seek holds.
      Future<void> letEventsRun() async {
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      Future<void> startSeek(Duration to) async {
        await h.play();
        await h.settle();
        h.engine.emit(
          EngineLoaded(h.loadedToken, const Duration(seconds: 200)),
        );
        await h.settle();
        h.engine.tickPosition(const Duration(seconds: 10));
        await h.settle();
        gate = Completer<void>();
        h.engine.seekGate = gate.future;
        seek = h.c.seek(to);
        await letEventsRun();
      }

      test('an old tick while the seek is in flight is dropped', () async {
        await startSeek(const Duration(seconds: 120));
        h.engine.tickPosition(const Duration(seconds: 11));
        await letEventsRun();
        gate.complete();
        await seek;
        await h.settle();
        expect(h.settings.read('playback.position_ms'), 120000);
        h.engine.tickPosition(const Duration(seconds: 12));
        await h.settle();
        h.engine.tickPosition(const Duration(seconds: 120, milliseconds: 400));
        await h.settle();
        final p = await h.c.position.first;
        expect(p.position, const Duration(seconds: 120, milliseconds: 400));
      });

      test('a seek that never lands does not freeze the position', () async {
        await startSeek(const Duration(seconds: 120));
        gate.complete();
        await seek;
        h.now += 3500;
        h.engine.tickPosition(const Duration(seconds: 15));
        await h.settle();
        final p = await h.c.position.first;
        expect(p.position, const Duration(seconds: 15));
      });
    });

    test('volume is clamped, stored and sent', () async {
      await h.play();
      await h.settle();
      await h.c.setVolume(150);
      expect(h.settings.read('playback.volume'), 100);
      await h.c.setVolume(35);
      expect(h.engine.commands, contains('volume:35'));
    });

    test('shuffle on and off, repeat mode saved', () async {
      await h.play(start: 1);
      await h.settle();
      final before = h.order();
      await h.c.setShuffle(true);
      expect(h.c.queueState.shuffled, isTrue);
      expect(h.c.queueState.current, 1);
      expect(h.order().sublist(0, 2), before.sublist(0, 2));
      await h.c.setShuffle(false);
      expect(h.order(), before, reason: 'shuffle off restores the user order');
      expect(h.c.queueState.currentItem?.trackId, h.tracks[1]);
      await h.c.setRepeat(RepeatMode.all);
      expect(h.c.queueState.repeat, RepeatMode.all);
      expect(h.settings.read('playback.repeat'), 'all');
      await h.c.setRepeat(RepeatMode.off);
      expect(h.c.queueState.repeat, RepeatMode.off);
      expect(h.settings.read('playback.repeat'), 'off');
    });

    test('focus denied keeps the intent paused and posts a notice', () async {
      h.focus.grant = false;
      await h.play();
      await h.settle();
      expect(h.c.intent, PlayIntent.paused);
      expect(h.notices.whereType<FocusDenied>(), hasLength(1));
      expect(h.engine.lastLoadPlay, isFalse);
    });

    test('a hung focus request counts as denied after the timeout', () async {
      final slow = await Harness.create(
        focusTimeout: const Duration(milliseconds: 20),
      );
      addTearDown(slow.close);
      slow.focus.hang = true;
      await slow.play();
      await slow.settle();
      expect(slow.c.intent, PlayIntent.paused);
      expect(slow.notices.whereType<FocusDenied>(), hasLength(1));
    });

    test('focus is requested again on a later play', () async {
      await h.play();
      await h.settle();
      await h.c.pause();
      await h.settle();
      await h.c.play();
      await h.settle();
      expect(h.focus.activations, 2);
    });

    test('play with nothing queued posts QueueEmpty', () async {
      await h.c.play();
      expect(h.notices.single, isA<QueueEmpty>());
      expect(h.engineCreations, 0);
    });
  });

  group('streams', () {
    test(
      'a late subscriber gets the current snapshot; values are distinct',
      () async {
        await h.play(start: 2);
        await h.settle();
        final seen = <int?>[];
        final sub = h.c.nowPlaying.listen((n) => seen.add(n.index));
        await pumpEventQueue();
        expect(seen, [2]);
        await h.c.pause();
        await h.c.pause();
        await h.settle();
        expect(seen, [2, 2], reason: 'playing -> paused is one more value');
        await sub.cancel();
      },
    );

    test('now playing carries playing, length and context', () async {
      await h.play(start: 1);
      await h.settle();
      final n = await h.c.nowPlaying.first;
      expect(n.playing, isTrue);
      expect(n.length, 6);
      expect(n.trackId, h.tracks[1]);
      expect(n.context, ctx);
      await h.c.pause();
      await h.settle();
      expect((await h.c.nowPlaying.first).playing, isFalse);
    });
  });

  test('a database failure leaves memory and the table in step', () async {
    await h.play();
    await h.settle();
    final before = h.c.queueState;
    await expectLater(h.c.playNext([const TrackId(99999)]), throwsA(anything));
    expect(h.c.queueState, before);
    // The chain keeps working.
    await h.c.playNext([h.tracks[1]]);
    expect(h.c.queueState.length, 7);
  });
}
