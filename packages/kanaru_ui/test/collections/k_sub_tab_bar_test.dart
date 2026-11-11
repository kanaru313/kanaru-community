import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

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
}
