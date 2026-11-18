import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:material_ui/material_ui.dart';

import '../../../database/support/test_db.dart';
import '../../../support/app_harness.dart';
import '../../../support/icon_button_finders.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }
  await tester.pumpAndSettle();
}

/// Two songs in Favorites of the app under test.
Future<void> _seedFavorites(WidgetTester tester, ProviderContainer c) async {
  final db = c.read(appDatabaseProvider);
  await tester.runAsync(() async {
    final source = await addSource(db, uid: 'src-tab');
    final tracks = [
      for (final name in ['Alpha', 'Bravo'])
        TrackId(await addTrack(db, source, locator: '$name.flac', title: name)),
    ];
    await c
        .read(playlistStoreProvider)
        .addToPlaylists(tracks: tracks, playlistUids: [PlaylistUids.favorites]);
  });
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('mobile: tapping the Playlists tab again leaves edit mode', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final c = await pumpKanaruApp(tester, width: 400);
    await _seedFavorites(tester, c);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(LibraryLocations.playlist(PlaylistUids.favorites));
    await _settle(tester);
    expect(find.text('Alpha'), findsOneWidget);

    await tester.tap(byAnyIconButton('Edit list'));
    await tester.pumpAndSettle();
    expect(byAnyIconButton('Done'), findsOneWidget);

    final tab = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.bySemanticsLabel(RegExp('Playlists')),
    );
    await tester.tap(tab.first);
    await tester.pumpAndSettle();
    expect(_path(router), LibraryLocations.playlists);
    // The page is gone, and so is its edit mode: a new visit starts normal.
    router.go(LibraryLocations.playlist(PlaylistUids.favorites));
    await _settle(tester);
    expect(byAnyIconButton('Done'), findsNothing);
    expect(byAnyIconButton('Edit list'), findsOneWidget);
    handle.dispose();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a page hidden behind another tab is not in edit mode when '
      'it comes back', (tester) async {
    final handle = tester.ensureSemantics();
    final c = await pumpKanaruApp(tester, width: 400);
    await _seedFavorites(tester, c);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(LibraryLocations.playlist(PlaylistUids.favorites));
    await _settle(tester);
    await tester.tap(byAnyIconButton('Edit list'));
    await tester.pumpAndSettle();
    expect(byAnyIconButton('Done'), findsOneWidget);

    router.go('/library');
    await _settle(tester);
    // Esc on the other tab does nothing to the hidden page.
    router.go(LibraryLocations.playlist(PlaylistUids.favorites));
    await _settle(tester);
    expect(byAnyIconButton('Done'), findsNothing);
    expect(byAnyIconButton('Edit list'), findsOneWidget);
    handle.dispose();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('desktop: Esc leaves edit mode and stays on the page; a second '
      'Esc goes back as before', (tester) async {
    final handle = tester.ensureSemantics();
    final c = await pumpKanaruApp(tester, width: 1400);
    await _seedFavorites(tester, c);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(LibraryLocations.playlists);
    await _settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('sidebar')),
        matching: find.text('Favorites'),
      ),
    );
    await _settle(tester);
    expect(_path(router), '/playlists/favorites');

    await tester.tap(byAnyIconButton('Edit list'));
    await tester.pumpAndSettle();
    expect(byAnyIconButton('Done'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_path(router), '/playlists/favorites');
    expect(byAnyIconButton('Edit list'), findsOneWidget);
    expect(byAnyIconButton('Done'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_path(router), '/playlists');
    handle.dispose();
    await tester.pump(const Duration(seconds: 2));
  });

  for (final viaFilter in [true, false]) {
    testWidgets('desktop: Esc still exits edit mode when focus was on '
        '${viaFilter ? 'the filter field' : 'a keyboard-focused row'}', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final c = await pumpKanaruApp(tester, width: 1400);
      await _seedFavorites(tester, c);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.go(LibraryLocations.playlists);
      await _settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('sidebar')),
          matching: find.text('Favorites'),
        ),
      );
      await _settle(tester);
      if (viaFilter) {
        await tester.tap(byAnyIconButton('Filter'));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'alp');
        await tester.pump(const Duration(milliseconds: 500));
      } else {
        Focus.of(tester.element(find.text('Alpha'))).requestFocus();
        await tester.pump();
      }
      await tester.tap(byAnyIconButton('Edit list'));
      await tester.pumpAndSettle();
      expect(byAnyIconButton('Done'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_path(router), '/playlists/favorites');
      expect(byAnyIconButton('Edit list'), findsOneWidget);
      handle.dispose();
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
