import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _panel({bool expanded = false, double bodyHeight = 200}) => Align(
  alignment: Alignment.bottomCenter,
  child: KSelectionPanel(
    semanticLabel: 'Selection',
    expanded: expanded,
    bodyHeight: bodyHeight,
    header: const SizedBox(height: 56, child: Center(child: Text('3 songs'))),
    body: ListView.builder(
      itemCount: 100,
      itemBuilder: (context, i) => SizedBox(height: 56, child: Text('s$i')),
    ),
  ),
);

Material _frame(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(
        of: find.byType(KSelectionPanel),
        matching: find.byType(Material),
      )
      .first,
);

double _radius(Material m) =>
    ((m.shape! as RoundedRectangleBorder).borderRadius as BorderRadius)
        .topLeft
        .x;

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders collapsed and expanded ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_panel(), brightness: brightness, textScale: scale),
      );
      expect(find.text('3 songs'), findsOneWidget);
      expect(find.text('s0'), findsNothing);
      await tester.pumpWidget(
        host(_panel(expanded: true), brightness: brightness, textScale: scale),
      );
      await tester.pumpAndSettle();
      expect(find.text('s0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mobile: 8 dp side margins like the mini player, radius 20', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_panel()));
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(KSelectionPanel),
                  matching: find.byType(Material),
                )
                .first,
          )
          .width,
      384,
    );
    expect(_radius(_frame(tester)), 20);
  });

  testWidgets('desktop: 440 wide, centred, radius 22, shadow', (tester) async {
    useWindow(tester, const Size(1400, 800));
    await tester.pumpWidget(host(_panel()));
    final rect = tester.getRect(
      find
          .descendant(
            of: find.byType(KSelectionPanel),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(rect.width, 440);
    expect(rect.center.dx, 700);
    expect(_radius(_frame(tester)), 22);
    expect(_frame(tester).elevation, greaterThan(3));
  });

  testWidgets('the body is clamped to 460 and scrolls inside', (tester) async {
    useWindow(tester, const Size(1400, 1000));
    await tester.pumpWidget(host(_panel(expanded: true, bodyHeight: 2000)));
    await tester.pumpAndSettle();
    final body = tester.getSize(find.byType(ListView));
    expect(body.height, 460);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('s0'), findsNothing);
  });

  testWidgets('a short body is not stretched', (tester) async {
    useWindow(tester, const Size(1400, 1000));
    await tester.pumpWidget(host(_panel(expanded: true, bodyHeight: 112)));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(ListView)).height, 112);
  });

  testWidgets('empty space beside the desktop panel passes taps through', (
    tester,
  ) async {
    useWindow(tester, const Size(1400, 800));
    var page = 0;
    await tester.pumpWidget(
      host(
        Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => page++,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: KSelectionPanel(
                header: const SizedBox(height: 56, child: Text('3 songs')),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tapAt(const Offset(100, 780));
    expect(page, 1, reason: 'left of the panel');
    await tester.tapAt(const Offset(700, 400));
    expect(page, 2, reason: 'above the panel');
  });

  testWidgets('the frame is a labelled container', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_panel()));
    expect(find.bySemanticsLabel(RegExp('Selection')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the body never takes more than half of a short window', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 600));
    late BuildContext context;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(KSelectionPanel.bodyHeightFor(context, 1000), 300);
    expect(KSelectionPanel.bodyHeightFor(context, 100), 100);
    expect(
      KSelectionPanel.heightFor(context, expanded: true, bodyHeight: 1000),
      KSelectionPanel.headerHeight + 300,
    );
    expect(
      KSelectionPanel.heightFor(context, expanded: false, bodyHeight: 1000),
      KSelectionPanel.headerHeight,
    );
  });
}
