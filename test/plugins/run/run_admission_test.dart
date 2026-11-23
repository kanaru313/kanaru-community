import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/run/run_admission.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';

import '../data/install_test_support.dart' show turns;

void main() {
  test('takes slots up to the limit and queues the rest in order', () async {
    final admission = RunAdmission(slots: 2);
    final a = (await admission.acquire())!;
    final b = (await admission.acquire())!;
    final order = <String>[];
    final c = admission.acquire().then((s) {
      order.add('c');
      return s!;
    });
    final d = admission.acquire().then((s) {
      order.add('d');
      return s!;
    });
    await turns();
    expect(admission.inUse, 2);
    expect(admission.waiting, 2);
    expect(order, isEmpty);

    a.release();
    final slotC = await c;
    expect(order, ['c']);
    expect(admission.inUse, 2, reason: 'the freed slot moved to c');

    b.release();
    final slotD = await d;
    expect(order, ['c', 'd']);
    slotC.release();
    slotD.release();
    expect(admission.inUse, 0);
  });

  test('release is idempotent', () async {
    final admission = RunAdmission(slots: 1);
    final slot = (await admission.acquire())!;
    slot.release();
    slot.release();
    expect(admission.inUse, 0);
    final again = (await admission.acquire())!;
    final blocked = admission.acquire();
    slot.release(); // stale handle: must not free `again`
    await turns();
    expect(admission.waiting, 1);
    again.release();
    (await blocked)!.release();
  });

  test('an aborted waiter leaves the queue and holds nothing', () async {
    final admission = RunAdmission(slots: 1);
    final held = (await admission.acquire())!;
    final abort = RunCancel();
    final waiter = admission.acquire(abort: abort);
    final next = admission.acquire();
    await turns();
    abort.cancel();
    expect(await waiter, isNull);
    expect(admission.waiting, 1);

    held.release();
    final slot = await next;
    expect(slot, isNotNull);
    expect(admission.inUse, 1);
    slot!.release();
    expect(admission.inUse, 0);
  });

  test('an abort that came before returns at once', () async {
    final admission = RunAdmission(slots: 1);
    final abort = RunCancel()..cancel();
    expect(await admission.acquire(abort: abort), isNull);
    expect(admission.inUse, 0);
  });
}
