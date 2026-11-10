import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/scan/library_counts.dart';
import 'package:kanaru/src/library/data/scan/scan_pipeline_types.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan/scan_controller.dart';

import 'support/fake_timers.dart';

ScanOutcome _done({int added = 0, int tracks = 1}) => ScanOutcome()
  ..added = added
  ..counts = LibraryCounts(tracks: tracks, albums: 0, artists: 0);

void main() {
  late FakeTimers timers;
  late bool setupDone;
  late List<bool> passes;
  late Future<ScanOutcome> Function(ScanSession, ScanHooks, bool full) onPass;
  late List<Set<String>> missJobs;
  late int garbageRuns;
  late int coverRuns;
  Object? coverError;
  Completer<void>? missGate;
  late StreamController<String> misses;
  late ScanController controller;
  late List<ScanStatus> seen;

  setUp(() {
    timers = FakeTimers();
    setupDone = true;
    passes = [];
    missJobs = [];
    garbageRuns = 0;
    coverRuns = 0;
    coverError = null;
    onPass = (_, _, _) async => _done();
    misses = StreamController<String>.broadcast();
    addTearDown(misses.close);
    controller = ScanController(
      runPass: (session, hooks, {required full}) {
        passes.add(full);
        return onPass(session, hooks, full);
      },
      runCoverMisses: (session, hooks, keys) async {
        missJobs.add(keys);
        await missGate?.future;
        return ScanOutcome();
      },
      isSetupDone: () => setupDone,
      collectGarbage: () async => garbageRuns++,
      collectCoverFiles: () async {
        coverRuns++;
        if (coverError != null) throw coverError!;
      },
      coverMisses: misses.stream,
      clock: () => timers.now,
      timer: timers.create,
    );
    addTearDown(controller.dispose);
    seen = [];
    controller.status.listen(seen.add);
  });

  List<ScanStatus> afterIdle() => seen.skip(1).toList();

  test('creating the controller starts no timer and no scan', () async {
    await timers.settle();
    expect(timers.created, 0);
    expect(passes, isEmpty);
    expect(seen.single, isA<ScanIdle>());
  });

  test('rescan before setup is done runs nothing', () async {
    setupDone = false;
    await controller.rescan();
    await timers.settle();
    expect(passes, isEmpty);
    expect(afterIdle(), isEmpty);
  });

  test(
    'a rescan runs a pass and ends with the counts, then collects garbage',
    () async {
      onPass = (_, _, _) async => _done(added: 4, tracks: 9);
      await controller.rescan();
      await timers.settle();
      final last = afterIdle().last as ScanFinished;
      expect((last.tracks, last.added), (9, 4));
      expect(last.at, timers.now);
      expect(garbageRuns, 1);
    },
  );

  test(
    'requests during a pass become one follow-up and full is merged',
    () async {
      final gate = Completer<void>();
      onPass = (_, _, full) async {
        if (passes.length == 1) await gate.future;
        return _done();
      };
      await controller.rescan();
      await controller.rescan();
      await controller.rescan(full: true);
      await controller.rescan();
      gate.complete();
      await timers.settle();
      expect(passes, [false, true]);
    },
  );

  test('the published added sums a pass and its follow-up', () async {
    final gate = Completer<void>();
    onPass = (_, _, _) async {
      if (passes.length == 1) {
        await gate.future;
        return _done(added: 3);
      }
      return _done(added: 0, tracks: 5);
    };
    await controller.rescan();
    await controller.rescan();
    gate.complete();
    await timers.settle();
    final finished = afterIdle().whereType<ScanFinished>().single;
    expect(finished.added, 3);
    expect(finished.tracks, 5);
    expect(garbageRuns, 1);
  });

  test('custom cover files are cleaned next to the track GC, after a '
      'completed scan', () async {
    await controller.rescan();
    await timers.settle();
    expect((garbageRuns, coverRuns), (1, 1));
  });

  test(
    'a failing cover cleanup is logged and the scan still finishes',
    () async {
      coverError = StateError('disk');
      await controller.rescan();
      await timers.settle();
      expect(afterIdle().last, isA<ScanFinished>());
      expect(coverRuns, 1);
    },
  );

  test('no cover cleanup after a failed scan', () async {
    onPass = (_, _, _) async => ScanOutcome()..failureKind = 'io';
    await controller.rescan();
    await timers.settle();
    expect((garbageRuns, coverRuns), (0, 0));
  });

  test('the startup run cleans cover files once with the track GC', () async {
    controller.ensureStartupWork();
    await timers.advance(const Duration(seconds: 30));
    expect((garbageRuns, coverRuns), (1, 1));
  });

  test('rescan never throws: a throwing pass ends as io', () async {
    onPass = (_, _, _) async => throw StateError('boom');
    await controller.rescan();
    await timers.settle();
    expect((afterIdle().last as ScanFailed).kind, 'io');
    expect(garbageRuns, 0);
  });

  test(
    'a custom cover cleanup that never ends does not stop the loop',
    () async {
      var passesRun = 0;
      final stuck = ScanController(
        runPass: (_, _, {required full}) async {
          passesRun++;
          return _done();
        },
        runCoverMisses: (_, _, _) async => ScanOutcome(),
        isSetupDone: () => true,
        collectGarbage: () async {},
        collectCoverFiles: () => Completer<void>().future,
        coverGcTimeout: const Duration(milliseconds: 50),
        timer: timers.create,
      );
      addTearDown(stuck.dispose);
      await stuck.rescan();
      await timers.settle();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await stuck.rescan();
      await timers.settle();
      expect(passesRun, 2);
    },
  );

  test('a throwing setup flag does not throw either', () async {
    final broken = ScanController(
      runPass: (_, _, {required full}) async => _done(),
      runCoverMisses: (_, _, _) async => ScanOutcome(),
      isSetupDone: () => throw StateError('no store'),
      collectGarbage: () async {},
      collectCoverFiles: () async {},
      timer: timers.create,
    );
    addTearDown(broken.dispose);
    await broken.rescan();
    broken.ensureStartupWork();
    expect(timers.created, 0);
  });

  test('a failure kind from the pass is published', () async {
    onPass = (_, _, _) async => ScanOutcome()..failureKind = 'permission';
    await controller.rescan();
    await timers.settle();
    expect((afterIdle().last as ScanFailed).kind, 'permission');
  });

  test(
    '50 progress events in 1 s give at most 4 emissions and the final',
    () async {
      final ran = Completer<void>();
      onPass = (_, hooks, _) async {
        for (var i = 0; i < 50; i++) {
          hooks.onStatus(
            ScanRunning(phase: ScanPhase.tags, done: i, total: 50),
          );
          await timers.advance(const Duration(milliseconds: 20));
        }
        ran.complete();
        return _done();
      };
      await controller.rescan();
      await ran.future;
      await timers.settle();
      final events = afterIdle();
      final running = events.whereType<ScanRunning>().toList();
      expect(running.length, lessThanOrEqualTo(4));
      expect(running.first.done, 0);
      expect(events.last, isA<ScanFinished>());
      // Counts only grow: the bar never jumps back.
      for (var i = 1; i < running.length; i++) {
        expect(running[i].done, greaterThan(running[i - 1].done));
      }
    },
  );

  test('the newest progress is delivered when the pass goes quiet', () async {
    final gate = Completer<void>();
    onPass = (_, hooks, _) async {
      hooks.onStatus(
        const ScanRunning(phase: ScanPhase.tags, done: 0, total: 9),
      );
      hooks.onStatus(
        const ScanRunning(phase: ScanPhase.tags, done: 9, total: 9),
      );
      await gate.future;
      return _done();
    };
    await controller.rescan();
    await timers.settle();
    expect(afterIdle().whereType<ScanRunning>().single.done, 0);
    await timers.advance(const Duration(milliseconds: 300));
    expect(afterIdle().whereType<ScanRunning>().last.done, 9);
    gate.complete();
  });

  test('a new listener first gets the latest status', () async {
    onPass = (_, _, _) async => _done(tracks: 7);
    await controller.rescan();
    await timers.settle();
    final first = await controller.status.first;
    expect((first as ScanFinished).tracks, 7);
  });

  group('startup work', () {
    test('does nothing, not even a timer, while setup is not done', () async {
      setupDone = false;
      controller.ensureStartupWork();
      await timers.advance(const Duration(minutes: 1));
      expect(timers.created, 0);
      expect(passes, isEmpty);
    });

    test('twice gives one scan and one garbage collection', () async {
      controller.ensureStartupWork();
      controller.ensureStartupWork();
      await timers.advance(const Duration(seconds: 1));
      expect(passes, isEmpty);
      await timers.advance(const Duration(seconds: 2));
      expect(passes, hasLength(1));
      await timers.advance(const Duration(seconds: 30));
      expect(passes, hasLength(1));
      expect(garbageRuns, 1);
    });

    test('the startup scan is not a requested one, a rescan is', () async {
      controller.ensureStartupWork();
      await timers.advance(const Duration(seconds: 3));
      expect(passes, hasLength(1));
      expect(controller.lastFinishWasRequested, isFalse);

      await controller.rescan();
      await timers.settle();
      expect(passes, hasLength(2));
      expect(controller.lastFinishWasRequested, isTrue);
    });

    test(
      'a rescan during the startup scan makes the finish a requested one',
      () async {
        final gate = Completer<void>();
        onPass = (_, _, _) async {
          await gate.future;
          return _done();
        };
        controller.ensureStartupWork();
        await timers.advance(const Duration(seconds: 3));
        await controller.rescan();
        gate.complete();
        await timers.settle();
        expect(passes, hasLength(2));
        expect(controller.lastFinishWasRequested, isTrue);
      },
    );

    test('a scan requested earlier means no second scan', () async {
      await controller.rescan();
      await timers.settle();
      controller.ensureStartupWork();
      await timers.advance(const Duration(seconds: 30));
      expect(passes, hasLength(1));
    });

    test('garbage waits for a scan that is still running', () async {
      final gate = Completer<void>();
      onPass = (_, _, _) async {
        await gate.future;
        return ScanOutcome()..failureKind = 'io';
      };
      controller.ensureStartupWork();
      await timers.advance(const Duration(seconds: 13));
      expect(passes, hasLength(1));
      expect(garbageRuns, 0);
      gate.complete();
      await timers.settle();
      expect(garbageRuns, 1);
    });
  });

  test('the startup garbage run goes through the loop, so a scan waits for '
      'it', () async {
    await controller.rescan();
    await timers.settle();
    final gate = Completer<void>();
    var collecting = false;
    var overlap = false;
    final c2 = ScanController(
      runPass: (session, hooks, {required full}) async {
        if (collecting) overlap = true;
        passes.add(full);
        return _done();
      },
      runCoverMisses: (_, _, _) async => ScanOutcome(),
      isSetupDone: () => true,
      collectCoverFiles: () async {},
      collectGarbage: () async {
        collecting = true;
        await gate.future;
        collecting = false;
      },
      clock: () => timers.now,
      timer: timers.create,
    );
    addTearDown(c2.dispose);
    passes.clear();
    await c2.rescan();
    await timers.settle();
    c2.ensureStartupWork();
    await timers.advance(const Duration(seconds: 13));
    expect(collecting, isTrue);
    expect(passes, hasLength(1));
    await c2.rescan();
    await timers.settle();
    expect(passes, hasLength(1)); // waits for the garbage run
    gate.complete();
    await timers.settle();
    expect(passes, hasLength(2));
    expect(overlap, isFalse);
  });

  test('added survives a pass that left a native call pending', () async {
    final call = Completer<void>();
    onPass = (session, _, _) async {
      if (passes.length == 1) {
        session.stuck.add('/a');
        return ScanOutcome()
          ..added = 3
          ..failureKind = 'native_timeout'
          ..pending.add((key: '/a', future: call.future));
      }
      return _done(added: 0, tracks: 7);
    };
    await controller.rescan();
    await timers.settle();
    expect(afterIdle().last, isA<ScanFailed>());
    call.complete();
    await timers.settle();
    final finished = afterIdle().whereType<ScanFinished>().single;
    expect(finished.added, 3);
    expect(finished.tracks, 7);
  });

  test('added kept for a resume that never comes is dropped by the next '
      'request', () async {
    final never = Completer<void>();
    onPass = (session, _, _) async {
      if (passes.length == 1) {
        session.stuck.add('/a');
        return ScanOutcome()
          ..added = 3
          ..failureKind = 'native_timeout'
          ..pending.add((key: '/a', future: never.future));
      }
      return _done(added: 1);
    };
    await controller.rescan();
    await timers.settle();
    await controller.rescan();
    await timers.settle();
    expect(afterIdle().whereType<ScanFinished>().single.added, 1);
  });

  test('added kept for a resume is dropped by a rescan that arrives while '
      'a cover job runs', () async {
    final never = Completer<void>();
    missGate = Completer<void>();
    onPass = (session, _, _) async {
      if (passes.length == 1) {
        session.stuck.add('/a');
        return ScanOutcome()
          ..added = 3
          ..failureKind = 'native_timeout'
          ..pending.add((key: '/a', future: never.future));
      }
      return _done(added: 1);
    };
    await controller.rescan();
    await timers.settle();
    misses.add('ab/0123456789abcdef0123456789abcdef');
    await timers.settle();
    await timers.advance(const Duration(seconds: 3));
    expect(missJobs, isNotEmpty); // the loop is busy with the cover job
    await controller.rescan();
    missGate!.complete();
    await timers.settle();
    expect(afterIdle().whereType<ScanFinished>().single.added, 1);
  });

  test('a rescan during the resume pass keeps that pass\'s count', () async {
    final call = Completer<void>();
    final resumeGate = Completer<void>();
    onPass = (session, _, _) async {
      if (passes.length == 1) {
        session.stuck.add('/a');
        return ScanOutcome()
          ..added = 3
          ..failureKind = 'native_timeout'
          ..pending.add((key: '/a', future: call.future));
      }
      if (passes.length == 2) {
        await resumeGate.future;
        return _done(added: 1);
      }
      return _done(added: 0);
    };
    await controller.rescan();
    await timers.settle();
    call.complete();
    await timers.settle();
    expect(passes, hasLength(2)); // the resume pass is running
    await controller.rescan();
    resumeGate.complete();
    await timers.settle();
    expect(afterIdle().whereType<ScanFinished>().single.added, 4);
  });

  test('added is dropped after a failure with nothing pending', () async {
    onPass = (_, _, _) async {
      if (passes.length == 1) {
        return ScanOutcome()
          ..added = 3
          ..failureKind = 'io';
      }
      return _done(added: 1);
    };
    await controller.rescan();
    await timers.settle();
    await controller.rescan();
    await timers.settle();
    expect(afterIdle().whereType<ScanFinished>().single.added, 1);
  });

  group('stuck native calls', () {
    test(
      'the mark clears when the call returns, then one automatic scan',
      () async {
        final call = Completer<void>();
        final marks = <bool>[];
        onPass = (session, _, _) async {
          marks.add(session.stuck.contains('/a'));
          if (passes.length == 1) {
            session.stuck.add('/a');
            return ScanOutcome()
              ..failureKind = 'native_timeout'
              ..pending.add((key: '/a', future: call.future));
          }
          return _done();
        };
        await controller.rescan();
        await timers.settle();
        expect(passes, hasLength(1));
        call.complete();
        await timers.settle();
        expect(passes, hasLength(2));
        expect(marks, [false, false]);
        expect(afterIdle().last, isA<ScanFinished>());
      },
    );

    test('an automatic scan arms nothing further', () async {
      final calls = [Completer<void>(), Completer<void>()];
      onPass = (session, _, _) async {
        final n = passes.length - 1;
        if (n < 2) {
          session.stuck.add('/a');
          return ScanOutcome()
            ..failureKind = 'native_timeout'
            ..pending.add((key: '/a', future: calls[n].future));
        }
        return _done();
      };
      await controller.rescan();
      await timers.settle();
      calls[0].complete();
      await timers.settle();
      expect(passes, hasLength(2));
      calls[1].complete();
      await timers.settle();
      expect(passes, hasLength(2));
    });
  });

  group('cover misses', () {
    test('are debounced into one job', () async {
      misses.add('aa/1');
      await timers.settle();
      await timers.advance(const Duration(seconds: 1));
      misses.add('bb/2');
      await timers.settle();
      await timers.advance(const Duration(seconds: 1));
      expect(missJobs, isEmpty);
      misses.add('cc/3');
      await timers.settle();
      await timers.advance(const Duration(seconds: 2));
      expect(missJobs, [
        {'aa/1', 'bb/2', 'cc/3'},
      ]);
      expect(afterIdle(), isEmpty);
    });

    test('are ignored while setup is not done', () async {
      setupDone = false;
      misses.add('aa/1');
      await timers.settle();
      await timers.advance(const Duration(seconds: 5));
      expect(missJobs, isEmpty);
    });

    test('wait for a running scan', () async {
      final gate = Completer<void>();
      onPass = (_, _, _) async {
        await gate.future;
        return _done();
      };
      await controller.rescan();
      misses.add('aa/1');
      await timers.settle();
      await timers.advance(const Duration(seconds: 3));
      expect(missJobs, isEmpty);
      gate.complete();
      await timers.settle();
      expect(missJobs, hasLength(1));
    });
  });

  group('dispose', () {
    test(
      'ends a running pass at its next check and publishes nothing',
      () async {
        final gate = Completer<void>();
        var writesAfterStop = 0;
        onPass = (_, hooks, _) async {
          await gate.future;
          if (hooks.shouldStop()) return ScanOutcome()..stopped = true;
          writesAfterStop++;
          return _done();
        };
        final done = Completer<void>();
        controller.status.listen(null, onDone: done.complete);
        await controller.rescan();
        await timers.settle();
        controller.dispose();
        gate.complete();
        await timers.settle();
        expect(writesAfterStop, 0);
        expect(afterIdle().whereType<ScanFinished>(), isEmpty);
        expect(garbageRuns, 0);
        expect(done.isCompleted, isTrue);
      },
    );

    test('cancels every timer', () async {
      controller.ensureStartupWork();
      misses.add('aa/1');
      await timers.settle();
      expect(timers.active, greaterThan(0));
      controller.dispose();
      expect(timers.active, 0);
    });
  });
}
