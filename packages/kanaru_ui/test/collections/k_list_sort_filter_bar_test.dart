import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _bar({
  bool ascending = true,
  bool filterOpen = false,
  void Function(GlobalKey)? onSort,
  VoidCallback? onFilter,
}) {
  return Align(
    alignment: Alignment.topCenter,
    child: KListSortFilterBar(
      leading: const Text('36 songs'),
      criterionLabel: 'Title',
      ascending: ascending,
      onSortPressed: onSort ?? (_) {},
      filterOpen: filterOpen,
      onFilterToggle: onFilter ?? () {},
      sortTooltip: 'Sort',
      filterTooltip: 'Filter',
    ),
  );
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders both groups ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_bar(), brightness: brightness, textScale: scale),
      );
      expect(find.text('36 songs'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.byIcon(KIcons.sortAsc), findsOneWidget);
      expect(find.byIcon(KIcons.filter), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the arrow follows the direction', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_bar(ascending: false)));
    expect(find.byIcon(KIcons.sortDesc), findsOneWidget);
    expect(find.byIcon(KIcons.sortAsc), findsNothing);
  });

  testWidgets('52 tall on mobile, 48 on desktop', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_bar()));
    expect(
      tester.getSize(find.byType(KListSortFilterBar)).height,
      greaterThanOrEqualTo(52),
    );
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_bar()));
    expect(tester.getSize(find.byType(KListSortFilterBar)).height, 48);
  });

  testWidgets('the chip hands over an attached anchor; filter toggles', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    GlobalKey? anchor;
    var toggles = 0;
    await tester.pumpWidget(
      host(_bar(onSort: (k) => anchor = k, onFilter: () => toggles++)),
    );
    await tester.tap(find.text('Title'));
    expect(anchor?.currentContext, isNotNull);
    await tester.tap(find.byIcon(KIcons.filter));
    expect(toggles, 1);
  });

  testWidgets('the open filter button is selected', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_bar(filterOpen: true)));
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(KIcons.filter),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.isSelected, isTrue);
  });

  testWidgets('the sort chip is announced with its criterion', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_bar()));
    expect(find.bySemanticsLabel('Sort: Title'), findsOneWidget);
    handle.dispose();
  });
}
