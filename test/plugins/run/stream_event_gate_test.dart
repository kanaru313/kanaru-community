import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/run/stream_event_gate.dart';

// Short settle so the timeout path runs in real time.
const _settle = Duration(milliseconds: 50);

void main() {
  test('events arrive in order and finish waits for the stream end', () async {
    final controller = StreamController<String>();
    final seen = <String>[];
    final gate = StreamEventGate(controller.stream, seen.add, settle: _settle);
    controller.add('1');
    final finish = gate.finish();
    controller
      ..add('2')
      ..close();
    await finish;
    expect(seen, ['1', '2']);
  });

  test('settle timeout closes the gate and drops late events', () async {
    final controller = StreamController<String>();
    final seen = <String>[];
    final gate = StreamEventGate(controller.stream, seen.add, settle: _settle);
    final watch = Stopwatch()..start();
    await gate.finish();
    expect(watch.elapsed, greaterThanOrEqualTo(_settle));
    controller.add('late');
    await Future<void>.delayed(Duration.zero);
    expect(seen, isEmpty);
    expect(controller.hasListener, isFalse);
  });

  test('a throwing handler does not stop later events', () async {
    final controller = StreamController<String>();
    final seen = <String>[];
    StreamEventGate(controller.stream, (json) {
      seen.add(json);
      if (json == 'a') throw StateError('secret text');
    }, settle: _settle);
    controller
      ..add('a')
      ..add('b');
    await Future<void>.delayed(Duration.zero);
    expect(seen, ['a', 'b']);
  });

  test('a stream error counts as the end', () async {
    final controller = StreamController<String>();
    final gate = StreamEventGate(controller.stream, (_) {}, settle: _settle);
    final finish = gate.finish();
    controller.addError(StateError('x'));
    final watch = Stopwatch()..start();
    await finish;
    expect(watch.elapsed, lessThan(_settle));
  });
}
