import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/mpv_playlist_tracker.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';

EngineToken tok(int entry, {int gen = 1, int handoff = 1}) =>
    EngineToken(entryId: entry, generation: gen, handoff: handoff);

MpvSnapshot snap({
  int pos = 0,
  int? id,
  int count = 1,
  bool idle = false,
  bool eof = false,
  double? seconds,
}) => MpvSnapshot(
  playingPos: pos,
  playingId: id,
  count: count,
  idle: idle,
  eofReached: eof,
  duration: seconds == null
      ? null
      : Duration(milliseconds: (seconds * 1000).round()),
);

List<String> kinds(List<EngineEvent> e) => [
  for (final x in e)
    switch (x) {
      EngineAdvanced(:final token) =>
        'advanced:${token.entryId}.${token.handoff}',
      EngineLoaded(:final token) => 'loaded:${token.entryId}',
      EngineFailed(:final token) => 'failed:${token.entryId}',
      EngineEnded(:final token) => 'ended:${token.entryId}',
      EngineSeeked() => 'seeked',
    },
];

void main() {
  late MpvPlaylistTracker t;
  setUp(() {
    t = MpvPlaylistTracker()..startLoad(tok(1), 10);
  });

  test('loaded fires once when the duration appears', () {
    expect(t.onSnapshot(snap(id: 10)), isEmpty);
    expect(kinds(t.onSnapshot(snap(id: 10, seconds: 3))), ['loaded:1']);
    expect(t.onSnapshot(snap(id: 10, seconds: 3)), isEmpty);
  });

  test('promotes only when mpv plays the handed-over entry id', () {
    t.onSnapshot(snap(id: 10, seconds: 3));
    t.registerNext(tok(2, handoff: 2), 11);
    expect(t.onSnapshot(snap(id: 10, count: 2, seconds: 3)), isEmpty);
    expect(t.onSnapshot(snap(id: 99, count: 2)), isEmpty);
    expect(kinds(t.onSnapshot(snap(pos: 1, id: 11, count: 2, seconds: 4))), [
      'advanced:2.2',
      'loaded:2',
    ]);
  });

  test('the same file queued twice is two entries', () {
    t.onSnapshot(snap(id: 10, seconds: 3));
    t.registerNext(tok(1, handoff: 2), 11); // same queue entry, new loop
    final e = t.onSnapshot(snap(pos: 1, id: 11, count: 2, seconds: 3));
    expect(kinds(e), ['advanced:1.2', 'loaded:1']);
  });

  test(
    'repeat one: two handoffs of one entry give distinct advanced tokens',
    () {
      t.onSnapshot(snap(id: 10, seconds: 3));
      final seen = <EngineToken>[];
      var id = 10;
      for (var loop = 2; loop <= 3; loop++) {
        t.registerNext(tok(1, handoff: loop), ++id);
        final e = t.onSnapshot(snap(pos: 1, id: id, count: 2, seconds: 3));
        seen.add((e.first as EngineAdvanced).token);
      }
      expect(seen.toSet(), hasLength(2));
    },
  );

  test('a duration read with the advance is reported for the new entry', () {
    t.onSnapshot(snap(id: 10, seconds: 3));
    t.registerNext(tok(2), 11);
    final e = t.onSnapshot(snap(pos: 1, id: 11, count: 2, seconds: 7));
    expect(e.last, isA<EngineLoaded>());
    expect((e.last as EngineLoaded).duration, const Duration(seconds: 7));
  });

  test('an entry mpv left without a duration failed', () {
    t.registerNext(tok(2), 11);
    final e = t.onSnapshot(snap(pos: 1, id: 11, count: 2, seconds: 5));
    expect(kinds(e), ['failed:1', 'advanced:2.1', 'loaded:2']);
  });

  test(
    'idle with a next: a current that never loaded failed, and the next too',
    () {
      t.registerNext(tok(2), 11);
      expect(kinds(t.onSnapshot(snap(pos: -1, idle: true, count: 0))), [
        'failed:1',
        'failed:2',
      ]);
    },
  );

  test(
    'idle with a next after the current had loaded: only the next failed',
    () {
      t.onSnapshot(snap(id: 10, seconds: 3));
      t.registerNext(tok(2), 11);
      expect(kinds(t.onSnapshot(snap(pos: -1, idle: true, count: 0))), [
        'failed:2',
      ]);
    },
  );

  test('end of file on the last entry reports ended once', () {
    t.onSnapshot(snap(id: 10, seconds: 3));
    expect(kinds(t.onSnapshot(snap(id: 10, seconds: 3, eof: true))), [
      'ended:1',
    ]);
    expect(t.onSnapshot(snap(id: 10, seconds: 3, eof: true)), isEmpty);
  });

  test(
    'end of file with a next waiting asks for playlist-next and is not ended',
    () {
      t.onSnapshot(snap(id: 10, seconds: 3));
      t.registerNext(tok(2), 11);
      final s = snap(id: 10, count: 2, seconds: 3, eof: true);
      expect(t.needsPlaylistNext(s), isTrue);
      expect(t.onSnapshot(s), isEmpty);
      expect(kinds(t.onSnapshot(snap(pos: 1, id: 11, count: 2, seconds: 3))), [
        'advanced:2.1',
        'loaded:2',
      ]);
    },
  );

  test('a late append after the end of file advances via playlist-next', () {
    t.onSnapshot(snap(id: 10, seconds: 3, eof: true)); // ended
    t.registerNext(tok(2), 11);
    expect(
      t.needsPlaylistNext(snap(id: 10, count: 2, seconds: 3, eof: true)),
      isTrue,
    );
  });

  test('a seek back from the end re-arms the end report', () {
    t.onSnapshot(snap(id: 10, seconds: 3));
    expect(kinds(t.onSnapshot(snap(id: 10, seconds: 3, eof: true))), [
      'ended:1',
    ]);
    expect(t.onSnapshot(snap(id: 10, seconds: 3)), isEmpty);
    expect(kinds(t.onSnapshot(snap(id: 10, seconds: 3, eof: true))), [
      'ended:1',
    ]);
  });

  test('no playing entry without idle is a transient gap, not a failure', () {
    expect(t.onSnapshot(snap(pos: -1, count: 1)), isEmpty);
    expect(kinds(t.onSnapshot(snap(id: 10, seconds: 3))), ['loaded:1']);
  });

  test('a stale entry after a new load is ignored', () {
    t.onSnapshot(snap(id: 10, seconds: 3));
    t.startLoad(tok(5, gen: 2), 20);
    expect(t.onSnapshot(snap(id: 10, seconds: 3, eof: true)), isEmpty);
    expect(kinds(t.onSnapshot(snap(id: 20, seconds: 2))), ['loaded:5']);
  });

  test('trim removes entries before the playing one so at most two remain', () {
    t.onSnapshot(snap(id: 10, seconds: 3));
    t.registerNext(tok(2), 11);
    final s = snap(pos: 1, id: 11, count: 2, seconds: 3);
    t.onSnapshot(s);
    expect(t.entriesToTrim(s), 1);
    expect(s.count - t.entriesToTrim(s), lessThanOrEqualTo(2));
    expect(t.entriesToTrim(snap(pos: 0, id: 11)), 0);
  });

  test('nothing happens without a loaded entry', () {
    t.reset();
    expect(t.onSnapshot(snap(id: 10, seconds: 3)), isEmpty);
  });

  test('a next with the current entry id is refused and never promoted', () {
    expect(t.registerNext(tok(2, handoff: 2), 10), isFalse);
    expect(t.nextToken, isNull);
    // The playing entry has no duration yet: it must not be reported failed.
    expect(t.onSnapshot(snap(id: 10)), isEmpty);
    expect(t.registerNext(tok(2, handoff: 2), 11), isTrue);
    expect(t.currentMpvId, 10);
  });
}
