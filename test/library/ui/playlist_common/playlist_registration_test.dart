import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/extension/state/registry_entries.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/library_extension.dart';
import 'package:kanaru/src/library/ui/playlist_common/playlist_labels.dart';
import 'package:kanaru/src/library/ui/playlists/playlist_page.dart';
import 'package:kanaru/src/shell/state/mobile_sidebar_state.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/m3u/m3u_entry_points.dart';
import 'package:flutter/rendering.dart' show RenderSliver;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../support/app_harness.dart';

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

void main() {
  test('locations match the registered paths', () {
    expect(LibraryLocations.playlists, '/playlists');
    expect(LibraryLocations.playlist('abc'), '/playlists/abc');
  });

  group('nav', () {
    final registry = ExtensionRegistry()..install(const [LibraryExtension()]);
    NavItem item(String id) => registry.navItems.singleWhere((n) => n.id == id);

    test('Playlists is a mobile tab, Favorites is a sidebar child of it', () {
      final playlists = item('playlists');
      expect(playlists.path, '/playlists');
      expect(playlists.order, 210);
      expect(playlists.mobileOrder, 30);
      expect(playlists.comingSoon, isFalse);
      final favorites = item('favorites');
      expect(favorites.path, '/playlists/favorites');
      expect(favorites.parentId, 'playlists');
      expect(favorites.order, 220);
      expect(favorites.mobileTab, isFalse);
      expect(favorites.comingSoon, isFalse);
    });

    test('History and Most played stay coming soon', () {
      expect(item('history').comingSoon, isTrue);
      expect(item('most_played').comingSoon, isTrue);
      expect(item('history').order, 240);
      expect(item('most_played').order, 250);
    });
  });

  const ulid = '01HZZZZZZZZZZZZZZZZZZZZZZZ';

  Finder page(String uid) => find.byWidgetPredicate(
    (w) => w is PlaylistPage && w.uid == uid,
    description: 'PlaylistPage($uid)',
  );

  Finder inSidebar(String label) => find.descendant(
    of: find.byKey(const ValueKey('sidebar')),
    matching: find.bySemanticsLabel(label),
  );

  testWidgets('Favorites opens inside Playlists; Back returns to its root', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpKanaruApp(tester);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(LibraryLocations.playlists);
    await tester.pumpAndSettle();
    // Desktop sidebar: tapping Favorites opens its page, lit; Playlists not.
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('sidebar')),
        matching: find.text('Favorites'),
      ),
    );
    await tester.pumpAndSettle();
    expect(_location(tester), '/playlists/favorites');
    expect(page(PlaylistUids.favorites), findsOneWidget);
    expect(
      tester.getSemantics(inSidebar('Favorites')),
      isSemantics(isSelected: true, isButton: true, isEnabled: true),
    );
    expect(
      tester.getSemantics(inSidebar('Playlists')),
      isSemantics(isSelected: false, isButton: true, isEnabled: true),
    );
    router.pop();
    await tester.pumpAndSettle();
    expect(_location(tester), '/playlists');
    handle.dispose();
  });

  testWidgets('a playlist uid opens its page with Playlists selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpKanaruApp(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go(LibraryLocations.playlist(ulid));
    await tester.pumpAndSettle();
    expect(page(ulid), findsOneWidget);
    expect(
      tester.getSemantics(inSidebar('Playlists')),
      isSemantics(isSelected: true, isButton: true, isEnabled: true),
    );
    handle.dispose();
  });

  testWidgets('mobile: Favorites in the drawer opens inside Playlists', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final c = await pumpKanaruApp(tester, width: 400);
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go(LibraryLocations.playlists);
    c.read(mobileSidebarOpenProvider.notifier).open();
    await tester.pumpAndSettle();
    final favorites = find.bySemanticsLabel('Favorites');
    expect(
      tester.getSemantics(favorites),
      isSemantics(isSelected: false, isButton: true, isEnabled: true),
    );
    await tester.tap(favorites);
    await tester.pumpAndSettle();
    expect(_location(tester), '/playlists/favorites');
    expect(page(PlaylistUids.favorites), findsOneWidget);
    c.read(mobileSidebarOpenProvider.notifier).open();
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Favorites')),
      isSemantics(isSelected: true, isButton: true, isEnabled: true),
    );
    handle.dispose();
  });

  testWidgets('playlistDisplayName: Favorites localized, others by name', (
    tester,
  ) async {
    PlaylistSummary summary(String uid, String name, {bool fav = false}) =>
        PlaylistSummary(
          uid: uid,
          name: name,
          description: '',
          isFavorites: fav,
          trackCount: 0,
          durationMs: 0,
          createdAt: 0,
          updatedAt: 0,
          autoCoverKeys: const [],
        );
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      playlistDisplayName(l10n, summary('favorites', 'x', fav: true)),
      l10n.playlistFavoritesName,
    );
    expect(playlistDisplayName(l10n, summary('p1', 'Road trip')), 'Road trip');
  });

  testWidgets('the import progress seed draws nothing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(slivers: [M3uImportProgressSliver()]),
          ),
        ),
      ),
    );
    final sliver = tester.renderObject<RenderSliver>(
      find.byType(M3uImportProgressSliver, skipOffstage: false),
    );
    expect(sliver.geometry!.scrollExtent, 0);
    expect(m3uAvailable, isFalse);
  });
}
