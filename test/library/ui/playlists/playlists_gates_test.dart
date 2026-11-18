import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/playlists/list/playlist_card.dart';
import 'package:kanaru/src/library/ui/playlists/playlists_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'support/playlist_ui_harness.dart';
import 'support/playlists_page_support.dart';

void main() {
  pageTest('a page that is not shown starts no query; once shown it keeps '
      'its data', (t) async {
    final shown = ValueNotifier(false);
    addTearDown(shown.dispose);
    final h = await pumpPlaylistsPage(
      t,
      wrap: (page) => ValueListenableBuilder<bool>(
        valueListenable: shown,
        builder: (_, on, _) => TickerMode(enabled: on, child: page),
      ),
    );
    expect(find.byType(PlaylistsPage), findsOneWidget);
    expect(find.byType(Column), findsNothing, reason: 'nothing built yet');
    expect(h.store.watchCalls, 0);

    shown.value = true;
    await settlePage(t);
    expect(h.store.watchCalls, 1);
    expect(find.text(pageL10n(t).playlistsEmptyTitle), findsOneWidget);

    shown.value = false;
    await settlePage(t);
    expect(find.text(pageL10n(t).playlistsEmptyTitle), findsOneWidget);
    expect(h.store.watchCalls, 1);
  });

  pageTest('Ctrl+N does nothing while the page sits in a hidden tab', (
    t,
  ) async {
    final shown = ValueNotifier(true);
    addTearDown(shown.dispose);
    await pumpPlaylistsPage(
      t,
      width: 1400,
      asRoot: true,
      wrap: (page) => ValueListenableBuilder<bool>(
        valueListenable: shown,
        builder: (_, on, _) => TickerMode(enabled: on, child: page),
      ),
    );
    final l10n = pageL10n(t);
    shown.value = false;
    await settlePage(t);
    await pressCtrlN(t);
    await settlePage(t);
    expect(find.text(l10n.playlistCreateTitle), findsNothing);

    shown.value = true;
    await settlePage(t);
    await pressCtrlN(t);
    await settlePage(t);
    expect(find.text(l10n.playlistCreateTitle), findsWidgets);
  });

  pageTest('Ctrl+Shift+N is not "new playlist"', (t) async {
    await pumpPlaylistsPage(t, width: 1400, asRoot: true);
    await pressCtrlN(t, shift: true);
    await settlePage(t);
    expect(find.text(pageL10n(t).playlistCreateTitle), findsNothing);
  });

  pageTest('the filter goes with the last playlist; Back is not swallowed', (
    t,
  ) async {
    final h = await pumpPlaylistsPage(t, asRoot: true);
    await seedPlaylists(t, h, ['Solo']);
    final l10n = pageL10n(t);
    await t.tap(byIconButton(l10n.libraryFilter));
    await t.pump();
    expect(find.byType(TextField), findsOneWidget);

    final uid = (await storedPlaylists(t, h)).single.uid;
    await t.runAsync(() => h.fixture.repo.deletePlaylist(uid));
    await eventually(
      t,
      () => find.byType(PlaylistCard).evaluate().isEmpty,
      what: 'the playlist gone from the page',
    );
    await settlePage(t);
    expect(find.byType(TextField), findsNothing);
    expect(find.text(l10n.playlistsEmptyTitle), findsOneWidget);
    // No hidden field left to take the Back press.
    expect(await t.binding.handlePopRoute(), isFalse);
  });
}
