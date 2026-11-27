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

  group('shellActions: false', () {
    Widget scoped(PageHeader header) => _host(
      PageHeaderScope(
        leading: const Icon(Icons.menu, key: Key('scope-leading')),
        trailing: const [Icon(Icons.search, key: Key('scope-trailing'))],
        rootTrailing: const [
          Icon(Icons.settings, key: Key('scope-root-trailing')),
        ],
        child: header,
      ),
    );
    const own = Icon(Icons.tune, key: Key('own-action'));

    testWidgets('root keeps leading, title and own actions only', (
      tester,
    ) async {
      await tester.pumpWidget(
        scoped(
          const PageHeader(
            title: 'Audius',
            actions: [own],
            shellActions: false,
          ),
        ),
      );
      expect(find.byKey(const Key('scope-leading')), findsOneWidget);
      expect(find.text('Audius'), findsOneWidget);
      expect(find.byKey(const Key('own-action')), findsOneWidget);
      expect(find.byKey(const Key('scope-trailing')), findsNothing);
      expect(find.byKey(const Key('scope-root-trailing')), findsNothing);
    });

    testWidgets('child keeps back, title and own actions only', (tester) async {
      await tester.pumpWidget(
        scoped(
          PageHeader(
            title: 'Album',
            onBack: () {},
            backTooltip: 'Up',
            actions: const [own],
            shellActions: false,
          ),
        ),
      );
      expect(
        find.byWidgetPredicate((w) => w is KIconButton && w.tooltip == 'Up'),
        findsOneWidget,
      );
      expect(find.text('Album'), findsOneWidget);
      expect(find.byKey(const Key('own-action')), findsOneWidget);
      expect(find.byKey(const Key('scope-trailing')), findsNothing);
      expect(find.byKey(const Key('scope-root-trailing')), findsNothing);
    });

    testWidgets('default still shows the scope actions', (tester) async {
      await tester.pumpWidget(
        scoped(const PageHeader(title: 'Audius', actions: [own])),
      );
      expect(find.byKey(const Key('scope-trailing')), findsOneWidget);
      expect(find.byKey(const Key('scope-root-trailing')), findsOneWidget);
    });

    testWidgets('no scope: unchanged, no overflow at 2x text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: const PageHeader(
                title: 'A very long page title that must ellipsize',
                actions: [own],
                shellActions: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('own-action')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
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
