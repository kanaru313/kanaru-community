import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_store.dart';
import 'package:kanaru/src/library/state/playlists/playlist_page_controller.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/ui/playlists/playlist_removal_toasts.dart';

import 'support/playlist_ui_harness.dart';

/// Records what is committed; can be told to fail.
class _CommitLog implements PlaylistStore {
  final committed = <PlaylistRemoval>[];
  Object? error;

  @override
  Future<void> commitRemoval(PlaylistRemoval removal) async {
    committed.add(removal);
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PlaylistRemoval _removal(int at, {String playlist = 'p'}) =>
    PlaylistRemoval(playlistUid: playlist, entryUids: ['e$at'], removedAt: at);

void main() {
  group('PlaylistRemovalHolder', () {
    late _CommitLog store;
    late PlaylistRemovalHolder holder;

    setUp(() {
      store = _CommitLog();
      holder = PlaylistRemovalHolder(store);
    });

    test('commit is idempotent per removal', () async {
      final a = _removal(1);
      holder.hold(a);
      unawaited(holder.commit(a));
      unawaited(holder.commit(a));
      await pumpEventQueue();
      expect(store.committed, [a]);
    });

    test('a new removal commits the previous one first', () async {
      final a = _removal(1);
      final b = _removal(2);
      holder.hold(a);
      holder.hold(b);
      await pumpEventQueue();
      expect(store.committed, [a]);
      // The replaced toast closing later changes nothing.
      unawaited(holder.commit(a));
      await pumpEventQueue();
      expect(store.committed, [a]);
      unawaited(holder.commit(b));
      await pumpEventQueue();
      expect(store.committed, [a, b]);
    });

    test('a cancelled removal is never committed', () async {
      final a = _removal(1);
      holder.hold(a);
      holder.cancel(a);
      unawaited(holder.commit(a));
      unawaited(holder.commitPending());
      await pumpEventQueue();
      expect(store.committed, isEmpty);
    });

    test('commitPending commits what waits, and nothing when idle', () async {
      unawaited(holder.commitPending());
      await pumpEventQueue();
      expect(store.committed, isEmpty);
      final a = _removal(1);
      holder.hold(a);
      unawaited(holder.commitPending());
      await pumpEventQueue();
      expect(store.committed, [a]);
    });

    test(
      'a failing commit is swallowed and the holder keeps working',
      () async {
        store.error = StateError('db closed');
        final a = _removal(1);
        final b = _removal(2);
        holder.hold(a);
        Object? escaped;
        runZonedGuarded(
          () => unawaited(holder.commit(a)),
          (e, _) => escaped = e,
        );
        await pumpEventQueue();
        expect(escaped, isNull);
        store.error = null;
        holder.hold(b);
        unawaited(holder.commit(b));
        await pumpEventQueue();
        expect(store.committed, [a, b]);
      },
    );

    test(
      'the provider commits the pending removal when the app ends',
      () async {
        final container = ProviderContainer(
          overrides: [playlistStoreProvider.overrideWithValue(store)],
        );
        final a = _removal(1);
        container.read(playlistRemovalHolderProvider).hold(a);
        container.dispose();
        await pumpEventQueue();
        expect(store.committed, [a]);
      },
    );
  });

  group('showRemovalToast', () {
    /// Tombstoned rows left in the table (what a commit deletes).
    Future<int> tombstones(WidgetTester t, PlaylistUiHarness h) async {
      final rows = await t.runAsync(
        () => h.fixture.db
            .customSelect(
              'SELECT COUNT(*) AS n FROM playlist_entries '
              'WHERE deleted_at IS NOT NULL',
            )
            .getSingle(),
      );
      return rows!.read<int>('n');
    }

    /// A playlist of [n] songs, then its first [removed] entries removed.
    Future<(PlaylistSummary, PlaylistRemoval)> removedFrom(
      WidgetTester t,
      PlaylistUiHarness h, {
      int n = 3,
      int removed = 2,
      String name = 'Src',
    }) async {
      final src = await seedPlaylist(t, h, name: name, trackCount: n);
      final live = (await t.runAsync(() => h.fixture.live(src.uid)))!;
      final removal = (await t.runAsync(
        () => h.fixture.repo.removeEntries(src.uid, [
          for (final e in live.take(removed)) e.uid,
        ]),
      ))!;
      return (src, removal);
    }

    uiTest('Undo brings the entries back and nothing is committed', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final (src, removal) = await removedFrom(t, h);
      showRemovalToast(h.hostContext(t), h.container, removal, 'Removed 2');
      await t.pump();
      expect(find.text('Removed 2'), findsOneWidget);
      await eventuallyLive(
        t,
        h,
        src.uid,
        (v) => v.length == 1,
        what: 'removed',
      );

      await tapUndo(t, l10n);
      await eventuallyLive(t, h, src.uid, (v) => v.length == 3, what: 'undone');
      await t.pump(const Duration(seconds: 5));
      expect(h.store.committed, isEmpty);
      expect(await tombstones(t, h), 0);
    });

    uiTest('closing the toast untouched commits: tombstones go', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final (_, removal) = await removedFrom(t, h);
      expect(await tombstones(t, h), 2);
      showRemovalToast(h.hostContext(t), h.container, removal, 'Removed 2');
      await t.pump();
      await t.pump(const Duration(seconds: 5));
      await eventually(t, () => h.store.committed.length == 1, what: 'commit');
      await eventually(t, () => true);
      expect(await tombstones(t, h), 0);
    });

    uiTest('a second toast commits the first removal at once', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final (_, first) = await removedFrom(t, h, name: 'A');
      final (_, second) = await removedFrom(t, h, name: 'B');
      showRemovalToast(h.hostContext(t), h.container, first, 'first');
      await t.pump();
      showRemovalToast(h.hostContext(t), h.container, second, 'second');
      await t.pump();
      await eventually(
        t,
        () => h.store.committed.contains(first),
        what: 'first committed',
      );
      expect(h.store.committed, isNot(contains(second)));
      // The second one is still undoable.
      await tapUndo(t, l10n);
      await t.pump(const Duration(seconds: 5));
      expect(h.store.committed, isNot(contains(second)));
    });

    uiTest('Undo after the removal was committed says it failed', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final (src, removal) = await removedFrom(t, h);
      showRemovalToast(h.hostContext(t), h.container, removal, 'Removed 2');
      await t.pump();
      await t.pump(const Duration(seconds: 5));
      await eventually(t, () => h.store.committed.length == 1, what: 'commit');
      // A stale removal shown again: its tombstones no longer exist.
      showRemovalToast(h.hostContext(t), h.container, removal, 'stale');
      await t.pump();
      await tapUndo(t, l10n);
      await eventually(
        t,
        () => find.text(l10n.libraryMenuUndoFailed).evaluate().isNotEmpty,
        what: 'undo failed toast',
      );
      expect((await t.runAsync(() => h.fixture.live(src.uid)))!, hasLength(1));
    });

    uiTest('Undo that throws says it failed', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final (_, removal) = await removedFrom(t, h);
      h.store.undoError = StateError('db locked');
      showRemovalToast(h.hostContext(t), h.container, removal, 'Removed 2');
      await t.pump();
      await tapUndo(t, l10n);
      await eventually(
        t,
        () => find.text(l10n.libraryMenuUndoFailed).evaluate().isNotEmpty,
        what: 'undo failed toast',
      );
    });

    uiTest('Undo queued behind a blocked write on the open page finishes '
        'after the page closed', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await seedPlaylist(t, h, trackCount: 4);
      final page = playlistPageProvider(src.uid);
      final sub = h.container.listen(page, (_, _) {});
      await eventually(
        t,
        () => h.container.read(page).detail.value?.entries.length == 4,
        what: 'page loaded',
      );
      final uids = [
        for (final e in h.container.read(page).detail.value!.entries) e.uid,
      ];
      final removal = (await t.runAsync(
        () => h.container.read(page.notifier).remove(uids.take(2).toList()),
      ))!;
      showRemovalToast(h.hostContext(t), h.container, removal, 'Removed 2');
      await t.pump();

      // A later write waits in the page's queue (its store call is blocked);
      // the undo queues behind it and the page closes before it runs.
      h.store.removeGate = Completer<void>();
      unawaited(h.container.read(page.notifier).remove([uids[2]]));
      await eventually(
        t,
        () => h.container.read(page).busy,
        what: 'blocked write queued',
      );
      await tapUndo(t, l10n);
      sub.close();
      await t.pump(const Duration(milliseconds: 50));
      h.store.removeGate!.complete();
      final live = await eventuallyLive(
        t,
        h,
        src.uid,
        (v) => v.length == 3,
        what: 'undo applied after the blocked write',
      );
      expect(live, hasLength(3));
      expect(find.text(l10n.libraryMenuUndoFailed), findsNothing);
      await t.pump(const Duration(seconds: 5));
    });
  });
}
