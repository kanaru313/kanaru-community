import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/menus/song_lyrics_entry.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_body.dart';
import 'package:kanaru/src/lyrics/ui/song_lyrics_entry_impl.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';
import 'package:kanaru/src/screens/now_playing/ui/favorite_button.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_song_menu.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../lyrics/ui/lyrics_ui_host.dart' show syncedLyrics;
import '../../playback/support/ui_host.dart';
import '../../playback/ui/sleep_timer/sleep_timer_modal_host.dart';
import '../../library/ui/info/song_info_harness.dart' show link;
import '../../support/icon_button_finders.dart';
import 'support/song_menu_pump.dart';

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

/// Mobile Now Playing over a playing, tagged song; [open] taps ⋮.
Future<UiHost> _pump(
  WidgetTester tester, {
  bool tagged = true,
  bool open = true,
  bool inLibrary = true,
  bool loadFails = false,
}) async {
  final host = await pumpWithPlayer(
    tester,
    const Text('home'),
    routes: _routes,
    size: const Size(390, 900),
    play: false,
    overrides: [
      extensionRegistryProvider.overrideWithValue(ExtensionRegistry()),
      sleepTimerProvider.overrideWith(FakeSleepTimer.new),
      ...sleepEstimates(),
      songLyricsEntryProvider.overrideWithValue(const LyricsSongEntry()),
      if (!inLibrary)
        trackInfoProvider.overrideWith((ref, id) => Stream.value(null)),
      if (loadFails)
        trackInfoProvider.overrideWith(
          (ref, id) => Stream.error(StateError('read failed')),
        ),
      trackLyricsProvider.overrideWith(
        (ref, id) => LyricsShown(syncedLyrics(2)),
      ),
    ],
  );
  await host.run(tester, () async {
    if (tagged) {
      await host.h.db.customStatement(
        "UPDATE tracks SET album = 'Alb', artist = 'Art One', "
        "album_title_key = 'alb', album_artist_key = 'art one' "
        "WHERE title = 'T0'",
      );
      await host.h.db.customStatement(
        'INSERT INTO track_artists (track_id, artist_key, artist_name, '
        "position) VALUES (${host.h.tracks[0].value}, 'art one', 'Art One', 0)",
      );
    }
    await host.h.play();
  });
  host.router!.push('/now-playing');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await host.letStreamsArrive(tester);
  if (open) {
    await _openMenu(
      tester,
      until: inLibrary && !loadFails
          ? null
          : find.text(loadFails ? _loadFailed : _notInLibrary),
    );
  }
  return host;
}

Future<void> _openMenu(WidgetTester tester, {Finder? until}) async {
  await tester.tap(byIconButton('More'));
  await menuLoads(tester, until: until);
}

const _notInLibrary = 'This is no longer in your library.';
const _loadFailed = 'Could not open the menu';

FakeSleepTimer _timer(UiHost host) =>
    host.container.read(sleepTimerProvider.notifier) as FakeSleepTimer;

String _location(UiHost host) =>
    host.router!.routerDelegate.currentConfiguration.last.matchedLocation;

/// Whether the menu row titled [label] can be chosen, by its semantics.
bool _enabled(WidgetTester tester, String label) =>
    tester.getSemantics(find.text(label)).flagsCollection.isEnabled ==
    Tristate.isTrue;

/// The spoken label of the menu row titled [label].
String _spoken(WidgetTester tester, String label) =>
    tester.getSemantics(find.text(label)).label;

/// Unmounts the page and lets what its disposal schedules finish.
Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

double _y(WidgetTester tester, String label) =>
    tester.getTopLeft(find.text(label)).dy;

void main() {
  testWidgets('groups follow the song menu: go to | sleep, lyrics, translate, '
      'effects | the rest; no Select, no queue footer', (tester) async {
    await _pump(tester);
    final ys = [
      for (final l in [
        'Go to album',
        'Go to artist',
        'Sleep timer',
        'Lyrics source',
        'Translate lyrics…',
        'Visual effects',
        'Add to playlist…',
        'Add to favorites',
      ])
        _y(tester, l),
    ];
    expect(ys, [...ys]..sort());
    expect(find.text('Select'), findsNothing);
    expect(find.text('Play next'), findsNothing);
    expect(find.text('Add to queue'), findsNothing);
    // The header is the playing song's.
    expect(find.text('T0'), findsWidgets);
    expect(find.text('Art One · Alb'), findsOneWidget);
  });

  testWidgets('sleep timer is live; translate is soon, effects are Pro', (
    tester,
  ) async {
    await _pump(tester);
    final handle = tester.ensureSemantics();
    expect(_enabled(tester, 'Sleep timer'), isTrue);
    expect(_enabled(tester, 'Lyrics source'), isTrue);
    expect(_enabled(tester, 'Translate lyrics…'), isFalse);
    expect(_spoken(tester, 'Translate lyrics…'), contains('Coming soon'));
    // Effects: dimmed, Pro, no "Coming soon". Ask AI: soon, no Pro.
    expect(_enabled(tester, 'Visual effects'), isFalse);
    expect(_spoken(tester, 'Visual effects'), isNot(contains('Coming soon')));
    expect(find.byType(ProBadge), findsOneWidget);
    // The one Pro pill sits on the Visual effects row.
    expect(
      (tester.getCenter(find.byType(ProBadge)).dy -
              tester.getCenter(find.text('Visual effects')).dy)
          .abs(),
      lessThan(8),
    );
    handle.dispose();
    await _finish(tester);
  });

  testWidgets('the sleep timer label ticks while the menu is open', (
    tester,
  ) async {
    final host = await _pump(tester);
    final handle = tester.ensureSemantics();
    _timer(host).set(runningMinutes());
    await tester.pump();
    expect(find.text('Sleep timer · 23:41 left'), findsOneWidget);
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

  testWidgets('sleep timer closes the menu, opens its modal on the root and '
      'leaves Now Playing in place', (tester) async {
    final host = await _pump(tester);
    await tester.tap(find.text('Sleep timer'));
    await tester.pumpAndSettle();
    expect(find.text('Turn off timer'), findsNothing);
    expect(find.text('Tap an item to start right away.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Tap an item to start right away.'), findsNothing);
    expect(_location(host), '/now-playing');
  });

  testWidgets('the lyrics row opens "Lyrics for this song" of the playing '
      'song and closes when the song changes', (tester) async {
    final host = await _pump(tester);
    await tester.tap(find.text('Lyrics source'));
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsOneWidget);
    expect(tester.takeException(), isNull);
    // It follows the playing song: the next one closes it.
    await host.run(tester, host.h.c.next);
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsNothing);
    expect(_location(host), '/now-playing');
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('the lyrics modal stays open until Back when the song does '
      'not change', (tester) async {
    final host = await _pump(tester);
    await tester.tap(find.text('Lyrics source'));
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsNothing);
    expect(_location(host), '/now-playing');
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('Go to album closes Now Playing and opens the album', (
    tester,
  ) async {
    final host = await _pump(tester);
    await tester.tap(find.text('Go to album'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_location(host), LibraryLocations.album(AlbumKey('art one', 'alb')));
    expect(find.text('album page'), findsOneWidget);
    // Now Playing was closed first (not left under the album).
    final stack = host.router!.routerDelegate.currentConfiguration.matches;
    expect([
      for (final m in stack) m.matchedLocation,
    ], isNot(contains('/now-playing')));
    expect(find.byType(NowPlayingPage, skipOffstage: false), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('an info link opened with › closes Now Playing too', (
    tester,
  ) async {
    final host = await _pump(tester);
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.text('T0')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(link('Alb').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_location(host), LibraryLocations.album(AlbumKey('art one', 'alb')));
    final stack = host.router!.routerDelegate.currentConfiguration.matches;
    expect([
      for (final m in stack) m.matchedLocation,
    ], isNot(contains('/now-playing')));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Go to artist opens the artist page', (tester) async {
    final host = await _pump(tester);
    await tester.tap(find.text('Go to artist'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      _location(host),
      LibraryLocations.artist(ArtistKey(groupKey('Art One'))),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a song without an album has a dimmed, inert Go to album', (
    tester,
  ) async {
    final host = await _pump(tester, tagged: false);
    final handle = tester.ensureSemantics();
    expect(_enabled(tester, 'Go to album'), isFalse);
    handle.dispose();
    await tester.tap(find.text('Go to album'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_location(host), '/now-playing');
  });

  testWidgets('a song that is not in the library shows the toast, no menu', (
    tester,
  ) async {
    await _pump(tester, inLibrary: false);
    expect(find.text(_notInLibrary), findsOneWidget);
    expect(find.text('Sleep timer'), findsNothing);
  });

  testWidgets('nothing playing shows the not-in-library toast, no menu', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      play: false,
      overrides: [
        sleepTimerProvider.overrideWith(FakeSleepTimer.new),
        ...sleepEstimates(),
      ],
    );
    unawaited(openNowPlayingSongMenu(tester.element(find.text('home'))));
    await menuLoads(tester, until: find.text(_notInLibrary));
    expect(find.text(_notInLibrary), findsOneWidget);
    expect(find.text('Sleep timer'), findsNothing);
    expect(host.container.read(nowPlayingProvider).value, isNull);
  });

  testWidgets('a failed read shows the load-failed toast, no menu', (
    tester,
  ) async {
    await _pump(tester, loadFails: true);
    expect(find.text(_loadFailed), findsOneWidget);
    expect(find.text('Sleep timer'), findsNothing);
  });

  testWidgets('the menu keeps the song it opened for when the queue moves on', (
    tester,
  ) async {
    final host = await _pump(tester);
    await host.run(tester, host.h.c.next);
    await tester.pump(const Duration(milliseconds: 300));
    // Header and rows are still the first song's.
    expect(find.text('Art One · Alb'), findsOneWidget);
    expect(find.text('T0'), findsWidgets);
    await tester.tap(find.text('Add to favorites'));
    await host.letStreamsArrive(tester);
    expect(host.container.read(isFavoriteProvider(host.h.tracks[0])), isTrue);
    expect(host.container.read(isFavoriteProvider(host.h.tracks[1])), isFalse);
  });

  testWidgets('the menu heart is the Now Playing heart (one value)', (
    tester,
  ) async {
    final host = await _pump(tester, open: false);
    final id = host.h.tracks.first;
    expect(host.container.read(isFavoriteProvider(id)), isFalse);
    await tester.tap(find.byType(FavoriteButton).first);
    await host.letStreamsArrive(tester);
    expect(host.container.read(isFavoriteProvider(id)), isTrue);
    await _openMenu(tester);
    expect(find.text('Remove from favorites'), findsOneWidget);
    expect(find.text('Add to favorites'), findsNothing);
  });
}
