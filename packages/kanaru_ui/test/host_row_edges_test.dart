import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/collections/k_menu_row.dart';
import 'package:kanaru_ui/src/widgets/multi_selection_body.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

/// Which [KRowEdges] the open host gave its rows.
KRowEdges _edges(WidgetTester tester) =>
    tester.widget<KRowEdgesScope>(find.byType(KRowEdgesScope).last).edges;

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Widget _picker({GlobalKey? anchor}) => Builder(
  builder: (context) => TextButton(
    key: anchor,
    onPressed: () => showSelectionPicker<int>(
      context,
      options: const [SelectionOption<int>(value: 1, title: Text('One'))],
      selected: 1,
      title: const Text('Pick'),
      anchor: anchor,
    ),
    child: const Text('open'),
  ),
);

Widget _sort(GlobalKey anchor) => Builder(
  builder: (context) => TextButton(
    key: anchor,
    onPressed: () => showKSortPopover<String>(
      context,
      anchor: anchor,
      criteria: const [
        KSortCriterion(value: 'a', label: 'Alpha', icon: KIcons.songs),
      ],
      selected: 'a',
    ),
    child: const Text('open'),
  ),
);

Widget _menu() => Builder(
  builder: (context) => TextButton(
    onPressed: () => showKLayeredMenu(
      context,
      root: KMenuPage(
        groups: [
          [KMenuRow(title: 'Play', icon: KIcons.play, onTap: () {})],
        ],
      ),
    ),
    child: const Text('open'),
  ),
);

void main() {
  group('selection picker host', () {
    testWidgets('mobile sheet is full-bleed', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_picker()));
      await _open(tester);
      expect(_edges(tester), KRowEdges.fullBleed);
    });

    testWidgets('desktop dialog is inset', (tester) async {
      useWindow(tester, const Size(1300, 900));
      await tester.pumpWidget(host(_picker()));
      await _open(tester);
      expect(_edges(tester), KRowEdges.inset);
    });

    testWidgets('desktop anchored panel is inset', (tester) async {
      useWindow(tester, const Size(1300, 900));
      final anchor = GlobalKey();
      await tester.pumpWidget(host(_picker(anchor: anchor)));
      await _open(tester);
      expect(_edges(tester), KRowEdges.inset);
    });
  });

  for (final (shell, size) in [
    ('mobile', const Size(400, 800)),
    ('desktop', const Size(1300, 900)),
  ]) {
    testWidgets('sort popover is inset on $shell', (tester) async {
      useWindow(tester, size);
      await tester.pumpWidget(host(_sort(GlobalKey())));
      await _open(tester);
      expect(_edges(tester), KRowEdges.inset);
    });
  }

  testWidgets('layered menu: full-bleed sheet on mobile', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_menu()));
    await _open(tester);
    expect(_edges(tester), KRowEdges.fullBleed);
  });

  testWidgets('layered menu: inset dialog on desktop', (tester) async {
    useWindow(tester, const Size(1300, 900));
    await tester.pumpWidget(host(_menu()));
    await _open(tester);
    expect(_edges(tester), KRowEdges.inset);
  });

  group('host form', () {
    for (final (edges, sheet) in [
      (KRowEdges.fullBleed, true),
      (KRowEdges.inset, false),
    ]) {
      testWidgets('$edges: sheet = $sheet whatever the shell width', (
        tester,
      ) async {
        // A wide shell with a sheet host and a narrow one with a dialog host.
        useWindow(tester, sheet ? const Size(1300, 900) : const Size(400, 800));
        bool? seen;
        await tester.pumpWidget(
          host(
            KRowEdgesScope(
              edges: edges,
              child: Builder(
                builder: (context) {
                  seen = kHostIsSheet(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        expect(seen, sheet);
      });
    }

    testWidgets('without a host the shell decides', (tester) async {
      useWindow(tester, const Size(400, 800));
      bool? seen;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              seen = kHostIsSheet(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, isTrue);
    });
  });

  group('rows follow the host', () {
    for (final edges in KRowEdges.values) {
      testWidgets('KListRow tint under $edges', (tester) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(
          host(
            KRowEdgesScope(
              edges: edges,
              child: const KListRow(title: Text('Row'), selected: true),
            ),
          ),
        );
        final rect = tester.getRect(
          find.descendant(
            of: find.byType(KListRow),
            matching: find.byType(Material),
          ),
        );
        if (edges == KRowEdges.fullBleed) {
          expect([rect.left, rect.right], [0, 400]);
        } else {
          expect([rect.left, 400 - rect.right], [KSpace.x2, KSpace.x2]);
        }
      });

      testWidgets('KMenuRow text stays on the 16 dp axis under $edges', (
        tester,
      ) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(
          host(
            KRowEdgesScope(
              edges: edges,
              child: KMenuRowTile(
                row: KMenuRow(title: 'Play', onTap: () {}),
                onActivate: (_) {},
              ),
            ),
          ),
        );
        expect(tester.getTopLeft(find.text('Play')).dx, KSpace.x4);
      });
    }
  });

  group('multi picker keeps a caller banner off the edges', () {
    for (final (edges, inset) in [
      (KRowEdges.fullBleed, KSpace.x4),
      (KRowEdges.inset, KSpace.x2),
    ]) {
      testWidgets('$edges', (tester) async {
        useWindow(tester, const Size(400, 800));
        await tester.pumpWidget(
          host(
            KRowEdgesScope(
              edges: edges,
              child: MultiSelectionBody<int>(
                title: const Text('T'),
                options: const [
                  SelectionOption<int>(value: 1, title: Text('One')),
                ],
                initial: const {},
                cancelLabel: 'Cancel',
                confirmLabel: (_) => 'OK',
                banner: const SizedBox(key: Key('banner'), height: 20),
              ),
            ),
          ),
        );
        final rect = tester.getRect(find.byKey(const Key('banner')));
        expect([rect.left, 400 - rect.right], [inset, inset]);
      });
    }
  });
}
