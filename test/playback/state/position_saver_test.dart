import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/playback/state/position_saver.dart';

import '../../support/memory_settings_store.dart';

void main() {
  late MemorySettingsStore store;
  late PositionSaver saver;

  setUp(() {
    store = MemorySettingsStore();
    saver = PositionSaver(store);
  });

  test('starts frozen: saves and snapshots are silent', () {
    saver.observe(
      entryId: 3,
      context: null,
      position: const Duration(seconds: 9),
    );
    saver.save(const Duration(seconds: 9));
    expect(store.read('playback.position_ms'), isNull);
    expect(saver.snapshot(), isNull);
  });

  test('thawed: save writes the position at once', () {
    saver.frozen = false;
    saver.observe(entryId: 3, context: null, position: Duration.zero);
    saver.save(const Duration(milliseconds: 4200));
    expect(store.read('playback.position_ms'), 4200);
  });

  test('nothing loaded: nothing to save or snapshot', () {
    saver.frozen = false;
    saver.observe(entryId: null, context: null, position: Duration.zero);
    saver.save(const Duration(seconds: 1));
    expect(store.read('playback.position_ms'), isNull);
    expect(saver.snapshot(), isNull);
  });

  test('snapshot holds the last observed entry, position and context', () {
    saver.frozen = false;
    const ctx = PlayContext(PlayContextKind.album, ref: 'k', label: 'A');
    saver.observe(entryId: 7, context: ctx, position: const Duration(seconds: 3));
    saver.observe(entryId: 7, context: ctx, position: const Duration(seconds: 8));
    final s = saver.snapshot()!;
    expect(s.entryId, 7);
    expect(s.position, const Duration(seconds: 8));
    expect(s.context, ctx);
  });

  test('while playing it writes again after 15 s of progress', () {
    saver.frozen = false;
    void at(int s, {bool playing = true}) => saver.observe(
      entryId: 1,
      context: null,
      position: Duration(seconds: s),
      playing: playing,
    );
    at(14);
    expect(store.read('playback.position_ms'), isNull);
    at(15);
    expect(store.read('playback.position_ms'), 15000);
    at(29);
    expect(store.read('playback.position_ms'), 15000);
    at(30);
    expect(store.read('playback.position_ms'), 30000);
    at(60, playing: false);
    expect(store.read('playback.position_ms'), 30000);
  });

  test('frozen, it never writes on progress', () {
    saver.observe(
      entryId: 1,
      context: null,
      position: const Duration(seconds: 40),
      playing: true,
    );
    expect(store.read('playback.position_ms'), isNull);
  });

  test('a failing store is logged, not thrown', () async {
    final failing = _FailingStore();
    final s = PositionSaver(failing)
      ..frozen = false
      ..observe(entryId: 1, context: null, position: Duration.zero);
    s.save(const Duration(seconds: 1));
    await pumpEventQueue();
    expect(failing.attempts, 1);
  });
}

class _FailingStore extends MemorySettingsStore {
  int attempts = 0;

  @override
  Future<void> write(String key, Object? value) {
    attempts++;
    return Future.error(StateError('disk full'));
  }
}
