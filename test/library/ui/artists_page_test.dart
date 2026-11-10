import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/collections/artist_tile.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';

import '../../support/fake_playback_commands.dart';
import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

const _coverOld = 'aaaaaaaaaaaaaaaa';
const _coverNew = 'bbbbbbbbbbbbbbbb';

Future<LibraryHarness> _pump(
  WidgetTester tester, {
  FakePlaybackCommands? playback,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/artists',
    playback: playback,
  );
  Future<void> add(String title, String album, int year, String cover) =>
      addLibraryTrack(
        h.db,
        source: h.sourceId,
        locator: '$album/$title.flac',
        title: title,
        artists: ['Mai'],
        album: album,
        albumArtist: 'Mai',
        year: year,
        durationMs: 3600000,
        coverKey: cover,
      );
  await add('Old 1', 'Old', 1990, _coverOld);
  await add('New 1', 'New', 2020, _coverNew);
  await add('New 2', 'New', 2020, _coverNew);
  await addLibraryTrack(
    h.db,
    source: h.sourceId,
    locator: 'solo.flac',
    title: 'Solo',
    artists: ['Bao'],
    durationMs: 60000,
  );
  await h.settle(tester);
  return h;
}

void main() {
  testWidgets('artists are round photos in a grid with song counts', (
    tester,
  ) async {
    final h = await _pump(tester);
    // Artists open as rows; the switch makes them a grid.
    expect(find.byType(ArtistCard), findsNothing);
    await tester.tap(find.byTooltip('Grid'));
    await h.settle(tester, rounds: 1);
    expect(find.text('2 artists'), findsOneWidget);
    expect(find.byType(ArtistCard), findsNWidgets(2));
    expect(find.text('3 songs'), findsOneWidget);
    expect(find.text('1 song'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets(
    'rows give albums, songs and length; the photo is the newest album cover',
    (tester) async {
      await _pump(tester);
      expect(find.byType(ArtistTile), findsNWidgets(2));
      expect(find.text('2 albums'), findsOneWidget);
      expect(find.text('3 songs • 3 h'), findsOneWidget);
      expect(find.text('1 song • 1 min'), findsOneWidget);
      final covers = [
        for (final c in tester.widgetList<TrackCover>(find.byType(TrackCover)))
          (c.coverKey, c.circle),
      ];
      // Bao (no cover) then Mai (newest own album with a cover); both round.
      expect(covers, [(null, true), (_coverNew, true)]);
      await unmountApp(tester);
    },
  );

  testWidgets('play on a row plays every song of the artist', (tester) async {
    final playback = FakePlaybackCommands();
    await _pump(tester, playback: playback);
    await tester.tap(find.byTooltip('Play all songs').last);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.tracks.length, 3);
    expect(call.context.kind, PlayContextKind.artist);
    expect(call.context.label, 'Mai');
    await unmountApp(tester);
  });

  testWidgets('a tap pushes the artist location', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.text('Mai'));
    await tester.pump();
    expect(
      h.location,
      '/library/artists/${ArtistKey(groupKey('Mai')).encode()}',
    );
    await unmountApp(tester);
  });
}
