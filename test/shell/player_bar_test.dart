import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';
import 'package:kanaru/src/playback/state/playing_cover_colors.dart';
import 'package:kanaru/src/playback/ui/transport_buttons.dart';
import 'package:kanaru/src/playback/ui/volume_control.dart';
import 'package:kanaru/src/screens/now_playing/ui/favorite_button.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/shell/state/right_panel.dart';
import 'package:kanaru/src/shell/ui/player_bar.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../playback/support/ui_host.dart';

Widget get _bar =>
    const Align(alignment: Alignment.bottomCenter, child: PlayerBar());

Future<UiHost> _pump(WidgetTester tester, double width) =>
    pumpWithPlayer(tester, _bar, size: Size(width, 700));

void main() {
  testWidgets('full layout at 1280: every control is there, 88 dp tall', (
    tester,
  ) async {
    await _pump(tester, 1280);
    expect(tester.getSize(find.byType(PlayerBar)).height, 88);
    expect(find.byType(FavoriteButton), findsOneWidget);
    expect(find.byType(ShuffleButton), findsOneWidget);
    expect(find.byType(RepeatButton), findsOneWidget);
    expect(find.byType(VolumeControl), findsOneWidget);
    expect(find.byType(KSeekBar), findsOneWidget);
    expect(find.byTooltip('Lyrics'), findsOneWidget);
    expect(find.byTooltip('Queue'), findsOneWidget);
    expect(find.byTooltip('Open Now Playing'), findsWidgets);
  });

  testWidgets('sleep timer is dimmed with a coming-soon tooltip', (
    tester,
  ) async {
    await _pump(tester, 1280);
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(KIcons.sleepTimer),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(button.tooltip, contains('Coming soon'));
  });

  testWidgets('the heart sits right after the title text', (tester) async {
    await _pump(tester, 1280);
    final title = find.descendant(
      of: find.byType(PlayerBar),
      matching: find.text('T0'),
    );
    // Text edge to the 24 dp icon: the button's own 12 dp padding.
    final gap =
        tester.getCenter(find.byIcon(KIcons.heart)).dx -
        12 -
        tester.getTopRight(title).dx;
    expect(gap, inInclusiveRange(0, 16));
  });

  testWidgets('under 1000 the volume, sleep timer and heart go', (
    tester,
  ) async {
    await _pump(tester, 999);
    expect(find.byType(VolumeControl), findsNothing);
    expect(find.byIcon(KIcons.sleepTimer), findsNothing);
    expect(find.byType(FavoriteButton), findsNothing);
    expect(find.byType(ShuffleButton), findsOneWidget);
    expect(find.byType(RepeatButton), findsOneWidget);
    expect(find.byTooltip('Lyrics'), findsOneWidget);
  });

  testWidgets('under 760 shuffle and repeat go too', (tester) async {
    await _pump(tester, 759);
    expect(find.byType(ShuffleButton), findsNothing);
    expect(find.byType(RepeatButton), findsNothing);
    expect(find.byTooltip('Next'), findsOneWidget);
    expect(find.byTooltip('Previous'), findsOneWidget);
    expect(find.byTooltip('Queue'), findsOneWidget);
  });

  testWidgets('a 200-character title ellipsizes at 760 without overflow', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      _bar,
      size: const Size(760, 700),
      play: false,
    );
    final id = host.h.tracks.first.value;
    final title = 'T' * 200;
    await tester.runAsync(
      () => host.h.db.customStatement(
        "UPDATE tracks SET title = '$title' WHERE id = $id",
      ),
    );
    await tester.runAsync(() => host.h.play());
    await host.letStreamsArrive(tester);
    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.text(title));
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('Lyrics, cover and expand open Now Playing', (tester) async {
    final host = await _pump(tester, 1280);
    NowPlayingPanelState panel() =>
        host.container.read(nowPlayingPanelProvider);

    await tester.tap(find.byTooltip('Lyrics'));
    await tester.pump();
    expect(panel().open, isTrue);

    host.container.read(nowPlayingPanelProvider.notifier).close();
    await tester.tap(find.byTooltip('Open Now Playing').first);
    await tester.pump();
    expect(panel().open, isTrue);

    host.container.read(nowPlayingPanelProvider.notifier).close();
    await tester.tap(find.byIcon(KIcons.openFull));
    await tester.pump();
    expect(panel().open, isTrue);
  });

  testWidgets('Queue toggles the right panel and is tonal while it is open', (
    tester,
  ) async {
    final host = await _pump(tester, 1280);
    RightPanelKind kind() => host.container.read(rightPanelProvider);
    IconButton button() => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, KIcons.queueMusic),
    );

    expect(button().isSelected, isFalse);
    await tester.tap(find.byTooltip('Queue'));
    await tester.pump();
    expect(kind(), RightPanelKind.queue);
    expect(button().isSelected, isTrue);
    expect(
      host.container.read(nowPlayingPanelProvider).open,
      isFalse,
      reason: 'the Queue button never opens Now Playing',
    );

    await tester.tap(find.byTooltip('Queue'));
    await tester.pump();
    expect(kind(), RightPanelKind.closed);
    expect(button().isSelected, isFalse);
  });

  group('controls drive the player', () {
    testWidgets('Play/Pause, Next and Previous', (tester) async {
      final host = await _pump(tester, 1280);
      await host.tap(tester, find.byTooltip('Pause'));
      expect(host.h.c.intent, PlayIntent.paused);
      await host.tap(tester, find.byTooltip('Next'));
      expect(host.h.c.queueState.currentItem?.trackId, host.h.tracks[1]);
      await host.tap(tester, find.byTooltip('Previous'));
      expect(host.h.c.queueState.currentItem?.trackId, host.h.tracks[0]);
    });

    testWidgets('Shuffle toggles on and off', (tester) async {
      final host = await _pump(tester, 1280);
      expect(host.container.read(shuffleSettingProvider), isFalse);
      await host.tap(tester, find.byTooltip('Shuffle'));
      expect(host.container.read(shuffleSettingProvider), isTrue);
      expect(find.byKey(KToggleIconButton.dotKey), findsOneWidget);
      await host.tap(tester, find.byTooltip('Shuffle'));
      expect(host.container.read(shuffleSettingProvider), isFalse);
    });

    testWidgets('Repeat opens a menu; a row sets the mode', (tester) async {
      final host = await _pump(tester, 1280);
      RepeatMode mode() => host.container.read(repeatSettingProvider);
      expect(mode(), RepeatMode.off);
      await host.tap(tester, find.byTooltip('Stop at the end'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectionRow), findsNWidgets(5));
      expect(mode(), RepeatMode.off, reason: 'the button only opens it');
      await host.tap(tester, find.text('Repeat this song'));
      await tester.pumpAndSettle();
      expect(mode(), RepeatMode.one);
      expect(find.byIcon(KIcons.repeatOne), findsOneWidget);
      expect(find.byTooltip('Repeat this song'), findsOneWidget);
      expect(find.byType(SelectionRow), findsNothing);
    });

    testWidgets('mute sets volume 0 and unmute restores the level', (
      tester,
    ) async {
      final host = await _pump(tester, 1280);
      await host.run(tester, () => host.h.c.setVolume(40));
      expect(host.container.read(volumeSettingProvider), 40);
      await host.tap(tester, find.byTooltip('Mute'));
      expect(host.container.read(volumeSettingProvider), 0);
      await host.tap(tester, find.byTooltip('Unmute'));
      expect(host.container.read(volumeSettingProvider), 40);
    });

    testWidgets('the scroll wheel steps the volume by 5, from the level '
        'before a mute', (tester) async {
      final host = await _pump(tester, 1280);
      int volume() => host.container.read(volumeSettingProvider);
      final control = find.byType(VolumeControl);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      Future<void> scroll(double dy) async {
        await tester.runAsync(() async {
          await tester.sendEventToBinding(
            pointer.hover(tester.getCenter(control)),
          );
          await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
          await host.h.settle();
        });
        await tester.pump();
      }

      await host.run(tester, () => host.h.c.setVolume(40));
      await scroll(-20);
      expect(volume(), 45);
      await scroll(20);
      await scroll(20);
      expect(volume(), 35);

      await host.tap(tester, find.byTooltip('Mute'));
      expect(volume(), 0);
      await scroll(-20);
      expect(volume(), 40, reason: 'continues from 35, not from 0');
    });

    testWidgets('a drag that outlives its track does not seek the next one', (
      tester,
    ) async {
      final host = await _pump(tester, 1280);
      await host.run(
        tester,
        () async => host.h.engine.emit(
          EngineLoaded(host.h.loadedToken, const Duration(seconds: 100)),
        ),
      );

      final strip = tester.getRect(find.byType(KSeekBar));
      final drag = await tester.startGesture(
        Offset(strip.left + strip.width / 4, strip.center.dy),
        kind: PointerDeviceKind.mouse,
      );
      await drag.moveBy(const Offset(40, 0));
      await tester.pump();

      // The engine moves on mid-drag; the new duration is not known yet.
      final nextToken = host.h.engine.nexts.last!.token;
      await host.run(
        tester,
        () async => host.h.engine.emit(EngineAdvanced(nextToken)),
      );
      await drag.moveBy(const Offset(40, 0));
      await tester.runAsync(() async {
        await drag.up();
        await host.h.settle();
      });
      await tester.pump();

      expect(
        host.h.engine.commands.where((c) => c.startsWith('seek:')),
        isEmpty,
      );

      // The strip is not stuck: the next drag on the new track seeks.
      await host.run(
        tester,
        () async => host.h.engine.emit(
          EngineLoaded(nextToken, const Duration(seconds: 200)),
        ),
      );
      final again = await tester.startGesture(
        Offset(strip.left + strip.width / 4, strip.center.dy),
        kind: PointerDeviceKind.mouse,
      );
      await again.moveBy(const Offset(40, 0));
      await tester.runAsync(() async {
        await again.up();
        await host.h.settle();
      });
      await tester.pump();
      expect(
        host.h.engine.commands.where((c) => c.startsWith('seek:')),
        hasLength(1),
      );
    });
  });

  group('cover tint', () {
    const colors = CoverColors(
      seed: 0xFFE63946,
      palette: [0xFFE63946, 0xFFFF7F11, 0xFFD90368],
    );
    final palette = [for (final c in colors.palette) Color(c)];

    Override cover(PlayingCoverColors value) =>
        playingCoverColorsProvider.overrideWithValue(value);

    /// The gradient the bar paints, after its colour tween has finished.
    Future<List<Color>> stopsOf(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 500));
      final gradients = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(CoverTintBackground),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.gradient)
          .whereType<LinearGradient>();
      return gradients.single.colors;
    }

    ColorScheme schemeOf(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(PlayerBar))).colorScheme;

    /// Expected painted stops: the readable stops (padded by repeating the
    /// last one) with alpha multiplied by [strength].
    List<Color> expected(ColorScheme s, double strength) {
      final stops = readableGradientStops(
        palette,
        base: s.surfaceContainerLow,
        onSurface: s.onSurface,
        onSurfaceVariant: s.onSurfaceVariant,
        brightness: s.brightness,
      );
      return [
        for (var i = 0; i < maxGradientStops; i++)
          stops[i < stops.length ? i : stops.length - 1].withValues(
            alpha: stops[i < stops.length ? i : stops.length - 1].a * strength,
          ),
      ];
    }

    testWidgets('colours tint the bar by the strength constant', (
      tester,
    ) async {
      await pumpWithPlayer(
        tester,
        _bar,
        size: const Size(1280, 700),
        overrides: [cover(const PlayingCoverColorsFound(colors))],
      );
      final painted = await stopsOf(tester);
      final want = expected(schemeOf(tester), playerBarTintStrength);
      expect(painted, hasLength(want.length));
      for (var i = 0; i < want.length; i++) {
        expect(painted[i].a, closeTo(want[i].a, 0.005));
        expect(painted[i].toARGB32() & 0xFFFFFF, want[i].toARGB32() & 0xFFFFFF);
      }
      expect(painted.any((c) => c.a > 0), isTrue);
    });

    testWidgets('no colours: the flat surfaceContainerLow, no tint', (
      tester,
    ) async {
      await pumpWithPlayer(
        tester,
        _bar,
        size: const Size(1280, 700),
        overrides: [cover(const PlayingCoverColorsNone())],
      );
      final painted = await stopsOf(tester);
      expect(painted.every((c) => c.a == 0), isTrue);
      final base = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(CoverTintBackground),
              matching: find.byType(ColoredBox),
            ),
          )
          .first;
      expect(base.color, schemeOf(tester).surfaceContainerLow);
    });

    testWidgets('pending colours pass the loading flag', (tester) async {
      await pumpWithPlayer(
        tester,
        _bar,
        size: const Size(1280, 700),
        overrides: [cover(const PlayingCoverColorsPending())],
      );
      final tint = tester.widget<CoverTintBackground>(
        find.byType(CoverTintBackground),
      );
      expect(tint.loading, isTrue);
      expect(tint.palette, isNull);
      expect(tint.strength, playerBarTintStrength);
    });

    test('the tint strength is a fraction the contrast test can divide by', () {
      expect(playerBarTintStrength, greaterThan(0));
      expect(playerBarTintStrength, lessThanOrEqualTo(1));
    });

    // The painted stops are scaled by the strength constant; undoing that
    // gives the full-strength tint, the worst case for any value up to 1.
    for (final brightness in Brightness.values) {
      for (final p in const {
        'saturated': [0xFFE63946, 0xFFFF7F11, 0xFFD90368],
        'dark': [0xFF0D1B2A, 0xFF1B263B, 0xFF415A77],
      }.entries) {
        testWidgets('title and artist keep 4.5:1 at full tint '
            '(${p.key}, ${brightness.name})', (tester) async {
          await pumpWithPlayer(
            tester,
            _bar,
            size: const Size(1280, 700),
            brightness: brightness,
            overrides: [
              cover(
                PlayingCoverColorsFound(
                  CoverColors(seed: p.value.first, palette: p.value),
                ),
              ),
            ],
          );
          final painted = await stopsOf(tester);
          final s = schemeOf(tester);
          expect(painted.any((c) => c.a > 0), isTrue);
          for (final c in painted) {
            final full = c.withValues(
              alpha: (c.a / playerBarTintStrength).clamp(0.0, 1.0),
            );
            final blend = Color.alphaBlend(full, s.surfaceContainerLow);
            for (final text in [s.onSurface, s.onSurfaceVariant]) {
              expect(_contrast(text, blend), greaterThanOrEqualTo(4.5));
            }
          }
        });
      }
    }
  });
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
