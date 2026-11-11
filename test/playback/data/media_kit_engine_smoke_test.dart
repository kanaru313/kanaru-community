import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/media_kit_engine.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:media_kit/media_kit.dart';

/// Opt-in: loads libmpv. Run with `KANARU_MPV_SMOKE=1 flutter test <file>`.
/// `ao=null`: nothing is played aloud.
final _enabled = Platform.environment['KANARU_MPV_SMOKE'] == '1';

Uint8List _wav(int seconds) {
  const rate = 8000;
  final n = rate * seconds;
  final b = ByteData(44 + n);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      b.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  b.setUint32(4, 36 + n, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, rate, Endian.little);
  b.setUint32(28, rate, Endian.little);
  b.setUint16(32, 1, Endian.little);
  b.setUint16(34, 8, Endian.little);
  tag(36, 'data');
  b.setUint32(40, n, Endian.little);
  for (var i = 0; i < n; i++) {
    b.setUint8(44 + i, 128 + (i % 40));
  }
  return b.buffer.asUint8List();
}

void main() {
  late Directory dir;

  setUpAll(() {
    if (!_enabled) return;
    MediaKit.ensureInitialized();
    dir = Directory.systemTemp.createTempSync('kanaru_smoke');
    File('${dir.path}/a.wav').writeAsBytesSync(_wav(3));
    File('${dir.path}/b.wav').writeAsBytesSync(_wav(3));
  });
  tearDownAll(() {
    if (_enabled) dir.deleteSync(recursive: true);
  });

  EngineMedia m(int id, String f) => EngineMedia(
    EngineToken(entryId: id, generation: 1, handoff: id),
    '${dir.path}/$f',
  );

  Future<MediaKitEngine> newEngine() async {
    final e = MediaKitEngine(
      player: Player(configuration: const PlayerConfiguration()),
    );
    await e.set('ao', 'null');
    return e;
  }

  test('start position, gapless advance, two entries, options', () async {
    final engine = await newEngine();
    addTearDown(engine.dispose);
    final events = <EngineEvent>[];
    engine.events.listen(events.add);
    final sw = Stopwatch()..start();
    await engine.load(
      m(1, 'a.wav'),
      next: m(2, 'b.wav'),
      play: true,
      start: const Duration(seconds: 1),
    );
    // The first tick is near the start offset, not near zero.
    final first = await engine.position
        .firstWhere((p) => p > Duration.zero)
        .timeout(const Duration(seconds: 5));
    expect(first, greaterThanOrEqualTo(const Duration(milliseconds: 900)));
    // A 3 s file started at 1 s ends after about 2 s: the advance proves the
    // start was honoured (from zero it would take 3 s).
    await engine.events
        .firstWhere((e) => e is EngineAdvanced)
        .timeout(const Duration(seconds: 10));
    expect(sw.elapsed, lessThan(const Duration(milliseconds: 2900)));
    // The next entry starts at its own beginning, not at the resume offset.
    expect(double.tryParse(await engine.get('time-pos')) ?? 0, lessThan(1.0));
    expect(events.whereType<EngineFailed>(), isEmpty);
    expect(int.parse(await engine.get('playlist-count')), 1);
    expect(await engine.get('sub-auto'), 'no');
    expect(await engine.get('keep-open'), 'yes');
  }, skip: _enabled ? false : 'set KANARU_MPV_SMOKE=1 to load libmpv');

  test('a reload while playing does not fail', () async {
    final engine = await newEngine();
    addTearDown(engine.dispose);
    final events = <EngineEvent>[];
    engine.events.listen(events.add);
    await engine.load(m(1, 'a.wav'), play: true);
    await engine.position
        .firstWhere((p) => p > Duration.zero)
        .timeout(const Duration(seconds: 5));
    final loaded = engine.events
        .firstWhere((e) => e is EngineLoaded && e.token.entryId == 2)
        .timeout(const Duration(seconds: 5));
    await engine.load(m(2, 'b.wav'), play: true);
    await loaded;
    expect(events.whereType<EngineFailed>(), isEmpty);
  }, skip: _enabled ? false : 'set KANARU_MPV_SMOKE=1 to load libmpv');

  test('the end is reported once; a late next advances and stays paused if asked', () async {
    final engine = await newEngine();
    addTearDown(engine.dispose);
    final events = <EngineEvent>[];
    engine.events.listen(events.add);
    await engine.load(
      m(1, 'a.wav'),
      play: true,
      start: const Duration(milliseconds: 2400),
    );
    await engine.events
        .firstWhere((e) => e is EngineEnded)
        .timeout(const Duration(seconds: 10));
    await engine.pause(); // what the controller does at the end of the queue
    await engine.setNext(m(2, 'b.wav'));
    await engine.events
        .firstWhere((e) => e is EngineAdvanced)
        .timeout(const Duration(seconds: 5));
    expect(events.whereType<EngineEnded>(), hasLength(1));
    expect(events.whereType<EngineFailed>(), isEmpty);
    expect(
      await engine.get('pause'),
      'yes',
      reason: 'paused entry stays paused',
    );
    expect(
      await engine.get('playlist-pos'),
      '0',
      reason: 'finished entry trimmed',
    );
    expect(await engine.get('path'), endsWith('b.wav'));
    // Play now: the appended entry plays from its start; the finished one
    // does not come back.
    await engine.play();
    // Read at once: a loaded machine can stretch any wait past the file length.
    expect(await engine.get('pause'), 'no');
    expect(await engine.get('path'), endsWith('b.wav'));
    expect(await engine.get('playlist-pos'), '0');
    expect(double.tryParse(await engine.get('time-pos')) ?? 0, lessThan(1.5));
  }, skip: _enabled ? false : 'set KANARU_MPV_SMOKE=1 to load libmpv');
}
