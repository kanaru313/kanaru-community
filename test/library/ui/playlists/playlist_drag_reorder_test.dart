import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/icon_button_finders.dart';
import 'support/playlist_page_support.dart';
import 'support/playlist_ui_harness.dart'
    show PlaylistUiHarness, canTap, eventually;
import 'support/reorder_support.dart';

const _all = ['Alpha', 'Bravo', 'Cello', 'Delta'];

Future<(PlaylistUiHarness, String)> _edit(
  WidgetTester t, {
  List<String> titles = _all,
}) async {
  final (h, uid) = await openSeededPlaylist(t, titles);
  await t.tap(byAnyIconButton(pageL10n(t).plScreensEditList));
  await settlePlaylistPage(t);
  return (h, uid);
}

List<String> _dataOrder(PlaylistUiHarness h, String uid) => [
  for (final e in shownDetail(h, uid)!.entries) e.info.title,
];

/// A move done behind the page's back (another writer): the stored detail
/// changes and the page's data follows (real time).
Future<void> _moveBehind(
  WidgetTester t,
  PlaylistUiHarness h,
  String uid,
  String title,
  String? afterTitle,
) async {
  final before = _dataOrder(h, uid).join(',');
  final names = {
    for (final e in shownDetail(h, uid)!.entries) e.info.title: e.uid,
  };
  await t.runAsync(
    () => h.store.moveEntry(
      uid,
      names[title]!,
      afterEntryUid: afterTitle == null ? null : names[afterTitle],
    ),
  );
  await eventually(
    t,
    () => _dataOrder(h, uid).join(',') != before,
    what: 'the page to take the stored move',
  );
}

double _dy(WidgetTester t, String title) => t.getTopLeft(find.text(title)).dy;

void main() {
  late String label;

  pageTest('dragging a handle down one row writes the new order', (t) async {
    final (h, uid) = await _edit(t);
    label = pageL10n(t).playlistDragHandle;
    final g = await dragHandle(t, 'Alpha', label, 1.2);
    await release(t, g);
    await settlePlaylistPage(t);
    expect(rowOrder(t, _all), ['Bravo', 'Alpha', 'Cello', 'Delta']);
    await expectStoredOrder(t, h, uid, ['Bravo', 'Alpha', 'Cello', 'Delta']);
  });

  pageTest('dragging up to the top and down to the end', (t) async {
    final (h, uid) = await _edit(t);
    label = pageL10n(t).playlistDragHandle;
    var g = await dragHandle(t, 'Cello', label, -2.2);
    await release(t, g);
    await settlePlaylistPage(t);
    await expectStoredOrder(t, h, uid, ['Cello', 'Alpha', 'Bravo', 'Delta']);
    g = await dragHandle(t, 'Cello', label, 3.2);
    await release(t, g);
    await settlePlaylistPage(t);
    await expectStoredOrder(t, h, uid, ['Alpha', 'Bravo', 'Delta', 'Cello']);
    expect(rowOrder(t, _all), ['Alpha', 'Bravo', 'Delta', 'Cello']);
  });

  pageTest('a missing row is a row: dragging over it lands behind it', (
    t,
  ) async {
    final names = ['Alpha', 'Gone', 'Cello'];
    final (h, uid) = await _edit(t, titles: ['Alpha', 'Gone*', 'Cello']);
    label = pageL10n(t).playlistDragHandle;
    final g = await dragHandle(t, 'Alpha', label, 1.2);
    await release(t, g);
    await settlePlaylistPage(t);
    await expectStoredOrder(t, h, uid, ['Gone', 'Alpha', 'Cello']);
    expect(rowOrder(t, names), ['Gone', 'Alpha', 'Cello']);
  });

  pageTest('a saved emission during the drag does not swap the rows; the drop '
      'uses the order the drag began with', (t) async {
    final (h, uid) = await _edit(t);
    label = pageL10n(t).playlistDragHandle;
    final g = await dragHandle(t, 'Alpha', label, 1.2);
    await _moveBehind(t, h, uid, 'Delta', null);
    await t.pump(const Duration(milliseconds: 50));
    expect(_dy(t, 'Bravo'), lessThan(_dy(t, 'Cello')));
    expect(_dy(t, 'Cello'), lessThan(_dy(t, 'Delta')), reason: 'still frozen');
    await release(t, g);
    await settlePlaylistPage(t);
    // Alpha went behind Bravo in the frozen order; Delta was first.
    await expectStoredOrder(t, h, uid, ['Delta', 'Bravo', 'Alpha', 'Cello']);
    expect(rowOrder(t, _all), ['Delta', 'Bravo', 'Alpha', 'Cello']);
  });

  pageTest('an emission during the drop animation does not swap the rows '
      'either', (t) async {
    final (h, uid) = await _edit(t);
    label = pageL10n(t).playlistDragHandle;
    final g = await dragHandle(t, 'Alpha', label, 1.2);
    await g.up();
    await t.pump(const Duration(milliseconds: 60));
    await _moveBehind(t, h, uid, 'Delta', null);
    await t.pump(const Duration(milliseconds: 20));
    expect(_dy(t, 'Cello'), lessThan(_dy(t, 'Delta')), reason: 'still frozen');
    await t.pump(const Duration(milliseconds: 400));
    await settlePlaylistPage(t);
    await expectStoredOrder(t, h, uid, ['Delta', 'Bravo', 'Alpha', 'Cello']);
  });

  pageTest('the dropped row never flashes back: the frame after the drop '
      'already shows the new order', (t) async {
    final (h, uid) = await _edit(t);
    label = pageL10n(t).playlistDragHandle;
    // The write is held: only the page's own optimistic order can show it.
    final gate = Completer<void>();
    h.store.moveGate = gate;
    final g = await dragHandle(t, 'Alpha', label, 1.2);
    await g.up();
    await t.pump(const Duration(milliseconds: 260));
    await t.pump();
    expect(rowOrder(t, _all), ['Bravo', 'Alpha', 'Cello', 'Delta']);
    await t.pump(const Duration(milliseconds: 100));
    expect(rowOrder(t, _all), ['Bravo', 'Alpha', 'Cello', 'Delta']);
    gate.complete();
    await settlePlaylistPage(t);
    await expectStoredOrder(t, h, uid, ['Bravo', 'Alpha', 'Cello', 'Delta']);
  });

  pageTest('a drop back in place and a cancelled drag unfreeze through the '
      'grace timer', (t) async {
    final (h, uid) = await _edit(t);
    final l10n = pageL10n(t);
    label = l10n.playlistDragHandle;

    // Back in place: no list callback follows the drop.
    var g = await dragHandle(t, 'Alpha', label, 1.2);
    await g.moveBy(Offset(0, -1.2 * t.getSize(tileOf('Alpha').first).height));
    await t.pump(const Duration(milliseconds: 50));
    await _moveBehind(t, h, uid, 'Delta', null);
    await g.up();
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 200));
    await settlePlaylistPage(t);
    expect(rowOrder(t, _all), ['Delta', 'Alpha', 'Bravo', 'Cello']);

    // Cancelled drag.
    g = await dragHandle(t, 'Alpha', label, 1.2);
    await _moveBehind(t, h, uid, 'Delta', 'Cello');
    await g.cancel();
    await t.pump(const Duration(milliseconds: 200));
    await t.pump(const Duration(milliseconds: 300));
    await settlePlaylistPage(t);
    expect(rowOrder(t, _all), ['Alpha', 'Bravo', 'Cello', 'Delta']);
    await expectStoredOrder(t, h, uid, ['Alpha', 'Bravo', 'Cello', 'Delta']);
  });

  pageTest('the toggle waits while a row is dragged', (t) async {
    final semantics = t.ensureSemantics();
    final (h, uid) = await _edit(t);
    final l10n = pageL10n(t);
    label = l10n.playlistDragHandle;
    final done = byAnyIconButton(l10n.plScreensEditDone);
    expect(canTap(t, done), isTrue);
    final g = await dragHandle(t, 'Alpha', label, 1.2);
    await t.pump();
    expect(canTap(t, done), isFalse);
    await release(t, g);
    await settlePlaylistPage(t);
    expect(canTap(t, done), isTrue);
    await expectStoredOrder(t, h, uid, ['Bravo', 'Alpha', 'Cello', 'Delta']);
    semantics.dispose();
  });

  pageTest('a failed move says so once and the saved order is back', (t) async {
    final (h, uid) = await _edit(t);
    final l10n = pageL10n(t);
    label = l10n.playlistDragHandle;
    h.store.moveError = StateError('disk');
    final g = await dragHandle(t, 'Alpha', label, 1.2);
    await release(t, g);
    await settlePlaylistPage(t);
    expect(find.text(l10n.playlistSaveFailed), findsOneWidget);
    expect(rowOrder(t, _all), _all);
    await expectStoredOrder(t, h, uid, _all);
  });

  pageTest('a second finger lifting mid-drag does not release the freeze, and '
      'the drop moves the dragged row', (t) async {
    final semantics = t.ensureSemantics();
    final (h, uid) = await _edit(t);
    final l10n = pageL10n(t);
    label = l10n.playlistDragHandle;
    final g = await dragHandle(t, 'Alpha', label, 1.2);
    // A palm: another finger touches a row and lifts.
    final other = await t.startGesture(t.getCenter(find.text('Delta')));
    await other.up();
    await t.pump(const Duration(milliseconds: 500));
    await _moveBehind(t, h, uid, 'Delta', null);
    await t.pump(const Duration(milliseconds: 500));
    expect(canTap(t, byAnyIconButton(l10n.plScreensEditDone)), isFalse);
    expect(_dy(t, 'Cello'), lessThan(_dy(t, 'Delta')), reason: 'still frozen');
    await release(t, g);
    await settlePlaylistPage(t);
    await expectStoredOrder(t, h, uid, ['Delta', 'Bravo', 'Alpha', 'Cello']);
    semantics.dispose();
  });

  pageTest('Esc and Back wait for a drag in progress', (t) async {
    final (h, uid) = await openSeededPlaylist(t, _all);
    h.router.go('/playlists/$uid');
    await settlePlaylistPage(t);
    final l10n = pageL10n(t);
    label = l10n.playlistDragHandle;
    await t.tap(byAnyIconButton(l10n.plScreensEditList));
    await settlePlaylistPage(t);
    final g = await dragHandle(t, 'Alpha', label, 1.2);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.binding.handlePopRoute();
    await t.pump();
    expect(byAnyIconButton(l10n.plScreensEditDone), findsOneWidget);
    await release(t, g);
    await settlePlaylistPage(t);
    await expectStoredOrder(t, h, uid, ['Bravo', 'Alpha', 'Cello', 'Delta']);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settlePlaylistPage(t);
    expect(byAnyIconButton(l10n.plScreensEditList), findsOneWidget);
  });
}
