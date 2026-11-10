import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

List<KBreadcrumbSegment> _path(int n, List<String> taps) => [
  for (var i = 0; i < n; i++)
    KBreadcrumbSegment(label: 'L$i', onTap: () => taps.add('L$i')),
];

Widget _crumb(
  List<KBreadcrumbSegment> segments,
  void Function(List<KBreadcrumbSegment>) onHidden,
) => Align(
  alignment: Alignment.topLeft,
  child: KBreadcrumb(
    segments: segments,
    onShowHidden: onHidden,
    hiddenTooltip: 'Levels',
  ),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          _crumb(_path(2, []), (_) {}),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(find.text('L0'), findsOneWidget);
      expect(find.text('L1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('desktop keeps the first and last three, hides the middle', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 800));
    List<KBreadcrumbSegment>? hidden;
    await tester.pumpWidget(host(_crumb(_path(7, []), (h) => hidden = h)));
    for (final shown in ['L0', 'L4', 'L5', 'L6']) {
      expect(find.text(shown), findsOneWidget);
    }
    for (final gone in ['L1', 'L2', 'L3']) {
      expect(find.text(gone), findsNothing);
    }
    await tester.tap(find.byIcon(KIcons.moreHoriz));
    expect(hidden?.map((s) => s.label), ['L1', 'L2', 'L3']);
  });

  testWidgets('desktop shows four levels in full', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_crumb(_path(4, []), (_) {})));
    expect(find.byIcon(KIcons.moreHoriz), findsNothing);
    expect(find.text('L1'), findsOneWidget);
  });

  testWidgets('mobile shows up to two levels in full', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_crumb(_path(2, []), (_) {})));
    expect(find.byIcon(KIcons.moreHoriz), findsNothing);
    expect(find.text('L0'), findsOneWidget);
  });

  testWidgets('mobile deeper than two: tonal ... then the open level', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    List<KBreadcrumbSegment>? hidden;
    await tester.pumpWidget(host(_crumb(_path(5, []), (h) => hidden = h)));
    expect(find.text('L4'), findsOneWidget);
    expect(find.text('L0'), findsNothing);
    final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
    final tonal = tester.widget<Material>(
      find
          .ancestor(
            of: find.byIcon(KIcons.moreHoriz),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(tonal.color, scheme.secondaryContainer);
    await tester.tap(find.byIcon(KIcons.moreHoriz));
    expect(hidden?.map((s) => s.label), ['L0', 'L1', 'L2', 'L3']);
  });

  testWidgets('a level jumps; the open level is bold and inert', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final taps = <String>[];
    await tester.pumpWidget(host(_crumb(_path(2, taps), (_) {})));
    await tester.tap(find.text('L0'));
    await tester.tap(find.text('L1'));
    expect(taps, ['L0']);
    final open = tester.widget<Text>(find.text('L1'));
    final other = tester.widget<Text>(find.text('L0'));
    expect(open.style!.fontWeight, FontWeight.w800);
    expect(other.style!.fontWeight, isNot(FontWeight.w800));
  });

  testWidgets('long names do not overflow', (tester) async {
    useWindow(tester, const Size(360, 800));
    final long = [
      for (var i = 0; i < 2; i++)
        KBreadcrumbSegment(label: 'A very long folder name number $i x' * 3),
    ];
    await tester.pumpWidget(host(_crumb(long, (_) {}), textScale: 1.5));
    expect(tester.takeException(), isNull);
  });
}
