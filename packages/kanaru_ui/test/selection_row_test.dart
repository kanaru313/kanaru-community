import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

KCheckMark _mark(WidgetTester tester) =>
    tester.widget<KCheckMark>(find.byType(KCheckMark));

void main() {
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
}
