import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/domain/media_controls.dart';
import 'package:kanaru/src/playback/data/queue_repository.dart';
import 'package:kanaru/src/playback/data/track_info_rows.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/state/media_session_bridge.dart';

import '../support/controller_harness.dart';

class FakeControls implements MediaControls {
  final log = <String>[];
  final updates = <(MediaControlsItem?, MediaControlsState)>[];
  final positions = <Duration>[];
  final seeks = <Duration>[];
  final commandCtrl = StreamController<MediaCommand>.broadcast();
  bool grant = true;
  bool hang = false;
  int starts = 0;

  @override
  Future<void> start() async {
    starts++;
    log.add('start');
  }

  @override
  Future<void> update(MediaControlsItem? item, MediaControlsState state) async {
    updates.add((item, state));
    log.add('update');
  }

  @override
  void updatePosition(Duration position) => positions.add(position);

  @override
  void seeked(Duration position) {
    seeks.add(position);
    log.add('seeked');
  }

  @override
  Stream<MediaCommand> get commands => commandCtrl.stream;

  @override
  Future<bool> activate() {
    if (hang) return Completer<bool>().future;
    return Future.value(grant);
  }

  @override
  Future<void> deactivate() async => log.add('deactivate');

  @override
  Future<void> dispose() async {}
}

const _coverKey = 'ab/0123456789abcdef0123456789abcdef';

void main() {
  late Harness h;
  late FakeControls controls;
  late MediaSessionBridge bridge;
  late Directory dir;
  var artExists = false;
  Completer<void>? infoGate;

  Future<void> make({
    bool startOnRestore = false,
    Future<void> Function(Harness h)? prepare,
    Duration focusTimeout = const Duration(seconds: 2),
  }) async {
    h = await Harness.create(prepare: prepare);
    controls = FakeControls();
    dir = Directory.systemTemp.createTempSync('kanaru-bridge');
    bridge = MediaSessionBridge(
      controls: controls,
      infoOf: (id) async {
        await infoGate?.future;
        return (await loadTrackInfos(h.db, [id])).firstOrNull;
      },
      artPathOf: (key) {
        final path = '${dir.path}/$key.jpg';
        return artExists ? path : null;
      },
      startOnRestore: startOnRestore,
      window: const Duration(milliseconds: 10),
      focusTimeout: focusTimeout,
    );
    bridge.attach(h.c);
  }

  setUp(() {
    artExists = false;
    infoGate = null;
  });
  tearDown(() async {
    bridge.dispose();
    await h.close();
    dir.deleteSync(recursive: true);
  });

  /// Lets the controller finish, sends what the bridge holds right now and
  /// lets the controller finish again: no sleeping.
  Future<void> settleAll() async {
    await h.settle();
    await bridge.flush();
    await h.settle();
    await bridge.flush();
  }

  Future<void> until(bool Function() done) async {
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (!done() && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  group('updates', () {
    test('one update per burst of changes, none for a repeat', () async {
      await make();
      await h.play(start: 1);
      await settleAll();
      expect(controls.updates, hasLength(1));
      final (item, state) = controls.updates.single;
      expect(item!.title, 'T1');
      expect(state.playing, isTrue);
      expect(state.stopped, isFalse);
      expect(state.canNext, isTrue);
      expect(state.canPrevious, isTrue);

      // Several changes inside one window: shuffle, repeat, volume.
      await h.c.setShuffle(true);
      await h.c.setRepeat(RepeatMode.all);
      await h.c.setVolume(50);
      await settleAll();
      expect(controls.updates, hasLength(2));
      final s = controls.updates.last.$2;
      expect(s.shuffle, isTrue);
      expect(s.repeat, MediaRepeat.playlist);
      expect(s.volume, 0.5);

      // The same state again sends nothing.
      await h.c.setVolume(50);
      await settleAll();
      expect(controls.updates, hasLength(2));
    });

    test('a new track and a new length are separate, changed items', () async {
      await make();
      await h.play();
      await settleAll();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
      await settleAll();
      h.engine.tickPosition(const Duration(seconds: 1));
      await settleAll();
      expect(controls.updates.last.$1!.duration, const Duration(seconds: 200));
      expect(controls.updates.last.$2.canSeek, isTrue);
      final before = controls.updates.length;
      await h.c.next();
      await settleAll();
      expect(controls.updates.length, greaterThan(before));
      expect(controls.updates.last.$1!.title, 'T1');
    });

    test('position ticks are stored but never trigger an update', () async {
      await make();
      await h.play();
      await settleAll();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
      await settleAll();
      final before = controls.updates.length;
      for (var s = 1; s <= 20; s++) {
        h.engine.tickPosition(Duration(seconds: s));
      }
      await settleAll();
      expect(controls.updates.length, before);
      expect(controls.positions.last, const Duration(seconds: 20));
    });

    test('art is published only when the file exists', () async {
      await make(prepare: (x) async {
        await x.db.customStatement("UPDATE tracks SET cover_key = '$_coverKey'");
      });
      await h.play();
      await settleAll();
      expect(controls.updates.last.$1!.artUri, isNull);
      artExists = true;
      await h.c.next();
      await settleAll();
      expect(controls.updates.last.$1!.artUri, Uri.file('${dir.path}/$_coverKey.jpg'));
      expect(controls.updates.last.$1!.artUri!.scheme, 'file');
    });

    test('stopped and empty states', () async {
      await make();
      await settleAll();
      expect(controls.updates, isEmpty, reason: 'nothing to say yet');
      await h.play();
      await settleAll();
      await h.c.stop();
      await settleAll();
      final s = controls.updates.last.$2;
      expect(s.stopped, isTrue);
      expect(s.playing, isFalse);
      expect(s.started, isFalse);
      expect(controls.updates.last.$1, isNotNull);
    });

    test('canNext is false at the last entry without repeat', () async {
      await make();
      await h.play(start: 5);
      await settleAll();
      expect(controls.updates.last.$2.canNext, isFalse);
      expect(controls.updates.last.$2.canPrevious, isTrue);
    });
  });

  test('the window timer sends changes on its own', () async {
    await make();
    await h.play();
    await h.settle();
    await until(() => controls.updates.isNotEmpty);
    expect(controls.updates.single.$1!.title, 'T0');
  });

  group('seeks', () {
    test('seeked waits for an update that is already running', () async {
      await make();
      await h.play();
      await settleAll();
      controls.log.clear();
      infoGate = Completer<void>();
      await h.c.next();
      await h.settle();
      unawaited(bridge.flush()); // blocks on the track lookup
      final seek = h.c.seek(const Duration(seconds: 30));
      await h.settle();
      expect(controls.log, isEmpty, reason: 'nothing may go out yet');
      infoGate!.complete();
      await seek;
      await until(() => controls.log.contains('seeked'));
      expect(controls.log, ['update', 'seeked']);
      expect(controls.updates.last.$1!.title, 'T1');
    });

    test('seeked goes out after the pending update', () async {
      await make();
      await h.play();
      await settleAll();
      controls.log.clear();
      await h.c.next(); // a change waiting in the window
      await h.c.seek(const Duration(seconds: 30));
      await settleAll();
      expect(controls.log, ['update', 'seeked']);
      expect(controls.seeks.single, const Duration(seconds: 30));
    });
  });

  group('start', () {
    test('without startOnRestore the controls start at the first play', () async {
      await make(prepare: _saved);
      await settleAll();
      expect(controls.starts, 0);
      await h.c.play();
      await settleAll();
      expect(controls.starts, 1);
      expect(controls.updates.last.$2.started, isTrue);
    });

    test('startOnRestore starts them once the restored entry is known', () async {
      await make(startOnRestore: true, prepare: _saved);
      await settleAll();
      expect(controls.starts, 1);
      expect(controls.log.first, 'start');
      final (item, state) = controls.updates.last;
      expect(item!.title, 'T2');
      expect(state.playing, isFalse);
      expect(state.started, isFalse, reason: 'nothing played yet');
      expect(state.canPlay, isTrue);
      // Never twice.
      await h.c.play();
      await settleAll();
      expect(controls.starts, 1);
    });

    test('an empty queue starts nothing', () async {
      await make(startOnRestore: true);
      await settleAll();
      expect(controls.starts, 0);
    });
  });

  group('commands', () {
    test('map to controller methods', () async {
      await make();
      await h.play();
      await settleAll();
      controls.commandCtrl.add(const Pause());
      await settleAll();
      expect(h.c.intent, PlayIntent.paused);
      controls.commandCtrl.add(const Play());
      await settleAll();
      expect(h.c.intent, PlayIntent.playing);
      controls.commandCtrl.add(const PlayPause());
      await settleAll();
      expect(h.c.intent, PlayIntent.paused);
      controls.commandCtrl.add(const Next());
      await settleAll();
      expect(h.c.queueState.current, 1);
      controls.commandCtrl.add(const Previous());
      await settleAll();
      expect(h.c.queueState.current, 0);
      controls.commandCtrl.add(const SetShuffle(true));
      controls.commandCtrl.add(const SetRepeat(MediaRepeat.track));
      controls.commandCtrl.add(const SetVolume(0.25));
      await settleAll();
      expect(h.c.queueState.shuffled, isTrue);
      expect(h.c.queueState.repeat, RepeatMode.one);
      expect(h.engine.commands, contains('volume:25'));
    });

    test('parallel Next and Stop go through the chain: ends stopped', () async {
      await make();
      await h.play();
      await settleAll();
      controls.commandCtrl.add(const Next());
      controls.commandCtrl.add(const Stop());
      await settleAll();
      expect(h.c.intent, PlayIntent.stopped);
      expect(h.c.queueState.current, 1);
    });

    test('Seek is relative; SetPosition needs the current entry', () async {
      await make();
      await h.play();
      await settleAll();
      h.engine.emit(EngineLoaded(h.loadedToken, const Duration(seconds: 200)));
      await settleAll();
      h.engine.tickPosition(const Duration(seconds: 10));
      await settleAll();
      controls.commandCtrl.add(const Seek(Duration(seconds: 5)));
      await settleAll();
      expect(h.engine.commands, contains('seek:15000'));
      final entry = h.c.queueState.currentItem!.entryId;
      controls.commandCtrl.add(SetPosition('${entry + 99}', const Duration(seconds: 90)));
      await settleAll();
      expect(h.engine.commands, isNot(contains('seek:90000')));
      controls.commandCtrl.add(SetPosition('$entry', const Duration(seconds: 90)));
      await settleAll();
      expect(h.engine.commands, contains('seek:90000'));
    });

    test('a failing command is logged and the bridge goes on', () async {
      await make();
      await h.play();
      await settleAll();
      await h.c.dispose(); // commands now fail with a closed chain
      controls.commandCtrl.add(const Next());
      await pumpEventQueue();
      controls.commandCtrl.add(const Pause());
      await pumpEventQueue();
    });
  });

  group('focus gate', () {
    test('grants and denies as the controls say', () async {
      await make();
      expect(await bridge.activate(), isTrue);
      controls.grant = false;
      expect(await bridge.activate(), isFalse);
      await bridge.deactivate();
      expect(controls.log, contains('deactivate'));
    });

    test('no answer within the timeout is a denial', () async {
      await make(focusTimeout: const Duration(milliseconds: 40));
      controls.hang = true;
      expect(await bridge.activate(), isFalse);
    });
  });

  test('dispose stops following the player', () async {
    await make();
    await h.play();
    await settleAll();
    final before = controls.updates.length;
    bridge.dispose();
    await h.c.next();
    await settleAll();
    expect(controls.updates.length, before);
    bridge.dispose();
  });

  test('the track id of the item is the queue entry id', () async {
    await make();
    await h.play(start: 2);
    await settleAll();
    final entry = h.c.queueState.currentItem!.entryId;
    expect(controls.updates.last.$1!.id, '$entry');
  });
}

/// A saved session: the queue of all tracks, entry 2 current.
Future<void> _saved(Harness h) async {
  final items = await QueueRepository(h.db).replace(h.tracks, 1000);
  await h.settings.write('playback.queue.current_entry', items[2].entryId);
  await h.settings.write('playback.position_ms', 1000);
}
