import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('root page hides the back button', (tester) async {
    await tester.pumpWidget(_host(const PageHeader(title: 'Library')));
    expect(find.byIcon(KIcons.back), findsNothing);
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('child page shows back and calls onBack', (tester) async {
    var backs = 0;
    await tester.pumpWidget(
      _host(PageHeader(title: 'Album', onBack: () => backs++)),
    );
    await tester.tap(find.byIcon(KIcons.back));
    expect(backs, 1);
  });

  testWidgets('root page shows the scope leading and rootTrailing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const PageHeaderScope(
          leading: Icon(Icons.menu),
          trailing: [Icon(Icons.search)],
          rootTrailing: [Icon(Icons.settings)],
          child: PageHeader(title: 'Home'),
        ),
      ),
    );
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    // Order: leading, title, trailing, rootTrailing.
    final xs = [
      Icons.menu,
      Icons.search,
      Icons.settings,
    ].map((i) => tester.getCenter(find.byIcon(i)).dx).toList();
    expect(xs[0] < tester.getCenter(find.text('Home')).dx, isTrue);
    expect(xs[1] < xs[2], isTrue);
  });

  testWidgets('child page hides the scope leading and rootTrailing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PageHeaderScope(
          leading: const Icon(Icons.menu),
          trailing: const [Icon(Icons.search)],
          rootTrailing: const [Icon(Icons.settings)],
          child: PageHeader(title: 'Album', onBack: () {}),
        ),
      ),
    );
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byIcon(Icons.settings), findsNothing);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(KIcons.back), findsOneWidget);
  });

  testWidgets('KEmpty shows message and action', (tester) async {
    await tester.pumpWidget(
      _host(
        KEmpty(
          icon: Icons.music_note,
          message: 'Nothing here',
          action: TextButton(onPressed: () {}, child: const Text('Add')),
        ),
      ),
    );
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  group('titleInContent', () {
    Finder inHeader(String name) =>
        find.descendant(of: find.byType(PageHeader), matching: find.text(name));

    Widget page({bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: KDetailTitleHost(
            child: Column(
              children: [
                PageHeader(
                  title: 'Album',
                  onBack: () {},
                  titleInContent: true,
                  actions: const [Icon(Icons.search)],
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: KGridHeading(title: 'Album'),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: 40,
                        itemBuilder: (_, i) => SizedBox(height: 48),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    testWidgets('without a host there is no name in the header', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(PageHeader(title: 'Album', onBack: () {}, titleInContent: true)),
      );
      expect(inHeader('Album'), findsNothing);
      expect(find.byIcon(KIcons.back), findsOneWidget);
    });

    testWidgets('the name appears when collapsed and leaves no Text after', (
      tester,
    ) async {
      await tester.pumpWidget(page());
      expect(inHeader('Album'), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      expect(inHeader('Album'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(inHeader('Album'), findsNothing);
    });

    testWidgets('with animations off it shows after one frame', (tester) async {
      await tester.pumpWidget(page(reduceMotion: true));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      final text = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(PageHeader),
          matching: find.byType(Opacity),
        ),
      );
      expect(text.opacity, 1);
    });

    testWidgets('fades in over a short while when animations are on', (
      tester,
    ) async {
      await tester.pumpWidget(page());
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final mid = tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(PageHeader),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
      expect(mid, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
    });

    testWidgets('the actions keep their place while the name shows or hides', (
      tester,
    ) async {
      await tester.pumpWidget(page());
      final hidden = tester.getTopLeft(find.byIcon(Icons.search));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(inHeader('Album'), findsOneWidget);
      expect(tester.getTopLeft(find.byIcon(Icons.search)), hidden);
    });

    testWidgets('the default keeps the title always visible', (tester) async {
      await tester.pumpWidget(_host(const PageHeader(title: 'Album')));
      expect(inHeader('Album'), findsOneWidget);
    });
  });
}
