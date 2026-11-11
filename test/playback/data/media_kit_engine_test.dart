import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/media_kit_engine.dart';
import 'package:kanaru/src/playback/data/mpv_options.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';

class _ScriptedMpv implements MpvConsole {
  final commands = <List<String>>[];
  final props = <String, String>{'keep-open': 'yes'};
  final ids = <int>[];
  int playingPos = -1;
  bool idle = true;
  bool eofReached = false;
  double? durationSeconds = 180.0;

  bool dropAppends = false;
  bool unreadableAppendId = false;
  bool goIdleOnAppend = false;

  int _nextId = 10;

  @override
  Future<void> command(List<String> args) async {
    commands.add(args);
    switch (args) {
      case ['loadfile', _, 'replace']:
        ids
          ..clear()
          ..add(_nextId++);
        playingPos = 0;
        idle = false;
        eofReached = false;
      case ['loadfile', _, 'append']:
        if (goIdleOnAppend) {
          ids.add(_nextId++);
          playingPos = -1;
          idle = true;
          return;
        }
        if (dropAppends) return;
        ids.add(_nextId++);
      case ['playlist-remove', final idxStr]:
        final idx = int.parse(idxStr);
        ids.removeAt(idx);
        if (idx < playingPos) playingPos--;
      case ['playlist-clear']:
        ids.clear();
        playingPos = -1;
      case ['playlist-next']:
        if (playingPos + 1 < ids.length) {
          playingPos++;
          eofReached = false;
        }
      case ['stop']:
        ids.clear();
        playingPos = -1;
        idle = true;
        eofReached = false;
    }
  }

  @override
  Future<String> get(String name) async {
    switch (name) {
      case 'playlist-playing-pos':
        return '$playingPos';
      case 'playlist-count':
        return '${ids.length}';
      case 'idle-active':
        return idle ? 'yes' : 'no';
      case 'eof-reached':
        return eofReached ? 'yes' : 'no';
      case 'duration':
        final d = durationSeconds;
        if (d == null) throw StateError('duration unavailable');
        return '$d';
    }
    final m = RegExp(r'^playlist/(\d+)/id$').firstMatch(name);
    if (m != null) {
      final i = int.parse(m.group(1)!);
      if (unreadableAppendId && i > playingPos) {
        throw StateError('unreadable id at $i');
      }
      if (i < 0 || i >= ids.length) throw StateError('index out of range: $i');
      return '${ids[i]}';
    }
    final v = props[name];
    if (v == null) throw StateError('property unavailable: $name');
    return v;
  }

  @override
  Future<void> set(String name, String value) async {
    props[name] = value;
  }
}

EngineMedia _media(int id, String name, {int handoff = 1}) => EngineMedia(
  EngineToken(entryId: id, generation: 1, handoff: handoff),
  '/music/$name',
);

void main() {
  late _ScriptedMpv mpv;
  late MediaKitEngine engine;
  late List<EngineEvent> events;

  setUp(() {
    mpv = _ScriptedMpv();
    engine = MediaKitEngine(mpv: mpv);
    events = <EngineEvent>[];
    engine.events.listen(events.add);
  });

  tearDown(() async {
    await engine.dispose();
  });

  test(
    'rejected append during load keeps current playing and reports ended at eof',
    () async {
      mpv.dropAppends = true;
      await engine.load(
        _media(1, 'a.flac'),
        next: _media(2, 'b.flac', handoff: 2),
        play: true,
      );
      await pumpEventQueue();

      expect(events, [
        isA<EngineLoaded>()
            .having((e) => e.token.entryId, 'entryId', 1)
            .having((e) => e.duration, 'duration', const Duration(seconds: 180)),
      ]);
      expect(mpv.ids, [10]);
      expect(mpv.props['pause'], 'no');

      // When the current file reaches EOF, the engine emits EngineEnded
      // instead of waiting for a gapless advance that never registered.
      mpv.eofReached = true;
      await engine.poll();
      await pumpEventQueue();

      expect(events.last, isA<EngineEnded>());
      expect((events.last as EngineEnded).token.entryId, 1);
      expect(
        mpv.commands.where((c) => c.first == 'playlist-next'),
        isEmpty,
      );
    },
  );

  test(
    'failed append on setNext removes stale and unverified entries after playingPos',
    () async {
      await engine.load(
        _media(1, 'a.flac'),
        next: _media(2, 'b.flac', handoff: 2),
        play: true,
      );
      expect(mpv.ids, [10, 11]);

      // Replace next with c.flac, whose append lands (id 12) but cannot be
      // verified: both the unverified entry (index 2) and the previous next
      // (index 1) must be removed so mpv cannot advance untracked.
      mpv.unreadableAppendId = true;
      await engine.setNext(_media(3, 'c.flac', handoff: 3));
      await pumpEventQueue();

      expect(mpv.ids, [10]);
      expect(events.whereType<EngineFailed>(), isEmpty);

      // Reaching EOF now reports EngineEnded rather than advancing to a stale next.
      mpv.eofReached = true;
      await engine.poll();
      await pumpEventQueue();

      expect(events.whereType<EngineEnded>(), hasLength(1));
      expect(
        mpv.commands.where((c) => c.first == 'playlist-next'),
        isEmpty,
      );
    },
  );

  test(
    'idle during append in load clears playlist, drops next, and fails unopened current',
    () async {
      mpv.durationSeconds = null;
      mpv.goIdleOnAppend = true;

      await engine.load(
        _media(1, 'a.flac'),
        next: _media(2, 'b.flac', handoff: 2),
        play: true,
      );
      await pumpEventQueue();

      expect(
        mpv.commands,
        contains(equals(['playlist-clear'])),
      );
      expect(mpv.ids, isEmpty);
      expect(events, [
        isA<EngineFailed>().having((e) => e.token.entryId, 'entryId', 1),
      ]);
    },
  );

  test(
    'idle during setNext after current loaded clears playlist and does not fail next',
    () async {
      await engine.load(_media(1, 'a.flac'), play: true);
      await pumpEventQueue();
      expect(events.single, isA<EngineLoaded>());

      mpv.goIdleOnAppend = true;
      await engine.setNext(_media(2, 'b.flac', handoff: 2));
      await pumpEventQueue();

      expect(
        mpv.commands,
        contains(equals(['playlist-clear'])),
      );
      expect(mpv.ids, isEmpty);
      expect(events.whereType<EngineFailed>(), isEmpty);
    },
  );

  test(
    'replacing next appends the new entry before removing the old one and advances cleanly',
    () async {
      await engine.load(
        _media(1, 'a.flac'),
        next: _media(2, 'b.flac', handoff: 2),
        play: true,
      );
      expect(mpv.ids, [10, 11]);

      await engine.setNext(_media(3, 'c.flac', handoff: 3));
      expect(mpv.ids, [10, 12]);

      // Simulate mpv gaplessly advancing to entry 12 at index 1.
      mpv.playingPos = 1;
      mpv.durationSeconds = 210.0;
      await engine.poll();
      await pumpEventQueue();

      expect(mpv.ids, [12], reason: 'finished entry at index 0 is trimmed');
      expect(
        events.whereType<EngineAdvanced>().single.token.entryId,
        3,
      );
      expect(
        events.whereType<EngineLoaded>().last.duration,
        const Duration(seconds: 210),
      );
    },
  );
}
