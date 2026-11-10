import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

List<KSortCriterion<String>> _criteria([int n = 3]) => [
  for (var i = 0; i < n; i++)
    KSortCriterion(value: 'c$i', label: 'Criterion $i', icon: KIcons.songs),
];

class _Opener extends StatelessWidget {
  const _Opener({
    required this.onResult,
    required this.onOrder,
    this.count = 3,
    this.align = Alignment.topRight,
  });

  final void Function(Future<String?>) onResult;
  final ValueChanged<bool> onOrder;
  final int count;
  final Alignment align;

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();
    return Align(
      alignment: align,
      child: TextButton(
        key: key,
        onPressed: () => onResult(
          showKSortPopover<String>(
            context,
            anchor: key,
            criteria: _criteria(count),
            selected: 'c0',
            ascending: true,
            ascendingLabel: 'A to Z',
            descendingLabel: 'Z to A',
            onAscendingChanged: onOrder,
          ),
        ),
        child: const Text('open'),
      ),
    );
  }
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('anchored popover on mobile too ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          _Opener(onResult: (_) {}, onOrder: (_) {}),
          brightness: brightness,
          textScale: scale,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('A to Z'), findsOneWidget);
      expect(find.text('Criterion 2'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opens under the anchor', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_Opener(onResult: (_) {}, onOrder: (_) {})));
    final anchorBottom = tester.getBottomLeft(find.text('open')).dy;
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(find.text('A to Z')).dy;
    expect(top, greaterThan(anchorBottom));
  });

  testWidgets('changing the order keeps it open; a criterion closes it', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    late Future<String?> result;
    final orders = <bool>[];
    await tester.pumpWidget(
      host(_Opener(onResult: (f) => result = f, onOrder: orders.add)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Z to A'));
    await tester.pumpAndSettle();
    expect(orders, [false]);
    expect(find.text('Criterion 1'), findsOneWidget);

    await tester.tap(find.text('A to Z'));
    await tester.pumpAndSettle();
    expect(orders, [false, true]);

    await tester.tap(find.text('A to Z'));
    await tester.pumpAndSettle();
    expect(orders, [false, true], reason: 'already ascending: no event');

    await tester.tap(find.text('Criterion 1'));
    await tester.pumpAndSettle();
    expect(await result, 'c1');
    expect(find.text('Criterion 1'), findsNothing);
  });

  testWidgets('Esc and a tap outside dismiss it with null', (tester) async {
    useWindow(tester, const Size(400, 800));
    late Future<String?> result;
    await tester.pumpWidget(
      host(_Opener(onResult: (f) => result = f, onOrder: (_) {})),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await result, isNull);
    expect(find.text('A to Z'), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 700));
    await tester.pumpAndSettle();
    expect(find.text('A to Z'), findsNothing);
  });

  testWidgets('criteria scroll while the order row stays', (tester) async {
    useWindow(tester, const Size(400, 400));
    await tester.pumpWidget(
      host(_Opener(onResult: (_) {}, onOrder: (_) {}, count: 20)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Criterion 19'), findsNothing);
    final orderTop = tester.getTopLeft(find.text('A to Z')).dy;
    await tester.drag(find.text('Criterion 2'), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Criterion 19'), findsOneWidget);
    expect(tester.getTopLeft(find.text('A to Z')).dy, orderTop);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flips above the anchor near the bottom edge', (tester) async {
    useWindow(tester, const Size(400, 500));
    await tester.pumpWidget(
      host(
        _Opener(
          onResult: (_) {},
          onOrder: (_) {},
          count: 3,
          align: Alignment.bottomRight,
        ),
      ),
    );
    final anchorTop = tester.getTopLeft(find.text('open')).dy;
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.text('Criterion 2')).dy,
      lessThan(anchorTop),
    );
  });
}
