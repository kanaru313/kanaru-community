import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/ui/detail/detail_header.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/icon_button_finders.dart';

Future<void> _pump(
  WidgetTester tester, {
  List<Widget> actions = const [],
  bool showBack = true,
  bool titleInContent = true,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: DetailFrame(
            title: 'Name',
            fallback: '/',
            actions: actions,
            showBack: showBack,
            titleInContent: titleInContent,
            child: const Text('body'),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('default frame: back button, title kept in the content', (
    tester,
  ) async {
    await _pump(tester);
    expect(byIconButton('Back'), findsOneWidget);
    // The name is the page's own content; the header shows it only once it
    // scrolls out of sight.
    expect(find.text('Name'), findsNothing);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('actions are shown in the header', (tester) async {
    await _pump(tester, actions: const [Text('act one'), Text('act two')]);
    expect(find.text('act one'), findsOneWidget);
    expect(find.text('act two'), findsOneWidget);
    expect(byIconButton('Back'), findsOneWidget);
  });

  testWidgets('showBack: false drops the back button only', (tester) async {
    await _pump(tester, showBack: false, actions: const [Text('act')]);
    expect(byIconButton('Back'), findsNothing);
    expect(find.text('act'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('titleInContent: false shows the title in the header', (
    tester,
  ) async {
    await _pump(tester, titleInContent: false, showBack: false);
    expect(find.text('Name'), findsOneWidget);
  });

  testWidgets('showBack: false makes it a root header (scope slots show)', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: PageHeaderScope(
              leading: const Text('lead'),
              rootTrailing: const [Text('root trail')],
              child: DetailFrame(
                title: 'Name',
                fallback: '/',
                showBack: false,
                child: const Text('body'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('lead'), findsOneWidget);
    expect(find.text('root trail'), findsOneWidget);
  });
}
