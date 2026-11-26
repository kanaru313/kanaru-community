import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/data/run/stream_table.dart';

void main() {
  test('holds at most two streams and refuses a taken id', () {
    final table = StreamTable(RunCancel());
    final a = table.reserve(1);
    expect(a, isNotNull);
    expect(table.reserve(1), isNull);
    expect(table.reserve(2), isNotNull);
    expect(table.reserve(3), isNull);
    table.release(a!);
    expect(table.reserve(3), isNotNull);
    table.dispose();
  });

  test('the job cancel seals the table and stops every entry', () {
    final cancel = RunCancel();
    final table = StreamTable(cancel);
    final a = table.reserve(1)!;
    cancel.cancel();
    expect(table.isSealed, isTrue);
    expect(a.isClosed, isTrue);
    expect(table.length, 0);
    expect(table.reserve(2), isNull);
  });

  test('dispose removes its listener from the job token', () {
    final cancel = RunCancel();
    final table = StreamTable(cancel)..reserve(1);
    expect(cancel.listenerCount, 1);
    table.dispose();
    expect(cancel.listenerCount, 0);
    expect(table.length, 0);
  });

  test('a released entry cannot free a slot taken by a newer one', () {
    final table = StreamTable(RunCancel());
    final old = table.reserve(1)!;
    table.release(old);
    final fresh = table.reserve(1)!;
    table.release(old);
    expect(table.find(1), same(fresh));
    table.dispose();
  });
}
