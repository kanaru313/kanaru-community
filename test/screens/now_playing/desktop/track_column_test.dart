import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/playback/ui/play_pause_button.dart';
import 'package:kanaru/src/playback/ui/playback_time_label.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';
import 'package:kanaru/src/playback/ui/transport_buttons.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_track_column.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_seek_slot.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shell/support/desktop_now_playing_host.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/library/albums/:id',
    builder: (_, _) => const Text('album page'),
  ),
  GoRoute(
    path: '/library/artists/:id',
    builder: (_, _) => const Text('artist page'),
  ),
];

Future<DesktopHost> _open(
  WidgetTester tester, {
  Size size = const Size(1280, 800),
  bool tagged = false,
  String? title,
}) async {
  final host = await pumpDesktopShell(
    tester,
    size: size,
    routes: _routes,
    play: false,
  );
  await host.run(tester, () async {
    if (tagged) {
      await host.h.db.customStatement(
        "UPDATE tracks SET album = 'Alb', artist = 'Art One', "
        "album_title_key = 'alb', album_artist_key = 'art one' "
        "WHERE title = 'T0'",
      );
    }
    if (title != null) {
      await host.h.db.customStatement(
        "UPDATE tracks SET title = '$title' WHERE title = 'T0'",
      );
    }
    await host.h.play();
    await host.h.c.pause();
  });
  host.container.read(nowPlayingPanelProvider.notifier).open();
  await tester.pump();
  await settleSlide(tester);
  await host.letStreamsArrive(tester);
  return host;
}

void main() {
  testWidgets('the column holds cover, title, seek slot, transport and times', (
    tester,
  ) async {
    await _open(tester, tagged: true);
    final column = find.byType(DesktopTrackColumn);
    for (final f in [
      find.byType(TrackCover),
      find.text('T0'),
      find.byType(NowPlayingSeekSlot),
      find.byType(PreviousButton),
      find.byType(PlayPauseButton),
      find.byType(NextButton),
      find.byType(PlaybackTimeLabel),
    ]) {
      expect(find.descendant(of: column, matching: f), findsWidgets);
    }
    expect(
      find.descendant(of: column, matching: find.byType(PlaybackTimeLabel)),
      findsNWidgets(2),
    );
    // Top to bottom: cover, title, seek, transport.
    double y(Finder f) =>
        tester.getTopLeft(find.descendant(of: column, matching: f).first).dy;
    final ys = [
      y(find.byType(TrackCover)),
      y(find.text('T0')),
      y(find.byType(NowPlayingSeekSlot)),
      y(find.byType(PlayPauseButton)),
    ];
    expect(ys, [...ys]..sort());
  });

  testWidgets('the cover has radius 32 and the 42 % column width', (
    tester,
  ) async {
    await _open(tester);
    final column = tester.getSize(find.byType(DesktopTrackColumn));
    expect(column.width, closeTo(1280 * 0.42, 1));
    final cover = tester.getSize(find.byType(TrackCover));
    expect(cover.width, cover.height);
    expect(cover.width, lessThanOrEqualTo(500));
  });

  testWidgets('the artist and album lines go to the library', (tester) async {
    final host = await _open(tester, tagged: true);
    expect(find.text('Art One'), findsOneWidget);
    await tester.tap(find.text('Alb'));
    await tester.pump();
    await tester.pump();
    expect(
      host.router!.routerDelegate.currentConfiguration.last.matchedLocation,
      LibraryLocations.album(AlbumKey('art one', 'alb')),
    );
  });

  testWidgets('the artist line goes to the artist page', (tester) async {
    final host = await _open(tester, tagged: true);
    await tester.tap(find.text('Art One'));
    await tester.pump();
    await tester.pump();
    expect(
      host.router!.routerDelegate.currentConfiguration.last.matchedLocation,
      LibraryLocations.artist(ArtistKey(groupKey('Art One'))),
    );
  });

  testWidgets('a position change does not rebuild the title', (tester) async {
    final host = await _open(tester);
    final before = tester.widget<Text>(find.text('T0'));
    await host.run(tester, () => host.h.c.seek(const Duration(seconds: 30)));
    await host.letStreamsArrive(tester);
    expect(find.text('0:30'), findsOneWidget);
    expect(identical(tester.widget<Text>(find.text('T0')), before), isTrue);
  });

  testWidgets('nothing moves when the title wraps to two lines', (
    tester,
  ) async {
    final host = await _open(tester);
    final cover = tester.getTopLeft(find.byType(TrackCover));
    final seek = tester.getTopLeft(find.byType(NowPlayingSeekSlot));
    final play = tester.getTopLeft(find.byType(PlayPauseButton));
    await host.run(tester, () async {
      await host.h.db.customUpdate(
        "UPDATE tracks SET title = '${'A very long song title ' * 6}' "
        "WHERE title = 'T0'",
        updates: {host.h.db.tracks},
      );
    });
    await host.letStreamsArrive(tester);
    expect(tester.getTopLeft(find.byType(TrackCover)), cover);
    expect(tester.getTopLeft(find.byType(NowPlayingSeekSlot)), seek);
    expect(tester.getTopLeft(find.byType(PlayPauseButton)), play);
  });

  testWidgets('a late album does not move the controls', (tester) async {
    final host = await _open(tester);
    final seek = tester.getTopLeft(find.byType(NowPlayingSeekSlot));
    await host.run(tester, () async {
      await host.h.db.customUpdate(
        "UPDATE tracks SET album = 'Alb', artist = 'Art' WHERE title = 'T0'",
        updates: {host.h.db.tracks},
      );
    });
    await host.letStreamsArrive(tester);
    expect(find.text('Alb'), findsOneWidget);
    expect(tester.getTopLeft(find.byType(NowPlayingSeekSlot)), seek);
  });

  testWidgets('a short window scales the block down instead of overflowing', (
    tester,
  ) async {
    await _open(tester, size: const Size(1280, 420));
    expect(tester.takeException(), isNull);
    expect(find.byType(FittedBox), findsWidgets);
    final box = tester.getRect(find.byType(DesktopTrackColumn));
    final cover = tester.getRect(find.byType(TrackCover));
    expect(box.contains(cover.center), isTrue);
  });

  testWidgets('the column keeps the header shown while the pointer is on it', (
    tester,
  ) async {
    await _open(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(100, 400));
    await tester.pump();
    await mouse.moveTo(const Offset(150, 420));
    await tester.pump(const Duration(seconds: 6));
    expect(
      tester
          .widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first)
          .opacity,
      1,
    );
    await mouse.removePointer();
  });
}
