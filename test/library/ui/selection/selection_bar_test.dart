import 'package:drift/drift.dart' show Variable;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';
import 'package:kanaru/src/library/ui/selection/selection_bar.dart';
import 'package:kanaru/src/library/ui/selection/selection_row.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../browse/support/library_fixture.dart';
import '../menus/menu_pump.dart';
import '../support/library_harness.dart';
import '../support/ui_harness.dart';
import 'selection_support.dart';

Finder _button(String tooltip) => find.byTooltip(tooltip);

IconButton _iconButton(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(find.widgetWithIcon(IconButton, _icon(tooltip)));

// The panel icon behind a tooltip, for dimmed checks.
IconData _icon(String tooltip) => switch (tooltip) {
  'Edit info · Coming soon' => KIcons.edit,
  'Add to playlist… · Coming soon' => KIcons.playlistAdd,
  _ => throw ArgumentError(tooltip),
};

void main() {
  testWidgets('no panel without a selection, one with it', (tester) async {
    final h = await pumpSelection(tester);
    expect(find.byType(KSelectionPanel), findsNothing);
    final ids = await allIds(h);
    h.selection.addRange(ids.take(2));
    await tester.pump();
    expect(find.byType(KSelectionPanel), findsOneWidget);
    expect(find.text('2 songs'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the top row has every control, the unbuilt ones dimmed', (
    tester,
  ) async {
    final h = await pumpSelection(tester);
    h.selection.addRange((await allIds(h)).take(2));
    await tester.pump();
    for (final tooltip in [
      'Clear selection',
      'Play all selected',
      'Options for the selection',
      'Select all songs on this screen',
      'Show the selected songs',
    ]) {
      expect(_button(tooltip), findsOneWidget, reason: tooltip);
    }
    expect(_iconButton(tester, 'Edit info · Coming soon').onPressed, isNull);
    expect(
      _iconButton(tester, 'Add to playlist… · Coming soon').onPressed,
      isNull,
    );
    await unmountApp(tester);
  });

  testWidgets('play all replaces the queue with the selection in order', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await pumpSelection(tester, playback: playback);
    final ids = await allIds(h);
    h.selection
      ..toggle(ids[3])
      ..toggle(ids[0])
      ..toggle(ids[2]);
    await tester.pump();
    await tester.tap(_button('Play all selected'));
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.tracks, [ids[3], ids[0], ids[2]]);
    expect(call.startIndex, 0);
    expect(call.context.kind, PlayContextKind.selection);
    expect(call.context.label, '3 songs');
    // Playing does not touch the selection.
    expect(h.selected.ids, [ids[3], ids[0], ids[2]]);
    await unmountApp(tester);
  });

  testWidgets('play all with every selected song gone says so, plays nothing', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await pumpSelection(tester, playback: playback);
    final ids = (await allIds(h)).take(2).toList();
    h.selection.addRange(ids);
    await tester.pump();
    // Missing tracks are not visible any more: the same as gone.
    await h.db.customStatement(
      "UPDATE tracks SET status = 'missing', missing_since = 1 "
      'WHERE id IN (${ids.map((i) => i.value).join(',')})',
    );
    await tester.tap(_button('Play all selected'));
    await h.settle(tester, rounds: 3);
    expect(playback.calls, isEmpty);
    expect(
      find.text('The selected songs are no longer in the library'),
      findsOneWidget,
    );
    expect(h.selected.isEmpty, isTrue);
    await unmountApp(tester);
  });

  testWidgets('clear empties the selection and the panel goes', (tester) async {
    final h = await pumpSelection(tester);
    h.selection.addRange((await allIds(h)).take(3));
    await tester.pump();
    await tester.tap(_button('Clear selection'));
    await tester.pump();
    expect(h.selected.isEmpty, isTrue);
    expect(find.byType(KSelectionPanel), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('open: the selected songs in order, with the length', (
    tester,
  ) async {
    final h = await pumpSelection(tester);
    final ids = await allIds(h);
    h.selection
      ..toggle(ids[4])
      ..toggle(ids[1]);
    await tester.pump();
    await tester.tap(_button('Show the selected songs'));
    await h.settle(tester, rounds: 3);
    expect(find.byType(SelectedSongRow), findsNWidgets(2));
    final titles = [
      for (final r in tester.widgetList<SelectedSongRow>(
        find.byType(SelectedSongRow),
      ))
        r.info.title,
    ];
    expect(titles, ['Album 2 2', 'Album 1 2']);
    // Two songs of a minute each.
    expect(find.text('2 min'), findsOneWidget);
    expect(_button('Collapse'), findsOneWidget);
    await tester.tap(_button('Collapse'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SelectedSongRow), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a row drag changes the play order', (tester) async {
    final h = await pumpSelection(tester);
    final ids = await allIds(h);
    h.selection.addRange(ids.take(3));
    h.selection.setExpanded(true);
    await h.settle(tester, rounds: 3);
    await tester.drag(
      find.byIcon(KIcons.dragHandle).first,
      const Offset(0, 140),
    );
    await tester.pumpAndSettle();
    expect(h.selected.ids.first, isNot(ids[0]));
    expect(h.selected.ids.toSet(), ids.take(3).toSet());
    await unmountApp(tester);
  });

  testWidgets('a panel row drag handle is at least the minimum target', (
    tester,
  ) async {
    final h = await pumpSelection(tester);
    final ids = await allIds(h);
    h.selection.addRange(ids.take(2));
    h.selection.setExpanded(true);
    await h.settle(tester, rounds: 3);
    final size = tester.getSize(
      find
          .ancestor(
            of: find.byIcon(KIcons.dragHandle).first,
            matching: find.byType(ReorderableDragStartListener),
          )
          .first,
    );
    expect(size.width, greaterThanOrEqualTo(KLayout.minTarget));
    expect(size.height, greaterThanOrEqualTo(KLayout.minTarget));
    await unmountApp(tester);
  });

  testWidgets('a panel row: handle left of the always-visible menu button', (
    tester,
  ) async {
    final h = await pumpSelection(tester);
    final ids = await allIds(h);
    h.selection.addRange(ids.take(2));
    h.selection.setExpanded(true);
    await h.settle(tester, rounds: 3);
    final row = find.byType(SelectedSongRow).first;
    final handle = find.descendant(
      of: row,
      matching: find.byIcon(KIcons.dragHandle),
    );
    final more = find.descendant(
      of: row,
      matching: find.byIcon(KIcons.moreVert),
    );
    expect(tester.getCenter(handle).dx, lessThan(tester.getCenter(more).dx));
    final card = tester.widget<KMediaCard>(
      find.descendant(of: row, matching: find.byType(KMediaCard)),
    );
    expect(card.accessory, isNotNull);
    expect(card.trailing, isNotNull);
    // No hover: the button opens the menu all the same.
    await tester.tap(more);
    await pumpMenu(tester);
    expect(find.text('Deselect'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a song menu from a panel row can deselect the song', (
    tester,
  ) async {
    final h = await pumpSelection(tester);
    final ids = await allIds(h);
    h.selection.addRange(ids.take(2));
    h.selection.setExpanded(true);
    await h.settle(tester, rounds: 3);
    await tester.tap(
      find.descendant(
        of: find.byType(SelectedSongRow).first,
        matching: find.byIcon(KIcons.moreVert),
      ),
    );
    await pumpMenu(tester);
    await tester.tap(find.text('Deselect'));
    await pumpMenu(tester);
    expect(h.selected.ids, [ids[1]]);
    await unmountApp(tester);
  });

  testWidgets('the last song removed hides the panel', (tester) async {
    final h = await pumpSelection(tester);
    final ids = await allIds(h);
    h.selection.toggle(ids[0]);
    await tester.pump();
    h.selection.remove(ids[0]);
    await tester.pump();
    expect(find.byType(KSelectionPanel), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('select all takes the songs of this screen; off without a list', (
    tester,
  ) async {
    final h = await pumpSelection(tester);
    final ids = await allIds(h);
    h.selection.toggle(ids[0]);
    await tester.pump();
    await tester.tap(_button('Select all songs on this screen'));
    await tester.pump();
    expect(h.selected.ids.toSet(), ids.toSet());
    // The first song keeps its place at the front.
    expect(h.selected.ids.first, ids[0]);

    h.router.go('/library/albums');
    await h.settle(tester);
    expect(h.container.read(activeTrackListProvider), isNull);
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, KIcons.selectAll),
    );
    expect(button.onPressed, isNull);
    await unmountApp(tester);
  });

  Future<void> hide(LibraryHarness h, TrackId id) => h.db.customUpdate(
    'UPDATE tracks SET status = ?, missing_since = 1 WHERE id = ?',
    variables: [const Variable('missing'), Variable(id.value)],
    updates: {h.db.tracks},
  );

  testWidgets('tracks that vanish leave the selection without a toggle', (
    tester,
  ) async {
    final h = await pumpSelection(tester);
    final ids = await allIds(h);
    h.selection.addRange(ids.take(3));
    await pumpSummary(tester, h);
    await hide(h, ids[1]);
    await h.settle(tester, rounds: 12);
    expect(h.selected.ids, [ids[0], ids[2]]);
    await unmountApp(tester);
  });

  testWidgets('play all never plays a track that left the library', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await pumpSelection(tester, playback: playback);
    final ids = await allIds(h);
    h.selection.addRange(ids.take(3));
    await pumpSummary(tester, h);
    await hide(h, ids[1]);
    // No time for the panel to notice: the button checks for itself.
    await tester.tap(_button('Play all selected'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.tracks, [ids[0], ids[2]]);
    expect(call.context.label, '2 songs');
    expect(h.selected.ids, [ids[0], ids[2]]);
    await unmountApp(tester);
  });

  testWidgets('the selection menu opens from the panel', (tester) async {
    final h = await pumpSelection(tester);
    h.selection.addRange((await allIds(h)).take(3));
    await tester.pump();
    await tester.tap(_button('Options for the selection'));
    await pumpMenu(tester);
    expect(find.text('3 songs selected'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('select all of 20k then one toggle reads no 20k rows', (
    tester,
  ) async {
    final loads = <int>[];
    final durationReads = <int>[];
    final h = await pumpLibrary(
      tester,
      selectionBar: const LibrarySelectionBar(),
      overrides: [
        trackRowLoaderProvider.overrideWithValue((ids) async {
          loads.add(ids.length);
          return const [];
        }),
        selectionDurationReaderProvider.overrideWithValue((db, ids) async {
          durationReads.add(ids.length);
          return (durationMs: 0, absent: <TrackId>[]);
        }),
      ],
    );
    final ids = [for (var i = 1; i <= 20000; i++) TrackId(i)];
    // The way the app does it: a list on screen registers its ids and the
    // panel's button adds them all.
    h.container.read(activeTrackListProvider.notifier).set(ids);
    h.selection.toggle(TrackId(20001));
    await tester.pump();
    await tester.tap(_button('Select all songs on this screen'));
    await tester.pump();
    expect(h.selected.ids, hasLength(20001));
    h.selection.toggle(TrackId(20001));
    await pumpSummary(tester, h);
    // Collapsed: no row at all; only the length is read, for the list.
    expect(loads, isEmpty);
    expect(durationReads, isNotEmpty);
    h.selection.setExpanded(true);
    await h.settle(tester, rounds: 2);
    // Open: only the rows in view, a page at a time.
    expect(loads, isNotEmpty);
    expect(loads.every((n) => n <= 100), isTrue, reason: '$loads');
    expect(find.byType(SongTile), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('scrolling the open panel past the first page reads the rows', (
    tester,
  ) async {
    final h = await pumpSelection(tester, albums: 0);
    for (var i = 0; i < 250; i++) {
      await addLibraryTrack(
        h.db,
        source: h.sourceId,
        locator: 's${i.toString().padLeft(4, '0')}.flac',
        title: 'Song ${i.toString().padLeft(4, '0')}',
      );
    }
    await h.settle(tester);
    final ids = await allIds(h);
    h.selection.addRange(ids);
    h.selection.setExpanded(true);
    await h.settle(tester, rounds: 3);
    Finder inPanel(String title) => find.descendant(
      of: find.byType(KSelectionPanel),
      matching: find.text(title),
    );
    expect(inPanel('Song 0000'), findsOneWidget);
    final list = find.descendant(
      of: find.byType(KSelectionPanel),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(list.first).position;
    final extent = KMediaCard.extentOf(TextScaler.noScaling);
    // Row 150 is in the second page, never in view when the panel opened.
    position.jumpTo(150 * extent);
    await h.settle(tester, rounds: 3);
    expect(inPanel('Song 0150'), findsOneWidget);
    final row = find.ancestor(
      of: inPanel('Song 0150'),
      matching: find.byType(SelectedSongRow),
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(KIcons.dragHandle)),
      findsOneWidget,
    );
    await unmountApp(tester);
  });
}
