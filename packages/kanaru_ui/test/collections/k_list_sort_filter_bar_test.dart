import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _bar({
  bool ascending = true,
  bool filterOpen = false,
  void Function(GlobalKey)? onSort,
  VoidCallback? onFilter,
  Widget? view,
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
      view: view,
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

  testWidgets('with the view switch the bar fits 360 dp at text scale 2', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 800));
    await tester.pumpWidget(
      host(
        _bar(
          view: KIconButton(
            tooltip: 'View',
            icon: KIcons.grid,
            size: KIconSize.sm,
            onPressed: () {},
          ),
        ),
        textScale: 2.0,
      ),
    );
    expect(find.byIcon(KIcons.grid), findsOneWidget);
    expect(find.byIcon(KIcons.filter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  for (final (name, size, platform) in [
    ('mobile', const Size(400, 800), TargetPlatform.android),
    ('desktop', const Size(1280, 800), TargetPlatform.linux),
  ]) {
    testWidgets('the filter is a 36 dp small icon, light closed and tonal '
        'open, the same on every shell ($name)', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        useWindow(tester, size);
        await tester.pumpWidget(host(_bar()));
        final closed = tester.getSize(find.byType(KIconButton));
        await tester.pumpWidget(host(_bar(filterOpen: true)));
        final open = tester.getSize(find.byType(IconButton));
        expect(closed, const Size.square(KListSortFilterBar.buttonSize));
        expect(open, closed);
        expect(find.byType(KIconButton), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('the view switch sits left of the sort chip, filter last', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topCenter,
          child: KListSortFilterBar(
            leading: const Text('36 songs'),
            criterionLabel: 'Title',
            ascending: true,
            onSortPressed: (_) {},
            filterOpen: false,
            onFilterToggle: () {},
            filterTooltip: 'Filter',
            view: KIconButton(
              tooltip: 'View',
              icon: KIcons.grid,
              size: KIconSize.sm,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    final chip = tester.getRect(find.text('Title')).center.dx;
    final view = tester.getCenter(find.byIcon(KIcons.grid)).dx;
    final filter = tester.getCenter(find.byIcon(KIcons.filter)).dx;
    expect(view, lessThan(chip));
    expect(chip, lessThan(filter));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard focus stays on the filter button when it toggles', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var open = false;
    var toggles = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            return _bar(
              filterOpen: open,
              onFilter: () {
                toggles++;
                setState(() => open = !open);
              },
            );
          },
        ),
      ),
    );
    // Focus the light button with the keyboard, then press Enter twice.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final button = tester.widget<KIconButton>(find.byType(KIconButton));
    button.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    expect(open, isTrue);
    expect(find.byType(KIconButton), findsNothing, reason: 'tonal now');
    final tonal = tester.widget<IconButton>(find.byType(IconButton));
    expect(tonal.focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    expect(open, isFalse);
    expect(toggles, 2);
    final light = tester.widget<KIconButton>(find.byType(KIconButton));
    expect(light.focusNode!.hasFocus, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('the sort chip is announced with its criterion', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_bar()));
    expect(find.bySemanticsLabel('Sort: Title'), findsOneWidget);
    handle.dispose();
  });
}
