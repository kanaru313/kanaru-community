import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';
import '../support/scaled_host.dart';

Widget _bar({
  String label = 'Title',
  bool ascending = true,
  bool filterOpen = false,
  void Function(GlobalKey)? onSort,
  VoidCallback? onReverse,
  bool withReverse = true,
  VoidCallback? onFilter,
  Widget? view,
}) {
  return Align(
    alignment: Alignment.topCenter,
    child: KListSortFilterBar(
      leading: const Text('36 songs'),
      sortLabel: label,
      ascending: ascending,
      onSortPressed: onSort ?? (_) {},
      onReverse: withReverse ? (onReverse ?? () {}) : null,
      reverseTooltip: withReverse ? 'Reverse order' : null,
      filterOpen: filterOpen,
      onFilterToggle: onFilter ?? () {},
      sortTooltip: 'Sort',
      filterTooltip: 'Filter',
      view: view,
    ),
  );
}

Widget _viewButton() => KIconButton(
  tooltip: 'View',
  icon: KIcons.grid,
  size: KIconSize.sm,
  onPressed: () {},
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders both groups ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        scaledHost(_bar(), brightness: brightness, textScale: scale),
      );
      expect(find.text('36 songs'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(byIconButton('Reverse order'), findsOneWidget);
      expect(byIconButton('Filter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('with the view switch the bar fits 360 dp at text scale 2', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 800));
    await tester.pumpWidget(
      scaledHost(_bar(view: _viewButton()), textScale: 2.0),
    );
    expect(byIconButton('View'), findsOneWidget);
    expect(byIconButton('Reverse order'), findsOneWidget);
    expect(byIconButton('Filter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long label is ellipsized and every button stays at 320 dp', (
    tester,
  ) async {
    useWindow(tester, const Size(320, 800));
    await tester.pumpWidget(
      scaledHost(
        _bar(
          label: 'A criterion with a very long name +2',
          view: _viewButton(),
        ),
      ),
    );
    final text = tester.widget<Text>(
      find.text('A criterion with a very long name +2'),
    );
    expect(text.overflow, TextOverflow.ellipsis);
    expect(byIconButton('View'), findsOneWidget);
    expect(byIconButton('Reverse order'), findsOneWidget);
    expect(byIconButton('Filter'), findsOneWidget);
    expect(find.text('36 songs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the chip shows the label it is given, e.g. "Artist +2"', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_bar(label: 'Artist +2')));
    expect(find.text('Artist +2'), findsOneWidget);
  });

  testWidgets('the reverse button follows the direction and calls back', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var reversed = 0;
    await tester.pumpWidget(scaledHost(_bar(onReverse: () => reversed++)));
    KIconButton button() =>
        tester.widget<KIconButton>(byIconButton('Reverse order'));
    expect(button().icon, KIcons.sortAsc);
    await tester.tap(byIconButton('Reverse order'));
    expect(reversed, 1);
    await tester.pumpWidget(scaledHost(_bar(ascending: false)));
    expect(button().icon, KIcons.sortDesc);
  });

  testWidgets('the reverse button is announced and is a button', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(scaledHost(_bar()));
    final flags = tester
        .getSemantics(byIconButton('Reverse order'))
        .getSemanticsData();
    expect(flags.label, 'Reverse order');
    expect(flags.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('no onReverse: no reverse button', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_bar(withReverse: false)));
    expect(byIconButton('Reverse order'), findsNothing);
    expect(byIconButton('Filter'), findsOneWidget);
  });

  testWidgets('40 tall on mobile and on desktop, the chip 32', (tester) async {
    for (final size in [const Size(400, 800), const Size(1300, 800)]) {
      useWindow(tester, size);
      await tester.pumpWidget(scaledHost(_bar()));
      expect(
        tester.getSize(find.byType(KListSortFilterBar)).height,
        KListSortFilterBar.height,
      );
      expect(KListSortFilterBar.height, 40);
      final chip = find.ancestor(
        of: find.text('Title'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(chip).height, KListSortFilterBar.chipHeight);
    }
  });

  testWidgets('the chip hands over an attached anchor; filter toggles', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    GlobalKey? anchor;
    var toggles = 0;
    await tester.pumpWidget(
      scaledHost(_bar(onSort: (k) => anchor = k, onFilter: () => toggles++)),
    );
    await tester.tap(find.text('Title'));
    expect(anchor?.currentContext, isNotNull);
    await tester.tap(byIconButton('Filter'));
    expect(toggles, 1);
  });

  testWidgets('the open filter button is selected', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_bar(filterOpen: true)));
    final button = tester.widget<IconButton>(find.byType(IconButton));
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
        await tester.pumpWidget(scaledHost(_bar()));
        final closed = tester.getSize(byIconButton('Filter'));
        await tester.pumpWidget(scaledHost(_bar(filterOpen: true)));
        final open = tester.getSize(find.byType(IconButton));
        expect(closed, const Size.square(KListSortFilterBar.buttonSize));
        expect(open, closed);
        expect(byIconButton('Filter'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('order: leading, view, chip, reverse, filter', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_bar(view: _viewButton())));
    final xs = [
      tester.getCenter(find.text('36 songs')).dx,
      tester.getCenter(byIconButton('View')).dx,
      tester.getCenter(find.text('Title')).dx,
      tester.getCenter(byIconButton('Reverse order')).dx,
      tester.getCenter(byIconButton('Filter')).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));
    expect(xs.toSet().length, xs.length);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the reverse button sits right after the chip, filter last', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(scaledHost(_bar()));
    final chip = tester.getRect(
      find.ancestor(of: find.text('Title'), matching: find.byType(InkWell)),
    );
    final reverse = tester.getRect(byIconButton('Reverse order'));
    final filter = tester.getRect(byIconButton('Filter'));
    expect(reverse.left, closeTo(chip.right, 0.5));
    expect(filter.left, closeTo(reverse.right, 0.5));
  });

  testWidgets('keyboard focus stays on the filter button when it toggles', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var open = false;
    var toggles = 0;
    await tester.pumpWidget(
      scaledHost(
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
    final button = tester.widget<KIconButton>(byIconButton('Filter'));
    button.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    expect(open, isTrue);
    expect(byIconButton('Filter'), findsNothing, reason: 'tonal now');
    final tonal = tester.widget<IconButton>(find.byType(IconButton));
    expect(tonal.focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    expect(open, isFalse);
    expect(toggles, 2);
    final light = tester.widget<KIconButton>(byIconButton('Filter'));
    expect(light.focusNode!.hasFocus, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('the sort chip is announced with its criterion', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(scaledHost(_bar()));
    expect(find.bySemanticsLabel('Sort: Title'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a screen reader can tap the sort chip', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    GlobalKey? anchor;
    await tester.pumpWidget(scaledHost(_bar(onSort: (k) => anchor = k)));
    tester.semantics.tap(find.semantics.byLabel('Sort: Title'));
    expect(anchor?.currentContext, isNotNull);
    handle.dispose();
  });
}
