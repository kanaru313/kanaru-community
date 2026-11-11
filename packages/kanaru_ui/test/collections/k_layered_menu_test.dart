import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

KMenuPage _page({List<String>? log, int filler = 0, bool footer = true}) {
  void note(String s) => log?.add(s);
  return KMenuPage(
    header: const Text('Header'),
    groups: [
      [
        KMenuRow(title: 'Play', icon: KIcons.play, onTap: () => note('play')),
        KMenuRow(
          title: 'Shuffle',
          icon: KIcons.shuffle,
          onTap: () => note('shuffle'),
        ),
      ],
      const [],
      [
        KMenuRow(
          title: 'Soon',
          icon: KIcons.playlistAdd,
          soonLabel: 'Coming soon',
          onTap: () => note('soon'),
        ),
        KMenuRow(
          title: 'Gone',
          subtitle: 'No album',
          enabled: false,
          onTap: () => note('gone'),
        ),
        KMenuRow(
          title: 'Ask',
          proLabel: 'PRO',
          icon: KIcons.ai,
          onTap: () => note('ask'),
        ),
        KMenuRow(
          title: 'Remove',
          danger: true,
          icon: KIcons.delete,
          onTap: () => note('remove'),
        ),
        KMenuRow(
          title: 'Artists',
          subtitle: '2 artists',
          chipsExpanded: true,
          chips: [
            KMenuChip(label: 'Ann', onTap: () => note('ann')),
            KMenuChip(label: 'Bob', onTap: () => note('bob')),
          ],
        ),
        KMenuRow(
          title: 'Folder',
          trailing: KMenuTrailing(
            icon: KIcons.openInNew,
            tooltip: 'Open in file manager',
            onPressed: () => note('reveal'),
          ),
        ),
        KMenuRow(
          title: 'Advanced',
          icon: KIcons.advanced,
          opens: KMenuPage(
            title: 'Advanced page',
            groups: [
              [KMenuRow(title: 'Deep', onTap: () => note('deep'))],
            ],
          ),
        ),
        for (var i = 0; i < filler; i++) KMenuRow(title: 'Filler $i'),
      ],
    ],
    footer: footer
        ? [
            KMenuButton(
              label: 'Play next',
              icon: KIcons.playlistPlay,
              onPressed: () => note('next'),
            ),
            KMenuButton(
              label: 'Add to queue',
              icon: KIcons.queueMusic,
              onPressed: () => note('queue'),
            ),
          ]
        : const [],
  );
}

Widget _opener(KMenuPage page, {bool viaKeyboard = false}) => Builder(
  builder: (context) => Align(
    alignment: Alignment.topLeft,
    child: TextButton(
      onPressed: () => showKLayeredMenu(
        context,
        root: page,
        backTooltip: 'Back',
        viaKeyboard: viaKeyboard,
      ),
      child: const Text('open'),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    for (final (shell, size) in [
      ('mobile', const Size(400, 800)),
      ('desktop', const Size(1300, 900)),
    ]) {
      testWidgets('renders on $shell ($name)', (tester) async {
        useWindow(tester, size);
        await tester.pumpWidget(
          host(_opener(_page()), brightness: brightness, textScale: scale),
        );
        await _open(tester);
        for (final t in [
          'Header',
          'Play',
          'Soon',
          'Coming soon',
          'PRO',
          'Ann',
        ]) {
          expect(find.text(t), findsOneWidget, reason: t);
        }
        expect(find.text('Play next'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('mobile is a bottom sheet of at most 85 % height', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener(_page(filler: 40))));
    await _open(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(
      tester.getSize(find.byType(BottomSheet)).height,
      lessThanOrEqualTo(680),
    );
    expect(
      find.text('Play next'),
      findsOneWidget,
      reason: 'footer stays pinned',
    );
  });

  testWidgets('desktop is a 400 wide dialog of at most 640 on a 45 % barrier', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 900));
    await tester.pumpWidget(host(_opener(_page(filler: 40))));
    await _open(tester);
    final surface = find
        .descendant(of: find.byType(Dialog), matching: find.byType(Material))
        .first;
    final size = tester.getSize(surface);
    expect(size.width, 400);
    expect(size.height, lessThanOrEqualTo(640));
    expect(find.byType(BottomSheet), findsNothing);
    final barrier = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .map((b) => b.color)
        .whereType<Color>()
        .last;
    expect(barrier.a, closeTo(0.45, 0.01));
    expect(
      tester.getCenter(surface),
      const Offset(650, 450),
      reason: 'centred in the window',
    );
  });

  testWidgets('a chosen row closes the menu, then runs', (tester) async {
    useWindow(tester, const Size(1300, 900));
    final log = <String>[];
    bool? menuStillRoutedWhenRan;
    final page = KMenuPage(
      groups: [
        [
          KMenuRow(
            title: 'Play',
            onTap: () {
              log.add('play');
              menuStillRoutedWhenRan = Navigator.of(
                tester.element(find.text('open')),
                rootNavigator: true,
              ).canPop();
            },
          ),
        ],
      ],
    );
    await tester.pumpWidget(host(_opener(page)));
    await _open(tester);
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(log, ['play']);
    expect(menuStillRoutedWhenRan, isFalse);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('footer buttons, chips and trailing buttons close and run', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 900));
    final log = <String>[];
    await tester.pumpWidget(host(_opener(_page(log: log))));
    for (final (tap, expected) in [
      (find.text('Play next'), 'next'),
      (find.text('Add to queue'), 'queue'),
      (find.text('Bob'), 'bob'),
      (find.byIcon(KIcons.openInNew), 'reveal'),
    ]) {
      await _open(tester);
      await tester.tap(tap);
      await tester.pumpAndSettle();
      expect(log.last, expected);
      expect(find.byType(Dialog), findsNothing);
    }
  });

  testWidgets('dimmed and disabled rows are inert', (tester) async {
    useWindow(tester, const Size(1300, 900));
    final log = <String>[];
    await tester.pumpWidget(host(_opener(_page(log: log))));
    await _open(tester);
    await tester.tap(find.text('Soon'));
    await tester.tap(find.text('Gone'));
    await tester.pumpAndSettle();
    expect(log, isEmpty);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('No album'), findsOneWidget);
  });

  testWidgets('a row with chips folds and unfolds them', (tester) async {
    useWindow(tester, const Size(1300, 900));
    await tester.pumpWidget(host(_opener(_page())));
    await _open(tester);
    expect(find.text('Ann'), findsOneWidget);
    await tester.tap(find.text('Artists'));
    await tester.pumpAndSettle();
    expect(find.text('Ann'), findsNothing);
    await tester.tap(find.text('Artists'));
    await tester.pumpAndSettle();
    expect(find.text('Ann'), findsOneWidget);
  });

  testWidgets('the danger row uses the error colour', (tester) async {
    useWindow(tester, const Size(1300, 900));
    await tester.pumpWidget(host(_opener(_page())));
    await _open(tester);
    final scheme = buildKanaruTheme(brightness: Brightness.light).colorScheme;
    expect(tester.widget<Text>(find.text('Remove')).style!.color, scheme.error);
  });

  testWidgets('a sub-page replaces the content; the arrow goes back', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 900));
    final log = <String>[];
    await tester.pumpWidget(host(_opener(_page(log: log))));
    await _open(tester);
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(find.text('Advanced page'), findsOneWidget);
    expect(find.text('Header'), findsNothing);
    await tester.tap(find.byIcon(KIcons.back));
    await tester.pumpAndSettle();
    expect(find.text('Header'), findsOneWidget);
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deep'));
    await tester.pumpAndSettle();
    expect(log, ['deep']);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Esc on a sub-page goes back, on the root closes', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 900));
    await tester.pumpWidget(host(_opener(_page())));
    await _open(tester);
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Header'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('system Back on a sub-page goes back first (sheet)', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener(_page())));
    await _open(tester);
    await tester.ensureVisible(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Header'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('opened from the keyboard: first row focused; arrows move', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 900));
    final log = <String>[];
    await tester.pumpWidget(host(_opener(_page(log: log), viaKeyboard: true)));
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(log, ['play']);

    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(log, ['play', 'shuffle']);
  });

  testWidgets('opens on the root navigator, not the nested one', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final rootKey = GlobalKey<NavigatorState>();
    final nestedKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootKey,
        theme: buildKanaruTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Navigator(
            key: nestedKey,
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => _opener(_page())),
          ),
        ),
      ),
    );
    await _open(tester);
    expect(find.text('Header'), findsOneWidget);
    expect(rootKey.currentState!.canPop(), isTrue, reason: 'menu is on root');
    expect(nestedKey.currentState!.canPop(), isFalse);
  });

  testWidgets('a group has its heading; an empty group loses it', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        _opener(
          KMenuPage(
            groups: [
              [KMenuRow(title: 'Mine')],
              const [],
              [KMenuRow(title: 'Guest')],
            ],
            groupTitles: const ['Albums', 'Hidden', 'Appears on'],
          ),
        ),
      ),
    );
    await _open(tester);
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Appears on'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);
  });

  testWidgets('the header opens its page and Back returns', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        _opener(
          KMenuPage(
            header: const Text('Song'),
            headerOpens: KMenuPage(
              title: 'Song info',
              groups: [
                [KMenuRow(title: 'Format', subtitle: 'FLAC')],
              ],
            ),
            groups: [
              [KMenuRow(title: 'Play')],
            ],
          ),
        ),
      ),
    );
    await _open(tester);
    expect(find.byIcon(KIcons.chevronRight), findsOneWidget);
    await tester.tap(find.text('Song'));
    await tester.pumpAndSettle();
    expect(find.text('Song info'), findsOneWidget);
    expect(find.text('Format'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('a row can show a picture in place of its icon', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        _opener(
          KMenuPage(
            groups: [
              [
                KMenuRow(
                  title: 'Blue',
                  icon: KIcons.album,
                  leading: const SizedBox.square(
                    key: ValueKey('cover'),
                    dimension: 40,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    await _open(tester);
    expect(find.byKey(const ValueKey('cover')), findsOneWidget);
    expect(find.byIcon(KIcons.album), findsNothing);
  });

  testWidgets('opened with a pointer: no row focused until an arrow key', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 900));
    final log = <String>[];
    await tester.pumpWidget(host(_opener(_page(log: log))));
    await _open(tester);
    bool rowFocused() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<InkWell>() !=
        null;

    expect(rowFocused(), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(rowFocused(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(log, ['play']);
  });

  for (final (shell, size) in [
    ('mobile', const Size(400, 800)),
    ('desktop', const Size(1300, 900)),
  ]) {
    testWidgets('a sub-page of 500 rows builds only the visible ones '
        '($shell)', (tester) async {
      useWindow(tester, size);
      final page = KMenuPage(
        title: 'Big',
        groups: [
          [for (var i = 0; i < 500; i++) KMenuRow(title: 'Row $i')],
        ],
      );
      final root = KMenuPage(
        groups: [
          [KMenuRow(title: 'Many', opens: page)],
        ],
      );
      await tester.pumpWidget(host(_opener(root)));
      await _open(tester);
      await tester.tap(find.text('Many'));
      await tester.pumpAndSettle();
      expect(find.text('Row 0'), findsOneWidget);
      expect(find.byType(InkWell).evaluate().length, lessThan(40));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Back restores the scroll position of the parent page', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final root = KMenuPage(
      groups: [
        [
          for (var i = 0; i < 60; i++)
            KMenuRow(
              title: 'Row $i',
              opens: i == 30
                  ? KMenuPage(
                      title: 'Sub',
                      groups: [
                        [KMenuRow(title: 'Deep')],
                      ],
                    )
                  : null,
            ),
        ],
      ],
    );
    await tester.pumpWidget(host(_opener(root)));
    await _open(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    final before = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(before, greaterThan(500));
    await tester.tap(find.text('Row 30'));
    await tester.pumpAndSettle();
    expect(find.text('Deep'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final after = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(after, before);
  });

  testWidgets('keyboard: Enter on a row with a sub-page focuses the sub-page', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 900));
    final root = KMenuPage(
      groups: [
        [
          KMenuRow(
            title: 'Open',
            opens: KMenuPage(
              title: 'Sub',
              groups: [
                [KMenuRow(title: 'Deep'), KMenuRow(title: 'Deeper')],
              ],
            ),
          ),
        ],
      ],
    );
    await tester.pumpWidget(host(_opener(root, viaKeyboard: true)));
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Deep'), findsOneWidget);
    final focused = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<InkWell>();
    expect(
      focused,
      tester.widget<InkWell>(find.widgetWithText(InkWell, 'Deep')),
    );
    // And Back (Esc) lands on the row that opened the page.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<InkWell>(),
      tester.widget<InkWell>(find.widgetWithText(InkWell, 'Open')),
    );
  });

  testWidgets('keyboard Back onto a scrolled long page focuses the row that '
      'opened the sub-page', (tester) async {
    useWindow(tester, const Size(400, 800));
    final root = KMenuPage(
      groups: [
        [
          for (var i = 0; i < 60; i++)
            KMenuRow(
              title: 'Row $i',
              opens: i == 30
                  ? KMenuPage(
                      title: 'Sub',
                      groups: [
                        [KMenuRow(title: 'Deep')],
                      ],
                    )
                  : null,
            ),
        ],
      ],
    );
    await tester.pumpWidget(host(_opener(root, viaKeyboard: true)));
    await _open(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Row 30'));
    await tester.pumpAndSettle();
    expect(find.text('Deep'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<InkWell>(),
      tester.widget<InkWell>(find.widgetWithText(InkWell, 'Row 30')),
    );
  });

  testWidgets('pointer open: Tab then ArrowDown moves from the focused row', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 900));
    await tester.pumpWidget(host(_opener(_page())));
    await _open(tester);
    InkWell focusedRow() => FocusManager.instance.primaryFocus!.context!
        .findAncestorWidgetOfExactType<InkWell>()!;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final first = focusedRow();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    final second = focusedRow();
    expect(identical(first, second), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(focusedRow(), first);
  });

  testWidgets('pointer open: ArrowUp with nothing focused lands on a row', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 900));
    await tester.pumpWidget(host(_opener(_page())));
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<InkWell>(),
      isNotNull,
    );
  });
}
