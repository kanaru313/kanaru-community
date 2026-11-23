import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/ui/songs/song_grid_card.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../support/fake_playback_commands.dart';
import '../../support/icon_button_finders.dart';
import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Future<List<int>> _addSongs(LibraryHarness h, List<String> titles) async => [
  for (final t in titles)
    await addLibraryTrack(
      h.db,
      source: h.sourceId,
      locator: '$t.flac',
      title: t,
      artists: ['Artist $t'],
      album: 'Album $t',
      year: 2020,
      durationMs: 185000,
    ),
];

Future<(LibraryHarness, List<int>)> _pumpGrid(
  WidgetTester tester, {
  FakePlaybackCommands? playback,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/songs',
    playback: playback,
  );
  final ids = await _addSongs(h, ['Charlie', 'Alpha', 'Bravo']);
  await h.settle(tester);
  await tester.tap(byIconButton('Grid'));
  await h.settle(tester);
  return (h, ids);
}

void main() {
  testWidgets('songs start as rows; the switch shows cards and is kept', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    await _addSongs(h, ['Alpha']);
    await h.settle(tester);
    expect(find.byType(SongTile), findsOneWidget);
    expect(find.byType(SongGridCard), findsNothing);

    await tester.tap(byIconButton('Grid'));
    await h.settle(tester);
    expect(find.byType(SongTile), findsNothing);
    expect(find.byType(SongGridCard), findsOneWidget);
    expect(find.text('Artist Alpha'), findsOneWidget);
    expect(find.text('Album Alpha • 3:05'), findsOneWidget);
    expect(
      h.container.read(libraryListViewsProvider).of(BrowseList.songs).view,
      CollectionView.grid,
    );
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('a tap plays the list from that card', (tester) async {
    final playback = FakePlaybackCommands();
    final (_, ids) = await _pumpGrid(tester, playback: playback);
    await tester.tap(find.text('Bravo'));
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.startIndex, 1);
    expect(call.tracks, [
      for (final i in [ids[1], ids[2], ids[0]]) TrackId(i),
    ]);
    await unmountApp(tester);
  });

  testWidgets('long press selects; then a tap toggles, the heart hides', (
    tester,
  ) async {
    final (h, ids) = await _pumpGrid(tester);
    expect(byIconButton('Add to favorites'), findsNWidgets(3));
    await tester.longPress(find.text('Alpha'));
    await tester.pump();
    expect(h.container.read(librarySelectionProvider).ids, [TrackId(ids[1])]);
    expect(byIconButton('Add to favorites'), findsNothing);
    await tester.tap(find.text('Charlie'));
    await tester.pump();
    expect(h.container.read(librarySelectionProvider).ids.toSet(), {
      TrackId(ids[1]),
      TrackId(ids[0]),
    });
    final card = find.ancestor(
      of: find.text('Charlie'),
      matching: find.byType(KGridCard),
    );
    expect(tester.widget<KGridCard>(card).selected, isTrue);
    await unmountApp(tester);
  });

  testWidgets('the heart on the cover toggles the favorite', (tester) async {
    final (h, ids) = await _pumpGrid(tester);
    final heart = find.descendant(
      of: find.ancestor(
        of: find.text('Alpha'),
        matching: find.byType(SongGridCard),
      ),
      matching: find.byType(SongFavoriteButton),
    );
    await tester.tap(heart);
    await h.settle(tester, rounds: 1);
    expect(h.container.read(favoriteTrackIdsProvider).value, {TrackId(ids[1])});
    expect(byIconButton('Remove from favorites'), findsOneWidget);
    await unmountApp(tester);
  });
}
