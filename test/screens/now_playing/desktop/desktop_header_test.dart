import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/menus/song_lyrics_entry.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_source_button.dart';
import 'package:kanaru/src/lyrics/ui/song_lyrics_entry_impl.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';
import 'package:kanaru/src/playback/ui/transport_buttons.dart';
import 'package:kanaru/src/playback/ui/volume_control.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing_header.dart';
import 'package:kanaru/src/screens/now_playing/ui/favorite_button.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../support/song_menu_pump.dart';

import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../lyrics/ui/lyrics_ui_host.dart' show syncedLyrics;
import '../../../playback/ui/sleep_timer/sleep_timer_modal_host.dart';
import '../../../shell/support/desktop_now_playing_host.dart';

/// The playing song has file lyrics, so the source button is enabled.
List<Override> _lyricsOverrides() => [
  playingLyricsProvider.overrideWithValue(
    PlayingLyrics(
      entryId: 1,
      trackId: const TrackId(1),
      lyrics: LyricsShown(syncedLyrics(2)),
    ),
  ),
  trackLyricsProvider.overrideWith((ref, id) => LyricsShown(syncedLyrics(2))),
];

Future<DesktopHost> _open(WidgetTester tester) async {
  final host = await pumpDesktopShell(
    tester,
    overrides: [
      sleepTimerProvider.overrideWith(FakeSleepTimer.new),
      ...sleepEstimates(),
      ..._lyricsOverrides(),
      songLyricsEntryProvider.overrideWithValue(const LyricsSongEntry()),
    ],
  );
  host.container.read(nowPlayingPanelProvider.notifier).open();
  await tester.pump();
  await settleSlide(tester);
  return host;
}

/// Taps ⋮ and lets the menu load and open (its data comes from the database).
Future<void> _openMore(WidgetTester tester) async {
  await tester.tap(
    find.ancestor(
      of: find.descendant(
        of: find.byType(DesktopNowPlayingHeader),
        matching: find.byIcon(KIcons.moreVert),
      ),
      matching: find.byType(KIconButton),
    ),
  );
  await menuLoads(tester);
}

double _headerOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find
          .ancestor(
            of: byIconButton('Minimise'),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    )
    .opacity;

double _x(WidgetTester tester, Finder f) => tester.getCenter(f.first).dx;

Finder _in(Finder inside, Finder f) => find.descendant(of: inside, matching: f);

void main() {
  final header = find.byType(DesktopNowPlayingHeader);

  testWidgets(
    'left group: close, cover column, favourite, playlist, translate',
    (tester) async {
      await _open(tester);
      final xs = [
        _x(tester, _in(header, find.byIcon(KIcons.collapse))),
        _x(tester, _in(header, find.byIcon(KIcons.sidebarCover))),
        _x(tester, _in(header, find.byType(FavoriteButton))),
        _x(tester, _in(header, find.byIcon(KIcons.playlistAdd))),
        _x(tester, _in(header, find.text('Translate'))),
      ];
      expect(xs, [...xs]..sort());
    },
  );

  testWidgets(
    'the lyrics source button sits after playlist, before Translate',
    (tester) async {
      await _open(tester);
      final xs = [
        _x(tester, _in(header, find.byIcon(KIcons.playlistAdd))),
        _x(tester, _in(header, find.byType(LyricsSourceButton))),
        _x(tester, _in(header, find.text('Translate'))),
      ];
      expect(xs, [...xs]..sort());
      final button = tester.widget<KIconButton>(
        find.descendant(
          of: find.byType(LyricsSourceButton),
          matching: find.byType(KIconButton),
        ),
      );
      expect(button.tooltip, startsWith('Lyrics in tag · Synced (L)'));
      expect(button.tooltip, contains('Right-click'));
    },
  );

  testWidgets('right group: repeat, sleep timer, volume, more', (tester) async {
    await _open(tester);
    final xs = [
      _x(tester, _in(header, find.byType(RepeatButton))),
      _x(tester, _in(header, find.byIcon(KIcons.sleepTimer))),
      _x(tester, _in(header, find.byType(VolumeControl))),
      _x(tester, _in(header, find.byIcon(KIcons.moreVert))),
    ];
    expect(xs, [...xs]..sort());
    // The right group sits right of the left one.
    expect(
      xs.first,
      greaterThan(_x(tester, _in(header, find.text('Translate')))),
    );
  });

  testWidgets('the header repeat button opens the repeat menu', (tester) async {
    final host = await _open(tester);
    await host.tap(tester, _in(header, find.byType(RepeatButton)));
    await tester.pumpAndSettle();
    expect(find.byType(SelectionRow), findsNWidgets(5));
    await host.tap(tester, find.text('Repeat this song'));
    await tester.pumpAndSettle();
    expect(host.container.read(repeatSettingProvider), RepeatMode.one);
    expect(_in(header, find.byIcon(KIcons.repeatOne)), findsOneWidget);
    expect(_in(header, find.byKey(KToggleIconButton.dotKey)), findsOneWidget);
  });

  testWidgets('there is no Shuffle in the header', (tester) async {
    await _open(tester);
    expect(_in(header, find.byType(ShuffleButton)), findsNothing);
    expect(_in(header, find.byIcon(KIcons.shuffle)), findsNothing);
  });

  testWidgets('the sleep timer is a live entry; only translate is dimmed', (
    tester,
  ) async {
    await _open(tester);
    final button = tester.widget<KIconButton>(byIconButton('Sleep timer'));
    expect(button.onPressed, isNotNull);
    final chip = find.ancestor(
      of: find.text('Translate'),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(chip.first).opacity, lessThan(1));
    expect(find.byTooltip('Translate · Coming soon'), findsOneWidget);
  });

  testWidgets('a running timer shows its pill in the header, not the icon', (
    tester,
  ) async {
    final host = await _open(tester);
    (host.container.read(sleepTimerProvider.notifier) as FakeSleepTimer).set(
      runningMinutes(),
    );
    await tester.pump();
    expect(_in(header, find.byIcon(KIcons.sleepTimer)), findsNothing);
    final pill = tester.widget<KPill>(_in(header, find.byType(KPill)));
    expect(pill.label, '23:41');
    expect(pill.placement, KPillPlacement.standard);
    // Between repeat and volume.
    final x = _x(tester, _in(header, find.byType(KPill)));
    expect(x, greaterThan(_x(tester, _in(header, find.byType(RepeatButton)))));
    expect(x, lessThan(_x(tester, _in(header, find.byType(VolumeControl)))));
  });

  testWidgets('the header is 64 dp tall', (tester) async {
    await _open(tester);
    expect(tester.getSize(header).height, 64);
  });

  testWidgets('the ⋮ opens the song menu of the playing song as a dialog', (
    tester,
  ) async {
    await _open(tester);
    await _openMore(tester);
    final ys = [
      for (final l in [
        'Go to album',
        'Sleep timer',
        'Lyrics source',
        'Translate lyrics…',
        'Visual effects',
        'Add to playlist…',
      ])
        tester.getTopLeft(find.text(l)).dy,
    ];
    expect(ys, [...ys]..sort());
    expect(find.text('Select'), findsNothing);
    expect(find.text('Play next'), findsNothing);
    expect(find.text('Track info'), findsNothing);
    expect(find.byType(ProBadge), findsWidgets);
    // The header is the playing song's.
    expect(find.text('T0'), findsWidgets);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('the sleep timer row is live and ticks', (tester) async {
    final host = await _open(tester);
    await _openMore(tester);
    final timer =
        host.container.read(sleepTimerProvider.notifier) as FakeSleepTimer;
    timer.set(runningMinutes());
    await tester.pump();
    expect(find.text('Sleep timer · 23:41 left'), findsOneWidget);
    timer.set(
      runningMinutes(remaining: const Duration(minutes: 23, seconds: 40)),
    );
    await tester.pump();
    expect(find.text('Sleep timer · 23:40 left'), findsOneWidget);
  });

  testWidgets('the header stays shown while the menu is open and hides after '
      'it is dismissed without a choice', (tester) async {
    await _open(tester);
    await _openMore(tester);
    await tester.pump(const Duration(seconds: 6));
    expect(_headerOpacity(tester), 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Sleep timer'), findsNothing);
    // The pin is given back: the header hides after the usual stillness.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_headerOpacity(tester), 0);
  });

  testWidgets('the More menu sleep item pins the header and returns to ⋮', (
    tester,
  ) async {
    await _open(tester);
    final more = find.ancestor(
      of: _in(header, find.byIcon(KIcons.moreVert)),
      matching: find.byType(KIconButton),
    );
    await _openMore(tester);
    await tester.tap(find.text('Sleep timer'));
    await tester.pumpAndSettle();
    expect(find.text('Tap an item to start right away.'), findsOneWidget);
    // Header fully shown long after the usual stillness: the modal pins it.
    await tester.pump(const Duration(seconds: 6));
    expect(
      tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(
                  of: byIconButton('Minimise'),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity,
      1,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Tap an item to start right away.'), findsNothing);
    expect(tester.widget<KIconButton>(more).focusNode!.hasPrimaryFocus, isTrue);
    // Pin given back: the header hides after the usual stillness.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(
                  of: byIconButton('Minimise'),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity,
      0,
    );
  });

  testWidgets('the cover-column button reflects and flips the view', (
    tester,
  ) async {
    await _open(tester);
    expect(find.byKey(const ValueKey('split')), findsOneWidget);
    await tester.tap(_in(header, find.byIcon(KIcons.sidebarCover)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('split')), findsNothing);
    expect(find.byKey(const ValueKey('pane only')), findsOneWidget);
  });

  testWidgets('the heart is 16 dp after the cover-column button', (
    tester,
  ) async {
    await _open(tester);
    final toggle = tester.getTopRight(
      _in(
        header,
        find.ancestor(
          of: find.byIcon(KIcons.sidebarCover),
          matching: find.byType(KIconButton),
        ),
      ),
    );
    final heart = tester.getTopLeft(_in(header, find.byType(FavoriteButton)));
    expect(heart.dx - toggle.dx, 16);
  });
}
