import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/media_kit_engine.dart';
import 'package:kanaru/src/playback/data/silent_audio_engine.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/state/audio_engine_provider.dart';

EngineMedia media(int entry, {int handoff = 1}) => EngineMedia(
  EngineToken(entryId: entry, generation: 1, handoff: handoff),
  '/music/$entry.mp3',
);

void main() {
  test('the default factory is the silent engine under flutter test', () {
    expect(Platform.environment['FLUTTER_TEST'], 'true');
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final engine = c.read(audioEngineFactoryProvider)();
    addTearDown(engine.dispose);
    expect(engine, isA<SilentAudioEngine>());
    expect(engine, isNot(isA<MediaKitEngine>()));
  });

  // Logical time (testWidgets runs in fake async): load does not matter.
  testWidgets('load reports a duration; playing advances to next, then ends', (
    tester,
  ) async {
    final e = SilentAudioEngine(
      durationOf: (_) => const Duration(milliseconds: 100),
      tick: const Duration(milliseconds: 40),
    );
    final events = <EngineEvent>[];
    e.events.listen(events.add);
    await e.load(media(1), next: media(2), play: true);
    await tester.pump(const Duration(milliseconds: 450));
    final names = events.map((x) => x.runtimeType.toString()).toList();
    expect(names.first, 'EngineLoaded');
    expect(
      names,
      containsAllInOrder(['EngineAdvanced', 'EngineLoaded', 'EngineEnded']),
    );
    expect(events.whereType<EngineEnded>().single.token.entryId, 2);
    expect(e.isPlaying, isFalse);
    await e.dispose();
  });

  testWidgets('it does not tick while paused or after dispose', (tester) async {
    final e = SilentAudioEngine(tick: const Duration(milliseconds: 20));
    final ticks = <Duration>[];
    e.position.listen(ticks.add);
    await e.load(media(1), play: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(ticks, isEmpty);
    await e.play();
    await tester.pump(const Duration(milliseconds: 100));
    expect(ticks, isNotEmpty);
    await e.dispose();
    await e.play(); // no-op after dispose
    expect(e.isPlaying, isFalse);
  });

  test('seek and stop', () async {
    final e = SilentAudioEngine();
    addTearDown(e.dispose);
    final events = <EngineEvent>[];
    e.events.listen(events.add);
    await e.load(media(1), play: false, start: const Duration(seconds: 5));
    await e.seek(const Duration(seconds: 9));
    await e.stop();
    await pumpEventQueue();
    expect(
      events.whereType<EngineSeeked>().single.position,
      const Duration(seconds: 9),
    );
    await e.seek(const Duration(seconds: 1)); // nothing loaded: ignored
    await pumpEventQueue();
    expect(events.whereType<EngineSeeked>(), hasLength(1));
  });
}
