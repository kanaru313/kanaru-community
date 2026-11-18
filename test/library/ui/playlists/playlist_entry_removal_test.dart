import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_page_controller.dart';
import 'package:kanaru/src/library/ui/playlists/page/playlist_entry_removal.dart';
import 'package:kanaru/src/library/ui/playlists/playlist_removal_toasts.dart';
import 'package:kanaru/src/library/ui/playlists/page/playlist_row_shell.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'support/playlist_page_support.dart';
import 'support/playlist_ui_harness.dart'
    show PlaylistUiHarness, eventually, eventuallyLive, tapUndo;
import 'support/reorder_support.dart';

const _titles = ['Alpha', 'Bravo', 'Cello'];

/// Opens the page and enters edit mode.
Future<(PlaylistUiHarness, String)> _openEditing(
  WidgetTester t,
  List<String> titles, {
  double width = 360,
}) async {
  final (h, uid) = await openSeededPlaylist(t, titles, width: width);
  await t.tap(byAnyIconButton(pageL10n(t).plScreensEditList));
  await settlePlaylistPage(t);
  return (h, uid);
}

/// Swipes the row of [title] by [fraction] of its width (negative: left).
Future<void> _swipe(WidgetTester t, String title, double fraction) async {
  final width = t.getSize(tileOf(title).first).width;
  await t.drag(find.text(title), Offset(width * fraction, 0));
  await settlePlaylistPage(t);
}

/// Waits (bounded, real time) until [title] is no longer an entry of [uid].
Future<void> _untilGone(
  WidgetTester t,
  PlaylistUiHarness h,
  String uid,
  String title,
) => eventually(
  t,
  () =>
      !(shownDetail(h, uid)?.entries.any((e) => e.info.title == title) ??
          false),
  what: '$title to leave the page',
);

/// Title of the row that holds the keyboard focus, null when none does.
String? _focusedTitle() => FocusManager.instance.primaryFocus?.context
    ?.findAncestorWidgetOfExactType<SongTile>()
    ?.info
    .title;

/// A click on an edit row puts it in focus (it has no tap action).
/// The row's own focus node holds the focus (not a button inside it).
void _expectRowFocus(String title) {
  expect(_focusedTitle(), title);
  expect(FocusManager.instance.primaryFocus?.debugLabel, 'KMediaCard editing');
}

Future<void> _focusRow(WidgetTester t, String title) async {
  await t.tap(find.text(title));
  await t.pump();
}

Future<void> _pressDelete(WidgetTester t) async {
  await t.sendKeyEvent(LogicalKeyboardKey.delete);
  await settlePlaylistPage(t);
}

void main() {
  group('swipe in edit mode', () {
    for (final (name, fraction) in [('left', -0.85), ('right', 0.85)]) {
      pageTest('$name past 70 % removes the entry, with an Undo toast that '
          'puts it back in the same place', (t) async {
        final (h, uid) = await _openEditing(t, _titles);
        final l10n = pageL10n(t);
        await _swipe(t, 'Bravo', fraction);
        await _untilGone(t, h, uid, 'Bravo');
        await settlePlaylistPage(t);
        expect(find.text('Bravo'), findsNothing);
        expect(find.text(l10n.playlistRemovedEntry('Bravo')), findsOneWidget);
        await expectStoredOrder(t, h, uid, ['Alpha', 'Cello']);

        await tapUndo(t, l10n);
        await eventuallyLive(t, h, uid, (tracks) => tracks.length == 3);
        await settlePlaylistPage(t);
        await expectStoredOrder(t, h, uid, _titles);
        expect(rowOrder(t, _titles), _titles);
      });
    }

    pageTest('below 70 % and a fling leave the entry where it is', (t) async {
      final (h, uid) = await _openEditing(t, _titles);
      final width = t.getSize(tileOf('Bravo').first).width;
      await _swipe(t, 'Bravo', -0.4);
      await t.fling(find.text('Bravo'), Offset(-width * 0.4, 0), 4000);
      await settlePlaylistPage(t);
      expect(find.text('Bravo'), findsOneWidget);
      expect(
        find.text(pageL10n(t).playlistRemovedEntry('Bravo')),
        findsNothing,
      );
      await expectStoredOrder(t, h, uid, _titles);
    });

    pageTest('a failing write springs the row back and says so once', (
      t,
    ) async {
      final (h, uid) = await _openEditing(t, _titles);
      final l10n = pageL10n(t);
      h.store.removeError = StateError('disk full');
      await _swipe(t, 'Bravo', -0.85);
      await eventually(
        t,
        () => find.text(l10n.playlistSaveFailed).evaluate().isNotEmpty,
        what: 'the failure toast',
      );
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistSaveFailed), findsOneWidget);
      expect(find.text(l10n.playlistRemovedEntry('Bravo')), findsNothing);
      expect(find.text('Bravo'), findsOneWidget);
      await expectStoredOrder(t, h, uid, _titles);
    });

    pageTest('a slow write: the row is gone at once and stays gone', (t) async {
      final (h, uid) = await _openEditing(t, _titles);
      final l10n = pageL10n(t);
      final gate = h.store.removeGate = Completer<void>();
      await _swipe(t, 'Bravo', -0.85);
      expect(find.text('Bravo'), findsNothing);
      expect(find.text(l10n.playlistRemovedEntry('Bravo')), findsNothing);
      gate.complete();
      await _untilGone(t, h, uid, 'Bravo');
      await eventually(
        t,
        () =>
            find.text(l10n.playlistRemovedEntry('Bravo')).evaluate().isNotEmpty,
        what: 'the toast',
      );
      expect(find.text('Bravo'), findsNothing);
      await expectStoredOrder(t, h, uid, ['Alpha', 'Cello']);
    });
  });

  group('the ✕', () {
    pageTest('desktop: every edit row has one; it removes the entry', (
      t,
    ) async {
      final (h, uid) = await _openEditing(t, _titles, width: 1400);
      final l10n = pageL10n(t);
      final cross = find.descendant(
        of: find.byType(SongTile),
        matching: byIconButton(l10n.playlistMenuRemoveEntry),
      );
      expect(cross, findsNWidgets(3));
      await t.tap(
        find.descendant(
          of: tileOf('Bravo'),
          matching: byIconButton(l10n.playlistMenuRemoveEntry),
        ),
      );
      await settlePlaylistPage(t);
      await _untilGone(t, h, uid, 'Bravo');
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistRemovedEntry('Bravo')), findsOneWidget);
      await expectStoredOrder(t, h, uid, ['Alpha', 'Cello']);
    });

    pageTest('mobile: only a missing row has one; it removes that entry', (
      t,
    ) async {
      final (h, uid) = await _openEditing(t, ['Alpha', 'Gone*']);
      final l10n = pageL10n(t);
      final cross = find.descendant(
        of: find.byType(SongTile),
        matching: byIconButton(l10n.playlistMenuRemoveEntry),
      );
      expect(cross, findsOneWidget);
      expect(
        find.descendant(of: tileOf('Gone'), matching: cross),
        findsOneWidget,
      );
      await t.tap(cross);
      await settlePlaylistPage(t);
      await _untilGone(t, h, uid, 'Gone');
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistRemovedEntry('Gone')), findsOneWidget);
      await expectStoredOrder(t, h, uid, ['Alpha']);
    });

    pageTest('a double tap removes the entry once', (t) async {
      final (h, uid) = await _openEditing(t, _titles, width: 1400);
      final l10n = pageL10n(t);
      final cross = find.descendant(
        of: tileOf('Bravo'),
        matching: byIconButton(l10n.playlistMenuRemoveEntry),
      );
      await t.tap(cross);
      await t.tap(cross, warnIfMissed: false);
      await settlePlaylistPage(t);
      await _untilGone(t, h, uid, 'Bravo');
      await expectStoredOrder(t, h, uid, ['Alpha', 'Cello']);
    });
  });

  group('Delete on the focused row', () {
    pageTest('removes it and moves focus to the row that takes its place, '
        'again and again; the last one leaves edit mode', (t) async {
      final (h, uid) = await _openEditing(t, _titles, width: 1400);
      final l10n = pageL10n(t);
      await _focusRow(t, 'Bravo');
      expect(_focusedTitle(), 'Bravo');

      await _pressDelete(t);
      await _untilGone(t, h, uid, 'Bravo');
      await settlePlaylistPage(t);
      _expectRowFocus('Cello');

      await _pressDelete(t);
      await _untilGone(t, h, uid, 'Cello');
      await settlePlaylistPage(t);
      _expectRowFocus('Alpha');

      await _pressDelete(t);
      await _untilGone(t, h, uid, 'Alpha');
      await settlePlaylistPage(t);
      // Nothing left to edit: edit mode ends and focus stays on the page.
      expect(byAnyIconButton(l10n.plScreensEditDone), findsNothing);
      expect(_focusedTitle(), isNull);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'PlaylistPage');
      await eventually(
        t,
        () => h.store.committed.length == 2,
        what: 'each removal to commit its predecessor',
      );
    });

    pageTest('a held key removes one row', (t) async {
      final (h, uid) = await _openEditing(t, _titles, width: 1400);
      await _focusRow(t, 'Alpha');
      await t.sendKeyDownEvent(LogicalKeyboardKey.delete);
      await t.sendKeyRepeatEvent(LogicalKeyboardKey.delete);
      await t.sendKeyRepeatEvent(LogicalKeyboardKey.delete);
      await t.sendKeyUpEvent(LogicalKeyboardKey.delete);
      await settlePlaylistPage(t);
      await _untilGone(t, h, uid, 'Alpha');
      await expectStoredOrder(t, h, uid, ['Bravo', 'Cello']);
    });

    pageTest('does nothing outside edit mode', (t) async {
      final (h, uid) = await openSeededPlaylist(t, _titles, width: 1400);
      await _pressDelete(t);
      await expectStoredOrder(t, h, uid, _titles);
    });
  });

  group('failures of a keyboard removal', () {
    pageTest('a write that fails after the page was left throws nothing', (
      t,
    ) async {
      final (h, _) = await _openEditing(t, _titles, width: 1400);
      final gate = h.store.removeGate = Completer<void>();
      h.store.removeError = StateError('disk full');
      await _focusRow(t, 'Bravo');
      await t.sendKeyEvent(LogicalKeyboardKey.delete);
      await t.pump();
      h.router.go('/');
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      gate.complete();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
    });

    pageTest('two queued removals failing together: one toast, focus on the '
        'first failed row', (t) async {
      final (h, uid) = await _openEditing(t, _titles, width: 1400);
      final l10n = pageL10n(t);
      final gate = h.store.removeGate = Completer<void>();
      h.store.removeError = StateError('disk full');
      await _focusRow(t, 'Alpha');
      await t.sendKeyEvent(LogicalKeyboardKey.delete);
      await t.pump();
      await t.pump();
      _expectRowFocus('Bravo');
      await t.sendKeyEvent(LogicalKeyboardKey.delete);
      await t.pump();
      await t.pump();
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Bravo'), findsNothing);
      gate.complete();
      await eventually(
        t,
        () => find.text(l10n.playlistSaveFailed).evaluate().isNotEmpty,
        what: 'the failure toast',
      );
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistSaveFailed), findsOneWidget);
      expect(find.text(l10n.playlistRemovedEntry('Alpha')), findsNothing);
      expect(rowOrder(t, _titles), _titles);
      await expectStoredOrder(t, h, uid, _titles);
      _expectRowFocus('Alpha');
    });
  });

  group('undo', () {
    pageTest('a second removal commits the first', (t) async {
      final (h, uid) = await _openEditing(t, _titles);
      await _swipe(t, 'Alpha', -0.85);
      await _untilGone(t, h, uid, 'Alpha');
      await settlePlaylistPage(t);
      expect(h.store.committed, isEmpty);
      await _swipe(t, 'Bravo', 0.85);
      await _untilGone(t, h, uid, 'Bravo');
      await eventually(t, () => h.store.committed.length == 1, what: 'commit');
      expect(h.store.committed.single.entryUids, hasLength(1));
    });

    pageTest('after the page is left the toast still undoes (store path)', (
      t,
    ) async {
      final (h, uid) = await _openEditing(t, _titles);
      final l10n = pageL10n(t);
      // Short pumps only: the toast closes (and commits) after its duration.
      final width = t.getSize(tileOf('Bravo').first).width;
      await t.drag(find.text('Bravo'), Offset(-width * 0.85, 0));
      await _untilGone(t, h, uid, 'Bravo');
      await t.pump(const Duration(milliseconds: 300));
      h.router.go('/');
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Bravo'), findsNothing);
      expect(
        h.container.read(playlistPageProvider(uid).exists),
        isFalse,
        reason: 'the undo has to take the store path',
      );
      await tapUndo(t, l10n);
      await eventuallyLive(t, h, uid, (tracks) => tracks.length == 3);
      expect(find.text(l10n.libraryMenuUndoFailed), findsNothing);
    });

    pageTest('undoing a removal already committed says so', (t) async {
      final (h, uid) = await _openEditing(t, _titles);
      final l10n = pageL10n(t);
      await _swipe(t, 'Bravo', -0.85);
      await _untilGone(t, h, uid, 'Bravo');
      await settlePlaylistPage(t);
      // The toast's removal is committed behind its back (what its timeout
      // or the next removal does).
      await t.runAsync(
        () => h.container.read(playlistRemovalHolderProvider).commitPending(),
      );
      await eventually(t, () => h.store.committed.isNotEmpty, what: 'commit');
      await tapUndo(t, l10n);
      await eventually(
        t,
        () => find.text(l10n.libraryMenuUndoFailed).evaluate().isNotEmpty,
        what: 'the undo failure toast',
      );
    });
  });

  group('Favorites', () {
    pageTest('the swipe un-hearts the song; undo hearts it again, in place', (
      t,
    ) async {
      final h = await pumpPlaylistPage(t, uid: PlaylistUids.favorites);
      await seedFavorites(t, h, _titles);
      await settlePlaylistPage(t);
      final l10n = pageL10n(t);
      final bravo = shownDetail(
        h,
        PlaylistUids.favorites,
      )!.entries.singleWhere((e) => e.info.title == 'Bravo').info.id;
      // Nothing on the page watches the heart: keep the answer alive.
      final heart = h.container.listen(isFavoriteProvider(bravo), (_, _) {});
      addTearDown(heart.close);
      await eventually(t, () => heart.read(), what: 'Bravo to be a favorite');
      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      await _swipe(t, 'Bravo', -0.85);
      await eventually(t, () => !heart.read(), what: 'Bravo to be un-hearted');
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistRemovedFavorite('Bravo')), findsOneWidget);

      await tapUndo(t, l10n);
      await eventually(
        t,
        () => heart.read(),
        what: 'Bravo to be a favorite again',
      );
      await settlePlaylistPage(t);
      expect(rowOrder(t, _titles), _titles);
    });
  });

  group('the shell of a row', () {
    testWidgets('registers its focus node by entry and drops it on dispose', (
      t,
    ) async {
      final r = PlaylistEntryRemoval(
        context: () => t.element(find.byType(PlaylistRowShell)),
        uid: () => 'p',
        rows: () => const [],
        pageFocus: FocusNode(),
      );
      await t.pumpWidget(
        PlaylistRowShell(
          uid: 'e1',
          removal: r,
          child: const SizedBox(width: 10, height: 10),
        ),
      );
      expect(r.rowNodes.keys, ['e1']);
      await t.pumpWidget(const SizedBox());
      expect(r.rowNodes, isEmpty);
    });
  });
}
