import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/data/play_log_writer.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/listen_accumulator.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/state/listen_recorder.dart';

import '../../database/support/test_db.dart';
import '../support/controller_harness.dart';

Duration secs(int n) => Duration(seconds: n);

void main() {
  group('recorder alone', () {
    late var db = openTestDb();
    late ListenRecorder rec;
    late TrackId track;
    var now = 1000;
    var mono = Duration.zero;
    const ctx = PlayContext(PlayContextKind.album, ref: 'k', label: 'A');

    setUp(() async {
      db = openTestDb();
      final src = await addSource(db);
      track = TrackId(await addTrack(db, src, locator: 'a.mp3'));
      now = 1000;
      mono = Duration.zero;
      rec = ListenRecorder(
        writer: PlayLogWriter(db),
        deviceId: () => 'dev-1',
        wallClock: () => now,
        monotonic: () => mono,
      );
    });
    tearDown(() => db.close());

    EngineToken token(int gen) =>
        EngineToken(entryId: 1, generation: gen, handoff: gen);

    ListenObservation obs(
      int gen,
      int pos, {
      bool playing = true,
      int length = 100,
    }) => ListenObservation(
      token: token(gen),
      trackId: track,
      context: ctx,
      position: secs(pos),
      length: secs(length),
      playing: playing,
    );

    /// One observation per second from [from] to [to] of load [gen].
    void run(int gen, int from, int to) {
      for (var p = from; p <= to; p++) {
        mono = secs(p);
        now = 1000 + p * 1000;
        rec.observe(obs(gen, p));
      }
    }

    Future<List<Map<String, Object?>>> rows() async => [
      for (final r in await db
          .customSelect('SELECT * FROM play_log ORDER BY id')
          .get())
        r.data,
    ];

    test('no row below the threshold', () async {
      run(1, 0, 49);
      await rec.flush();
      expect(await rows(), isEmpty);
    });

    test('one row at the threshold, with the load\'s first playing time', () async {
      run(1, 0, 50);
      await rec.flush();
      final r = await rows();
      expect(r, hasLength(1));
      expect(r.single['played_at'], 1000);
      expect(r.single['listened_ms'], 50000);
      expect(r.single['device_id'], 'dev-1');
      expect(r.single['context_kind'], 'album');
      expect(r.single['context_ref'], 'k');
      expect(r.single['track_id'], track.value);
    });

    test('listened_ms follows every ten seconds, never a second row', () async {
      run(1, 0, 50);
      await pumpEventQueue();
      expect((await rows()).single['listened_ms'], 50000);
      run(1, 51, 59);
      await pumpEventQueue();
      expect((await rows()).single['listened_ms'], 50000, reason: 'not due');
      run(1, 60, 60);
      await pumpEventQueue();
      expect((await rows()).single['listened_ms'], 60000);
      run(1, 61, 75);
      await rec.flush();
      final r = await rows();
      expect(r, hasLength(1));
      expect(r.single['listened_ms'], 75000);
    });

    test('a pause writes the current value', () async {
      run(1, 0, 52);
      await rec.flush();
      mono = secs(53);
      rec.observe(obs(1, 53, playing: false));
      await pumpEventQueue();
      expect((await rows()).single['listened_ms'], 52000);
    });

    test('a new load ends the old listen with its final value', () async {
      run(1, 0, 55);
      rec.observe(
        ListenObservation(
          token: token(2),
          trackId: track,
          context: ctx,
          position: Duration.zero,
          length: secs(100),
          playing: true,
        ),
      );
      await rec.flush();
      final r = await rows();
      expect(r, hasLength(1));
      expect(r.single['listened_ms'], 55000);
    });

    test('null ends the listen; a row written once stays one row', () async {
      run(1, 0, 60);
      rec.observe(null);
      rec.observe(null);
      await rec.flush();
      expect(await rows(), hasLength(1));
    });

    test('the length is locked: a later shorter length changes nothing', () async {
      for (var p = 0; p <= 30; p++) {
        mono = secs(p);
        rec.observe(obs(1, p, length: p == 0 ? 100 : 20));
      }
      await rec.flush();
      expect(await rows(), isEmpty, reason: '100 s track needs 50 s');
    });

    test('a failing write is logged and later writes still go through', () async {
      final failing = _FailOnce(db);
      final r = ListenRecorder(
        writer: failing,
        deviceId: () => 'dev-1',
        wallClock: () => now,
        monotonic: () => mono,
      );
      for (var p = 0; p <= 55; p++) {
        mono = secs(p);
        r.observe(obs(1, p));
      }
      await r.flush();
      expect(failing.failures, 1);
      for (var p = 56; p <= 70; p++) {
        mono = secs(p);
        r.observe(obs(1, p));
      }
      await r.flush();
      expect(await rows(), hasLength(1));
      expect((await rows()).single['listened_ms'], 70000);
    });

    group('rule and history', () {
      var rule = ListenRule.standard;
      var history = true;
      late ListenRecorder custom;

      setUp(() {
        rule = ListenRule.standard;
        history = true;
        custom = ListenRecorder(
          writer: PlayLogWriter(db),
          deviceId: () => 'dev-1',
          rule: () => rule,
          historyEnabled: () => history,
          wallClock: () => now,
          monotonic: () => mono,
        );
      });

      void feed(int gen, int from, int to) {
        for (var p = from; p <= to; p++) {
          mono = secs(p);
          now = 1000 + p * 1000;
          custom.observe(obs(gen, p));
        }
      }

      test('the rule is read at most once a second while a listen runs', () async {
        var reads = 0;
        final counting = ListenRecorder(
          writer: PlayLogWriter(db),
          deviceId: () => 'dev-1',
          rule: () {
            reads++;
            return ListenRule.standard;
          },
          wallClock: () => now,
          monotonic: () => mono,
        );
        for (var ms = 0; ms <= 10000; ms += 100) {
          mono = Duration(milliseconds: ms);
          now = 1000 + ms;
          counting.observe(
            ListenObservation(
              token: token(1),
              trackId: track,
              context: ctx,
              position: Duration(milliseconds: ms),
              length: secs(100),
              playing: true,
            ),
          );
        }
        expect(reads, lessThanOrEqualTo(11), reason: '101 observations');
        expect(reads, greaterThan(1), reason: 'refreshed, not read once');
      });

      test('a shorter rule records earlier', () async {
        rule = const ListenRule(afterMs: 20000, percent: 50);
        feed(1, 0, 20);
        await custom.flush();
        expect((await rows()).single['listened_ms'], 20000);
      });

      test('a rule changed mid-listen applies at the next check', () async {
        feed(1, 0, 30);
        await custom.flush();
        expect(await rows(), isEmpty);
        rule = const ListenRule(afterMs: 0, percent: 20);
        feed(1, 31, 33);
        await custom.flush();
        expect(await rows(), hasLength(1));
      });

      test('history off inserts nothing and deletes nothing', () async {
        feed(1, 0, 50);
        await custom.flush();
        expect(await rows(), hasLength(1));
        history = false;
        feed(2, 0, 60);
        await custom.close();
        final r = await rows();
        expect(r, hasLength(1), reason: 'the second listen is not recorded');
        expect(r.single['listened_ms'], 50000);
      });

      test('an open row keeps being updated after history goes off', () async {
        feed(1, 0, 50);
        await pumpEventQueue();
        history = false;
        feed(1, 51, 70);
        await custom.flush();
        final r = await rows();
        expect(r, hasLength(1));
        expect(r.single['listened_ms'], 70000);
      });

      test('history turned on mid-track inserts once', () async {
        history = false;
        feed(1, 0, 60);
        await custom.flush();
        expect(await rows(), isEmpty);
        history = true;
        feed(1, 61, 80);
        await custom.flush();
        final r = await rows();
        expect(r, hasLength(1));
        expect(r.single['listened_ms'], 80000);
      });
    });

    test('after close nothing is recorded', () async {
      await rec.close();
      run(1, 0, 60);
      await rec.flush();
      expect(await rows(), isEmpty);
    });
  });

  group('through the controller', () {
    Future<int> count(Harness h) async => (await h.db
            .customSelect('SELECT COUNT(*) AS n FROM play_log')
            .getSingle())
        .read<int>('n');

    Future<int> playCount(Harness h, int track) async => (await h.db
            .customSelect(
              'SELECT play_count FROM play_stats WHERE track_id = ?',
              variables: [Variable.withInt(track)],
            )
            .getSingleOrNull())
        ?.read<int>('play_count') ??
        0;

    /// Plays [seconds] of the loaded entry of a 60 s track.
    Future<void> listen(Harness h, EngineToken token, int seconds) async {
      h.engine.emit(EngineLoaded(token, secs(60)));
      await h.settle();
      for (var p = 0; p <= seconds; p += 5) {
        h.mono += const Duration(seconds: 5);
        h.now += 5000;
        h.engine.tickPosition(secs(p));
        await pumpEventQueue();
      }
    }

    test('repeat one over three loops writes three rows', () async {
      final h = await Harness.create(tracks: 2);
      addTearDown(h.close);
      await h.c.setRepeat(RepeatMode.one);
      await h.play();
      await h.settle();
      final tokens = <EngineToken>[h.loadedToken];
      for (var loop = 0; loop < 3; loop++) {
        await listen(h, tokens.last, 40);
        if (loop < 2) {
          final next = h.engine.nexts.last!.token;
          tokens.add(next);
          h.engine.emit(EngineAdvanced(next));
          await h.settle();
        }
      }
      await h.c.flushPlayback();
      expect(tokens.map((t) => t.handoff).toSet(), hasLength(3));
      expect(await count(h), 3);
      expect(await playCount(h, h.tracks[0].value), 3);
    });

    test('a counted repeat of 2 over one entry writes three rows', () async {
      final h = await Harness.create(tracks: 2);
      addTearDown(h.close);
      await h.play();
      await h.settle();
      await h.c.setRepeatTimes(2);
      await h.settle();
      final tokens = <EngineToken>[h.loadedToken];
      for (var play = 0; play < 3; play++) {
        await listen(h, tokens.last, 40);
        if (play < 2) {
          final next = h.engine.nexts.last!.token;
          tokens.add(next);
          h.engine.emit(EngineAdvanced(next));
          await h.settle();
        }
      }
      await h.c.flushPlayback();
      expect(tokens.map((t) => t.handoff).toSet(), hasLength(3));
      expect(await count(h), 3);
      expect(await playCount(h, h.tracks[0].value), 3);
    });

    test('a one-entry queue with repeat all counts both passes', () async {
      final h = await Harness.create(tracks: 1);
      addTearDown(h.close);
      await h.c.setRepeat(RepeatMode.all);
      await h.play();
      await h.settle();
      await listen(h, h.loadedToken, 40);
      final next = h.engine.nexts.last!.token;
      h.engine.emit(EngineAdvanced(next));
      await h.settle();
      await listen(h, next, 40);
      await h.c.flushPlayback();
      expect(await count(h), 2);
      expect(await playCount(h, h.tracks[0].value), 2);
    });

    test('gapless advance gives each track its own row', () async {
      final h = await Harness.create(tracks: 3);
      addTearDown(h.close);
      await h.play();
      await h.settle();
      await listen(h, h.loadedToken, 40);
      final next = h.engine.nexts.last!.token;
      h.engine.emit(EngineAdvanced(next));
      await h.settle();
      await listen(h, next, 40);
      await h.c.flushPlayback();
      final ids = [
        for (final r in await h.db
            .customSelect('SELECT track_id FROM play_log ORDER BY id')
            .get())
          r.read<int>('track_id'),
      ];
      expect(ids, [h.tracks[0].value, h.tracks[1].value]);
    });

    test('flush writes the in-flight value', () async {
      final h = await Harness.create(tracks: 2);
      addTearDown(h.close);
      await h.play();
      await h.settle();
      await listen(h, h.loadedToken, 35);
      await h.c.flushPlayback();
      final r = await h.db.customSelect('SELECT listened_ms FROM play_log').get();
      expect(r.single.read<int>('listened_ms'), 35000);
    });

    test('skipping early records nothing', () async {
      final h = await Harness.create(tracks: 3);
      addTearDown(h.close);
      await h.play();
      await h.settle();
      await listen(h, h.loadedToken, 10);
      await h.c.next();
      await h.settle();
      await h.c.flushPlayback();
      expect(await count(h), 0);
    });
  });
}

/// Fails the first insert, then works.
class _FailOnce extends PlayLogWriter {
  _FailOnce(super.db);
  int failures = 0;

  @override
  Future<int> insertListen({
    required TrackId trackId,
    required int playedAt,
    required int listenedMs,
    required String deviceId,
    PlayContext? context,
    required int now,
  }) {
    if (failures == 0) {
      failures++;
      return Future.error(StateError('database busy'));
    }
    return super.insertListen(
      trackId: trackId,
      playedAt: playedAt,
      listenedMs: listenedMs,
      deviceId: deviceId,
      context: context,
      now: now,
    );
  }
}
