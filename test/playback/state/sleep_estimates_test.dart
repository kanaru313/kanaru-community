import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';
import 'package:kanaru/src/playback/state/sleep_estimates.dart';
import 'package:logging/logging.dart';

import '../support/sleep_timer_harness.dart';

void main() {
  late SleepHarness s;
  final open = <SleepHarness>[];

  Future<SleepHarness> make({int tracks = 6, bool playerCreated = true}) async {
    final h = await SleepHarness.create(
      tracks: tracks,
      playerCreated: playerCreated,
    );
    open.add(h);
    return h;
  }

  setUp(() async {
    open.clear();
    s = await make();
  });
  tearDown(() async {
    for (final h in open) {
      await h.close();
    }
  });

  /// Lets the player, the database and the estimate streams finish.
  Future<void> settle(SleepHarness h) async {
    for (var i = 0; i < 3; i++) {
      await h.h.settle();
      await pumpEventQueue();
    }
  }

  /// Keeps [provider] alive in [h]'s container and returns its latest value.
  Future<T> watch<T>(SleepHarness h, ProviderListenable<T> provider) async {
    h.container.listen(provider, (_, _) {});
    await settle(h);
    return h.container.read(provider);
  }

  Future<AlbumRun?> albumRun(SleepHarness h) async {
    h.container.listen(albumRunProvider, (_, _) {});
    await settle(h);
    return h.container.read(albumRunProvider).requireValue;
  }

  /// Tracks 0-2 album A, 3-4 album B, 5 no album.
  void twoAlbums(SleepHarness h) {
    for (var i = 0; i < 3; i++) {
      h.albumOf(i, 'A');
    }
    h.albumOf(3, 'B');
    h.albumOf(4, 'B');
    h.albumOf(5, null);
  }

  /// Starts the end-of-album timer and plays on to its stop: how many entries
  /// the engine played, the current one included. An entry is followed while
  /// the player hands the engine a next one after each step.
  Future<int> engineRun(SleepHarness h) async {
    final engine = h.h.engine;
    var before = engine.nexts.length;
    bool handed() => engine.nexts.length > before && engine.nexts.last != null;
    h.timer.startEndOfAlbum();
    await settle(h);
    var played = 1;
    while (handed()) {
      before = engine.nexts.length;
      await h.advance();
      await settle(h);
      played++;
      if (played > 200) fail('the timer never stopped');
    }
    await h.end();
    expect(h.state.active, isFalse, reason: 'the stop ends the timer');
    return played;
  }

  group('before the player exists', () {
    test('every figure is null and nothing is read', () async {
      final late = await make(playerCreated: false);
      expect(await watch(late, currentTrackLeftProvider), isNull);
      expect(await watch(late, currentTrackPlayedProvider), isNull);
      expect(await watch(late, queueLeftProvider), isNull);
      expect(await watch(late, albumLeftProvider), isNull);
      expect(await albumRun(late), isNull);
      expect(late.controllerReads, 0);
      expect(late.loads, isEmpty);
    });
  });

  group('the loaded entry', () {
    test('left and played are whole seconds of the position', () async {
      await s.play();
      s.h.engine.tickPosition(const Duration(milliseconds: 65500));
      await settle(s);
      expect(await watch(s, currentTrackPlayedProvider), (
        played: 65,
        total: 180,
      ));
      expect(await watch(s, currentTrackLeftProvider), 115);
    });

    test('nothing loaded has no figure', () async {
      expect(await watch(s, currentTrackLeftProvider), isNull);
      expect(await watch(s, currentTrackPlayedProvider), isNull);
    });

    test('ten ticks inside one second rebuild once', () async {
      await s.play();
      s.container.listen(currentTrackLeftProvider, (_, _) {});
      s.h.engine.tickPosition(const Duration(seconds: 10));
      await settle(s);
      final left = <int?>[];
      s.container.listen(currentTrackLeftProvider, (_, n) => left.add(n));
      for (var i = 1; i <= 9; i++) {
        s.h.engine.tickPosition(Duration(milliseconds: 10000 + i * 100));
      }
      await settle(s);
      expect(left, isEmpty, reason: 'still inside second 10');
      s.h.engine.tickPosition(const Duration(milliseconds: 11000));
      await settle(s);
      expect(left, [169]);
    });
  });

  group('album run', () {
    test('is what the timer plays, from every start', () async {
      for (final (start, expected) in [(0, 3), (1, 2), (3, 2), (5, 1)]) {
        final h = await make();
        twoAlbums(h);
        await h.play(start: start);
        final run = await albumRun(h);
        expect(run!.tracks, expected, reason: 'start $start');
        expect(await engineRun(h), expected, reason: 'start $start');
      }
    });

    test('follows two updates of the tracks table', () async {
      twoAlbums(s);
      await s.play();
      expect((await albumRun(s))!.tracks, 3);

      s.albumOf(1, 'Z'); // an edit splits the album
      s.tracksChanged.add(null);
      await settle(s);
      expect(s.container.read(albumRunProvider).requireValue!.tracks, 1);

      s.albumOf(1, 'A'); // and a second edit joins another track
      s.albumOf(3, 'A');
      s.tracksChanged.add(null);
      await settle(s);
      final run = s.container.read(albumRunProvider).requireValue!;
      expect(run.tracks, 4);
      expect(await engineRun(s), run.tracks);
    });

    test('a track without an album stops at itself', () async {
      twoAlbums(s);
      await s.play(start: 5);
      final run = (await albumRun(s))!;
      expect(run.noAlbum, isTrue);
      expect(run.tracks, 1);
      expect(run.restDuration, Duration.zero);
    });

    test(
      'a track the database does not have counts as without album',
      () async {
        await s.play();
        final run = (await albumRun(s))!;
        expect(run.noAlbum, isTrue);
        expect(run.tracks, 1);
      },
    );

    test('adds up the run after the current entry', () async {
      twoAlbums(s);
      for (var i = 0; i < 6; i++) {
        s.durations[s.h.tracks[i]] = 60000 * (i + 1);
      }
      await s.play(start: 1);
      final run = (await albumRun(s))!;
      expect(run.tracks, 2);
      expect(run.restDuration, const Duration(minutes: 3)); // track 2 only
      s.h.engine.tickPosition(const Duration(seconds: 30));
      s.container.listen(albumLeftProvider, (_, _) {});
      await settle(s);
      // 150 s left of the entry, then the rest of the run.
      expect(
        s.container.read(albumLeftProvider),
        const Duration(seconds: 150 + 180),
      );
    });

    test('repeat one is one play: stops after this one', () async {
      twoAlbums(s);
      await s.h.c.setRepeat(RepeatMode.one);
      await s.play(start: 1);
      final run = (await albumRun(s))!;
      expect(run.tracks, 1);
      expect(run.repeatsOne, isTrue);
    });

    test('the end of a reshuffled pass ends it', () async {
      for (var i = 0; i < 6; i++) {
        s.albumOf(i, 'A');
      }
      await s.h.c.setRepeat(RepeatMode.allShuffled);
      await s.play(start: 5);
      final run = (await albumRun(s))!;
      expect(run.tracks, 1);
      expect(await engineRun(s), 1);
    });

    test('a whole queue of one album under repeat all is capped', () async {
      for (var i = 0; i < 6; i++) {
        s.albumOf(i, 'A');
      }
      await s.h.c.setRepeat(RepeatMode.all);
      await s.play(start: 2);
      final run = (await albumRun(s))!;
      expect(run.tracks, 6);
      expect(run.capped, isTrue);
    });

    test('counts at most 100 and says there are more', () async {
      final big = await make(tracks: 130);
      for (var i = 0; i < 130; i++) {
        big.albumOf(i, 'A');
      }
      await big.play();
      final run = (await albumRun(big))!;
      expect(run.tracks, 100);
      expect(run.capped, isTrue);
      expect(big.loads.every((ids) => ids.length <= 101), isTrue);
    });

    test('exactly 100 is not "100+"', () async {
      final exact = await make(tracks: 100);
      for (var i = 0; i < 100; i++) {
        exact.albumOf(i, 'A');
      }
      await exact.play();
      final run = (await albumRun(exact))!;
      expect(run.tracks, 100);
      expect(run.capped, isFalse);
    });

    test('position ticks never ask the database', () async {
      twoAlbums(s);
      await s.play();
      await albumRun(s);
      final loads = s.loads.length;
      for (var i = 1; i < 30; i++) {
        s.h.engine.tickPosition(Duration(seconds: i));
      }
      await settle(s);
      expect(s.loads.length, loads);
    });

    test('a queue change asks again', () async {
      twoAlbums(s);
      await s.play();
      expect((await albumRun(s))!.tracks, 3);
      await s.h.c.next();
      await s.h.c.next();
      await settle(s);
      expect(s.container.read(albumRunProvider).requireValue!.tracks, 1);
    });

    test('a failed load is an error, logged once with its type only', () async {
      twoAlbums(s);
      await s.play();
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord
          .where((r) => r.loggerName == 'SleepEstimates')
          .listen(records.add);
      addTearDown(sub.cancel);
      s.loadError = StateError('secret path /home/x');
      s.container.listen(albumRunProvider, (_, _) {});
      await settle(s);
      expect(s.container.read(albumRunProvider).hasError, isTrue);
      expect(records, hasLength(1));
      expect(records.single.message, contains('StateError'));
      expect(records.single.message, isNot(contains('secret')));

      s.loadError = null;
      s.tracksChanged.add(null);
      await settle(s);
      expect(s.container.read(albumRunProvider).requireValue!.tracks, 3);
    });
  });

  group('queue left', () {
    test('counts the entries from the current one and their time', () async {
      for (var i = 0; i < 6; i++) {
        await s.h.db.customStatement(
          'UPDATE tracks SET duration_ms = ${(i + 1) * 1000} '
          'WHERE id = ${s.h.tracks[i].value}',
        );
      }
      await s.play(start: 1);
      s.h.engine.tickPosition(const Duration(seconds: 30));
      s.container.listen(queueLeftProvider, (_, _) {});
      await settle(s);
      // Entries 1..5 are left; 150 s of the loaded one plus entries 2..5.
      expect(s.container.read(queueLeftProvider), (
        tracks: 5,
        time: const Duration(seconds: 150 + 3 + 4 + 5 + 6),
      ));
      await s.h.c.next();
      await settle(s);
      expect(s.container.read(queueLeftProvider)!.tracks, 4);
    });

    test('the time waits for the length of the loaded entry', () async {
      // Played but not reported loaded: its length is not known yet.
      await s.h.play(start: 4);
      await s.h.settle();
      s.container.listen(queueLeftProvider, (_, _) {});
      await s.h.settle();
      await pumpEventQueue();
      final left = s.container.read(queueLeftProvider);
      expect(left!.tracks, 2);
      expect(left.time, isNull);
    });

    test('an empty queue has none', () async {
      expect(await watch(s, queueLeftProvider), isNull);
    });
  });

  group('lifetime', () {
    test('nothing stays subscribed once nobody listens', () async {
      twoAlbums(s);
      await s.play();
      final sub = s.container.listen(albumRunProvider, (_, _) {});
      await settle(s);
      final loads = s.loads.length;
      sub.close();
      await pumpEventQueue();
      s.tracksChanged.add(null);
      await s.h.c.next();
      await settle(s);
      expect(s.loads.length, loads);
    });

    test('a rebuild after dispose starts over', () async {
      twoAlbums(s);
      await s.play();
      final sub = s.container.listen(albumRunProvider, (_, _) {});
      await settle(s);
      sub.close();
      await pumpEventQueue();
      expect((await albumRun(s))!.tracks, 3);
    });
  });
}
