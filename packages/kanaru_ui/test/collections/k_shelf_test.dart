import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _shelf({VoidCallback? onSeeAll, int count = 5}) => Align(
  alignment: Alignment.topCenter,
  child: KShelf(
    title: 'Albums',
    seeAllLabel: 'See all: Albums',
    onSeeAll: onSeeAll,
    itemCount: count,
    itemWidth: 140,
    height: 180,
    itemBuilder: (context, i) => ColoredBox(
      color: const Color(0xFF999999),
      child: Center(child: Text('item $i')),
    ),
  ),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders title and items ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          _shelf(onSeeAll: () {}),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('item 0'), findsOneWidget);
      expect(find.byIcon(KIcons.chevronRight), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('items have the fixed width and scroll sideways', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_shelf(count: 12)));
    expect(tester.getSize(find.text('item 0').first).width, lessThan(140));
    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: find.text('item 0'),
                  matching: find.byType(SizedBox),
                )
                .first,
          )
          .width,
      140,
    );
    expect(find.text('item 11'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(-3000, 0));
    await tester.pumpAndSettle();
    expect(find.text('item 11'), findsOneWidget);
  });

  testWidgets('the title row opens "see all" and is labelled', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    var opened = 0;
    await tester.pumpWidget(host(_shelf(onSeeAll: () => opened++)));
    expect(find.bySemanticsLabel('See all: Albums'), findsOneWidget);
    await tester.tap(find.text('Albums'));
    expect(opened, 1);
    handle.dispose();
  });

  testWidgets('without onSeeAll there is no chevron', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_shelf()));
    expect(find.byIcon(KIcons.chevronRight), findsNothing);
  });
}
