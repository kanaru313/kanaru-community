import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/domain/settings_store.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/state/playback_flush.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';

import '../support/controller_harness.dart';

/// Forwards to [inner] and notes what the saved position was at each flush.
class _SpyStore implements SettingsStore {
  _SpyStore(this.inner);
  final SettingsStore inner;
  final positionsAtFlush = <Object?>[];

  @override
  Object? read(String key) => inner.read(key);
  @override
  Future<void> write(String key, Object? value) => inner.write(key, value);
  @override
  Stream<String> get changes => inner.changes;
  @override
  Future<void> flush() async => positionsAtFlush.add(inner.read('playback.position_ms'));
}

void main() {
  late Harness h;
  late _SpyStore spy;
  late ProviderContainer container;
  var created = 0;

  setUp(() async {
    created = 0;
    h = await Harness.create();
    spy = _SpyStore(h.settings);
    container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(spy),
        playerControllerProvider.overrideWith((ref) {
          created++;
          return h.c;
        }),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await h.close();
  });

  group('flush hook', () {
    test('does nothing, and creates nothing, without a controller', () async {
      await playbackFlushHook(container);
      expect(created, 0);
      expect(spy.positionsAtFlush, isEmpty);
    });

    test('writes the session, then flushes the settings store', () async {
      container.read(playerControllerProvider);
      await h.play(start: 1);
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
      await h.settle();
      h.engine.tickPosition(const Duration(seconds: 42));
      await pumpEventQueue();

      await playbackFlushHook(container);
      expect(h.settings.read('playback.position_ms'), 42000);
      expect(
        h.settings.read('playback.queue.current_entry'),
        h.c.queueState.currentItem!.entryId,
      );
      expect(h.settings.read('playback.context'), isNotNull);
      expect(spy.positionsAtFlush, [42000], reason: 'flush came after the write');
    });

    test('a frozen restored session is not written', () async {
      final f = await Harness.create(
        prepare: (x) async {
          await x.settings.write('playback.position_ms', 5000);
        },
      );
      addTearDown(f.close);
      await f.settle();
      expect(f.c.restoring, isFalse, reason: 'empty queue thaws');
      // Freeze by hand as a restored session would be.
      f.c.restoring = true;
      final c = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(_SpyStore(f.settings)),
          playerControllerProvider.overrideWithValue(f.c),
        ],
      );
      addTearDown(c.dispose);
      c.read(playerControllerProvider);
      await playbackFlushHook(c);
      expect(f.settings.read('playback.position_ms'), 5000);
    });

    test('finishes at once while a command blocks the chain', () async {
      container.read(playerControllerProvider);
      final gate = Completer<void>();
      h.engine.loadGate = gate.future; // the engine never finishes its load
      addTearDown(() => gate.complete());
      await h.play();
      await pumpEventQueue();
      // A user command is now queued behind the stuck load.
      unawaited(h.c.pause());
      final sw = Stopwatch()..start();
      await playbackFlushHook(container);
      expect(sw.elapsedMilliseconds, lessThan(100));
      expect(spy.positionsAtFlush, hasLength(1));
    });

    test('a throwing settings flush still flushes the listen', () async {
      final c = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(_FlushThrows(h.settings)),
          playerControllerProvider.overrideWithValue(h.c),
        ],
      );
      addTearDown(c.dispose);
      c.read(playerControllerProvider);
      await h.play();
      await h.settle();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 60)));
      await h.settle();
      for (var p = 0; p <= 40; p += 5) {
        h.mono += const Duration(seconds: 5);
        h.engine.tickPosition(Duration(seconds: p));
        await pumpEventQueue();
      }
      await playbackFlushHook(c);
      final rows = await h.db.customSelect('SELECT COUNT(*) AS n FROM play_log').getSingle();
      expect(rows.read<int>('n'), 1);
    });

    test('a failing write does not stop the settings flush', () async {
      final bad = _SpyStore(_ThrowingStore(h.settings));
      final c = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(bad),
          playerControllerProvider.overrideWithValue(h.c),
        ],
      );
      addTearDown(c.dispose);
      c.read(playerControllerProvider);
      await h.play();
      await h.settle();
      await playbackFlushHook(c);
      expect(bad.positionsAtFlush, hasLength(1));
    });
  });

  group('before-exit hook', () {
    test('does nothing without a controller', () async {
      await pausePlaybackOnExitHook(container);
      expect(created, 0);
    });

    test('pauses a playing controller', () async {
      container.read(playerControllerProvider);
      await h.play();
      await h.settle();
      await pausePlaybackOnExitHook(container);
      await h.settle();
      expect(h.c.intent, PlayIntent.paused);
      expect(h.engine.commands.last, 'pause');
    });

    test('a pause racing the flush is safe', () async {
      container.read(playerControllerProvider);
      await h.play();
      await h.settle();
      await Future.wait([
        pausePlaybackOnExitHook(container),
        playbackFlushHook(container),
      ]);
      expect(h.c.intent, PlayIntent.paused);
    });
  });
}

class _ThrowingStore implements SettingsStore {
  _ThrowingStore(this.inner);
  final SettingsStore inner;
  @override
  Object? read(String key) => inner.read(key);
  @override
  Future<void> write(String key, Object? value) =>
      Future.error(StateError('disk full'));
  @override
  Stream<String> get changes => inner.changes;
  @override
  Future<void> flush() => inner.flush();
}

class _FlushThrows extends _SpyStore {
  _FlushThrows(super.inner);
  @override
  Future<void> flush() => Future.error(StateError('disk full'));
}
