import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/playlists/page/playlist_back_chain.dart';
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

/// Alpha and Bravo in Favorites of the app under test.
Future<List<TrackId>> _seedFavorites(
  WidgetTester tester,
  ProviderContainer c,
) async {
  final db = c.read(appDatabaseProvider);
  return (await tester.runAsync(() async {
    final source = await addSource(db, uid: 'src-back');
    final tracks = [
      for (final name in ['Alpha', 'Bravo'])
        TrackId(await addTrack(db, source, locator: '$name.flac', title: name)),
    ];
    await c
        .read(playlistStoreProvider)
        .addToPlaylists(tracks: tracks, playlistUids: [PlaylistUids.favorites]);
    return tracks;
  }))!;
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

GoRouter _router(WidgetTester t) =>
    GoRouter.of(t.element(find.byType(Scaffold).first));

Future<void> _openFavorites(WidgetTester t, {required bool desktop}) async {
  final router = _router(t);
  if (desktop) {
    router.go(LibraryLocations.playlists);
    await _settle(t);
    await t.tap(
      find.descendant(
        of: find.byKey(const ValueKey('sidebar')),
        matching: find.text('Favorites'),
      ),
    );
  } else {
    router.go(LibraryLocations.playlist(PlaylistUids.favorites));
  }
  await _settle(t);
  expect(_path(router), '/playlists/favorites');
}

/// Opens the filter and types [text]; the rows follow after the debounce.
Future<void> _filterBy(WidgetTester t, String text) async {
  await t.tap(byAnyIconButton('Filter'));
  await t.pump();
  await t.enterText(find.byType(TextField), text);
  await t.pump(const Duration(milliseconds: 500));
}

Future<void> _enterEdit(WidgetTester t) async {
  await t.tap(byAnyIconButton('Edit list'));
  await t.pumpAndSettle();
  expect(byAnyIconButton('Done'), findsOneWidget);
}

Future<void> _back(WidgetTester t) async {
  expect(await t.binding.handlePopRoute(), isTrue);
  await t.pumpAndSettle();
}

Future<void> _esc(WidgetTester t) async {
  await t.sendKeyEvent(LogicalKeyboardKey.escape);
  await t.pumpAndSettle();
}

Future<void> _end(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  c.dispose();
  await t.pumpAndSettle();
  await t.pump(const Duration(milliseconds: 1));
}

void main() {
  group('playlist page, mobile shell', () {
    testWidgets('Back: edit mode, then the filter, then the page', (t) async {
      final handle = t.ensureSemantics();
      final c = await pumpKanaruApp(t, width: 400);
      await _seedFavorites(t, c);
      await _openFavorites(t, desktop: false);
      await _filterBy(t, 'alp');
      expect(find.text('Bravo'), findsNothing);
      await _enterEdit(t);
      expect(find.byType(TextField), findsNothing, reason: 'filter put away');

      await _back(t);
      expect(byAnyIconButton('Edit list'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget, reason: 'filter is back');
      expect(_path(_router(t)), '/playlists/favorites');

      await _back(t);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Bravo'), findsOneWidget);
      expect(_path(_router(t)), '/playlists/favorites');

      await _back(t);
      expect(_path(_router(t)), '/playlists');
      handle.dispose();
      await _end(t, c);
    });

    testWidgets('the app-wide panel collapses first, then the page chain', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      final c = await pumpKanaruApp(t, width: 400);
      final tracks = await _seedFavorites(t, c);
      await _openFavorites(t, desktop: false);
      await _enterEdit(t);
      c.read(librarySelectionProvider.notifier)
        ..toggle(tracks.first)
        ..setExpanded(true);
      await t.pumpAndSettle();
      expect(c.read(librarySelectionProvider).expanded, isTrue);

      await _back(t);
      expect(c.read(librarySelectionProvider).expanded, isFalse);
      expect(byAnyIconButton('Done'), findsOneWidget, reason: 'still editing');

      await _back(t);
      expect(byAnyIconButton('Edit list'), findsOneWidget);
      expect(_path(_router(t)), '/playlists/favorites');
      handle.dispose();
      await _end(t, c);
    });
  });

  group('playlist page, desktop shell', () {
    testWidgets('Esc: edit mode, then the filter, then the page', (t) async {
      final handle = t.ensureSemantics();
      final c = await pumpKanaruApp(t, width: 1400);
      await _seedFavorites(t, c);
      await _openFavorites(t, desktop: true);
      await _filterBy(t, 'alp');
      await _enterEdit(t);

      await _esc(t);
      expect(byAnyIconButton('Edit list'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget, reason: 'filter is back');
      expect(_path(_router(t)), '/playlists/favorites');

      await _esc(t);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Bravo'), findsOneWidget);
      expect(_path(_router(t)), '/playlists/favorites');

      await _esc(t);
      expect(_path(_router(t)), '/playlists');
      handle.dispose();
      await _end(t, c);
    });

    testWidgets('Esc: the app-wide panel collapses first, once', (t) async {
      final handle = t.ensureSemantics();
      final c = await pumpKanaruApp(t, width: 1400);
      final tracks = await _seedFavorites(t, c);
      await _openFavorites(t, desktop: true);
      await _enterEdit(t);
      c.read(librarySelectionProvider.notifier)
        ..toggle(tracks.first)
        ..setExpanded(true);
      await t.pumpAndSettle();

      await _esc(t);
      expect(c.read(librarySelectionProvider).expanded, isFalse);
      expect(byAnyIconButton('Done'), findsOneWidget, reason: 'still editing');
      expect(_path(_router(t)), '/playlists/favorites');

      await _esc(t);
      expect(byAnyIconButton('Edit list'), findsOneWidget);
      expect(_path(_router(t)), '/playlists/favorites');
      handle.dispose();
      await _end(t, c);
    });

    testWidgets('Esc closes the filter even when its field has no focus', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      final c = await pumpKanaruApp(t, width: 1400);
      await _seedFavorites(t, c);
      await _openFavorites(t, desktop: true);
      await _filterBy(t, 'alp');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await _esc(t);
      expect(find.byType(TextField), findsNothing);
      expect(_path(_router(t)), '/playlists/favorites');
      handle.dispose();
      await _end(t, c);
    });

    testWidgets('Esc in the filter field closes only the filter', (t) async {
      final handle = t.ensureSemantics();
      final c = await pumpKanaruApp(t, width: 1400);
      await _seedFavorites(t, c);
      await _openFavorites(t, desktop: true);
      await _filterBy(t, 'alp');
      await _esc(t);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Bravo'), findsOneWidget);
      expect(_path(_router(t)), '/playlists/favorites');
      handle.dispose();
      await _end(t, c);
    });
  });

  group('playlist list page, desktop shell', () {
    testWidgets('Esc: the FAB menu, then the filter, then the page', (t) async {
      final handle = t.ensureSemantics();
      final c = await pumpKanaruApp(t, width: 1400);
      await _seedFavorites(t, c);
      await t.runAsync(
        () => c.read(playlistStoreProvider).createPlaylist(name: 'Solo'),
      );
      await _openFavorites(t, desktop: true);
      await t.tap(
        find.descendant(
          of: find.byKey(const ValueKey('sidebar')),
          matching: find.text('Playlists'),
        ),
      );
      await _settle(t);
      expect(_path(_router(t)), '/playlists');

      await _filterBy(t, 'so');
      // The field loses focus: Esc is the page's, not the field's.
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Create'));
      await _settle(t);
      expect(find.text('New playlist'), findsOneWidget);

      await _esc(t);
      expect(find.text('New playlist'), findsNothing);
      expect(find.byType(TextField), findsOneWidget, reason: 'filter stays');
      expect(_path(_router(t)), '/playlists');

      await _esc(t);
      expect(find.byType(TextField), findsNothing);
      expect(_path(_router(t)), '/playlists');

      await _esc(t);
      expect(_path(_router(t)), '/playlists/favorites');
      handle.dispose();
      await _end(t, c);
    });
  });

  group('playlist list page, FAB menu alone', () {
    testWidgets('desktop: Esc closes the menu and the page stays; the next '
        'Esc leaves', (t) async {
      final handle = t.ensureSemantics();
      final c = await pumpKanaruApp(t, width: 1400);
      await _seedFavorites(t, c);
      await _openFavorites(t, desktop: true);
      await t.tap(
        find.descendant(
          of: find.byKey(const ValueKey('sidebar')),
          matching: find.text('Playlists'),
        ),
      );
      await _settle(t);
      expect(_path(_router(t)), '/playlists');
      await t.tap(find.byTooltip('Create'));
      await _settle(t);
      expect(find.text('New playlist'), findsOneWidget);

      await _esc(t);
      expect(find.text('New playlist'), findsNothing);
      expect(_path(_router(t)), '/playlists');

      await _esc(t);
      expect(_path(_router(t)), '/playlists/favorites');
      handle.dispose();
      await _end(t, c);
    });
  });

  group('PlaylistBackScope', () {
    int closed = 0;

    Widget app({required Widget child, bool active = true, FocusNode? node}) =>
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PlaylistBackScope(
                active: active,
                focusNode: node ?? FocusNode(skipTraversal: true),
                closeTop: () {
                  closed++;
                  return true;
                },
                child: child,
              ),
            ),
          ),
        );

    setUp(() => closed = 0);

    testWidgets('Esc closes one layer per press', (t) async {
      await t.pumpWidget(app(child: const SizedBox()));
      await t.pump();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closed, 1);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closed, 2);
    });

    testWidgets('Esc does nothing when no layer is open', (t) async {
      await t.pumpWidget(app(child: const SizedBox(), active: false));
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closed, 0);
    });

    testWidgets('Esc yields to a text field', (t) async {
      await t.pumpWidget(app(child: const TextField(autofocus: true)));
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closed, 0);
    });

    testWidgets('Esc yields to a root modal and closes only it', (t) async {
      final node = FocusNode(skipTraversal: true);
      addTearDown(node.dispose);
      await t.pumpWidget(app(child: const SizedBox(), node: node));
      await t.pump();
      await t.pump();
      final context = t.element(find.byType(SizedBox).first);
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('modal')),
      );
      await t.pumpAndSettle();
      // Focus on the page node although a dialog covers it: only the check
      // for a root modal keeps the page from closing a layer.
      node.requestFocus();
      await t.pump();
      expect(node.hasFocus, isTrue);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(closed, 0);
    });

    testWidgets('Back closes a layer instead of popping', (t) async {
      await t.pumpWidget(app(child: const SizedBox()));
      await t.pump();
      expect(await t.binding.handlePopRoute(), isTrue);
      await t.pump();
      expect(closed, 1);
    });
  });
}
