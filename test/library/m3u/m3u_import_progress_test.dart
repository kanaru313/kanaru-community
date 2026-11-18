import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/state/m3u/m3u_import_progress.dart';

M3uImportProgress _p(int done, [int? total]) =>
    M3uImportProgress(fileName: 'a.m3u', done: done, total: total);

Duration _ms(int n) => Duration(milliseconds: n);

void main() {
  late ProviderContainer container;
  late M3uImportProgressNotifier notifier;
  late List<M3uImportProgressView?> seen;

  M3uImportProgressView? view() => container.read(m3uImportProgressProvider);

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    seen = [];
    // Keeps the provider alive and records every state change.
    container.listen(m3uImportProgressProvider, (_, next) => seen.add(next));
    notifier = container.read(m3uImportProgressProvider.notifier);
  });

  testWidgets('nothing before begin; updates before begin are ignored', (
    t,
  ) async {
    notifier.update(_p(3, 10));
    expect(view(), isNull);
    expect(seen, isEmpty);
  });

  testWidgets('an import that ends within 500 ms never becomes visible', (
    t,
  ) async {
    notifier.begin('a.m3u');
    expect(view()!.visible, isFalse);
    await t.pump(_ms(500));
    notifier.end();
    await t.pump(const Duration(seconds: 3));
    expect(seen.any((v) => v?.visible ?? false), isFalse);
    expect(view(), isNull);
  });

  testWidgets('a 3 s import is visible from 1 s with the latest numbers', (
    t,
  ) async {
    notifier.begin('a.m3u');
    notifier.update(_p(0));
    await t.pump(_ms(900));
    expect(view()!.visible, isFalse);
    await t.pump(_ms(100));
    expect(view()!.visible, isTrue);
    expect(view()!.fileName, 'a.m3u');
    notifier.update(_p(0, 40));
    await t.pump(const Duration(seconds: 1));
    notifier.update(_p(25, 40));
    expect(view()!.done, 25);
    expect(view()!.total, 40);
    expect(view()!.visible, isTrue);
    notifier.end();
    expect(view(), isNull);
  });

  testWidgets('updates are coalesced to one per 100 ms, the last is kept', (
    t,
  ) async {
    notifier.begin('a.m3u');
    seen.clear();
    for (var i = 1; i <= 50; i++) {
      notifier.update(_p(i, 100));
      await t.pump(_ms(5)); // 250 ms of a fast reporter
    }
    // The first applied at once, then one per 100 ms gate.
    expect(seen.first!.done, 1);
    expect(seen.length, lessThanOrEqualTo(4));
    await t.pump(_ms(150));
    expect(seen.last!.done, 50, reason: 'the last update is never dropped');
    expect(view()!.done, 50);
    notifier.end();
  });

  testWidgets('end() drops a held update and stops every timer', (t) async {
    notifier.begin('a.m3u');
    notifier.update(_p(1, 10));
    notifier.update(_p(2, 10)); // held by the gate
    notifier.end();
    seen.clear();
    await t.pump(const Duration(seconds: 5));
    expect(seen, isEmpty, reason: 'no timer fired after end()');
    expect(view(), isNull);
  });

  testWidgets('a new begin replaces the previous import cleanly', (t) async {
    notifier.begin('a.m3u');
    await t.pump(_ms(800));
    notifier.begin('b.m3u');
    await t.pump(_ms(400));
    expect(view()!.fileName, 'b.m3u');
    expect(view()!.visible, isFalse, reason: 'the delay restarts');
    notifier.end();
  });

  testWidgets('disposing the container cancels the timers', (t) async {
    notifier.begin('a.m3u');
    notifier.update(_p(1, 10));
    notifier.update(_p(2, 10));
    container.dispose();
    // A live timer would fire into the disposed notifier and throw.
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('end() and update() after dispose do nothing', (t) async {
    notifier.begin('a.m3u');
    container.dispose();
    notifier.update(_p(1, 10));
    notifier.end();
  });
}
