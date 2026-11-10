import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/load_failure_guard.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';

EngineMedia _media(int id) => EngineMedia(
  EngineToken(entryId: id, generation: 1, handoff: id),
  '/music/$id.mp3',
);

void main() {
  test('a body that completes emits nothing', () async {
    final events = <EngineEvent>[];
    var failed = false;
    await guardLoad(
      current: _media(1),
      emit: events.add,
      onFailed: () => failed = true,
      body: () async {},
    );
    expect(events, isEmpty);
    expect(failed, isFalse);
  });

  test(
    'a throwing body fails the current token and resets the engine',
    () async {
      final events = <EngineEvent>[];
      var failed = false;
      final cur = _media(1);
      await guardLoad(
        current: cur,
        emit: events.add,
        onFailed: () => failed = true,
        body: () async => throw StateError('open failed'),
      );
      expect(failed, isTrue);
      expect((events.single as EngineFailed).token, cur.token);
    },
  );
}
