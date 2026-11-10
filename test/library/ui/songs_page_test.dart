import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/playback/data/track_info_rows.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_playback_commands.dart';
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

PlayTracksCall _only(FakePlaybackCommands playback) =>
    playback.calls.single as PlayTracksCall;

/// Placeholder rows (a page that is not read yet) among the built rows.
Finder _placeholders() => find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == '_PlaceholderCard',
);

void main() {
  testWidgets('lists the songs by title with their count and plays a tap', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      playback: playback,
    );
    final ids = await _addSongs(h, ['Charlie', 'Alpha', 'Bravo']);
    await h.settle(tester);
    expect(find.text('3 songs'), findsOneWidget);
    expect(h.songTitles(tester), ['Alpha', 'Bravo', 'Charlie']);
    expect(find.text('Artist Alpha'), findsOneWidget);
    expect(find.text('Album Alpha • 2020'), findsOneWidget);
    expect(find.text('3:05'), findsNWidgets(3));

    await tester.tap(find.text('Bravo'));
    await tester.pump();
    final call = _only(playback);
    expect(call.startIndex, 1);
    expect(call.shuffle, isFalse);
    expect(call.tracks, [
      for (final i in [ids[1], ids[2], ids[0]]) TrackId(i),
    ]);
    expect(call.context.kind, PlayContextKind.songs);
    await unmountApp(tester);
  });

  testWidgets('a tap in a sorted and filtered list plays the visible rows', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      playback: playback,
    );
    final ids = await _addSongs(h, ['Aa', 'Ab', 'Ac', 'Ad', 'Zz']);
    await h.container
        .read(libraryListViewsProvider.notifier)
        .setSort(
          BrowseList.songs,
          const SortSpec(SortCriterion.title, descending: true),
        );
    await h.settle(tester);
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await h.settle(tester);
    // Descending, and "zz" has no "a" in title, artist or album... it does
    // ("Artist Zz"), so every row matches; the order is what is checked.
    expect(h.songTitles(tester), ['Zz', 'Ad', 'Ac', 'Ab', 'Aa']);
    await tester.tap(find.text('Ac'));
    await tester.pump();
    final call = _only(playback);
    expect(call.startIndex, 2);
    expect(call.tracks, [
      for (final i in [ids[4], ids[3], ids[2], ids[1], ids[0]]) TrackId(i),
    ]);
    await tester.enterText(find.byType(TextField), 'ac');
    await h.settle(tester);
    expect(h.songTitles(tester), ['Ac']);
    playback.calls.clear();
    await tester.tap(find.text('Ac'));
    await tester.pump();
    expect(_only(playback).tracks, [TrackId(ids[2])]);
    await unmountApp(tester);
  });

  testWidgets('a track inserted before the tapped row does not shift the tap', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      playback: playback,
    );
    final ids = await _addSongs(h, ['Bravo', 'Charlie']);
    await h.settle(tester);
    final extra = (await _addSongs(h, ['Aardvark'])).single;
    await h.settle(tester);
    expect(h.songTitles(tester), ['Aardvark', 'Bravo', 'Charlie']);
    await tester.tap(find.text('Bravo'));
    await tester.pump();
    final call = _only(playback);
    expect(call.tracks.length, 3);
    expect(call.tracks.first, TrackId(extra));
    expect(call.tracks[call.startIndex], TrackId(ids[0]));
    await unmountApp(tester);
  });

  testWidgets('play all and shuffle send the visible ids once', (tester) async {
    final playback = FakePlaybackCommands();
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      playback: playback,
    );
    final ids = await _addSongs(h, ['Alpha', 'Bravo', 'Charlie']);
    await h.settle(tester);
    await tester.tap(find.byTooltip('Play all'));
    await tester.pump();
    var call = _only(playback);
    expect(call.startIndex, 0);
    expect(call.shuffle, isFalse);
    expect(call.tracks, [for (final i in ids) TrackId(i)]);
    playback.calls.clear();
    await tester.tap(find.byTooltip('Shuffle'));
    await tester.pump();
    call = _only(playback);
    expect(call.shuffle, isTrue);
    expect(call.tracks, [for (final i in ids) TrackId(i)]);
    expect(call.startIndex, inInclusiveRange(0, 2));
    await unmountApp(tester);
  });

  testWidgets('desktop labels the play buttons', (tester) async {
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      width: 1280,
      height: 800,
    );
    await _addSongs(h, ['Alpha']);
    await h.settle(tester);
    expect(find.text('Play all'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the heart toggles the favorite on the row', (tester) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    final ids = await _addSongs(h, ['Alpha', 'Bravo']);
    await h.settle(tester);
    expect(find.byTooltip('Remove from favorites'), findsNothing);
    await tester.tap(find.byTooltip('Add to favorites').first);
    await h.settle(tester, rounds: 1);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    final favorites = h.container.read(favoriteTrackIdsProvider).value;
    expect(favorites, {TrackId(ids[0])});
    await tester.tap(find.byTooltip('Remove from favorites'));
    await h.settle(tester, rounds: 1);
    expect(h.container.read(favoriteTrackIdsProvider).value, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('the playing row is tinted and shows the equalizer', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    final ids = await _addSongs(h, ['Alpha', 'Bravo']);
    await h.settle(tester);
    expect(find.byType(KEqualizerIcon), findsNothing);
    h.setNowPlaying(
      NowPlaying(entryId: 1, trackId: TrackId(ids[1]), playing: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(KEqualizerIcon), findsOneWidget);
    final cards = tester.widgetList<KMediaCard>(find.byType(KMediaCard));
    expect(cards.map((c) => c.current), [false, true]);
    expect(cards.last.currentLabel, 'Now playing');
    await unmountApp(tester);
  });

  testWidgets('a change to a row that keeps the order reaches the screen', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    final ids = await _addSongs(h, ['Alpha', 'Bravo']);
    await h.settle(tester);
    expect(find.text('Album Alpha • 2020'), findsOneWidget);
    await h.db.customUpdate(
      "UPDATE tracks SET album = 'Renamed' WHERE id = ?",
      variables: [Variable.withInt(ids[0])],
      updates: {h.db.tracks},
    );
    await h.settle(tester);
    expect(find.text('Renamed • 2020'), findsOneWidget);
    expect(find.text('Album Alpha • 2020'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a long list builds a window of rows, not all of them', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    await h.db.batch((b) {});
    for (var i = 0; i < 1500; i++) {
      await addLibraryTrack(
        h.db,
        source: h.sourceId,
        locator: 's${i.toString().padLeft(4, '0')}.flac',
        title: 'Song ${i.toString().padLeft(4, '0')}',
      );
    }
    await h.settle(tester);
    expect(find.text('1500 songs'), findsOneWidget);
    expect(find.byType(SongTile).evaluate().length, lessThan(60));
    expect(find.text('Song 0000'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('scrolling over a page boundary never shows a placeholder', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    for (var i = 0; i < 260; i++) {
      await addLibraryTrack(
        h.db,
        source: h.sourceId,
        locator: 's${i.toString().padLeft(4, '0')}.flac',
        title: 'Song ${i.toString().padLeft(4, '0')}',
      );
    }
    await h.settle(tester);
    final viewport = tester.view.physicalSize.height;
    final list = find.byType(Scrollable).last;
    var offset = 0.0;
    // Row 100 starts a page: walk across it in small steps.
    while (offset < 100 * 80 + 600) {
      offset += 120;
      tester.state<ScrollableState>(list).position.jumpTo(offset);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pump();
      for (final p in _placeholders().evaluate()) {
        final box = p.renderObject! as RenderBox;
        final top = box.localToGlobal(Offset.zero).dy;
        expect(
          top > viewport || top + box.size.height < 0,
          isTrue,
          reason: 'a placeholder is on screen at offset $offset',
        );
      }
    }
    expect(find.textContaining('Song 01'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets(
    'a page under another one does not reload, and does again on return',
    (tester) async {
      final h = await pumpLibrary(tester, initial: '/library/songs');
      await _addSongs(h, ['Alpha', 'Bravo']);
      await h.settle(tester);
      final count = songCountProvider(const SongScope.all());
      expect(h.container.read(count).value, 2);
      h.router.push('/probe');
      await tester.pumpAndSettle();
      await _addSongs(h, ['Charlie']);
      await h.settle(tester);
      expect(h.container.read(count).value, 2);
      h.router.pop();
      await tester.pumpAndSettle();
      await h.settle(tester);
      expect(h.container.read(count).value, 3);
      expect(find.text('3 songs'), findsOneWidget);
      await unmountApp(tester);
    },
  );

  testWidgets('only the page on screen offers its ids to select all', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    final ids = await _addSongs(h, ['Alpha', 'Bravo']);
    await h.settle(tester);
    expect(h.container.read(activeTrackListProvider), [
      for (final i in ids) TrackId(i),
    ]);
    h.router.push('/probe');
    await tester.pumpAndSettle();
    expect(h.container.read(activeTrackListProvider), isNull);
    h.router.pop();
    await tester.pumpAndSettle();
    expect(h.container.read(activeTrackListProvider)?.length, 2);
    await unmountApp(tester);
    expect(h.container.read(activeTrackListProvider), isNull);
  });

  testWidgets('a page that cannot be read says so and reads again on retry', (
    tester,
  ) async {
    var failures = 1;
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      overrides: [
        trackRowLoaderProvider.overrideWith((ref) {
          final db = ref.watch(appDatabaseProvider);
          return (ids) async {
            if (failures-- > 0) throw StateError('disk');
            return loadTrackInfos(db, ids);
          };
        }),
      ],
    );
    await _addSongs(h, ['Alpha', 'Bravo']);
    await h.settle(tester);
    expect(find.text('Could not load the list'), findsOneWidget);
    expect(h.songTitles(tester), isEmpty);
    await tester.tap(find.text('Retry'));
    await h.settle(tester);
    expect(find.text('Could not load the list'), findsNothing);
    expect(h.songTitles(tester), ['Alpha', 'Bravo']);
    await unmountApp(tester);
  });
}
