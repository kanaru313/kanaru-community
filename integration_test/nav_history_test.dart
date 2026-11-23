import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/widgets.dart'
    show Navigator, Offset, Scrollable, Size, Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/collections/artists_page.dart';
import 'package:kanaru/src/library/ui/detail/artist_page.dart';
import 'package:kanaru/src/library/ui/songs/songs_page.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/screens/settings/ui/library/artist_split_page.dart';
import 'package:kanaru/src/screens/settings/ui/library/library_settings_page.dart';
import 'package:kanaru/src/screens/settings/ui/root/settings_root_page.dart';
import 'package:kanaru/src/shell/ui/desktop_top_bar.dart';
import 'package:kanaru_ui/kanaru_ui.dart' show KIconButton, KNavRow;

import 'support/harness.dart';

/// Desktop navigation history and sidebar selection on the real app, Linux
/// (window 1400 wide, desktop shell): pushed Settings sub-pages are steps of
/// Back and Forward, the Settings item always opens the Settings root, and
/// a Library list item tapped over one of its detail pages opens the list.
/// Every step is a real tap on the sidebar, the page rows or the top bar's
/// Back / Forward buttons; checks are on which page is on stage. Screenshots
/// (app window only, `/tmp/kanaru-it/shots/linux-nav-*.png`) are for the eye
/// and never fail the test.
///
/// Run: `tool/integration_test.sh linux nav_history_test.dart` (through the
/// main checkout's `main-build.sh`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop Back / Forward over pushed pages and sidebar re-select', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);

    final app = await startKanaru(tester);
    final router = app.container.read(routerProvider);

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(Navigator).first));

    bool on(Type page) => find.byType(page).evaluate().isNotEmpty;

    String diag() {
      final pages = [
        for (final t in const [
          SongsPage,
          ArtistsPage,
          ArtistPage,
          SettingsRootPage,
          LibrarySettingsPage,
          ArtistSplitPage,
        ])
          if (on(t)) '$t',
      ];
      return 'uri=${router.routerDelegate.currentConfiguration.uri}, '
          'on stage=$pages, texts=${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().take(20).toList()}';
    }

    /// Waits until [page] is on stage.
    Future<void> expectPage(Type page, String step) =>
        app.pumpUntil(() => on(page), what: '$page after "$step" [${diag()}]');

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      try {
        final view = tester.binding.renderViews.first;
        final layer = view.debugLayer! as OffsetLayer;
        final image = await layer.toImage(Offset.zero & view.size);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final dir = Directory('/tmp/kanaru-it/shots')
          ..createSync(recursive: true);
        File('${dir.path}/linux-nav-$name.png')
            .writeAsBytesSync(bytes.buffer.asUint8List());
      } on Object catch (e) {
        debugPrint('screenshot $name failed: $e');
      }
    }

    Future<void> sidebar(String label) async {
      await tester.tap(
        find
            .ancestor(of: find.text(label), matching: find.byType(KNavRow))
            .first,
      );
      await tester.pumpAndSettle();
    }

    Future<void> rowIn(Type page, String label) async {
      final row = find.descendant(
        of: find.byType(page),
        matching: find.text(label),
      );
      if (row.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          row,
          300,
          scrollable: find
              .descendant(
                of: find.byType(page),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      await tester.ensureVisible(row.first);
      await tester.pumpAndSettle();
      await tester.tap(row.first);
      await tester.pumpAndSettle();
    }

    /// Taps the top bar's icon button [tooltip] (Back / Forward). The page
    /// header has its own Back arrow, so the search stays in the top bar.
    Future<void> topBar(String tooltip) async {
      await tester.tap(
        find.descendant(
          of: find.byType(DesktopTopBar),
          matching: find.byWidgetPredicate(
            (w) => w is KIconButton && w.tooltip == tooltip,
            description: 'KIconButton "$tooltip"',
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final t = l10n();

    // Songs, then Settings › Library › Tách nghệ sĩ: two pushed pages.
    await sidebar(t.libraryTabSongs);
    await expectPage(SongsPage, 'sidebar Songs');
    await sidebar(t.navSettings);
    await expectPage(SettingsRootPage, 'sidebar Settings');
    await rowIn(SettingsRootPage, t.settingsRootLibrary);
    await expectPage(LibrarySettingsPage, 'Settings › Library');
    await rowIn(LibrarySettingsPage, t.settingsLibraryArtistSplit);
    await expectPage(ArtistSplitPage, 'Library › Artist split');
    await shot('01-artist-split');

    // Back walks every step, pushed pages included.
    await topBar(t.tooltipBack);
    await expectPage(LibrarySettingsPage, 'Back 1');
    expect(on(ArtistSplitPage), isFalse, reason: diag());
    await topBar(t.tooltipBack);
    await expectPage(SettingsRootPage, 'Back 2');
    expect(on(LibrarySettingsPage), isFalse, reason: diag());
    await topBar(t.tooltipBack);
    await expectPage(SongsPage, 'Back 3');
    await shot('02-back-to-songs');

    // Forward replays them.
    await topBar(t.tooltipForward);
    await expectPage(SettingsRootPage, 'Forward 1');
    await topBar(t.tooltipForward);
    await expectPage(LibrarySettingsPage, 'Forward 2');
    await topBar(t.tooltipForward);
    await expectPage(ArtistSplitPage, 'Forward 3');
    await shot('03-forward-to-artist-split');

    // Settings in the sidebar opens the Settings root, not its last sub-page.
    await sidebar(t.libraryTabSongs);
    await expectPage(SongsPage, 'sidebar Songs again');
    await sidebar(t.navSettings);
    await expectPage(SettingsRootPage, 'sidebar Settings over a sub-page');
    expect(on(ArtistSplitPage), isFalse, reason: diag());
    expect(on(LibrarySettingsPage), isFalse, reason: diag());
    await shot('04-settings-root');

    // Artists over an artist page opens the Artists list; Back returns to
    // the artist. (The fixtures carry an artist tag but no album.)
    const artist = 'Kanaru Fixture';
    await sidebar(t.libraryTabArtists);
    await expectPage(ArtistsPage, 'sidebar Artists');
    final artistRow = find.descendant(
      of: find.byType(ArtistsPage),
      matching: find.text(artist),
    );
    await app.pumpUntil(
      () => artistRow.evaluate().isNotEmpty,
      what: 'the fixture artist [${diag()}]',
    );
    await tester.tap(artistRow.first);
    await tester.pumpAndSettle();
    await expectPage(ArtistPage, 'artist row');
    await shot('05-artist');
    await sidebar(t.libraryTabArtists);
    await expectPage(ArtistsPage, 'sidebar Artists over the artist');
    expect(on(ArtistPage), isFalse, reason: diag());
    await shot('06-artists-list');
    await topBar(t.tooltipBack);
    await expectPage(ArtistPage, 'Back to the artist');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
