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
    await tester.pumpWidget(_host(PageHeader(title: 'Album', onBack: () => backs++)));
    await tester.tap(find.byIcon(KIcons.back));
    expect(backs, 1);
  });

  testWidgets('root page shows the scope leading and rootTrailing', (tester) async {
    await tester.pumpWidget(_host(const PageHeaderScope(
      leading: Icon(Icons.menu),
      trailing: [Icon(Icons.search)],
      rootTrailing: [Icon(Icons.settings)],
      child: PageHeader(title: 'Home'),
    )));
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    // Order: leading, title, trailing, rootTrailing.
    final xs = [Icons.menu, Icons.search, Icons.settings]
        .map((i) => tester.getCenter(find.byIcon(i)).dx)
        .toList();
    expect(xs[0] < tester.getCenter(find.text('Home')).dx, isTrue);
    expect(xs[1] < xs[2], isTrue);
  });

  testWidgets('child page hides the scope leading and rootTrailing', (tester) async {
    await tester.pumpWidget(_host(PageHeaderScope(
      leading: const Icon(Icons.menu),
      trailing: const [Icon(Icons.search)],
      rootTrailing: const [Icon(Icons.settings)],
      child: PageHeader(title: 'Album', onBack: () {}),
    )));
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byIcon(Icons.settings), findsNothing);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(KIcons.back), findsOneWidget);
  });

  testWidgets('KEmpty shows message and action', (tester) async {
    await tester.pumpWidget(_host(KEmpty(
      icon: Icons.music_note,
      message: 'Nothing here',
      action: TextButton(onPressed: () {}, child: const Text('Add')),
    )));
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });
}
