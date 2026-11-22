import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_body.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/more_sheet.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../lyrics/ui/lyrics_ui_host.dart' show syncedLyrics;
import '../../../playback/support/ui_host.dart';
import '../../../playback/ui/sleep_timer/sleep_timer_modal_host.dart';
import '../../../support/icon_button_finders.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
  ),
  GoRoute(
    path: '/library/albums/:id',
    builder: (context, state) => const Scaffold(body: Text('album page')),
  ),
  GoRoute(
    path: '/library/artists/:id',
    builder: (context, state) => const Scaffold(body: Text('artist page')),
  ),
];

Future<UiHost> _openSheet(
  WidgetTester tester, {
  List<String> artists = const ['Art One'],
  bool tagged = true,
}) async {
  final host = await pumpWithPlayer(
    tester,
    const Text('home'),
    routes: _routes,
    size: const Size(390, 900),
    play: false,
    overrides: [
      sleepTimerProvider.overrideWith(FakeSleepTimer.new),
      ...sleepEstimates(),
      playingLyricsProvider.overrideWithValue(
        PlayingLyrics(
          entryId: 1,
          trackId: const TrackId(1),
          lyrics: LyricsShown(syncedLyrics(2)),
        ),
      ),
      trackLyricsProvider.overrideWith(
        (ref, id) => LyricsShown(syncedLyrics(2)),
      ),
    ],
  );
  await host.run(tester, () async {
    if (tagged) {
      await host.h.db.customStatement(
        "UPDATE tracks SET album = 'Alb', artist = '${artists.first}', "
        "album_title_key = 'alb', album_artist_key = 'art one' "
        "WHERE title = 'T0'",
      );
      final id = host.h.tracks[0].value;
      for (var i = 0; i < artists.length; i++) {
        await host.h.db.customStatement(
          'INSERT INTO track_artists (track_id, artist_key, artist_name, '
          "position) VALUES ($id, '${artists[i].toLowerCase()}', "
          "'${artists[i]}', $i)",
        );
      }
    }
    await host.h.play();
  });
  host.router!.push('/now-playing');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await host.letStreamsArrive(tester);
  await tester.tap(byIconButton('More'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return host;
}

FakeSleepTimer _timer(UiHost host) =>
    host.container.read(sleepTimerProvider.notifier) as FakeSleepTimer;

String _location(UiHost host) =>
    host.router!.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('the head shows cover, title and artist · album', (tester) async {
    await _openSheet(tester);
    expect(find.text('T0'), findsWidgets);
    expect(find.text('Art One · Alb'), findsOneWidget);
  });

  testWidgets('both groups are listed in order', (tester) async {
    await _openSheet(tester);
    final labels = [
      'Add to playlist',
      'Go to album',
      'Go to artist',
      'Sleep timer',
      'Lyrics source',
      'Translate lyrics…',
      'Visual effects',
      'Track info',
    ];
    final ys = [for (final l in labels) tester.getTopLeft(find.text(l)).dy];
    expect(ys, [...ys]..sort());
  });

  testWidgets('the sleep timer item is live, not "coming soon"', (
    tester,
  ) async {
    await _openSheet(tester);
    final row = find.ancestor(
      of: find.text('Sleep timer'),
      matching: find.byType(KListRow),
    );
    expect(tester.widget<KListRow>(row).enabled, isTrue);
    expect(
      find.descendant(of: row, matching: find.text('Coming soon')),
      findsNothing,
    );
  });

  testWidgets('the sleep timer label ticks while the sheet is open', (
    tester,
  ) async {
    final host = await _openSheet(tester);
    final handle = tester.ensureSemantics();
    _timer(host).set(runningMinutes());
    await tester.pump();
    expect(find.text('Sleep timer · 23:41 left'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Sleep timer · 24 minutes left'),
      findsOneWidget,
    );
    _timer(
      host,
    ).set(runningMinutes(remaining: const Duration(minutes: 23, seconds: 40)));
    await tester.pump();
    expect(find.text('Sleep timer · 23:40 left'), findsOneWidget);
    _timer(host).set(const SleepTimerState.off());
    await tester.pump();
    expect(find.text('Sleep timer'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the sleep timer item closes the sheet, then opens the modal', (
    tester,
  ) async {
    final host = await _openSheet(tester);
    _timer(host).set(runningMinutes());
    await tester.pump();
    await tester.tap(find.text('Sleep timer · 23:41 left'));
    await tester.pumpAndSettle();
    expect(find.byType(NowPlayingMoreSheet), findsNothing);
    expect(find.text('Turn off timer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The modal closes with Back and leaves Now Playing in place.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Turn off timer'), findsNothing);
    expect(_location(host), '/now-playing');
  });

  testWidgets('the lyrics source item is live and opens the modal after the '
      'sheet closed', (tester) async {
    final host = await _openSheet(tester);
    final row = find.ancestor(
      of: find.text('Lyrics source'),
      matching: find.byType(KListRow),
    );
    expect(tester.widget<KListRow>(row).enabled, isTrue);
    expect(
      find.descendant(of: row, matching: find.text('Coming soon')),
      findsNothing,
    );
    await tester.tap(find.text('Lyrics source'));
    await tester.pumpAndSettle();
    expect(find.byType(NowPlayingMoreSheet), findsNothing);
    expect(find.byType(LyricsForTrackBody), findsOneWidget);
    expect(tester.takeException(), isNull);
    // One route on top of Now Playing: Back closes the modal only.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsNothing);
    expect(_location(host), '/now-playing');
  });

  testWidgets('unbuilt items are dimmed with "Coming soon"; Pro has a badge', (
    tester,
  ) async {
    await _openSheet(tester);
    for (final label in ['Translate lyrics…', 'Track info']) {
      final row = find.ancestor(
        of: find.text(label),
        matching: find.byType(KListRow),
      );
      final opacity = tester.widget<Opacity>(
        find.descendant(of: row, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, lessThan(1), reason: label);
    }
    expect(
      find.descendant(
        of: find.byType(NowPlayingMoreSheet),
        matching: find.text('Coming soon'),
      ),
      findsNWidgets(2),
    );
    expect(find.byType(ProBadge), findsOneWidget);
  });

  testWidgets('Go to album navigates to the album location', (tester) async {
    final host = await _openSheet(tester);
    await tester.tap(find.text('Go to album'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(_location(host), LibraryLocations.album(AlbumKey('art one', 'alb')));
    expect(find.text('album page'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Go to artist navigates to the artist location', (tester) async {
    final host = await _openSheet(tester);
    await tester.tap(find.text('Go to artist'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      _location(host),
      LibraryLocations.artist(ArtistKey(groupKey('Art One'))),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('several artists open the picker first', (tester) async {
    final host = await _openSheet(tester, artists: ['Art One', 'Art Two']);
    await tester.tap(find.text('Go to artist'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(find.text('Choose an artist'), findsOneWidget);
    expect(_location(host), '/now-playing');
    await tester.tap(find.text('Art Two'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(
      _location(host),
      LibraryLocations.artist(ArtistKey(groupKey('Art Two'))),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('without an album, Go to album is dimmed and inert', (
    tester,
  ) async {
    final host = await _openSheet(tester, tagged: false);
    // The item exists: it is not "coming soon", only unavailable here.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Go to album'),
          matching: find.byType(KListRow),
        ),
        matching: find.text('Coming soon'),
      ),
      findsNothing,
    );
    await tester.tap(find.text('Go to album'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_location(host), '/now-playing');
  });
}
