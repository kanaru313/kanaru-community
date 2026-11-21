import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/write_queue.dart';

void main() {
  PluginWriteQueue queue0([Future<void> Function()? first]) =>
      PluginWriteQueue(firstJob: first ?? () async {});

  test('jobs run strictly one after another in the order queued', () async {
    final queue = queue0();
    final log = <String>[];
    Future<void> job(String name, int ms) async {
      log.add('start $name');
      await Future<void>.delayed(Duration(milliseconds: ms));
      log.add('end $name');
    }

    await Future.wait([
      queue.run(() => job('a', 30)),
      queue.run(() => job('b', 1)),
      queue.run(() => job('c', 10)),
    ]);
    expect(log, ['start a', 'end a', 'start b', 'end b', 'start c', 'end c']);
  });

  test('the first job ends before any later job starts', () async {
    final gate = Completer<void>();
    final log = <String>[];
    final queue = queue0(() async {
      await gate.future;
      log.add('sweep');
    });
    final later = queue.run(() async => log.add('install'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(log, isEmpty);
    gate.complete();
    await later;
    expect(log, ['sweep', 'install']);
    await queue.startup;
  });

  test('a failing first job does not stop the queue', () async {
    final queue = queue0(() async => throw StateError('disk'));
    expect(await queue.run(() async => 7), 7);
  });

  test('an error of one job reaches only its caller', () async {
    final queue = queue0();
    final failing = queue.run<int>(() async => throw StateError('boom'));
    final next = queue.run(() async => 2);
    await expectLater(failing, throwsStateError);
    expect(await next, 2);
  });

  test('onError turns an exception into a typed result', () async {
    final queue = queue0();
    final result = await queue.run<String>(
      () async => throw FormatException('x'),
      onError: (e, _) => 'failed: ${e.runtimeType}',
    );
    expect(result, 'failed: FormatException');
  });

  test('the same key in flight shares one run', () async {
    final queue = queue0();
    var runs = 0;
    Future<int> job() async {
      runs++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return runs;
    }

    final results = await Future.wait([
      queue.run(job, key: 'install:a'),
      queue.run(job, key: 'install:a'),
    ]);
    expect(results, [1, 1]);
    expect(runs, 1);
    // The key is released once the job ended.
    expect(await queue.run(job, key: 'install:a'), 2);
  });

  test('different keys do not share', () async {
    final queue = queue0();
    var runs = 0;
    await Future.wait([
      queue.run(() async => runs++, key: 'a'),
      queue.run(() async => runs++, key: 'b'),
    ]);
    expect(runs, 2);
  });

  test('a key is released after a failure too', () async {
    final queue = queue0();
    await expectLater(
      queue.run<int>(() async => throw StateError('x'), key: 'k'),
      throwsStateError,
    );
    expect(await queue.run(() async => 5, key: 'k'), 5);
  });

  test(
    'a closed queue refuses new jobs, typed when onError is given',
    () async {
      final queue = queue0()..close();
      await expectLater(queue.run(() async => 1), throwsStateError);
      expect(await queue.run<int>(() async => 1, onError: (_, _) => -1), -1);
    },
  );

  test('close lets jobs already queued run', () async {
    final queue = queue0();
    final done = <int>[];
    final a = queue.run(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      done.add(1);
    });
    final b = queue.run(() async => done.add(2));
    queue.close();
    await Future.wait([a, b]);
    expect(done, [1, 2]);
  });
}
