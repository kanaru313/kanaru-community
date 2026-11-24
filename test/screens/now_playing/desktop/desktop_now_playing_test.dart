import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/ui/menus/song_lyrics_entry.dart';
import 'package:kanaru/src/lyrics/ui/song_lyrics_entry_impl.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_body.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_settings_link.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_source_button.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';
import 'package:kanaru/src/playback/state/playing_cover_colors.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing_header.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_side_pane.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_track_column.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../lyrics/ui/lyrics_ui_host.dart' show syncedLyrics;
import '../../../playback/ui/sleep_timer/sleep_timer_modal_host.dart';
import '../../../shell/support/desktop_now_playing_host.dart';
import '../../../support/app_harness.dart';
import '../../../support/icon_button_finders.dart';
import '../support/song_menu_pump.dart';

Future<DesktopHost> _open(
  WidgetTester tester, {
  List<Override> overrides = const [],
  List<RouteBase> routes = const [],
}) async {
  final host = await pumpDesktopShell(
    tester,
    routes: routes,
    overrides: [
      sleepTimerProvider.overrideWith(FakeSleepTimer.new),
      ...sleepEstimates(),
      ...overrides,
    ],
  );
  host.container.read(nowPlayingPanelProvider.notifier).open();
  await tester.pump();
  await settleSlide(tester);
  return host;
}

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
  songLyricsEntryProvider.overrideWithValue(const LyricsSongEntry()),
];

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  testWidgets('the tint takes the playing cover palette', (tester) async {
    await _open(
      tester,
      overrides: [
        playingCoverColorsProvider.overrideWithValue(
          const PlayingCoverColorsFound(
            CoverColors(seed: 1, palette: [0xFFFF0000, 0xFF0000FF]),
          ),
        ),
      ],
    );
    final tint = tester.widget<CoverTintBackground>(
      find.byType(CoverTintBackground),
    );
    expect(tint.palette, const [Color(0xFFFF0000), Color(0xFF0000FF)]);
    expect(tint.loading, isFalse);
  });

  testWidgets('a pending cover leaves the tint loading, not faded out', (
    tester,
  ) async {
    await _open(
      tester,
      overrides: [
        playingCoverColorsProvider.overrideWithValue(
          const PlayingCoverColorsPending(),
        ),
      ],
    );
    final tint = tester.widget<CoverTintBackground>(
      find.byType(CoverTintBackground),
    );
    expect(tint.palette, isNull);
    expect(tint.loading, isTrue);
  });

  testWidgets('split: the track column and the side pane side by side', (
    tester,
  ) async {
    await _open(tester);
    expect(find.byType(DesktopTrackColumn), findsOneWidget);
    expect(find.byType(DesktopSidePane), findsOneWidget);
    expect(
      tester.getRect(find.byType(DesktopTrackColumn)).right,
      lessThanOrEqualTo(
        tester.getRect(find.byType(DesktopSidePane)).left + 0.5,
      ),
    );
  });

  testWidgets('V hides and shows the cover column', (tester) async {
    await _open(tester);
    await _key(tester, LogicalKeyboardKey.keyV);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DesktopTrackColumn), findsNothing);
    expect(find.byType(DesktopSidePane), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyV);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DesktopTrackColumn), findsOneWidget);
  });

  testWidgets('V with Ctrl does nothing', (tester) async {
    await _open(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DesktopTrackColumn), findsOneWidget);
  });

  testWidgets('V does nothing while the More menu is open', (tester) async {
    await _open(tester);
    await tester.tap(find.byIcon(KIcons.moreVert));
    await menuLoads(tester);
    await _key(tester, LogicalKeyboardKey.keyV);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DesktopTrackColumn), findsOneWidget);
  });

  testWidgets('the cover-column choice survives closing and reopening', (
    tester,
  ) async {
    final host = await _open(tester);
    await _key(tester, LogicalKeyboardKey.keyV);
    await tester.pump(const Duration(milliseconds: 400));
    final panel = host.container.read(nowPlayingPanelProvider.notifier);
    panel.close();
    await tester.pump();
    await settleSlide(tester);
    panel.open();
    await tester.pump();
    await settleSlide(tester);
    expect(find.byType(DesktopTrackColumn), findsNothing);
  });

  testWidgets('the switch cross-fades; the outgoing body ignores the pointer', (
    tester,
  ) async {
    await _open(tester);
    await _key(tester, LogicalKeyboardKey.keyV);
    await tester.pump(const Duration(milliseconds: 100));
    // Both bodies exist mid-fade.
    expect(find.byType(DesktopTrackColumn), findsOneWidget);
    expect(find.byType(DesktopSidePane), findsNWidgets(2));
    final leaving = find.ancestor(
      of: find.byType(DesktopTrackColumn),
      matching: find.byType(IgnorePointer),
    );
    expect(
      tester.widgetList<IgnorePointer>(leaving).any((w) => w.ignoring),
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DesktopSidePane), findsOneWidget);
  });

  testWidgets('Esc closes the screen', (tester) async {
    final host = await _open(tester);
    await _key(tester, LogicalKeyboardKey.escape);
    expect(host.container.read(nowPlayingPanelProvider).open, isFalse);
    await settleSlide(tester);
    expect(find.byType(DesktopNowPlaying), findsNothing);
  });

  testWidgets('the chevron closes the screen', (tester) async {
    final host = await _open(tester);
    await tester.tap(byIconButton('Minimise'));
    await tester.pump();
    expect(host.container.read(nowPlayingPanelProvider).open, isFalse);
    await settleSlide(tester);
  });

  testWidgets('Esc while the More menu is open closes only the menu', (
    tester,
  ) async {
    final host = await _open(tester);
    await tester.tap(find.byIcon(KIcons.moreVert));
    await menuLoads(tester);
    expect(find.text('Go to album'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Go to album'), findsNothing);
    expect(host.container.read(nowPlayingPanelProvider).open, isTrue);
    await _key(tester, LogicalKeyboardKey.escape);
    expect(host.container.read(nowPlayingPanelProvider).open, isFalse);
    await settleSlide(tester);
  });

  testWidgets('the header hides after 3 s still and returns on a key', (
    tester,
  ) async {
    await _open(tester);
    AnimatedOpacity fade() => tester.widget<AnimatedOpacity>(
      find
          .ancestor(
            of: byIconButton('Minimise'),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(fade().opacity, 0);
    await _key(tester, LogicalKeyboardKey.shiftLeft);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fade().opacity, 1);
  });

  testWidgets('the header stays while the More menu is open', (tester) async {
    await _open(tester);
    AnimatedOpacity fade() => tester.widget<AnimatedOpacity>(
      find
          .ancestor(
            of: byIconButton('Minimise'),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    await tester.tap(find.byIcon(KIcons.moreVert));
    await menuLoads(tester);
    await tester.pump(const Duration(seconds: 6));
    expect(fade().opacity, 1);
    await _key(tester, LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(fade().opacity, 0);
  });

  group('the header stays shown while a floating surface is open', () {
    AnimatedOpacity fade(WidgetTester tester) => tester.widget<AnimatedOpacity>(
      find
          .ancestor(
            of: byIconButton('Minimise'),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );

    Future<void> hideAfter(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
    }

    Finder headerSleep() => find.descendant(
      of: find.byType(DesktopNowPlayingHeader),
      matching: find.byIcon(KIcons.sleepTimer),
    );

    testWidgets('the sleep timer opened from the header icon', (tester) async {
      await _open(tester);
      await tester.tap(headerSleep());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      expect(fade(tester).opacity, 1);
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      // Closed: the header goes after the usual stillness.
      await hideAfter(tester);
      expect(fade(tester).opacity, 0);
    });

    testWidgets('the sleep timer opened from the running pill', (tester) async {
      final host = await _open(tester);
      (host.container.read(sleepTimerProvider.notifier) as FakeSleepTimer).set(
        runningMinutes(),
      );
      await tester.pump();
      await tester.tap(find.byType(KPill));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      expect(fade(tester).opacity, 1);
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await hideAfter(tester);
      expect(fade(tester).opacity, 0);
    });

    testWidgets('Now Playing closing under an open modal ends cleanly', (
      tester,
    ) async {
      final host = await _open(tester);
      await tester.tap(headerSleep());
      await tester.pumpAndSettle();
      host.container.read(nowPlayingPanelProvider.notifier).close();
      await tester.pump();
      await settleSlide(tester);
      expect(find.byType(DesktopNowPlaying), findsNothing);
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      // No unpin on the disposed controller: nothing throws, no timer is left
      // pending (the test binding checks).
      expect(tester.takeException(), isNull);
    });

    group('the lyrics modal', () {
      Future<DesktopHost> openLyricsHost(WidgetTester tester) =>
          _open(tester, overrides: _lyricsOverrides());

      Future<void> expectPinnedThenReleased(WidgetTester tester) async {
        expect(find.byType(LyricsForTrackBody), findsOneWidget);
        await tester.pump(const Duration(seconds: 6));
        expect(fade(tester).opacity, 1);
        await _key(tester, LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(LyricsForTrackBody), findsNothing);
        await hideAfter(tester);
        expect(fade(tester).opacity, 0);
      }

      testWidgets('the header button opens it with the header pinned', (
        tester,
      ) async {
        await openLyricsHost(tester);
        await tester.tap(
          find.descendant(
            of: find.byType(DesktopNowPlayingHeader),
            matching: find.byType(LyricsSourceButton),
          ),
        );
        await tester.pumpAndSettle();
        await expectPinnedThenReleased(tester);
      });

      testWidgets('its settings button closes the panel and opens Settings', (
        tester,
      ) async {
        final host = await _open(
          tester,
          overrides: _lyricsOverrides(),
          routes: [
            GoRoute(
              path: lyricsSettingsLocation,
              builder: (_, _) => const Text('lyrics settings page'),
            ),
          ],
        );
        await tester.tap(
          find.descendant(
            of: find.byType(DesktopNowPlayingHeader),
            matching: find.byType(LyricsSourceButton),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is KIconButton && w.tooltip == 'Lyrics settings',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LyricsForTrackBody), findsNothing);
        expect(host.container.read(nowPlayingPanelProvider).open, isFalse);
        expect(
          host.router!.routerDelegate.currentConfiguration.last.matchedLocation,
          lyricsSettingsLocation,
        );
        expect(find.text('lyrics settings page'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // The translate pill's database stream ends with the panel: let its
        // zero-length timer fire.
        await tester.pump(const Duration(milliseconds: 1));
      });

      testWidgets('L opens it with the header pinned', (tester) async {
        await openLyricsHost(tester);
        await _key(tester, LogicalKeyboardKey.keyL);
        await tester.pumpAndSettle();
        await expectPinnedThenReleased(tester);
      });

      testWidgets('L is ignored with a modifier', (tester) async {
        await openLyricsHost(tester);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(find.byType(LyricsForTrackBody), findsNothing);
      });

      testWidgets('L is ignored while a text field has focus', (tester) async {
        await openLyricsHost(tester);
        // A persistent bottom sheet lives inside the page's Scaffold, so its
        // field is under the key handler of the page.
        tester
            .state<ScaffoldState>(
              find
                  .descendant(
                    of: find.byType(DesktopNowPlaying),
                    matching: find.byType(Scaffold),
                  )
                  .first,
            )
            .showBottomSheet((_) => const TextField(autofocus: true));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(find.byType(EditableText), findsOneWidget);
        await _key(tester, LogicalKeyboardKey.keyL);
        await tester.pumpAndSettle();
        expect(find.byType(LyricsForTrackBody), findsNothing);
      });

      testWidgets('the ⋮ item opens it with the header pinned', (tester) async {
        await openLyricsHost(tester);
        await tester.tap(find.byIcon(KIcons.moreVert));
        await menuLoads(tester);
        await tester.tap(find.text('Lyrics source'));
        await tester.pumpAndSettle();
        await expectPinnedThenReleased(tester);
      });

      testWidgets('Now Playing closing under the open modal ends cleanly', (
        tester,
      ) async {
        final host = await openLyricsHost(tester);
        await _key(tester, LogicalKeyboardKey.keyL);
        await tester.pumpAndSettle();
        host.container.read(nowPlayingPanelProvider.notifier).close();
        await tester.pump();
        await settleSlide(tester);
        expect(find.byType(DesktopNowPlaying), findsNothing);
        await _key(tester, LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('V still works with the pointer resting on the header', (
      tester,
    ) async {
      await _open(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byIcon(KIcons.collapse)));
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.keyV);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DesktopTrackColumn), findsNothing);
      await mouse.removePointer();
    });
  });

  testWidgets('no player bar or mini player shows under the screen', (
    tester,
  ) async {
    await _open(tester);
    // The player bar button and the cover both carry this name.
    expect(byAnyIconButton('Open Now Playing'), findsNothing);
    expect(find.byTooltip('Open Now Playing'), findsNothing);
  });

  testWidgets('narrowing the window hands Now Playing to the mobile page', (
    tester,
  ) async {
    final container = await pumpKanaruApp(
      tester,
      overrides: [hasCurrentTrackProvider.overrideWithValue(true)],
    );
    final locations = <String>[];
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    void record() => locations.add(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
    );
    router.routerDelegate.addListener(record);
    addTearDown(() => router.routerDelegate.removeListener(record));

    container.read(nowPlayingPanelProvider.notifier).open();
    await tester.pump();
    for (final width in [400.0, 1280.0, 400.0, 1280.0, 400.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }
    await tester.pumpAndSettle();
    // One hand-over to the page (which leaves again: nothing is playing in
    // this app harness), the panel is closed, and nothing loops.
    expect(locations.where((l) => l == '/now-playing').length, 1);
    expect(container.read(nowPlayingPanelProvider).open, isFalse);
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      isNot('/now-playing'),
    );
  });
}
