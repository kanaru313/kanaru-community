import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/ui/playlists/playlist_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';

Future<AppLocalizations> _pump(
  WidgetTester tester,
  String uid, {
  double width = 400,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: '/playlists/$uid',
    routes: [
      GoRoute(path: '/playlists', builder: (_, _) => const Text('root')),
      GoRoute(
        path: '/playlists/:uid',
        builder: (_, _) => Scaffold(body: PlaylistPage(uid: uid)),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(PlaylistPage)));
}

void main() {
  testWidgets('Favorites shows the Favorites title, not Playlists', (t) async {
    final l10n = await _pump(t, PlaylistUids.favorites);
    expect(find.text(l10n.libraryNavFavorites), findsWidgets);
    expect(find.text(l10n.navPlaylists), findsNothing);
    expect(find.text(l10n.appComingSoon), findsOneWidget);
  });

  testWidgets('an ordinary playlist shows the Playlists title', (t) async {
    final l10n = await _pump(t, '01HZZZZZZZZZZZZZZZZZZZZZZZ');
    expect(find.text(l10n.navPlaylists), findsWidgets);
    expect(find.text(l10n.libraryNavFavorites), findsNothing);
  });

  testWidgets('mobile: Favorites has a back button that returns to the tab', (
    t,
  ) async {
    await _pump(t, PlaylistUids.favorites);
    expect(
      FormFactor.of(t.element(find.byType(PlaylistPage))),
      FormFactor.mobile,
    );
    expect(byIconButton('Back'), findsOneWidget);
    await t.tap(byIconButton('Back'));
    await t.pumpAndSettle();
    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('desktop: Favorites has no back button', (t) async {
    await _pump(t, PlaylistUids.favorites, width: 1400);
    expect(
      FormFactor.of(t.element(find.byType(PlaylistPage))),
      FormFactor.desktop,
    );
    expect(byIconButton('Back'), findsNothing);
  });

  testWidgets('desktop: an ordinary playlist keeps its back button', (t) async {
    await _pump(t, '01HZZZZZZZZZZZZZZZZZZZZZZZ', width: 1400);
    expect(byIconButton('Back'), findsOneWidget);
  });

  testWidgets('mobile: an ordinary playlist has a back button', (t) async {
    await _pump(t, '01HZZZZZZZZZZZZZZZZZZZZZZZ');
    expect(byIconButton('Back'), findsOneWidget);
    await t.tap(byIconButton('Back'));
    await t.pumpAndSettle();
    expect(find.text('root'), findsOneWidget);
  });
}
