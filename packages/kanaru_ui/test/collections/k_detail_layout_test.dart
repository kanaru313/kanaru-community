import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _layout({double headerHeight = 200, int rows = 30, Widget? banner}) =>
    KDetailLayout(
      banner: banner,
      header: SizedBox(
        key: const ValueKey('header'),
        height: headerHeight,
        child: const Center(child: Text('header')),
      ),
      slivers: [
        SliverList.builder(
          itemCount: rows,
          itemBuilder: (context, i) => SizedBox(
            height: 48,
            child: Text('row $i', key: ValueKey('row$i')),
          ),
        ),
      ],
    );

bool _hasGradient(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .any(
      (d) =>
          d.decoration is BoxDecoration &&
          (d.decoration as BoxDecoration).gradient != null,
    );

const _banner = SizedBox(
  key: ValueKey('banner'),
  height: 40,
  width: double.infinity,
);

void main() {
  testWidgets(
    'narrow: a tall banner moves the title collapse with the header',
    (tester) async {
      useWindow(tester, const Size(400, 800));
      Finder inHeader() => find.descendant(
        of: find.byType(PageHeader),
        matching: find.text('Blue Hour'),
      );
      await tester.pumpWidget(
        host(
          KDetailTitleHost(
            child: Column(
              children: [
                PageHeader(title: 'Blue Hour', titleInContent: true),
                Expanded(
                  child: KDetailLayout(
                    banner: const SizedBox(height: 300),
                    header: const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: KGridHeading(title: 'Blue Hour'),
                    ),
                    slivers: [
                      SliverList.builder(
                        itemCount: 40,
                        itemBuilder: (_, i) =>
                            SizedBox(height: 48, child: Text('r$i')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The name starts 400 dp down: still in view after 300 dp of scroll.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      expect(inHeader(), findsNothing);
      // Past the name (400 dp + its height): the header takes it over.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      expect(inHeader(), findsOneWidget);
    },
  );

  testWidgets('banner: above the header when narrow, same scroll', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_layout(banner: _banner)));
    final banner = tester.getRect(find.byKey(const ValueKey('banner')));
    final header = tester.getRect(find.byKey(const ValueKey('header')));
    expect(banner.width, 400);
    expect(header.top, banner.bottom);
  });

  testWidgets('banner: spans both columns above them when wide', (
    tester,
  ) async {
    useWindow(tester, const Size(1000, 800));
    await tester.pumpWidget(host(_layout(banner: _banner)));
    final banner = tester.getRect(find.byKey(const ValueKey('banner')));
    expect(banner.width, 1000);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('header'))).dy,
      banner.bottom,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy,
      banner.bottom,
    );
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders narrow and wide ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_layout(), brightness: brightness, textScale: scale),
      );
      expect(find.text('header'), findsOneWidget);
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(
        host(_layout(), brightness: brightness, textScale: scale),
      );
      expect(find.text('header'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('839 wide stacks the header above the list', (tester) async {
    useWindow(tester, const Size(839, 800));
    await tester.pumpWidget(host(_layout()));
    final header = tester.getRect(find.byKey(const ValueKey('header')));
    final row = tester.getRect(find.byKey(const ValueKey('row0')));
    expect(header.width, 839);
    expect(row.top, greaterThanOrEqualTo(header.bottom));
  });

  testWidgets('840 wide puts the header in a 320 column on the left', (
    tester,
  ) async {
    useWindow(tester, const Size(840, 800));
    await tester.pumpWidget(host(_layout()));
    final header = tester.getRect(find.byKey(const ValueKey('header')));
    final row = tester.getRect(find.byKey(const ValueKey('row0')));
    expect(header.width, 320);
    expect(row.left, 320);
    expect(row.top, 0);
  });

  testWidgets('wide: a short header sits at the top of the left column', (
    tester,
  ) async {
    useWindow(tester, const Size(840, 800));
    await tester.pumpWidget(host(_layout()));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('header'))).dy,
      tester.getTopLeft(find.byType(KDetailLayout)).dy,
    );
  });

  testWidgets('the left column stays while the right scrolls', (tester) async {
    useWindow(tester, const Size(1000, 800));
    await tester.pumpWidget(host(_layout()));
    final before = tester.getTopLeft(find.byKey(const ValueKey('header')));
    await tester.drag(
      find.byKey(const ValueKey('row3')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('header'))), before);
    expect(find.byKey(const ValueKey('row0')), findsNothing);
  });

  testWidgets('a short window scrolls the left column on its own', (
    tester,
  ) async {
    useWindow(tester, const Size(1000, 300));
    await tester.pumpWidget(host(_layout(headerHeight: 600)));
    expect(tester.takeException(), isNull);
    await tester.dragFrom(const Offset(100, 100), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('header'))).dy,
      lessThan(0),
    );
    expect(tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy, 0);
  });

  testWidgets('a short window leaves the right column where it is', (
    tester,
  ) async {
    useWindow(tester, const Size(1000, 300));
    await tester.pumpWidget(host(_layout(headerHeight: 600)));
    final before = tester.getTopLeft(find.byKey(const ValueKey('row0')));
    await tester.dragFrom(const Offset(100, 100), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('row0'))), before);
  });

  testWidgets('the layout draws no background of its own', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_layout()));
    expect(_hasGradient(tester), isFalse);
  });

  testWidgets('a page tint behind the layout shows under the header', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        CoverTintBackground(
          palette: const [Color(0xFFFF0000)],
          child: _layout(),
        ),
      ),
    );
    await tester.pump(coverTintTransition);
    expect(_hasGradient(tester), isTrue);
    expect(find.byKey(const ValueKey('header')), findsOneWidget);
  });

  testWidgets('a sticky bar stays pinned and is opaque, without blur', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        CustomScrollView(
          slivers: [
            const KStickyBarSliver(height: 52, child: Text('bar')),
            SliverList.builder(
              itemCount: 40,
              itemBuilder: (context, i) =>
                  SizedBox(height: 48, child: Text('r$i')),
            ),
          ],
        ),
      ),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('bar')).dy, 0);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
