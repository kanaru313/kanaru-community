import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/playlists/playlist_page.dart';
import 'package:kanaru/src/library/ui/playlists/playlists_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_harness.dart';
import '../../../support/icon_button_finders.dart';

/// The real app (router, shell branches, root navigator) on the Playlist tab.
Future<ProviderContainer> _pumpTab(
  WidgetTester t, {
  required double width,
}) async {
  final c = await pumpKanaruApp(t, width: width);
  await t.runAsync(
    () => c.read(playlistStoreProvider).createPlaylist(name: 'Solo'),
  );
  GoRouter.of(t.element(find.byType(Scaffold).first))
      .go(LibraryLocations.playlists);
  await _settle(t);
  return c;
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await t.pump(const Duration(milliseconds: 600));
  }
  await t.pumpAndSettle();
}

/// Unmounts the app and disposes its container, so no query timer is left.
Future<void> _end(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  c.dispose();
  await t.pumpAndSettle();
  await t.pump(const Duration(milliseconds: 1));
}

AppLocalizations _l10n(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(PlaylistsPage)));

void main() {
  testWidgets('mobile shell: Back closes the FAB menu, then the filter, and '
      'the tab stays', (t) async {
    final c = await _pumpTab(t, width: 400);
    final l10n = _l10n(t);
    await t.tap(byIconButton(l10n.libraryFilter));
    await t.pump();
    await t.tap(find.byTooltip(l10n.playlistFabOpen));
    await _settle(t);
    expect(find.text(l10n.playlistFabImport), findsOneWidget);

    expect(await t.binding.handlePopRoute(), isTrue);
    await _settle(t);
    expect(find.text(l10n.playlistFabImport), findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    expect(await t.binding.handlePopRoute(), isTrue);
    await _settle(t);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(PlaylistsPage), findsOneWidget);
    await _end(t, c);
  });

  testWidgets('mobile shell: with the list filter open, opening a playlist '
      'and pressing Back leaves the page at once and keeps the filter', (
    t,
  ) async {
    final c = await _pumpTab(t, width: 400);
    final uid = (await t.runAsync(
      () => c.read(playlistStoreProvider).createPlaylist(name: 'Other'),
    ))!;
    await _settle(t);
    final l10n = _l10n(t);
    await t.tap(byIconButton(l10n.libraryFilter));
    await t.pump();
    await t.enterText(find.byType(TextField), 'oth');
    await _settle(t);
    GoRouter.of(t.element(find.byType(Scaffold).first))
        .push(LibraryLocations.playlist(uid));
    await _settle(t);
    expect(find.byType(PlaylistPage), findsOneWidget);

    expect(await t.binding.handlePopRoute(), isTrue);
    await _settle(t);
    expect(find.byType(PlaylistPage), findsNothing);
    expect(find.widgetWithText(TextField, 'oth'), findsOneWidget);
    await _end(t, c);
  });

  testWidgets('mobile shell: Back from a playlist just created from the FAB '
      'leaves it at once and keeps the list filter', (t) async {
    final c = await _pumpTab(t, width: 400);
    final l10n = _l10n(t);
    await t.tap(byIconButton(l10n.libraryFilter));
    await t.pump();
    await t.enterText(find.byType(TextField), 'sol');
    await _settle(t);
    await t.tap(find.byTooltip(l10n.playlistFabOpen));
    await _settle(t);
    await t.tap(find.text(l10n.playlistFabNew));
    await _settle(t);
    await t.enterText(find.byType(TextField).last, 'Fresh');
    await t.pump();
    await t.tap(find.text(l10n.playlistCreateConfirm));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await _settle(t);
    expect(find.byType(PlaylistPage), findsOneWidget);

    expect(await t.binding.handlePopRoute(), isTrue);
    await _settle(t);
    expect(find.byType(PlaylistPage), findsNothing);
    expect(find.widgetWithText(TextField, 'sol'), findsOneWidget);
    await _end(t, c);
  });

  testWidgets('desktop shell: Ctrl+N opens the dialog on the tab, not above '
      'a playlist page', (t) async {
    final c = await _pumpTab(t, width: 1280);
    final l10n = _l10n(t);
    final router = GoRouter.of(t.element(find.byType(Scaffold).first));
    router.go(LibraryLocations.playlist('favorites'));
    await _settle(t);
    await _ctrlN(t);
    await _settle(t);
    expect(find.text(l10n.playlistCreateTitle), findsNothing);

    router.go(LibraryLocations.playlists);
    await _settle(t);
    await _ctrlN(t);
    await _settle(t);
    expect(find.text(l10n.playlistCreateTitle), findsWidgets);
    await _end(t, c);
  });
}

Future<void> _ctrlN(WidgetTester t) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await t.sendKeyEvent(LogicalKeyboardKey.keyN);
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await t.pump();
}
