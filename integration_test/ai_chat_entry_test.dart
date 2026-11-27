import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/state/chat_view/page_suggestions.dart';
import 'package:kanaru/src/ai/ai_extension.dart';
import 'package:kanaru/src/ai/state/chat_view/chat_view_state.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_draft.dart';
import 'package:kanaru/src/ai/ui/chat_page_mobile.dart';
import 'package:kanaru/src/ai/ui/chat_surface.dart';
import 'package:kanaru/src/ai/ui/history_page.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/browse/detail_providers.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/ui/detail/detail_header.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/shell/state/right_panel.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../test/ai/ui/support/chat_ui_support.dart';
import '../test/support/app_harness.dart';
import '../test/ai/ui/composer/composer_harness.dart' show chatPlugin;
import '../test/support/icon_button_finders.dart';
import '../test/support/nav_fixture.dart';
import 'support/ai_chat_harness.dart';

/// AI chat screens (PR #116, polish #118, #119) in Vietnamese, on both shells:
/// the phone (412 x 915, MobileShell, the `/chat` page) and the desktop
/// (1400 x 1000, DesktopShell, chat in the right panel). The real shell,
/// router and chat widgets run over the fake engine of `test/ai/ui/support`
/// (no plugin, no network, no native library), so the same file runs as a
/// plain widget test and on the Linux device.
///
/// It asserts state (finders, semantics), never pixels. Screenshots
/// `NN-<state>-<shell>.png` go to `$KANARU_IT_SHOTS` (default
/// `/tmp/kanaru-it/shots-ai-chat`) for comparing with `mockups/*/08-ai-chat`.
///
/// This file: the entry points (P1, P2, P5).

/// A plain header-bearing detail page for each location the chat offers a
/// page chip for (the library pages themselves are not built here).
class _DetailPages implements KanaruExtension {
  const _DetailPages();

  @override
  String get id => 'detail-pages';

  @override
  void register(ExtensionRegistry r) {
    GoRoute page(String path, {bool edit = false}) => GoRoute(
      path: path,
      builder: (context, state) => Scaffold(
        body: DetailFrame(
          title: state.uri.path,
          fallback: '/',
          actions: [
            if (edit)
              KIconButton(icon: KIcons.edit, tooltip: 'Sửa', onPressed: () {}),
          ],
          child: const SizedBox.shrink(),
        ),
      ),
    );
    NavItem item(String id, String path, int order) => NavItem(
      id: id,
      path: path,
      icon: KIcons.placeholder,
      selectedIcon: KIcons.placeholder,
      label: (_) => id,
      order: order,
    );
    GoRoute root(String path, List<GoRoute> routes) => GoRoute(
      path: path,
      builder: (_, _) => const Scaffold(body: PageHeader(title: 'root')),
      routes: routes,
    );
    r
      ..addNavItem(item('lib', '/library', 300))
      ..addNavItem(item('pls', '/playlists', 310))
      ..addRoute(
        root('/library', [
          page('albums/:id'),
          page('artists/:id'),
          page('genres/:id'),
          page('languages/:id'),
        ]),
      )
      ..addRoute(root('/playlists', [page(':uid', edit: true)]));
  }
}

PlaylistDetail _playlist(String uid, String name, {bool favorites = false}) =>
    PlaylistDetail(
      summary: PlaylistSummary(
        id: favorites ? 0 : 7,
        uid: uid,
        name: name,
        description: '',
        isFavorites: favorites,
        trackCount: 0,
        durationMs: 0,
        createdAt: 1,
        updatedAt: 1,
        autoCoverKeys: const [],
      ),
      entries: const [],
    );

/// The phone shell on [location], a detail page with its header, over the
/// fake engine; the library names come from fakes.
Future<ProviderContainer> _openDetail(
  WidgetTester tester,
  String location,
) async {
  tester.platformDispatcher.localesTestValue = const [Locale('vi')];
  tester.platformDispatcher.localeTestValue = const Locale('vi');
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final session = FakeChatSession();
  final container = await pumpKanaruApp(
    tester,
    extensions: [const NavFixture(), const _DetailPages(), const AiExtension()],
    width: phoneSize.width,
    height: phoneSize.height,
    overrides: [
      ...chatUiOverrides(session: session),
      chatHostOverride,
      albumDetailProvider.overrideWith(
        (ref, key) => Stream.value(
          AlbumSummary(
            key: key.encode(),
            title: 'Blue',
            artist: 'Miles',
            year: 1959,
            trackCount: 4,
            durationMs: 600000,
            coverKey: null,
            addedAt: 1,
          ),
        ),
      ),
      artistNameProvider.overrideWith(
        (ref, key) => const AsyncData<String?>('Miles'),
      ),
      genreNameProvider.overrideWith(
        (ref, key) => const AsyncData<String?>('Jazz'),
      ),
      playlistDetailProvider.overrideWith(
        (ref, uid) => Stream.value(
          uid == 'uid-fav'
              ? _playlist(uid, 'Yêu thích', favorites: true)
              : _playlist(uid, 'Road'),
        ),
      ),
    ],
  );
  container.read(fakeChatPluginsProvider.notifier).set([
    chatPlugin(id: chatPluginId),
  ]);
  container
      .read(fakeChatBindingProvider.notifier)
      .set(installId: chatPluginId, model: 'm1');
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('page entry points', () {
    for (final page in const [
      'album',
      'artist',
      'genre',
      'language',
      'playlist',
      'favorites',
    ]) {
      testWidgets('P1: phone detail header of $page has ✦, ✏ left of it', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = const [Locale('vi')];
        tester.platformDispatcher.localeTestValue = const Locale('vi');
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final album = albumKeyFor(
          album: 'Blue',
          albumArtist: 'Miles',
          artists: ['Miles'],
        )!;
        final location = switch (page) {
          'album' => LibraryLocations.album(album),
          'artist' => LibraryLocations.artist(ArtistKey('Miles')),
          'genre' => LibraryLocations.genre('jazz'),
          'language' => LibraryLocations.language('vi'),
          'playlist' => LibraryLocations.playlist('uid-1'),
          _ => LibraryLocations.playlist('uid-fav'),
        };
        final container = await _openDetail(tester, location);
        final ai = find.descendant(
          of: find.byType(PageHeader),
          matching: byIconButton('Trò chuyện AI'),
        );
        expect(ai, findsOneWidget);
        if (page == 'playlist') {
          final edit = find.descendant(
            of: find.byType(PageHeader),
            matching: byIconButton('Sửa'),
          );
          expect(tester.getCenter(edit).dx, lessThan(tester.getCenter(ai).dx));
        }
        await chatShot(tester, '24-detail-header-$page-phone');
        // The chat would offer the page as a suggested chip: the shell keeps
        // the page location and the real suggestion provider names it.
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PageHeader)),
        );
        expect(container.read(chatPageLocationProvider), location);
        final keep = container.listen(chatSuggestionsProvider(l10n), (_, _) {});
        addTearDown(keep.close);
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final chips = container.read(chatSuggestionsProvider(l10n));
        final kind = switch (page) {
          'album' => ChipKind.album,
          'artist' => ChipKind.artist,
          'genre' => ChipKind.genre,
          'language' => ChipKind.language,
          _ => ChipKind.playlist,
        };
        // The artist name comes from a provider chain the fakes do not feed:
        // its chip is not checked here.
        if (page != 'artist') {
          expect(chips.where((c) => c.kind == kind), hasLength(1));
        }
      });
    }

    testWidgets('P2: desktop detail header has no ✦, the top bar has it', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('vi')];
      tester.platformDispatcher.localeTestValue = const Locale('vi');
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await pumpKanaruApp(
        tester,
        extensions: [
          const NavFixture(),
          const _DetailPages(),
          const AiExtension(),
        ],
        width: desktopSize.width,
        height: desktopSize.height,
        overrides: [
          ...chatUiOverrides(session: FakeChatSession()),
          chatHostOverride,
          playlistDetailProvider.overrideWith(
            (ref, uid) => Stream.value(_playlist(uid, 'Road')),
          ),
        ],
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go(LibraryLocations.playlist('uid-1'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(PageHeader),
          matching: byIconButton('Trò chuyện AI'),
        ),
        findsNothing,
      );
      expect(byIconButton('Trò chuyện AI (Ctrl+J)'), findsOneWidget);
      await chatShot(tester, '26-detail-header-desktop');
    });

    testWidgets('P2: the top-bar button opens the panel with the page chip', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('vi')];
      tester.platformDispatcher.localeTestValue = const Locale('vi');
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await pumpKanaruApp(
        tester,
        extensions: [
          const NavFixture(),
          const _DetailPages(),
          const AiExtension(),
        ],
        width: desktopSize.width,
        height: desktopSize.height,
        overrides: [
          ...chatUiOverrides(session: FakeChatSession()),
          chatHostOverride,
          playlistDetailProvider.overrideWith(
            (ref, uid) => Stream.value(_playlist(uid, 'Road')),
          ),
        ],
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go(LibraryLocations.playlist('uid-1'));
      await tester.pumpAndSettle();
      await tester.tap(byIconButton('Trò chuyện AI (Ctrl+J)'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatSurface), findsOneWidget);
      expect(find.textContaining('Playlist: Road'), findsOneWidget);
      await chatShot(tester, '27-detail-chat-panel-desktop');
    });

    testWidgets(
      'P1: tapping ✦ opens the chat page with the page chip suggested',
      (tester) async {
        tester.platformDispatcher.localesTestValue = const [Locale('vi')];
        tester.platformDispatcher.localeTestValue = const Locale('vi');
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final album = albumKeyFor(
          album: 'Blue',
          albumArtist: 'Miles',
          artists: ['Miles'],
        )!;
        await _openDetail(tester, LibraryLocations.album(album));
        await tester.tap(
          find.descendant(
            of: find.byType(PageHeader),
            matching: byIconButton('Trò chuyện AI'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ChatPageMobile), findsOneWidget);
        expect(find.textContaining('Album: Blue'), findsOneWidget);
        await chatShot(tester, '25-detail-chat-album-phone');
      },
    );

    testWidgets('P2: desktop panel queue <-> chat keeps the chat state', (
      tester,
    ) async {
      final c = await openChat(tester, ChatShell.desktop);
      c.container
          .read(composerDraftProvider.notifier)
          .set(const TextEditingValue(text: 'câu hỏi dở dang'));
      c.container.read(chatViewProvider.notifier).openHistory();
      await c.pump();
      c.container.read(rightPanelProvider.notifier).show(RightPanelKind.queue);
      await c.pump();
      expect(find.byType(ChatSurface), findsNothing);
      await c.shot('28-panel-queue');
      c.container.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
      await c.pump();
      expect(find.byKey(chatHistoryPageKey), findsOneWidget);
      expect(c.container.read(composerDraftProvider).text, 'câu hỏi dở dang');
    });

    testWidgets('P5: a selection chip names the real count over 200 [phone]', (
      tester,
    ) async {
      const shell = ChatShell.phone;
      final c = await openChat(tester, shell);
      c.container.read(librarySelectionProvider.notifier).selectAll([
        for (var i = 1; i <= 1340; i++) TrackId(i),
      ]);
      await c.pump();
      // On desktop the selection may take the shared right panel: bring the
      // chat back, as a user who opens it with a selection does.
      c.container.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
      await c.pump();
      expect(find.textContaining('1340 bài'), findsOneWidget);
      await c.shot('29-selection-chip');
    });
  });
}
