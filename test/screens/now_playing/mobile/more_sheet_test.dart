import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/more_sheet.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/support/ui_host.dart';

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
  await tester.tap(find.byTooltip('More'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return host;
}

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
      'Sleep timer',
      'Add to playlist',
      'Go to album',
      'Go to artist',
      'Lyrics source',
      'Translate lyrics…',
      'Visual effects',
      'Track info',
    ];
    final ys = [for (final l in labels) tester.getTopLeft(find.text(l)).dy];
    expect(ys, [...ys]..sort());
  });

  testWidgets('unbuilt items are dimmed with "Coming soon"; Pro has a badge', (
    tester,
  ) async {
    await _openSheet(tester);
    for (final label in [
      'Sleep timer',
      'Add to playlist',
      'Lyrics source',
      'Translate lyrics…',
      'Track info',
    ]) {
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
      findsNWidgets(5),
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
