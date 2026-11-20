import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

KCheckMark _mark(WidgetTester tester) =>
    tester.widget<KCheckMark>(find.byType(KCheckMark));

void main() {
  tintFadeTests();
  actionRowTests();
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

  testWidgets('media row: one mark only, the plain tick, no cover mark', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const SelectionRow.media(
          cover: SizedBox.square(dimension: 56),
          mediaTitle: 'A',
          alikeOptions: true,
          selected: true,
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == 'KMediaCardCoverCheck',
      ),
      findsNothing,
    );
    expect(find.byType(KCheckMark), findsOneWidget);
    expect(byCheckState(KCheckState.on), findsOneWidget);
    expect(
      tester.getSemantics(find.text('A')),
      isSemantics(
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        label: 'A',
      ),
    );
  });

  testWidgets('multi media row: checked, not selected (like text rows)', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    Future<SemanticsNode> node(bool selected) async {
      await tester.pumpWidget(
        host(
          SelectionRow.media(
            cover: const SizedBox.square(dimension: 56),
            mediaTitle: 'A',
            multi: true,
            selected: selected,
            onTap: () {},
          ),
        ),
      );
      return tester.getSemantics(find.text('A'));
    }

    expect(
      await node(true),
      isSemantics(
        label: 'A',
        hasCheckedState: true,
        isChecked: true,
        hasSelectedState: false,
        hasTapAction: true,
        isFocusable: true,
      ),
    );
    expect(
      await node(false),
      isSemantics(
        label: 'A',
        hasCheckedState: true,
        isChecked: false,
        hasSelectedState: false,
        hasTapAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
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

  for (final (edges, label) in [
    (KRowEdges.fullBleed, 'full-bleed'),
    (KRowEdges.inset, 'inset'),
  ]) {
    testWidgets('tint edges under a $label host', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          KRowEdgesScope(
            edges: edges,
            child: const SelectionRow(title: Text('A'), selected: true),
          ),
        ),
      );
      final tint = find.descendant(
        of: find.byType(SelectionRow),
        matching: find.byType(AnimatedContainer),
      );
      final rect = tester.getRect(tint);
      final shape =
          (tester.widget<AnimatedContainer>(tint).decoration!
                      as ShapeDecoration)
                  .shape
              as RoundedRectangleBorder;
      final radius = shape.borderRadius as BorderRadius;
      if (edges == KRowEdges.fullBleed) {
        expect(rect.left, 0);
        expect(rect.right, 400);
        expect(radius, BorderRadius.zero);
      } else {
        expect(rect.left, greaterThanOrEqualTo(KSpace.x2));
        expect(400 - rect.right, greaterThanOrEqualTo(KSpace.x2));
        expect(radius.topLeft.x, greaterThan(0));
      }
    });
  }

  testWidgets('content lines up at 24 dp in both modes', (tester) async {
    useWindow(tester, const Size(400, 800));
    final lefts = <double>[];
    for (final edges in KRowEdges.values) {
      await tester.pumpWidget(
        host(
          KRowEdgesScope(
            edges: edges,
            child: const SelectionRow(
              title: Text('A'),
              selected: false,
              leading: Icon(Icons.add),
            ),
          ),
        ),
      );
      lefts.add(tester.getTopLeft(find.byIcon(Icons.add)).dx);
    }
    expect(lefts, [24, 24]);
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

const _touchSize = Size(400, 800);
const _deskSize = Size(1300, 800);

Widget _action({
  VoidCallback? onTap,
  String? reason,
  bool opensMore = false,
  bool running = false,
  bool autofocus = false,
}) => SelectionRow.action(
  leading: const Icon(KIcons.sleepTimer),
  title: const Text('Hết bài này'),
  subtitle: const Text('còn 2:48'),
  disabledReason: reason,
  opensMore: opensMore,
  running: running,
  autofocus: autofocus,
  onTap: onTap,
);

void actionRowTests() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('action rows lay out without overflow at 320 ($name)', (
      tester,
    ) async {
      useWindow(tester, const Size(320, 700));
      await tester.pumpWidget(
        host(
          Column(
            children: [
              _action(onTap: () {}),
              _action(reason: 'Bài này không có album'),
              _action(onTap: () {}, opensMore: true),
              _action(onTap: () {}, running: true),
            ],
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('action: a button, no mark, no selected or checked state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(host(_action(onTap: () => taps++)));
    expect(find.byType(KCheckMark), findsNothing);
    final node = tester.getSemantics(find.byType(SelectionRow));
    // Strict: every flag not listed (selected, checked, mutually exclusive
    // group, toggled...) must be absent, so a stray selected state fails.
    expect(
      node,
      matchesSemantics(
        label: 'Hết bài này\ncòn 2:48',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    expect(node.flagsCollection.isSelected, Tristate.none);
    expect(node.flagsCollection.isChecked, CheckedState.none);
    expect(node.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
    await tester.tap(find.byType(SelectionRow));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('disabledReason: dimmed, reason replaces the detail, no taps, '
      'not focusable', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(_action(onTap: () => taps++, reason: 'Bài này không có album')),
    );
    expect(find.text('Bài này không có album'), findsOneWidget);
    expect(find.text('còn 2:48'), findsNothing);
    final node = tester.getSemantics(find.byType(SelectionRow));
    expect(
      node,
      matchesSemantics(
        label: 'Hết bài này\nBài này không có album',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    await tester.tap(find.byType(SelectionRow), warnIfMissed: false);
    expect(taps, 0);
    expect(
      tester.widget<InkWell>(find.byType(InkWell)).canRequestFocus,
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('touch: detail under the title, flat standard 56 row', (
    tester,
  ) async {
    useWindow(tester, _touchSize);
    await tester.pumpWidget(host(_action(onTap: () {})));
    final t = tester.getCenter(find.text('Hết bài này'));
    final d = tester.getCenter(find.text('còn 2:48'));
    expect(d.dy, greaterThan(t.dy));
    expect(tester.getSize(find.byType(SelectionRow)).height, 56);
  });

  testWidgets('desktop: dense 40 row, detail on the title line, right', (
    tester,
  ) async {
    useWindow(tester, _deskSize);
    await tester.pumpWidget(host(_action(onTap: () {})));
    final t = tester.getCenter(find.text('Hết bài này'));
    final d = tester.getCenter(find.text('còn 2:48'));
    expect((d.dy - t.dy).abs(), lessThan(4));
    expect(d.dx, greaterThan(t.dx));
    expect(tester.getSize(find.byType(SelectionRow)).height, 40);
  });

  testWidgets('hover / press state layers are 8 % / 10 %', (tester) async {
    await tester.pumpWidget(host(_action(onTap: () {})));
    final scheme = Theme.of(tester.element(find.byType(SelectionRow)))
        .colorScheme;
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(ink.hoverColor, scheme.onSurface.withValues(alpha: 0.08));
    expect(ink.highlightColor, scheme.onSurface.withValues(alpha: 0.10));
    // Keyboard focus is the ring, not a tint.
    expect(ink.focusColor, const Color(0x00000000));
  });

  for (final (name, running, opensMore) in [
    ('plain', false, false),
    ('opensMore', false, true),
    ('running', true, false),
  ]) {
    testWidgets('keyboard focus rings the 36 dp shape ($name)', (tester) async {
      useKeyboardHighlight();
      useWindow(tester, _deskSize);
      await tester.pumpWidget(
        host(
          _action(
            onTap: () {},
            running: running,
            opensMore: opensMore,
            autofocus: true,
          ),
        ),
      );
      await tester.pump();
      final rings = tester
          .widgetList<KFocusRing>(find.byType(KFocusRing))
          .where((r) => r.visible);
      expect(rings, hasLength(1));
      final ring = tester.getRect(find.byType(KFocusRing).first);
      final row = tester.getRect(find.byType(SelectionRow));
      // 40 dp hit area, 36 dp visible shape centred: 2 dp band each side.
      expect(ring.height, 36 + (running ? 8 : 0));
      expect(ring.top - row.top, 2);
    });
  }

  testWidgets('no focus ring without keyboard focus', (tester) async {
    await tester.pumpWidget(host(_action(onTap: () {})));
    expect(
      tester
          .widgetList<KFocusRing>(find.byType(KFocusRing))
          .any((r) => r.visible),
      isFalse,
    );
  });

  testWidgets('semantics: focusable, focused only while it has focus', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(_action(onTap: () {})));
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(SelectionRow)),
      isSemantics(isButton: true, isFocusable: true, isFocused: false),
    );
    await tester.pumpWidget(
      host(
        KeyedSubtree(
          key: UniqueKey(),
          child: _action(onTap: () {}, autofocus: true),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(SelectionRow)),
      isSemantics(isButton: true, isFocusable: true, isFocused: true),
    );
    semantics.dispose();
  });

  testWidgets('action rows are built only by SelectionRow.action', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            SelectionRow(selected: true, title: Text('a')),
            SelectionRow.action(title: Text('b')),
          ],
        ),
      ),
    );
    final rows = tester.widgetList<SelectionRow>(find.byType(SelectionRow));
    expect(rows.map((r) => r.action), [false, true]);
    expect(rows.last.selected, isFalse);
    expect(rows.last.multi, isFalse);
    expect(rows.first.disabledReason, isNull);
  });

  testWidgets('autofocus takes focus; Enter activates', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(_action(onTap: () => taps++, autofocus: true)),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('running: primaryContainer card with a trailing chevron; '
      'keyboard focus draws the ring', (tester) async {
    useKeyboardHighlight();
    await tester.pumpWidget(
      host(_action(onTap: () {}, running: true, autofocus: true)),
    );
    await tester.pump();
    final scheme = Theme.of(tester.element(find.byType(SelectionRow)))
        .colorScheme;
    final fill = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((b) => b.decoration)
        .whereType<ShapeDecoration>()
        .map((d) => d.color);
    expect(fill, contains(scheme.primaryContainer));
    expect(find.byIcon(KIcons.chevronRight), findsOneWidget);
    expect(
      tester
          .widgetList<KFocusRing>(find.byType(KFocusRing))
          .any((r) => r.visible),
      isTrue,
    );
  });

  testWidgets('opensMore on touch: no outline, no fill, primary bold title', (
    tester,
  ) async {
    useWindow(tester, _touchSize);
    await tester.pumpWidget(host(_action(onTap: () {}, opensMore: true)));
    final scheme = Theme.of(tester.element(find.byType(SelectionRow)))
        .colorScheme;
    final shapes = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((b) => b.decoration)
        .whereType<ShapeDecoration>();
    expect(
      shapes.every(
        (d) =>
            d.color == null &&
            (d.shape is! RoundedRectangleBorder ||
                (d.shape as RoundedRectangleBorder).side == BorderSide.none),
      ),
      isTrue,
    );
    final style = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Hết bài này'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(style.style.color, scheme.primary);
    expect(style.style.fontWeight, FontWeight.w700);
  });

  testWidgets('touch row in a sheet: flat, spans the sheet, no gap', (
    tester,
  ) async {
    useWindow(tester, _touchSize);
    var taps = 0;
    await tester.pumpWidget(
      host(
        KRowEdgesScope(
          edges: KRowEdges.fullBleed,
          child: Column(
            children: [
              _action(onTap: () => taps++),
              _action(onTap: () {}),
            ],
          ),
        ),
      ),
    );
    final rows = find.byType(SelectionRow);
    final first = tester.getRect(rows.first);
    final ink = tester.getRect(find.byType(InkWell).first);
    expect(ink.left, 0);
    expect(ink.right, _touchSize.width);
    expect(first.height, 56);
    // No gap between rows.
    expect(tester.getRect(rows.last).top, first.bottom);
    await tester.tapAt(Offset(4, first.center.dy));
    expect(taps, 1);
    // Title keeps the 16 dp axis.
    expect(tester.getTopLeft(find.byIcon(KIcons.sleepTimer).first).dx, 16);
    // Square tint.
  });

  testWidgets('running card keeps a 56 tonal card, radius 12', (tester) async {
    useWindow(tester, _touchSize);
    await tester.pumpWidget(host(_action(onTap: () {}, running: true)));
    final scheme = Theme.of(tester.element(find.byType(SelectionRow)))
        .colorScheme;
    expect(tester.getSize(find.byType(SelectionRow)).height, 56);
    final card = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((b) => b.decoration)
        .whereType<ShapeDecoration>()
        .firstWhere((d) => d.color == scheme.primaryContainer);
    expect((card.shape as RoundedRectangleBorder).borderRadius, KRadius.sm);
  });

  testWidgets('reduced motion: action row builds and taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(_action(onTap: () => taps++), reduceMotion: true),
    );
    await tester.tap(find.byType(SelectionRow));
    expect(taps, 1);
  });
}
