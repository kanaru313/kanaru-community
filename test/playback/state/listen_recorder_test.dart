import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/data/play_log_writer.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/listen_accumulator.dart';
import 'package:kanaru/src/playback/domain/listen_clear_scope.dart';
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
      for (final r
          in await db.customSelect('SELECT * FROM play_log ORDER BY id').get())
        r.data,
    ];

    test('no row below the threshold', () async {
      run(1, 0, 49);
      await rec.flush();
      expect(await rows(), isEmpty);
    });

    test(
      'one row at the threshold, with the load\'s first playing time',
      () async {
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
      },
    );

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

    test(
      'the length is locked: a later shorter length changes nothing',
      () async {
        for (var p = 0; p <= 30; p++) {
          mono = secs(p);
          rec.observe(obs(1, p, length: p == 0 ? 100 : 20));
        }
        await rec.flush();
        expect(await rows(), isEmpty, reason: '100 s track needs 50 s');
      },
    );

    test(
      'a failing write is logged and later writes still go through',
      () async {
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
      },
    );

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

      test(
        'the rule is read at most once a second while a listen runs',
        () async {
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
        },
      );

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

    group('clearing', () {
      late _GateWriter gate;
      late ListenRecorder r;
      var history = true;

      setUp(() {
        gate = _GateWriter(db);
        history = true;
        r = ListenRecorder(
          writer: gate,
          deviceId: () => 'dev-1',
          historyEnabled: () => history,
          wallClock: () => now,
          monotonic: () => mono,
        );
      });

      void feed(int from, int to) {
        for (var p = from; p <= to; p++) {
          mono = secs(p);
          now = 1000 + p * 1000;
          r.observe(obs(1, p));
        }
      }

      test(
        'a listen begun inside the range is dropped and counted anew',
        () async {
          feed(0, 60);
          await r.flush();
          final oldId = (await rows()).single['id'];
          expect(await r.clearHistory(from: 0, to: 5000), 1);
          expect(await rows(), isEmpty);
          feed(61, 109);
          await r.flush();
          expect(await rows(), isEmpty, reason: '49 s since the restart');
          feed(110, 110);
          await r.flush();
          final after = await rows();
          expect(after, hasLength(1));
          expect(after.single['id'], isNot(oldId));
          expect(after.single['listened_ms'], 50000);
        },
      );

      test(
        'a listen begun before the range keeps its row and goes on',
        () async {
          feed(0, 60);
          await r.flush();
          final id = (await rows()).single['id'];
          expect(await r.clearHistory(from: 100000, to: 200000), 0);
          feed(61, 75);
          await r.flush();
          final after = await rows();
          expect(after.single['id'], id);
          expect(after.single['listened_ms'], 75000);
        },
      );

      test('a listen that never played is dropped', () async {
        r.observe(obs(1, 0, playing: false));
        expect(await r.clearHistory(from: 100000, to: 200000), 0);
        feed(1, 50);
        await r.flush();
        expect(await rows(), isEmpty, reason: 'counted anew: 49 s so far');
      });

      test('nothing is counted while the delete runs', () async {
        feed(0, 60);
        await r.flush();
        gate.hold = Completer<void>();
        final cleared = r.clearHistory();
        expect(r.clearing.value, isTrue);
        feed(61, 200);
        gate.hold!.complete();
        expect(await cleared, 1);
        expect(await rows(), isEmpty);
        feed(201, 249);
        await r.flush();
        expect(await rows(), isEmpty);
        feed(250, 250);
        await r.flush();
        expect(await rows(), hasLength(1));
      });

      test('an insert still queued is decided by its start', () async {
        feed(0, 50);
        final cleared = r.clearHistory(from: 0, to: 5000);
        expect(await cleared, 1, reason: 'the queued insert landed first');
        await r.flush();
        expect(await rows(), isEmpty);
      });

      test('two clears back to back each own their count', () async {
        await PlayLogWriter(db).insertListen(
          trackId: track,
          playedAt: 9000,
          listenedMs: 60000,
          deviceId: 'dev-1',
          now: 9000,
        );
        feed(0, 60);
        final first = r.clearHistory(to: 2000);
        final second = r.clearHistory(from: 9000);
        expect(await Future.wait([first, second]), [1, 1]);
        await r.flush();
        expect(await rows(), isEmpty);
      });

      test('a failing delete returns null and keeps the open listen', () async {
        feed(0, 60);
        await r.flush();
        final id = (await rows()).single['id'];
        gate.failNext = true;
        final cleared = r.clearHistory();
        feed(61, 70);
        expect(await cleared, isNull);
        feed(71, 80);
        await r.flush();
        final after = await rows();
        expect(after, hasLength(1));
        expect(after.single['id'], id);
        expect(after.single['listened_ms'], 80000);
      });

      test('clearing is false again after a failing delete', () async {
        gate.failNext = true;
        final cleared = r.clearHistory();
        expect(r.clearing.value, isTrue);
        expect(await cleared, isNull);
        expect(r.clearing.value, isFalse);
      });

      test('cleared emits only after a delete that worked', () async {
        final seen = <ClearBounds>[];
        r.cleared.listen(seen.add);
        gate.failNext = true;
        await r.clearHistory(from: 1, to: 2);
        await pumpEventQueue();
        expect(seen, isEmpty);
        await r.clearHistory(from: 3, to: 4);
        await pumpEventQueue();
        expect(seen, [(from: 3, to: 4)]);
      });

      test('flush waits for a pending clear', () async {
        final release = gate.hold = Completer<void>();
        final cleared = r.clearHistory();
        var flushed = false;
        final flush = r.flush().then((_) => flushed = true);
        await pumpEventQueue();
        expect(flushed, isFalse);
        release.complete();
        await cleared;
        await flush;
        expect(flushed, isTrue);
      });

      test('flush waits for a clear started by a clearing listener', () async {
        gate.hold = Completer<void>();
        Future<int?>? second;
        var secondDone = false;
        void onClearing() {
          if (r.clearing.value || second != null) return;
          second = r.clearHistory().then((n) {
            secondDone = true;
            return n;
          });
        }

        r.clearing.addListener(onClearing);
        final first = r.clearHistory();
        final flush = r.flush();
        gate.hold!.complete();
        await first;
        await flush;
        expect(second, isNotNull);
        expect(secondDone, isTrue);
        r.clearing.removeListener(onClearing);
      });

      test(
        'close closes the stream; a clear queued before it still returns',
        () async {
          final events = r.cleared.toList();
          gate.hold = Completer<void>();
          final cleared = r.clearHistory();
          final closed = r.close();
          gate.hold!.complete();
          expect(await cleared, 0);
          await closed;
          expect(await events, [(from: null, to: null)]);
          expect(await r.clearHistory(), isNull);
        },
      );

      test('a failure in the first of two queued clears does not stop the '
          'second', () async {
        feed(0, 60);
        await r.flush();
        gate.failNext = true;
        final first = r.clearHistory();
        final second = r.clearHistory();
        expect(await first, isNull);
        expect(await second, 1);
        expect(await rows(), isEmpty);
      });

      test(
        'a listen outside two queued clears survives with one insert',
        () async {
          feed(0, 60);
          await r.flush();
          gate.hold = Completer<void>();
          final first = r.clearHistory(from: 100000, to: 200000);
          final second = r.clearHistory(from: 100000, to: 200000);
          gate.hold!.complete();
          expect(await first, 0);
          expect(await second, 0);
          feed(61, 75);
          await r.flush();
          expect((await rows()).single['listened_ms'], 75000);
          expect(gate.inserts, 1);
        },
      );

      test(
        'an insert still queued outside the range is kept, written once',
        () async {
          gate.holdInsert = Completer<void>();
          feed(0, 50);
          final cleared = r.clearHistory(from: 100000, to: 200000);
          gate.holdInsert!.complete();
          expect(await cleared, 0);
          feed(51, 60);
          await r.flush();
          expect((await rows()).single['listened_ms'], 60000);
          expect(gate.inserts, 1);
        },
      );

      test(
        'close while the delete runs still deletes and writes nothing',
        () async {
          feed(0, 60);
          await r.flush();
          gate.hold = Completer<void>();
          final cleared = r.clearHistory();
          final closed = r.close();
          gate.hold!.complete();
          expect(await cleared, 1);
          await closed;
          expect(await rows(), isEmpty);
          expect(gate.inserts, 1);
        },
      );

      test(
        'a clear right after close is refused and the listen is written',
        () async {
          feed(0, 60);
          final closed = r.close();
          expect(await r.clearHistory(), isNull);
          await closed;
          expect((await rows()).single['listened_ms'], 60000);
          expect(gate.inserts, 1);
        },
      );

      test(
        'history switched off during a clear: the written row still follows',
        () async {
          feed(0, 60);
          await r.flush();
          gate.hold = Completer<void>();
          final cleared = r.clearHistory(from: 0, to: 500);
          history = false;
          feed(61, 70);
          gate.hold!.complete();
          expect(await cleared, 0);
          feed(71, 80);
          await r.flush();
          expect((await rows()).single['listened_ms'], 80000);
        },
      );

      test('history switched off during a clear: a dropped listen is not re-inserted', () async {
        feed(0, 30);
        gate.hold = Completer<void>();
        final cleared = r.clearHistory();
        history = false;
        feed(31, 40);
        gate.hold!.complete();
        await cleared;
        feed(41, 120);
        await r.flush();
        expect(await rows(), isEmpty);
      });
    });
  });

  group('through the controller', () {
    Future<int> count(Harness h) async =>
        (await h.db
                .customSelect('SELECT COUNT(*) AS n FROM play_log')
                .getSingle())
            .read<int>('n');

    Future<int> playCount(Harness h, int track) async =>
        (await h.db
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
        for (final r
            in await h.db
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
      final r = await h.db
          .customSelect('SELECT listened_ms FROM play_log')
          .get();
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

/// Lets a test hold, or fail, the next range delete.
class _GateWriter extends PlayLogWriter {
  _GateWriter(super.db);

  Completer<void>? hold;
  Completer<void>? holdInsert;
  bool failNext = false;
  int inserts = 0;

  @override
  Future<int> insertListen({
    required TrackId trackId,
    required int playedAt,
    required int listenedMs,
    required String deviceId,
    PlayContext? context,
    required int now,
  }) async {
    inserts++;
    final h = holdInsert;
    holdInsert = null;
    if (h != null) await h.future;
    return super.insertListen(
      trackId: trackId,
      playedAt: playedAt,
      listenedMs: listenedMs,
      deviceId: deviceId,
      context: context,
      now: now,
    );
  }

  @override
  Future<int> deleteRange({int? from, int? to}) async {
    if (failNext) {
      failNext = false;
      throw StateError('database busy');
    }
    final h = hold;
    hold = null;
    if (h != null) await h.future;
    return super.deleteRange(from: from, to: to);
  }
}
