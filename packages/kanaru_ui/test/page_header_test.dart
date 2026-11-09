import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('root page hides the back button', (tester) async {
    await tester.pumpWidget(_host(const PageHeader(title: 'Library')));
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('child page shows back and calls onBack', (tester) async {
    var backs = 0;
    await tester.pumpWidget(_host(PageHeader(title: 'Album', onBack: () => backs++)));
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(backs, 1);
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
