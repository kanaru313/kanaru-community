import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_harness.dart';
import '../../../support/nav_fixture.dart';

final _fab = KFabMenuController();

/// A Playlists tab whose page is a [KFabMenu] around a text, like the list
/// page the playlist screens build.
class _FabPlaylists implements KanaruExtension {
  const _FabPlaylists();

  @override
  String get id => 'fab-playlists';

  @override
  void register(ExtensionRegistry r) => r
    ..addNavItem(
      NavItem(
        id: 'playlists',
        path: '/playlists',
        icon: KIcons.playlists,
        selectedIcon: KIcons.playlistsSelected,
        label: (_) => 'Playlists',
        order: 210,
        mobileOrder: 30,
      ),
    )
    ..addRoute(
      GoRoute(
        path: '/playlists',
        builder: (_, _) => KFabMenu(
          controller: _fab,
          openTooltip: 'Create',
          closeTooltip: 'Close',
          items: [KFabMenuItem(icon: KIcons.add, label: 'New playlist')],
          child: const Text('playlist list'),
        ),
      ),
    );
}

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

Future<bool> _back(WidgetTester tester) async {
  final handled = await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  return handled;
}

void main() {
  testWidgets('Back closes the open FAB menu first, then goes Home', (
    tester,
  ) async {
    await pumpKanaruApp(
      tester,
      extensions: [const NavFixture(), const _FabPlaylists()],
      width: 400,
    );
    addTearDown(() => _fab.value = false);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/playlists');
    await tester.pumpAndSettle();
    _fab.open();
    await tester.pumpAndSettle();
    expect(find.text('New playlist'), findsOneWidget);

    // Back closes the menu and stays on Playlists.
    expect(await _back(tester), isTrue);
    expect(_fab.value, isFalse);
    expect(find.text('New playlist'), findsNothing);
    expect(_location(tester), '/playlists');

    // Back again: a tab root other than Home goes to Home.
    expect(await _back(tester), isTrue);
    expect(_location(tester), '/');
  });
}
