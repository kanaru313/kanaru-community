import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:kanaru_ui/src/widgets/collections/k_icon_tab_row.dart';

import '../support/host.dart';

const _labels = [
  'Songs',
  'Albums',
  'Artists',
  'Genres',
  'Languages',
  'Folders',
  'Playlists',
  'History',
];

Widget _bar({
  int selected = 0,
  double offset = 0,
  ValueChanged<int>? onSelected,
  ValueChanged<double>? onOffset,
}) => Align(
  alignment: Alignment.topCenter,
  child: SizedBox(
    height: 48,
    child: KSubTabBar(
      labels: _labels,
      selectedIndex: selected,
      onSelected: onSelected ?? (_) {},
      initialOffset: offset,
      onOffsetChanged: onOffset,
    ),
  ),
);

double _pixels(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(_bar(), brightness: brightness, textScale: scale),
      );
      await tester.pumpAndSettle();
      expect(find.text('Songs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the selected tab scrolls to the centre', (tester) async {
    useWindow(tester, const Size(360, 800));
    await tester.pumpWidget(host(_bar(selected: 4)));
    await tester.pumpAndSettle();
    final centre = tester.getCenter(find.text('Languages')).dx;
    expect(centre, closeTo(180, 2));
  });

  testWidgets('changing the selection glides to the new tab', (tester) async {
    useWindow(tester, const Size(360, 800));
    await tester.pumpWidget(host(_bar(selected: 0)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(_bar(selected: 3)));
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.text('Genres')).dx, closeTo(180, 2));
  });

  testWidgets('starts at the offset it was given, then reports the glide', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 800));
    final offsets = <double>[];
    await tester.pumpWidget(
      host(_bar(selected: 0, offset: 120, onOffset: offsets.add)),
    );
    expect(_pixels(tester), 120);
    await tester.pumpAndSettle();
    expect(_pixels(tester), 0);
    expect(offsets.last, 0);
  });

  testWidgets('tapping a tab selects it', (tester) async {
    useWindow(tester, const Size(360, 800));
    final picked = <int>[];
    await tester.pumpWidget(host(_bar(onSelected: picked.add)));
    await tester.tap(find.text('Albums'));
    expect(picked, [1]);
  });

  testWidgets('the selected tab is semantically selected', (tester) async {
    useWindow(tester, const Size(360, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_bar(selected: 1)));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Albums')),
      matchesSemantics(
        label: 'Albums',
        isButton: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  group('with icons', () {
    const icons = [
      KIcons.songs,
      KIcons.albums,
      KIcons.artists,
      KIcons.genres,
      KIcons.languages,
      KIcons.folders,
    ];

    Widget iconBar({
      int selected = 0,
      ValueChanged<int>? onSelected,
      bool reduceMotion = false,
    }) => host(
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 48,
          child: KSubTabBar(
            labels: _labels.take(6).toList(),
            icons: icons,
            selectedIndex: selected,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
      reduceMotion: reduceMotion,
    );

    Finder tab(String name) =>
        find.byWidgetPredicate((w) => w is Tooltip && w.message == name);

    double labelOpacity(WidgetTester tester, String name) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text(name),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    // The underline's rect with x measured from the row's start, so the
    // bar scrolling to centre the tab does not count as movement.
    Rect underline(WidgetTester tester) {
      final rect = tester.getRect(
        find
            .descendant(
              of: find.byType(KIconTabRow),
              matching: find.byType(AnimatedPositioned),
            )
            .first,
      );
      return rect.shift(-tester.getTopLeft(find.byType(KIconTabRow)));
    }

    testWidgets('only the selected tab shows its label', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(iconBar(selected: 1));
      await tester.pumpAndSettle();
      expect(labelOpacity(tester, 'Albums'), 1);
      expect(labelOpacity(tester, 'Songs'), 0);
      // Every tab keeps its name for the tooltip and the screen reader.
      for (final name in _labels.take(6)) {
        expect(tab(name), findsOneWidget, reason: name);
      }
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Songs'), findsOneWidget);
      expect(find.bySemanticsLabel('Albums'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a tap on an icon-only tab selects it', (tester) async {
      useWindow(tester, const Size(360, 800));
      final taps = <int>[];
      await tester.pumpWidget(iconBar(onSelected: taps.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(KIcons.artists));
      expect(taps, [2]);
    });

    testWidgets('the underline slides over 250 ms and ends under the tab', (
      tester,
    ) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(iconBar(selected: 0));
      await tester.pumpAndSettle();
      final before = underline(tester);
      await tester.pumpWidget(iconBar(selected: 2));
      await tester.pump(const Duration(milliseconds: 125));
      final mid = underline(tester);
      expect(mid.left, greaterThan(before.left));
      await tester.pumpAndSettle();
      final after = underline(tester);
      expect(after.left, greaterThan(mid.left));
      // Under the icon and label of the selected tab, 3 dp high.
      final origin = tester.getTopLeft(find.byType(KIconTabRow));
      final icon = tester.getRect(find.byIcon(KIcons.artists)).shift(-origin);
      final text = tester.getRect(find.text('Artists')).shift(-origin);
      expect(after.left, closeTo(icon.left, 1));
      expect(after.right, closeTo(text.right, 1));
      expect(after.height, 3);
    });

    testWidgets('reduced motion switches at once', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(iconBar(selected: 0, reduceMotion: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(iconBar(selected: 2, reduceMotion: true));
      await tester.pump();
      expect(labelOpacity(tester, 'Artists'), 1);
      expect(labelOpacity(tester, 'Songs'), 0);
      final icon = tester
          .getRect(find.byIcon(KIcons.artists))
          .shift(-tester.getTopLeft(find.byType(KIconTabRow)));
      expect(underline(tester).left, closeTo(icon.left, 1));
    });

    for (final scale in [1.3, 2.0]) {
      testWidgets('no overflow at text scale $scale', (tester) async {
        useWindow(tester, const Size(360, 800));
        await tester.pumpWidget(
          host(
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 48,
                child: KSubTabBar(
                  labels: _labels.take(6).toList(),
                  icons: icons,
                  selectedIndex: 4,
                  onSelected: (_) {},
                ),
              ),
            ),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
