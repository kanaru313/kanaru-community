import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/browse/throttled_query.dart';

import '../../database/support/test_db.dart';
import 'support/wait.dart';

const _gap = Duration(seconds: 1);
const _ms = Duration(milliseconds: 1);

// Fake time only moves on `pump`, so a cancel is started and then pumped.
Future<void> _cancel(WidgetTester tester, StreamSubscription<void> sub) async {
  unawaited(sub.cancel());
  await tester.pump();
}

// The state machine tests run in the widget test zone: time is fake and a
// timer left behind fails the test when its body ends.
void main() {
  late StreamController<void> changes;
  late int loads;

  setUp(() {
    changes = StreamController<void>.broadcast(sync: true);
    loads = 0;
    addTearDown(() {
      unawaited(changes.close());
    });
  });

  Stream<int> query({Future<int> Function()? load, Duration interval = _gap}) =>
      throttledReload(
        () => changes.stream,
        load ?? () async => ++loads,
        interval: interval,
        // Fake time does not move DateTime.now: no load costs anything here.
        now: () => DateTime(2026),
      );

  testWidgets('first load runs at once on listen', (tester) async {
    final sub = query().listen((_) {});
    await tester.pump();
    expect(loads, 1);
    await _cancel(tester, sub);
  });

  testWidgets(
    'storm of writes: exactly 2 loads, last one sees the last write',
    (tester) async {
      var version = 0;
      final seen = <int>[];
      final sub = query(
        load: () async {
          loads++;
          return version;
        },
      ).listen(seen.add);
      await tester.pump();
      for (var i = 0; i < 50; i++) {
        version++;
        changes.add(null);
        await tester.pump(_ms * 10);
      }
      await tester.pump(_gap * 2);
      expect(loads, 2);
      expect(seen.last, 50);
      await _cancel(tester, sub);
    },
  );

  testWidgets(
    'a running load is not cancelled by a write, loads never overlap',
    (tester) async {
      final gate = Completer<void>();
      var running = 0, maxRunning = 0;
      final seen = <int>[];
      final sub = query(
        interval: Duration.zero,
        load: () async {
          final n = ++loads;
          maxRunning = ++running > maxRunning ? running : maxRunning;
          if (n == 1) await gate.future;
          running--;
          return n;
        },
      ).listen(seen.add);
      await tester.pump();
      changes.add(null);
      changes.add(null);
      await tester.pump(_gap);
      expect(loads, 1);
      gate.complete();
      await tester.pump();
      expect(seen, [1, 2]);
      expect(maxRunning, 1);
      await _cancel(tester, sub);
    },
  );

  testWidgets('next load starts one interval after the previous load ended', (
    tester,
  ) async {
    // A slow load: a cooldown counted from the start would end sooner.
    const work = Duration(milliseconds: 300);
    final sub = query(
      load: () async {
        loads++;
        await Future<void>.delayed(work);
        return loads;
      },
    ).listen((_) {});
    await tester.pump(); // load 1 starts
    changes.add(null);
    await tester.pump(work); // load 1 ends
    expect(loads, 1);
    await tester.pump(_gap - _ms);
    expect(loads, 1, reason: 'cooldown counts from the end of the load');
    await tester.pump(_ms);
    expect(loads, 2);
    await tester.pump(work);
    await _cancel(tester, sub);
  });

  testWidgets('a slow load stretches the wait to four times its duration', (
    tester,
  ) async {
    // The clock is advanced by the load itself: Stopwatch and DateTime do not
    // follow fake time.
    var clock = DateTime(2026);
    const work = Duration(milliseconds: 400);
    final sub = throttledReload<int>(
      () => changes.stream,
      () async {
        loads++;
        await Future<void>.delayed(work);
        clock = clock.add(work);
        return loads;
      },
      interval: _gap,
      now: () => clock,
    ).listen((_) {});
    await tester.pump();
    changes.add(null);
    await tester.pump(work); // load 1 ends; the wait is max(1 s, 1.6 s)
    await tester.pump(_gap + const Duration(milliseconds: 599));
    expect(loads, 1);
    await tester.pump(_ms);
    expect(loads, 2);
    await tester.pump(work);
    await _cancel(tester, sub);
  });

  testWidgets('the adaptive wait is capped', (tester) async {
    var clock = DateTime(2026);
    const work = Duration(seconds: 30);
    final sub = throttledReload<int>(
      () => changes.stream,
      () async {
        loads++;
        await Future<void>.delayed(work);
        clock = clock.add(work);
        return loads;
      },
      interval: _gap,
      now: () => clock,
    ).listen((_) {});
    await tester.pump();
    changes.add(null);
    await tester.pump(work);
    await tester.pump(maxRefreshWait - _ms);
    expect(loads, 1);
    await tester.pump(_ms);
    expect(loads, 2);
    await tester.pump(work);
    await _cancel(tester, sub);
  });

  testWidgets('an equal result is not emitted; after an error it is', (
    tester,
  ) async {
    final events = <Object>[];
    var n = 0;
    final sub = throttledReload<List<int>>(
      () => changes.stream,
      () async {
        n++;
        if (n == 3) throw StateError('busy');
        return [1, 2];
      },
      interval: Duration.zero,
      now: () => DateTime(2026),
      equals: (a, b) => a.length == b.length && a.first == b.first,
    ).listen(events.add, onError: events.add);
    await tester.pump();
    changes.add(null); // same list: dropped
    await tester.pump();
    changes.add(null); // error
    await tester.pump();
    changes.add(null); // same list again, but the error reset the memory
    await tester.pump();
    expect(events, [
      [1, 2],
      isA<StateError>(),
      [1, 2],
    ]);
    await _cancel(tester, sub);
  });

  testWidgets('error is emitted and later writes still load', (tester) async {
    final values = <Object>[];
    final sub = query(
      load: () async {
        if (++loads == 1) throw StateError('boom');
        return loads;
      },
    ).listen(values.add, onError: values.add);
    await tester.pump();
    changes.add(null);
    await tester.pump(_gap);
    expect(values.first, isA<StateError>());
    expect(values.last, 2);
    await _cancel(tester, sub);
  });

  testWidgets('error of the change stream reaches the consumer', (
    tester,
  ) async {
    final errors = <Object>[];
    final sub = query().listen((_) {}, onError: errors.add);
    await tester.pump();
    changes.addError(StateError('closed'));
    await tester.pump();
    expect(errors, hasLength(1));
    await _cancel(tester, sub);
  });

  testWidgets('cancel during cooldown leaves no timer and loads nothing', (
    tester,
  ) async {
    final sub = query().listen((_) {});
    await tester.pump();
    changes.add(null);
    await _cancel(tester, sub);
    // The test fails after this body if the cooldown timer is still pending.
    await tester.pump(_gap * 2);
    expect(loads, 1);
    expect(changes.hasListener, isFalse);
  });

  testWidgets('cancel while loading drops the result and leaves no timer', (
    tester,
  ) async {
    final gate = Completer<void>();
    final seen = <int>[];
    final sub = query(
      load: () async {
        await gate.future;
        return 1;
      },
    ).listen(seen.add);
    await tester.pump();
    await _cancel(tester, sub);
    gate.complete();
    await tester.pump(_gap);
    expect(seen, isEmpty);
  });

  testWidgets('pause defers loading, resume loads once', (tester) async {
    final sub = query().listen((_) {});
    await tester.pump();
    sub.pause();
    changes.add(null);
    changes.add(null);
    await tester.pump(_gap * 2);
    expect(loads, 1);
    sub.resume();
    await tester.pump();
    expect(loads, 2);
    await tester.pump(_gap);
    await _cancel(tester, sub);
  });

  // Real time: sqlite I/O does not advance under fake time.
  test('reloads after a write to a watched table', () async {
    final db = openTestDb();
    addTearDown(db.close);
    final seen = <int>[];
    final sub = throttledQuery(
      db,
      {db.tracks},
      () async => (await db.select(db.tracks).get()).length,
      interval: const Duration(milliseconds: 20),
    ).listen(seen.add);
    addTearDown(sub.cancel);
    await until(() => seen.isNotEmpty);
    expect(seen, [0]);
    final source = await addSource(db);
    await addTrack(db, source, locator: 'a.flac');
    await until(() => seen.length == 2);
    expect(seen.last, 1);
  });
}
