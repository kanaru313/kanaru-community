import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/playlists/playlist_page_controller.dart';
import 'package:kanaru/src/library/state/playlists/playlist_prefs_providers.dart';
import 'package:kanaru/src/library/ui/playlists/dialogs/playlist_confirm_flows.dart';
import 'package:kanaru/src/platform/domain/settings_store.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/memory_settings_store.dart';
import 'support/playlist_ui_harness.dart';

/// A page stand-in: shows "not found" when its playlist is gone (what a real
/// playlist page does) and starts the delete flow from its own route.
/// A page route that stays current and never completes (it does not leave).
class _StuckRoute extends PageRouteBuilder<void> {
  _StuckRoute({this.current = true})
    : super(pageBuilder: (_, _, _) => const SizedBox());

  final bool current;

  @override
  bool get isCurrent => current;

  @override
  Future<void> get completed => Completer<void>().future;
}

/// Settings whose writes can be made to fail.
class _FailingSettings extends MemorySettingsStore {
  bool failWrites = false;

  @override
  Future<void> write(String key, Object? value) => failWrites
      ? Future.error(StateError('disk full'))
      : super.write(key, value);
}

class _OwnPage extends ConsumerWidget {
  const _OwnPage(this.uid, this.summary, {this.blockPop = false});

  final String uid;
  final PlaylistSummary summary;

  /// A page that refuses to leave: its route never completes.
  final bool blockPop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playlistPageProvider(uid));
    final gone = !state.detail.isLoading && state.detail.value == null;
    return PopScope(
      canPop: !blockPop,
      child: Scaffold(
        body: Column(
          children: [
            Text(gone ? 'NOT FOUND' : 'OWN PAGE'),
            TextButton(
              onPressed: () => unawaited(
                deletePlaylistFlow(
                  context,
                  summary,
                  pageRoute: ModalRoute.of(context),
                ),
              ),
              child: const Text('delete here'),
            ),
          ],
        ),
      ),
    );
  }
}

Finder _confirmDelete(String label) => find.widgetWithText(FilledButton, label);

Future<PlaylistDetail> _favorites(
  WidgetTester t,
  PlaylistUiHarness h,
  int n,
) async {
  await t.runAsync(() async {
    final tracks = await h.fixture.tracks(n);
    await h.fixture.repo.addToPlaylists(
      tracks: tracks,
      playlistUids: [PlaylistUids.favorites],
    );
  });
  return (await t.runAsync(
    () => h.fixture.repo.loadPlaylist(PlaylistUids.favorites),
  ))!;
}

void main() {
  group('deletePlaylistFlow', () {
    uiTest('Cancel writes nothing', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final src = await seedPlaylist(t, h);
      unawaited(h.launch(t, (c) => deletePlaylistFlow(c, src)));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(h.store.deleteCalls, 0);
      expect(await storedPlaylists(t, h), hasLength(1));
    });

    uiTest('from a list: asks with name and count, deletes, toasts, forgets '
        'the sort', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await seedPlaylist(t, h, trackCount: 3);
      final sort = SortOrder([const SortSpec(SortCriterion.title)]);
      await t.runAsync(
        () => h.container
            .read(playlistTrackSortsProvider.notifier)
            .set(src.uid, sort),
      );
      expect(h.container.read(playlistTrackSortsProvider), contains(src.uid));

      unawaited(h.launch(t, (c) => deletePlaylistFlow(c, src)));
      await t.pumpAndSettle();
      expect(find.text(l10n.playlistDeleteTitle('Src')), findsOneWidget);
      expect(find.text(l10n.playlistDeleteBody(3)), findsOneWidget);
      await t.tap(_confirmDelete(l10n.playlistDeleteConfirm));
      await eventually(
        t,
        () => find.text(l10n.plScreensDeleted('Src')).evaluate().isNotEmpty,
        what: 'deleted toast',
      );
      expect(await storedPlaylists(t, h), isEmpty);
      expect(
        h.container.read(playlistTrackSortsProvider),
        isNot(contains(src.uid)),
      );
    });

    /// Opens the page of [src] (pushed or gone to) and starts its delete.
    Future<PlaylistUiHarness> openOwnPage(
      WidgetTester t, {
      required bool push,
      bool blockPop = false,
      SettingsStore? settings,
      void Function(PlaylistUiHarness h, PlaylistSummary src)? before,
    }) async {
      late PlaylistSummary src;
      final h = await PlaylistUiHarness.pump(
        t,
        settings: settings,
        pageBuilder: (context, uid) => _OwnPage(uid, src, blockPop: blockPop),
      );
      src = await seedPlaylist(t, h);
      before?.call(h, src);
      final path = '/playlists/${src.uid}';
      if (push) {
        unawaited(h.router.push(path));
      } else {
        h.router.go(path);
      }
      await eventually(
        t,
        () => find.text('OWN PAGE').evaluate().isNotEmpty,
        what: 'page loaded',
      );
      await t.pumpAndSettle();
      return h;
    }

    Future<void> confirmFromPage(WidgetTester t, PlaylistUiHarness h) async {
      await t.tap(find.text('delete here'));
      await t.pumpAndSettle();
      final l10n = AppLocalizations.of(t.element(find.byType(AlertDialog)));
      await t.tap(_confirmDelete(l10n.playlistDeleteConfirm));
      await t.pump();
    }

    uiTest('pushed page: deletes only after its exit animation completed, '
        'with no not-found frame', (t) async {
      final h = await openOwnPage(t, push: true);
      final l10n = h.l10n(t);
      final route = ModalRoute.of(t.element(find.text('OWN PAGE')))!;
      AnimationStatus? statusAtDelete;
      h.store.onDelete = () => statusAtDelete = route.animation?.status;

      await confirmFromPage(t, h);
      var frames = 0;
      while (find.text('OWN PAGE').evaluate().isNotEmpty && frames < 60) {
        expect(h.store.deleteCalls, 0, reason: 'deleted before the exit');
        expect(find.text('NOT FOUND'), findsNothing);
        await t.pump(const Duration(milliseconds: 16));
        frames++;
      }
      expect(frames, greaterThan(5), reason: 'there is an exit animation');
      expect(frames, lessThan(60), reason: 'page never left');
      await eventually(
        t,
        () => find.text(l10n.plScreensDeleted('Src')).evaluate().isNotEmpty,
        what: 'deleted toast',
      );
      expect(statusAtDelete, AnimationStatus.dismissed);
      expect(find.text('NOT FOUND'), findsNothing);
      expect(h.router.state.uri.path, '/');
      expect(await storedPlaylists(t, h), isEmpty);
    });

    uiTest('page replaced by go: the dispose ends the wait well before the '
        'bound', (t) async {
      final h = await openOwnPage(t, push: false);
      await confirmFromPage(t, h);
      var waited = Duration.zero;
      while (h.store.deleteCalls == 0 && waited < const Duration(seconds: 2)) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await t.pump(const Duration(milliseconds: 16));
        waited += const Duration(milliseconds: 16);
      }
      expect(h.store.deleteCalls, 1);
      expect(waited, lessThan(const Duration(milliseconds: 900)));
      expect(find.text('PLAYLISTS LIST'), findsOneWidget);
      expect(find.text('NOT FOUND'), findsNothing);
    });

    uiTest(
      'a route that never completes: the delete runs after the 1 s bound',
      (t) async {
        final h = await PlaylistUiHarness.pump(t);
        final l10n = h.l10n(t);
        final src = await seedPlaylist(t, h);
        unawaited(
          h.launch(
            t,
            (c) => deletePlaylistFlow(c, src, pageRoute: _StuckRoute()),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(_confirmDelete(l10n.playlistDeleteConfirm));
        await t.pump();
        await t.pump(const Duration(milliseconds: 900));
        expect(h.store.deleteCalls, 0, reason: 'bound not reached yet');
        await t.pump(const Duration(milliseconds: 200));
        await eventually(
          t,
          () => h.store.deleteCalls == 1,
          what: 'delete call',
        );
      },
    );

    uiTest('page no longer current after the confirm: nothing is popped, '
        'the delete still runs', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await seedPlaylist(t, h);
      unawaited(
        h.launch(
          t,
          (c) => deletePlaylistFlow(
            c,
            src,
            pageRoute: _StuckRoute(current: false),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(_confirmDelete(l10n.playlistDeleteConfirm));
      await eventually(
        t,
        () => find.text(l10n.plScreensDeleted('Src')).evaluate().isNotEmpty,
        what: 'deleted toast',
      );
      // Still on the host: no pop, no go to the list.
      expect(h.router.state.uri.path, '/');
      expect(find.text('PLAYLISTS LIST'), findsNothing);
    });

    uiTest('a failing sort cleanup after the delete only logs', (t) async {
      final settings = _FailingSettings();
      final h = await PlaylistUiHarness.pump(t, settings: settings);
      final l10n = h.l10n(t);
      final src = await seedPlaylist(t, h);
      await t.runAsync(
        () => h.container
            .read(playlistTrackSortsProvider.notifier)
            .set(src.uid, SortOrder([const SortSpec(SortCriterion.title)])),
      );
      settings.failWrites = true;
      unawaited(h.launch(t, (c) => deletePlaylistFlow(c, src)));
      await t.pumpAndSettle();
      await t.tap(_confirmDelete(l10n.playlistDeleteConfirm));
      await eventually(
        t,
        () => find.text(l10n.plScreensDeleted('Src')).evaluate().isNotEmpty,
        what: 'deleted toast',
      );
      expect(find.text(l10n.plScreensDeleteFailed), findsNothing);
      expect(await storedPlaylists(t, h), isEmpty);
    });

    uiTest('already gone: no toast, no failure', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await seedPlaylist(t, h);
      unawaited(h.launch(t, (c) => deletePlaylistFlow(c, src)));
      await t.pumpAndSettle();
      await t.runAsync(() => h.fixture.repo.deletePlaylist(src.uid));
      await t.tap(_confirmDelete(l10n.playlistDeleteConfirm));
      await eventually(t, () => h.store.deleteCalls == 1, what: 'delete call');
      await t.pump(const Duration(milliseconds: 50));
      expect(find.text(l10n.plScreensDeleted('Src')), findsNothing);
      expect(find.text(l10n.plScreensDeleteFailed), findsNothing);
    });

    uiTest('failure after leaving the page: toast on the list', (t) async {
      late PlaylistSummary src;
      final h = await PlaylistUiHarness.pump(
        t,
        pageBuilder: (context, uid) => _OwnPage(uid, src),
      );
      final l10n = h.l10n(t);
      src = await seedPlaylist(t, h);
      h.store.deleteError = StateError('locked');
      unawaited(h.router.push('/playlists/${src.uid}'));
      await eventually(
        t,
        () => find.text('OWN PAGE').evaluate().isNotEmpty,
        what: 'page loaded',
      );
      await t.pumpAndSettle();
      await t.tap(find.text('delete here'));
      await t.pumpAndSettle();
      await t.tap(_confirmDelete(l10n.playlistDeleteConfirm));
      await eventually(
        t,
        () => find.text(l10n.plScreensDeleteFailed).evaluate().isNotEmpty,
        what: 'failure toast',
      );
      expect(find.text('OWN PAGE'), findsNothing);
      expect(await storedPlaylists(t, h), hasLength(1));
    });
  });

  group('clearFavoritesFlow', () {
    uiTest('Cancel removes nothing', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final detail = await _favorites(t, h, 2);
      unawaited(h.launch(t, (c) => clearFavoritesFlow(c, detail)));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      final now = await t.runAsync(
        () => h.fixture.liveTracks(PlaylistUids.favorites),
      );
      expect(now, hasLength(2));
    });

    uiTest('elsewhere: removes all, Undo brings them back in order', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final detail = await _favorites(t, h, 3);
      final before = await t.runAsync(
        () => h.fixture.liveTracks(PlaylistUids.favorites),
      );
      unawaited(h.launch(t, (c) => clearFavoritesFlow(c, detail)));
      await t.pumpAndSettle();
      expect(find.text(l10n.playlistClearFavoritesBody(3)), findsOneWidget);
      await t.tap(_confirmDelete(l10n.playlistClearFavoritesConfirm));
      await eventually(
        t,
        () => find.text(l10n.playlistClearedFavorites).evaluate().isNotEmpty,
        what: 'cleared toast',
      );
      await eventuallyLive(
        t,
        h,
        PlaylistUids.favorites,
        (tracks) => tracks.isEmpty,
        what: 'Favorites emptied',
      );

      await tapUndo(t, l10n);
      final after = await eventuallyLive(
        t,
        h,
        PlaylistUids.favorites,
        (tracks) => tracks.isNotEmpty,
        what: 'entries restored',
      );
      expect(after, before);
      expect(h.store.committed, isEmpty);
    });

    uiTest('on the Favorites page: through the page, Undo restores 1000 '
        'songs; closing the toast commits', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final detail = await _favorites(t, h, 1000);
      final before = await t.runAsync(
        () => h.fixture.liveTracks(PlaylistUids.favorites),
      );
      // The page is open: its controller is alive and holds the state.
      final page = playlistPageProvider(PlaylistUids.favorites);
      final sub = h.container.listen(page, (_, _) {});
      await eventually(
        t,
        () => h.container.read(page).detail.value?.entries.length == 1000,
        what: 'page loaded',
      );

      unawaited(h.launch(t, (c) => clearFavoritesFlow(c, detail)));
      await t.pumpAndSettle();
      await t.tap(_confirmDelete(l10n.playlistClearFavoritesConfirm));
      await eventually(
        t,
        () => find.text(l10n.libraryMenuUndo).evaluate().isNotEmpty,
        what: 'undo toast',
      );
      // Optimistic: the page already shows it empty.
      expect(h.container.read(page).detail.value!.entries, isEmpty);

      await tapUndo(t, l10n);
      await eventually(
        t,
        () => h.container.read(page).detail.value?.entries.length == 1000,
        what: 'page restored',
      );
      expect(
        await t.runAsync(() => h.fixture.liveTracks(PlaylistUids.favorites)),
        before,
      );
      expect(h.store.committed, isEmpty);
      // The page closes: its throttled query leaves a timer to run out.
      sub.close();
      await t.pump(const Duration(seconds: 2));
    });

    uiTest('closing the toast untouched commits the removal', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final detail = await _favorites(t, h, 2);
      unawaited(h.launch(t, (c) => clearFavoritesFlow(c, detail)));
      await t.pumpAndSettle();
      await t.tap(_confirmDelete(l10n.playlistClearFavoritesConfirm));
      await eventually(
        t,
        () => find.text(l10n.playlistClearedFavorites).evaluate().isNotEmpty,
        what: 'cleared toast',
      );
      await t.pump(const Duration(seconds: 5));
      await eventually(
        t,
        () => h.store.committed.length == 1,
        what: 'commit after the toast closed',
      );
      expect(h.store.committed.single.entryUids, hasLength(2));
    });

    uiTest('a write failure toasts and leaves Favorites alone', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final detail = await _favorites(t, h, 2);
      h.store.removeError = StateError('locked');
      unawaited(h.launch(t, (c) => clearFavoritesFlow(c, detail)));
      await t.pumpAndSettle();
      await t.tap(_confirmDelete(l10n.playlistClearFavoritesConfirm));
      await eventually(
        t,
        () => find.text(l10n.playlistSaveFailed).evaluate().isNotEmpty,
        what: 'failure toast',
      );
      expect(
        await t.runAsync(() => h.fixture.liveTracks(PlaylistUids.favorites)),
        hasLength(2),
      );
    });

    uiTest('empty Favorites asks nothing', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final empty = (await t.runAsync(
        () => h.fixture.repo.loadPlaylist(PlaylistUids.favorites),
      ))!;
      await h.launch(t, (c) => clearFavoritesFlow(c, empty));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
