import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Future<SplitMetrics> _pump(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  late SplitMetrics seen;
  await tester.pumpWidget(
    host(
      NowPlayingSplitLayout(
        titleStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        lineStyle: const TextStyle(fontSize: 16),
        seekHeight: 48,
        columnBuilder: (context, m) {
          seen = m;
          return ColoredBox(
            key: const ValueKey('column'),
            color: Colors.red,
            child: SizedBox(height: m.blockHeight),
          );
        },
        pane: const ColoredBox(key: ValueKey('pane'), color: Colors.blue),
      ),
      textScale: textScale,
    ),
  );
  return seen;
}

void main() {
  testWidgets('the column takes 42 % and the pane the rest', (tester) async {
    await _pump(tester, size: const Size(1000, 800));
    expect(tester.getSize(find.byKey(const ValueKey('column'))).width, 420);
    expect(tester.getSize(find.byKey(const ValueKey('pane'))).width, 580);
  });

  testWidgets('a narrow body still gives the column 300', (tester) async {
    await _pump(tester, size: const Size(600, 800));
    expect(tester.getSize(find.byKey(const ValueKey('column'))).width, 300);
  });

  testWidgets('a wide body caps the column at 600', (tester) async {
    await _pump(tester, size: const Size(2400, 1000));
    expect(tester.getSize(find.byKey(const ValueKey('column'))).width, 600);
  });

  testWidgets('metrics: inner width, cover side and block height agree', (
    tester,
  ) async {
    final m = await _pump(tester, size: const Size(1000, 900));
    expect(m.columnWidth, 420);
    expect(m.innerWidth, 420 - 48);
    expect(m.coverSide, lessThanOrEqualTo(m.innerWidth));
    expect(m.coverSide, lessThanOrEqualTo(500));
    final reserve = splitReserve(
      TextScaler.noScaling,
      titleStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      lineStyle: const TextStyle(fontSize: 16),
      seekHeight: 48,
    );
    expect(m.blockHeight, m.coverSide + reserve);
  });

  testWidgets('a short window shrinks the cover but not below 96', (
    tester,
  ) async {
    final m = await _pump(tester, size: const Size(1200, 300));
    expect(m.coverSide, 96);
  });

  testWidgets('a larger text scale shrinks the cover, not the other parts', (
    tester,
  ) async {
    final normal = await _pump(tester, size: const Size(1280, 800));
    final big = await _pump(
      tester,
      size: const Size(1280, 800),
      textScale: 1.5,
    );
    expect(big.coverSide, lessThan(normal.coverSide));
    expect(big.innerWidth, normal.innerWidth);
  });

  testWidgets('the metrics do not change when the window is the same', (
    tester,
  ) async {
    final a = await _pump(tester, size: const Size(1280, 800));
    final b = await _pump(tester, size: const Size(1280, 800));
    expect(a.coverSide, b.coverSide);
    expect(a.blockHeight, b.blockHeight);
  });
}
