import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/playback/data/queue_repository.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';

import '../support/controller_harness.dart';

const _album = PlayContext(PlayContextKind.album, ref: 'k', label: 'Album');

/// Saves a session: the queue of all tracks with entry [current] loaded at
/// [positionMs].
Future<void> saveSession(
  Harness h, {
  int current = 2,
  int positionMs = 30000,
}) async {
  final items = await QueueRepository(h.db).replace(h.tracks, 1000);
  await h.settings.write('playback.queue.current_entry', items[current].entryId);
  await h.settings.write('playback.position_ms', positionMs);
  await h.settings.write('playback.context', {
    'kind': 'album',
    'ref': 'k',
    'label': 'Album',
  });
}

void main() {
  group('restart', () {
    test('same entry, paused, at the saved position', () async {
      final h = await Harness.create();
      addTearDown(h.close);
      await h.c.playTracks(h.tracks, startIndex: 2, context: _album);
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
      await h.settle();
      h.engine.tickPosition(const Duration(seconds: 30));
      await pumpEventQueue();
      await h.c.pause();
      await h.settle();
      expect(h.settings.read('playback.position_ms'), 30000);

      await h.restart();
      await h.settle();
      expect(h.c.queueState.current, 2);
      expect(h.c.queueState.currentItem!.trackId, h.tracks[2]);
      expect(h.c.intent, PlayIntent.paused);
      expect(h.c.context, _album);
      expect(h.engine.loads.single.path, '/music/t2.mp3');
      expect(h.engine.lastStart, const Duration(seconds: 30));
      expect(h.engine.lastLoadPlay, isFalse);
      expect(h.engine.commands, ['volume:100', 'load']);
      expect((await h.c.position.first).position, const Duration(seconds: 30));
      expect(h.focus.activations, 1, reason: 'only the first run played');
    });

    test('empty queue: nothing loads and persistence is live', () async {
      final h = await Harness.create();
      addTearDown(h.close);
      await h.settle();
      expect(h.engineCreations, 0);
      expect(h.c.restoring, isFalse);
    });
  });

  group('frozen session', () {
    test('nothing is written until the file loads', () async {
      final h = await Harness.create(prepare: saveSession);
      addTearDown(h.close);
      await h.settle();
      expect(h.c.restoring, isTrue);
      expect(h.settings.read('playback.position_ms'), 30000);
      expect(h.settings.read('playback.queue.current_entry'), isNotNull);

      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
      await h.settle();
      expect(h.c.restoring, isFalse);
      await h.c.seek(const Duration(seconds: 12));
      expect(h.settings.read('playback.position_ms'), 12000);
    });

    test('all restored entries unplayable: state and settings stay', () async {
      final h = await Harness.create(prepare: saveSession);
      addTearDown(h.close);
      final entry = h.settings.read('playback.queue.current_entry');
      for (final t in h.tracks) {
        await h.markMissing(t);
      }
      await h.restart();
      await h.settle();
      expect(h.c.queueState.current, 2);
      expect(h.c.intent, PlayIntent.paused);
      expect(h.c.context, _album);
      expect(h.engine.loads, isEmpty);
      expect(h.notices, isEmpty);
      expect(h.settings.read('playback.queue.current_entry'), entry);
      expect(h.settings.read('playback.position_ms'), 30000);
      expect(h.c.restoring, isTrue);
      expect(await QueueRepository(h.db).load(shuffled: false), hasLength(6));
    });

    test('a user Play then skips forward with a notice', () async {
      final h = await Harness.create(prepare: saveSession);
      addTearDown(h.close);
      await h.markMissing(h.tracks[2]);
      await h.restart();
      await h.settle();
      expect(h.c.queueState.current, 2);
      expect(h.engine.loads, isEmpty);

      await h.c.play();
      await h.settle();
      expect(h.c.queueState.current, 3);
      expect(h.engine.loads.single.path, '/music/t3.mp3');
      expect(h.notices.whereType<TrackSkipped>(), hasLength(1));
      expect(h.c.restoring, isFalse);
    });

    test('a listed file that fails to open keeps the session', () async {
      final h = await Harness.create(prepare: saveSession);
      addTearDown(h.close);
      final entry = h.settings.read('playback.queue.current_entry');
      await h.settle();
      final restored = h.loadedToken;
      final handed = h.engine.nexts.last!.token;
      // What the engine reports when the file is gone: the current fails,
      // then the handed next opens.
      h.engine.emit(EngineFailed(restored, 'cannot open'));
      h.engine.emit(EngineAdvanced(handed));
      h.engine.emit(EngineLoaded(handed, const Duration(seconds: 50)));
      await h.settle();
      expect(h.c.queueState.current, 2);
      expect(h.c.restoring, isTrue);
      expect(h.notices, isEmpty);
      expect(h.engine.loads, hasLength(1));
      expect(h.settings.read('playback.queue.current_entry'), entry);
      expect(h.settings.read('playback.position_ms'), 30000);
      expect(h.c.context, _album);

      // A user Play retries the file once ...
      await h.c.play();
      await h.settle();
      expect(h.engine.loads, hasLength(2));
      expect(h.c.queueState.current, 2);
      // ... and when it fails again, skips with a notice.
      h.engine.emit(EngineFailed(h.loadedToken, 'cannot open'));
      await h.settle();
      expect(h.notices.whereType<TrackFailed>(), hasLength(1));
      expect(h.c.queueState.current, 3);
      expect(h.engine.loads, hasLength(3));
    });

    test('a missing drive does not burst through the queue', () async {
      final h = await Harness.create(prepare: saveSession);
      addTearDown(h.close);
      await h.settle();
      // Every file is on the missing drive: the current fails, then the
      // handed next fails too.
      h.engine.emit(EngineFailed(h.loadedToken, 'cannot open'));
      h.engine.emit(EngineFailed(h.engine.nexts.last!.token, 'cannot open'));
      await h.settle();
      expect(h.engine.loads, hasLength(1), reason: 'no load after the first');
      expect(h.c.queueState.current, 2);
      expect(h.notices, isEmpty);
      expect(h.c.intent, PlayIntent.paused);
      expect(h.settings.read('playback.position_ms'), 30000);
      expect(h.c.restoring, isTrue);
    });

    test('commands made during the restore apply to the restored state', () async {
      final h = await Harness.create(prepare: saveSession);
      addTearDown(h.close);
      // No settle: the restore is still the first task of the chain.
      await h.c.next();
      await h.settle();
      expect(h.c.queueState.current, 3);
      expect(h.engine.loads.single.path, '/music/t3.mp3');
      expect(h.engine.lastStart, Duration.zero);
    });
  });

  group('position saves', () {
    test('pause, seek and stop save at once; track change saves 0', () async {
      final h = await Harness.create();
      addTearDown(h.close);
      await h.play();
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
      await h.settle();
      h.engine.tickPosition(const Duration(seconds: 20));
      await pumpEventQueue();

      await h.c.pause();
      expect(h.settings.read('playback.position_ms'), 20000);
      await h.c.seek(const Duration(seconds: 50));
      expect(h.settings.read('playback.position_ms'), 50000);
      await h.c.next();
      expect(h.settings.read('playback.position_ms'), 0);
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
      await h.c.play();
      await h.settle();
      h.engine.tickPosition(const Duration(seconds: 7));
      await pumpEventQueue();
      await h.c.stop();
      expect(h.settings.read('playback.position_ms'), 7000);
    });

    test('playing saves again every 15 s of progress, paused does not', () async {
      final h = await Harness.create();
      addTearDown(h.close);
      await h.play();
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 300)));
      await h.settle();
      Future<void> tick(int s) async {
        h.engine.tickPosition(Duration(seconds: s));
        await pumpEventQueue();
      }

      for (var s = 1; s <= 14; s++) {
        await tick(s);
      }
      expect(h.settings.read('playback.position_ms'), 0);
      await tick(15);
      expect(h.settings.read('playback.position_ms'), 15000);
      await tick(29);
      expect(h.settings.read('playback.position_ms'), 15000);
      await tick(30);
      expect(h.settings.read('playback.position_ms'), 30000);

      await h.c.pause();
      await h.settle();
      expect(h.settings.read('playback.position_ms'), 30000);
      h.engine.tickPosition(const Duration(seconds: 100));
      await pumpEventQueue();
      expect(h.settings.read('playback.position_ms'), 30000);
    });

    test('a paused open does not move the position', () async {
      final h = await Harness.create(prepare: saveSession);
      addTearDown(h.close);
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
      h.engine.tickPosition(Duration.zero);
      await h.settle();
      expect((await h.c.position.first).position, const Duration(seconds: 30));
    });
  });
}
