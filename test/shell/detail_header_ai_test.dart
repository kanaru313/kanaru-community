import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/detail/detail_header.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/icon_button_finders.dart';
import '../support/nav_fixture.dart';

/// A detail page: a header with a back button and one page action (the
/// playlist's edit toggle), the way `DetailHeader` builds it.
class _Detail implements KanaruExtension {
  const _Detail();
  @override
  String get id => 'detail-header';
  @override
  void register(ExtensionRegistry r) {
    r
      ..addNavItem(
        NavItem(
          id: 'deep',
          path: '/deep',
          icon: KIcons.placeholder,
          selectedIcon: KIcons.placeholder,
          label: (_) => 'Deep',
          order: 300,
        ),
      )
      ..addRoute(
        GoRoute(
          path: '/deep',
          builder: (_, _) =>
              const Scaffold(body: PageHeader(title: 'deep root')),
          routes: [
            GoRoute(
              path: 'frame',
              builder: (context, _) => Scaffold(
                body: DetailFrame(
                  title: 'deep frame',
                  fallback: '/deep',
                  actions: [
                    KIconButton(
                      icon: KIcons.edit,
                      tooltip: 'Edit',
                      onPressed: () {},
                    ),
                  ],
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
            GoRoute(
              path: 'detail',
              builder: (context, _) => Scaffold(
                body: PageHeader(
                  title: 'deep detail',
                  onBack: context.pop,
                  actions: [
                    KIconButton(
                      icon: KIcons.edit,
                      tooltip: 'Edit',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }
}

Future<void> _openDetail(
  WidgetTester tester,
  double width, {
  String page = 'detail',
}) async {
  await pumpKanaruApp(
    tester,
    extensions: [const NavFixture(), const _Detail()],
    width: width,
  );
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/deep/$page');
  await tester.pumpAndSettle();
}

String _aiChat(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(PageHeader))).appAiChat;

Finder _inHeader(String tooltip) => find.descendant(
  of: find.byType(PageHeader),
  matching: byIconButton(tooltip),
);

void main() {
  testWidgets('mobile detail header: [back] title [page action] [AI chat]', (
    tester,
  ) async {
    await _openDetail(tester, 400);
    expect(_inHeader(_aiChat(tester)), findsOneWidget);
    expect(
      tester.getCenter(_inHeader('Edit')).dx,
      lessThan(tester.getCenter(_inHeader(_aiChat(tester))).dx),
    );
  });

  testWidgets('desktop detail header has no AI button (the top bar has it)', (
    tester,
  ) async {
    await _openDetail(tester, 1400);
    expect(_inHeader(_aiChat(tester)), findsNothing);
    expect(_inHeader('${_aiChat(tester)} (Ctrl+J)'), findsNothing);
    expect(byIconButton('${_aiChat(tester)} (Ctrl+J)'), findsOneWidget);
  });

  testWidgets(
    'the real DetailFrame header shows the AI button after its action',
    (tester) async {
      await _openDetail(tester, 400, page: 'frame');
      expect(find.byType(DetailFrame), findsOneWidget);
      expect(_inHeader(_aiChat(tester)), findsOneWidget);
      expect(
        tester.getCenter(_inHeader('Edit')).dx,
        lessThan(tester.getCenter(_inHeader(_aiChat(tester))).dx),
      );
    },
  );

  testWidgets('the real DetailFrame header has no AI button on desktop', (
    tester,
  ) async {
    await _openDetail(tester, 1400, page: 'frame');
    expect(_inHeader(_aiChat(tester)), findsNothing);
  });
}
