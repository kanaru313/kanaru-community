import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

KCheckMark _mark(WidgetTester tester) =>
    tester.widget<KCheckMark>(find.byType(KCheckMark));

void main() {
  tintFadeTests();
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('text rows: mark at the start, ring when off ($name)', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              SelectionRow(title: Text('A'), selected: true),
              SelectionRow(
                title: Text('A much longer title that wraps'),
                subtitle: Text('sub'),
                selected: false,
              ),
            ],
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(byCheckState(KCheckState.on), findsOneWidget);
      expect(byCheckState(KCheckState.off), findsOneWidget);
    });
  }

  testWidgets('hover / press state layers are 8 % / 10 % of onSurface', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(SelectionRow(title: const Text('A'), selected: false, onTap: () {})),
    );
    final scheme = Theme.of(tester.element(find.byType(SelectionRow)))
        .colorScheme;
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(ink.hoverColor, scheme.onSurface.withValues(alpha: 0.08));
    expect(ink.highlightColor, scheme.onSurface.withValues(alpha: 0.10));
  });

  testWidgets('text row: mark sits left of the title, nothing on the right', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(const SelectionRow(title: Text('One'), selected: true)),
    );
    final mark = tester.getRect(find.byType(KCheckMark));
    final title = tester.getRect(find.text('One'));
    expect(mark.right, lessThanOrEqualTo(title.left));
    expect(title.left - mark.right, 12);
    expect(_mark(tester).style, KCheckMarkStyle.surface);
  });

  testWidgets('titles line up and rows meet touch height', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            SelectionRow(title: Text('One'), selected: true),
            SelectionRow(title: Text('Two'), selected: false),
          ],
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('One')).dx,
      tester.getTopLeft(find.text('Two')).dx,
    );
    expect(
      tester.getSize(find.byType(SelectionRow).first).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('icon row, single choice: no mark at all', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            SelectionRow(
              leading: Icon(KIcons.folders),
              title: Text('A'),
              selected: true,
            ),
            SelectionRow(
              leading: Icon(KIcons.folders),
              title: Text('B'),
              selected: false,
            ),
          ],
        ),
      ),
    );
    expect(find.byType(KCheckMark), findsNothing);
    // Same title position whether chosen or not.
    expect(
      tester.getTopLeft(find.text('A')).dx,
      tester.getTopLeft(find.text('B')).dx,
    );
  });

  testWidgets('icon row, multi: plain tick on the right of the title', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const SelectionRow(
          leading: Icon(KIcons.folders),
          title: Text('A'),
          multi: true,
          selected: true,
        ),
      ),
    );
    expect(_mark(tester).style, KCheckMarkStyle.plain);
    expect(_mark(tester).state, KCheckState.on);
    expect(
      tester.getRect(find.byType(KCheckMark)).left,
      greaterThanOrEqualTo(tester.getRect(find.text('A')).right),
    );
  });

  testWidgets('alikeOptions icon row: tick on the chosen row, same slot', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            SelectionRow(
              leading: Icon(KIcons.image),
              title: Text('A'),
              alikeOptions: true,
              selected: true,
            ),
            SelectionRow(
              leading: Icon(KIcons.image),
              title: Text('B'),
              alikeOptions: true,
              selected: false,
            ),
          ],
        ),
      ),
    );
    final marks = tester.widgetList<KCheckMark>(find.byType(KCheckMark));
    expect(marks.map((m) => m.style), everyElement(KCheckMarkStyle.plain));
    expect(byCheckState(KCheckState.on), findsOneWidget);
    expect(byCheckState(KCheckState.off), findsOneWidget);
    expect(
      tester.getRect(find.byType(KCheckMark).first).left,
      greaterThanOrEqualTo(tester.getRect(find.text('A')).right),
    );
    expect(
      tester.getTopLeft(find.text('A')).dx,
      tester.getTopLeft(find.text('B')).dx,
    );
    expect(
      tester.getSize(find.byType(KCheckMark).first),
      tester.getSize(find.byType(KCheckMark).last),
    );
    expect(
      tester.getSemantics(find.text('A')),
      isSemantics(
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        label: 'A',
      ),
    );
    expect(
      tester.getSemantics(find.text('B')),
      isSemantics(
        isSelected: false,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        label: 'B',
      ),
    );
  });

  testWidgets('alikeOptions on a text row behaves as before', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const SelectionRow(
          title: Text('One'),
          alikeOptions: true,
          selected: true,
        ),
      ),
    );
    expect(_mark(tester).style, KCheckMarkStyle.surface);
    expect(
      tester.getRect(find.byType(KCheckMark)).right,
      lessThanOrEqualTo(tester.getRect(find.text('One')).left),
    );
  });

  testWidgets('alikeOptions with multi keeps checkbox semantics', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const SelectionRow(
          leading: Icon(KIcons.image),
          title: Text('A'),
          alikeOptions: true,
          multi: true,
          selected: true,
        ),
      ),
    );
    expect(_mark(tester).style, KCheckMarkStyle.plain);
    expect(byCheckState(KCheckState.on), findsOneWidget);
  });

  testWidgets('plainMark without icon: tick right, nothing at the start', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const SelectionRow(
          title: Text('All'),
          multi: true,
          partial: true,
          selected: true,
          plainMark: true,
        ),
      ),
    );
    expect(_mark(tester).state, KCheckState.partial);
    expect(_mark(tester).style, KCheckMarkStyle.plain);
    expect(
      tester.getRect(find.byType(KCheckMark)).left,
      greaterThan(tester.getRect(find.text('All')).left),
    );
  });

  testWidgets('disabled row ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        SelectionRow(
          title: const Text('X'),
          selected: false,
          enabled: false,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('X'));
    expect(taps, 0);
  });

  testWidgets('single choice: selected + mutually exclusive semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const SelectionRow(title: Text('S'), selected: true)),
    );
    expect(
      tester.getSemantics(find.byType(SelectionRow)),
      isSemantics(
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('multi: checked, mixed when partial, not exclusive', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    Future<SemanticsNode> node(bool selected, bool partial) async {
      await tester.pumpWidget(
        host(
          SelectionRow(
            title: const Text('M'),
            multi: true,
            selected: selected,
            partial: partial,
          ),
        ),
      );
      return tester.getSemantics(find.byType(SelectionRow));
    }

    expect(
      await node(true, false),
      isSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: false,
      ),
    );
    expect(
      await node(false, false),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    expect(
      await node(true, true),
      isSemantics(hasCheckedState: true, isCheckStateMixed: true),
    );
    handle.dispose();
  });

  testWidgets('dense rows: 40 tall on both shells; normal rows unchanged', (
    tester,
  ) async {
    Widget rows() => const Column(
      children: [
        SelectionRow(
          dense: true,
          leading: Icon(KIcons.songs, size: KIconSize.sm),
          title: Text('Dense'),
          selected: false,
        ),
        SelectionRow(
          leading: Icon(KIcons.songs, size: KIconSize.sm),
          title: Text('Normal'),
          selected: false,
        ),
      ],
    );
    Finder rowOf(String text) =>
        find.ancestor(of: find.text(text), matching: find.byType(SelectionRow));
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(rows()));
    expect(tester.getSize(rowOf('Dense')).height, KLayout.dropdownRowHeight);
    expect(tester.getSize(rowOf('Normal')).height, KLayout.minTarget + 8);
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(rows()));
    expect(tester.getSize(rowOf('Dense')).height, KLayout.dropdownRowHeight);
    expect(tester.getSize(rowOf('Normal')).height, KLayout.minTarget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dense row: tint is 36 tall and centred, the band takes taps', (
    tester,
  ) async {
    var taps = 0;
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            child: SelectionRow(
              dense: true,
              leading: const Icon(KIcons.songs, size: KIconSize.sm),
              title: const Text('Dense'),
              selected: true,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    final row = tester.getRect(find.byType(SelectionRow));
    final tint = tester.getRect(
      find.descendant(
        of: find.byType(SelectionRow),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(tint.height, KLayout.dropdownRowVisible);
    expect(tint.center.dy, closeTo(row.center.dy, 0.01));
    await tester.tapAt(Offset(row.center.dx, row.top + 1));
    await tester.tapAt(Offset(row.center.dx, row.bottom - 1));
    expect(taps, 2);
  });

  testWidgets('hover and focus ink is clipped to the 36 dp shape', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            child: SelectionRow(
              dense: true,
              autofocus: true,
              onTap: () {},
              title: const Text('Dense'),
              selected: false,
            ),
          ),
        ),
      ),
    );
    final row = tester.getRect(find.byType(SelectionRow));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(row.center);
    await tester.pumpAndSettle();
    // The Material's ink layer: the render object InkWell paints on.
    final ink =
        Material.of(tester.element(find.byType(InkWell))) as RenderObject;
    // Highlights paint on the 36 dp shape (2 dp in from the 40 dp row); an
    // un-inset shape would paint the whole row.
    bool inside(Path p) {
      final r = p.getBounds();
      return (r.top - (row.top + 2)).abs() < 0.01 &&
          (r.bottom - (row.bottom - 2)).abs() < 0.01;
    }

    // The highlight is clipped to the inset shape, not the 40 dp box.
    expect(
      ink,
      paints..clipPath(pathMatcher: predicate<Path>(inside, '36 dp clip')),
    );
  });

  testWidgets('dense row grows at 200 % text without overflow', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const SelectionRow(
          dense: true,
          title: Text('Dense'),
          subtitle: Text('Sub'),
          selected: false,
        ),
        textScale: 2,
      ),
    );
    expect(
      tester.getSize(find.byType(SelectionRow)).height,
      greaterThan(KLayout.dropdownRowHeight),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hint is the accessible description, not visible text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const SelectionRow(
          title: Text('Favorites'),
          selected: false,
          multi: true,
          hint: 'Songs already in it are skipped.',
        ),
      ),
    );
    expect(find.text('Songs already in it are skipped.'), findsNothing);
    expect(
      tester.getSemantics(find.byType(SelectionRow)),
      isSemantics(
        label: 'Favorites',
        hint: 'Songs already in it are skipped.',
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('without a hint the semantics carry none', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const SelectionRow(title: Text('Plain'), selected: false)),
    );
    expect(tester.getSemantics(find.byType(SelectionRow)).hint, isEmpty);
    handle.dispose();
  });
}

/// Tint colour currently painted behind the row (the ShapeDecoration fill).
Color? _tint(WidgetTester tester) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.descendant(
      of: find.byType(SelectionRow),
      matching: find.byType(DecoratedBox),
    ),
  )) {
    final d = box.decoration;
    if (d is ShapeDecoration) return d.color;
  }
  return null;
}

void _expectSameHue(Color c, Color container) {
  expect(
    (c.r - container.r).abs() +
        (c.g - container.g).abs() +
        (c.b - container.b).abs(),
    lessThan(0.01),
    reason: 'tint must fade alpha only, not drift towards grey / black',
  );
}

void tintFadeTests() {
  for (final selectNext in [false, true]) {
    testWidgets(
      'tint ${selectNext ? 'select' : 'deselect'} keeps the container hue',
      (tester) async {
        useWindow(tester, const Size(400, 800));
        Widget row(bool sel) => host(
          SelectionRow(
            title: const Text('A'),
            leading: const SizedBox(width: 24, height: 24),
            selected: sel,
            alikeOptions: true,
            onTap: () {},
          ),
        );
        await tester.pumpWidget(row(!selectNext));
        final container = Theme.of(tester.element(find.byType(SelectionRow)))
            .colorScheme
            .secondaryContainer;
        await tester.pumpWidget(row(selectNext));
        await tester.pump(KMotion.fast ~/ 2);
        final mid = _tint(tester)!;
        expect(mid.a, greaterThan(0));
        expect(mid.a, lessThan(container.a));
        _expectSameHue(mid, container);
      },
    );
  }
}
