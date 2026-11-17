import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';
import '../support/scaled_host.dart';

List<KSortCriterion<String>> _criteria([int n = 3, String? firstLabel]) => [
  for (var i = 0; i < n; i++)
    KSortCriterion(
      value: 'c$i',
      label: i == 0 && firstLabel != null ? firstLabel : 'Criterion $i',
      icon: KIcons.songs,
    ),
];

class _Opener extends StatelessWidget {
  const _Opener({
    required this.onResult,
    this.count = 3,
    this.firstLabel,
    this.advanced = 'Advanced',
    this.align = Alignment.topRight,
  });

  final void Function(Future<KSortPick<String>?>) onResult;
  final int count;
  final String? firstLabel;
  final String? advanced;
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
            criteria: _criteria(count, firstLabel),
            selected: 'c0',
            advancedLabel: advanced,
          ),
        ),
        child: const Text('open'),
      ),
    );
  }
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The popover's own panel: the nearest Material above its content.
Finder _panel() => find.ancestor(
  of: find.byType(IntrinsicWidth),
  matching: find.byType(Material),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('anchored popover on mobile too ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        scaledHost(
          _Opener(onResult: (_) {}),
          brightness: brightness,
          textScale: scale,
        ),
      );
      await _open(tester);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Criterion 2'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  Future<Rect> openAt(
    WidgetTester tester,
    Size window,
    Alignment align, {
    TextDirection? dir,
    int count = 3,
    String? firstLabel,
  }) async {
    useWindow(tester, window);
    Widget opener = _Opener(
      onResult: (_) {},
      align: align,
      count: count,
      firstLabel: firstLabel,
    );
    if (dir != null) opener = Directionality(textDirection: dir, child: opener);
    await tester.pumpWidget(scaledHost(opener));
    await _open(tester);
    return tester.getRect(_panel());
  }

  testWidgets('centred on the anchor when there is room', (tester) async {
    final panel = await openAt(
      tester,
      const Size(400, 800),
      const Alignment(0, -1),
    );
    final chip = tester.getCenter(find.text('open')).dx;
    expect(panel.center.dx, closeTo(chip, 1));
  });

  testWidgets('near the left edge it shifts inward, keeping the margin', (
    tester,
  ) async {
    final panel = await openAt(
      tester,
      const Size(400, 800),
      const Alignment(-1, -1),
    );
    expect(panel.left, closeTo(KSpace.x4, 0.01));
    expect(panel.width, greaterThanOrEqualTo(KLayout.dropdownMinWidth));
  });

  testWidgets('near the right edge it shifts inward, keeping the margin', (
    tester,
  ) async {
    final panel = await openAt(
      tester,
      const Size(400, 800),
      const Alignment(1, -1),
    );
    expect(panel.right, closeTo(400 - KSpace.x4, 0.01));
  });

  testWidgets('a wide popover on a 320 px screen stays inside the margins', (
    tester,
  ) async {
    final panel = await openAt(
      tester,
      const Size(320, 800),
      const Alignment(0.8, -1),
      count: 4,
      firstLabel: 'A very long criterion name that needs the full width',
    );
    expect(panel.left, greaterThanOrEqualTo(KSpace.x4 - 0.01));
    expect(panel.right, lessThanOrEqualTo(320 - KSpace.x4 + 0.01));
    expect(panel.width, greaterThanOrEqualTo(KLayout.dropdownMinWidth));
    expect(panel.width, lessThanOrEqualTo(KLayout.dropdownMaxWidth));
    // The chip is off-centre, so the panel is clamped, not centred.
    final chip = tester.getCenter(find.text('open')).dx;
    expect((panel.center.dx - chip).abs(), greaterThan(1));
    expect(
      (panel.left - KSpace.x4).abs() < 0.01 ||
          (panel.right - (320 - KSpace.x4)).abs() < 0.01,
      isTrue,
    );
  });

  testWidgets('opens under the anchor', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_Opener(onResult: (_) {})));
    final anchorBottom = tester.getBottomLeft(find.text('open')).dy;
    await _open(tester);
    expect(
      tester.getTopLeft(find.text('Advanced')).dy,
      greaterThan(anchorBottom),
    );
  });

  testWidgets('no direction row; Advanced is the first item, no state text', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_Opener(onResult: (_) {})));
    await _open(tester);
    expect(find.text('A to Z'), findsNothing);
    expect(find.text('Z to A'), findsNothing);
    final advancedTop = tester.getTopLeft(find.text('Advanced')).dy;
    for (var i = 0; i < 3; i++) {
      expect(
        tester.getTopLeft(find.text('Criterion $i')).dy,
        greaterThan(advancedTop),
      );
    }
    // The row says only its name: no count or state next to it.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Advanced'),
          matching: find.byType(SelectionRow),
        ),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a criterion resolves to picked and closes', (tester) async {
    useWindow(tester, const Size(400, 800));
    late Future<KSortPick<String>?> result;
    await tester.pumpWidget(scaledHost(_Opener(onResult: (f) => result = f)));
    await _open(tester);
    await tester.tap(find.text('Criterion 1'));
    await tester.pumpAndSettle();
    final pick = await result;
    expect(pick, isA<KSortPicked<String>>());
    expect((pick! as KSortPicked<String>).value, 'c1');
    expect(find.text('Criterion 1'), findsNothing);
  });

  testWidgets('Advanced resolves to advanced and closes', (tester) async {
    useWindow(tester, const Size(400, 800));
    late Future<KSortPick<String>?> result;
    await tester.pumpWidget(scaledHost(_Opener(onResult: (f) => result = f)));
    await _open(tester);
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(await result, isA<KSortAdvanced<String>>());
    expect(find.text('Advanced'), findsNothing);
  });

  testWidgets('the criterion in use is selected, the others are not', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_Opener(onResult: (_) {})));
    await _open(tester);
    expect(
      tester.getSemantics(find.text('Criterion 0')),
      isSemantics(isSelected: true, hasSelectedState: true),
    );
    expect(
      tester.getSemantics(find.text('Criterion 1')),
      isSemantics(isSelected: false, hasSelectedState: true),
    );
    handle.dispose();
  });

  testWidgets('Esc and a tap outside dismiss it with null', (tester) async {
    useWindow(tester, const Size(400, 800));
    late Future<KSortPick<String>?> result;
    await tester.pumpWidget(scaledHost(_Opener(onResult: (f) => result = f)));
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await result, isNull);
    expect(find.text('Advanced'), findsNothing);

    await _open(tester);
    await tester.tapAt(const Offset(20, 700));
    await tester.pumpAndSettle();
    expect(find.text('Advanced'), findsNothing);
  });

  testWidgets('Back dismisses it', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_Opener(onResult: (_) {})));
    await _open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Advanced'), findsNothing);
  });

  testWidgets('the chosen row has keyboard focus: Enter picks it', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    late Future<KSortPick<String>?> result;
    await tester.pumpWidget(scaledHost(_Opener(onResult: (f) => result = f)));
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect((await result)! as KSortPicked<String>, isA<KSortPicked<String>>());
  });

  testWidgets('12 criteria scroll, height <= 360, Advanced stays visible', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_Opener(onResult: (_) {}, count: 12)));
    await _open(tester);
    final panel = tester.getRect(_panel().first);
    expect(panel.height, lessThanOrEqualTo(KLayout.dropdownMaxHeight));
    expect(panel.height, greaterThan(300), reason: 'full, not collapsed');
    // Rows past the panel are built but clipped away below it.
    expect(
      tester.getTopLeft(find.text('Criterion 11')).dy,
      greaterThan(panel.bottom),
    );
    final advancedTop = tester.getTopLeft(find.text('Advanced')).dy;
    await tester.drag(find.text('Criterion 2'), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Criterion 11')).dy,
      lessThan(panel.bottom),
    );
    expect(tester.getTopLeft(find.text('Advanced')).dy, advancedTop);
    expect(tester.takeException(), isNull);
  });

  testWidgets('criteria rows are 2 dp apart', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_Opener(onResult: (_) {})));
    await _open(tester);
    Rect row(String t) => tester.getRect(
      find.ancestor(of: find.text(t), matching: find.byType(SelectionRow)),
    );
    expect(
      row('Criterion 1').top - row('Criterion 0').bottom,
      KLayout.dropdownRowGap,
    );
  });

  testWidgets('a short screen caps the height at 70 %', (tester) async {
    useWindow(tester, const Size(400, 400));
    await tester.pumpWidget(scaledHost(_Opener(onResult: (_) {}, count: 12)));
    await _open(tester);
    expect(tester.getRect(_panel().first).height, lessThanOrEqualTo(280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('width follows the content between 160 and 280', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      scaledHost(
        _Opener(
          onResult: (_) {},
          firstLabel:
              'A criterion name that is far too long for the dropdown to show',
        ),
      ),
    );
    await _open(tester);
    expect(
      tester.getRect(_panel().first).width,
      lessThanOrEqualTo(KLayout.dropdownMaxWidth),
    );
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(20, 700));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      scaledHost(_Opener(onResult: (_) {}, count: 1), textScale: 1.0),
    );
    await _open(tester);
    expect(
      tester.getRect(_panel().first).width,
      greaterThanOrEqualTo(KLayout.dropdownMinWidth),
    );
  });

  testWidgets('flips above the anchor near the bottom edge', (tester) async {
    useWindow(tester, const Size(400, 500));
    await tester.pumpWidget(
      scaledHost(_Opener(onResult: (_) {}, align: Alignment.bottomRight)),
    );
    final anchorTop = tester.getTopLeft(find.text('open')).dy;
    await _open(tester);
    expect(
      tester.getBottomLeft(find.text('Criterion 2')).dy,
      lessThan(anchorTop),
    );
  });

  testWidgets('without an Advanced label the row is left out', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      scaledHost(_Opener(onResult: (_) {}, advanced: null)),
    );
    await _open(tester);
    expect(find.text('Advanced'), findsNothing);
    expect(find.text('Criterion 0'), findsOneWidget);
  });
}
