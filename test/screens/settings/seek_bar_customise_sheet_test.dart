import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/seek_bar_options.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru/src/playback/state/seek_bar_style_provider.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';

import '../../support/icon_button_finders.dart';
import 'support/settings_host.dart';

/// The semantics node labelled [label] whose enabled state is [enabled].
SemanticsFinder _button(String label, {required bool enabled}) =>
    find.semantics.byPredicate((node) {
      final data = node.getSemanticsData();
      return data.label.split('\n').contains(label) &&
          data.flagsCollection.isEnabled ==
              (enabled ? Tristate.isTrue : Tristate.isFalse);
    }, describeMatch: (_) => '${enabled ? 'enabled' : 'disabled'} "$label"');

/// Opens the customise sheet of the style card titled [card].
Future<SettingsHarness> _open(
  WidgetTester tester,
  String card, {
  Size size = const Size(400, 900),
}) async {
  final h = await pumpSettings(
    tester,
    location: SettingsPaths.seekBar,
    size: size,
    reduceMotion: true,
  );
  // Bars is chosen on first run; tapping a chosen card would open its sheet.
  if (card != 'Bars') {
    await tester.ensureVisible(find.text(card));
    await tester.tap(find.text(card));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text('Customise'));
  await tester.tap(find.text('Customise'));
  await tester.pumpAndSettle();
  return h;
}

Future<void> _pick(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, size) in [
    ('mobile', const Size(400, 900)),
    ('desktop', const Size(1400, 900)),
  ]) {
    group(name, () {
      testWidgets('the wave group shows its four rows and writes at once', (
        tester,
      ) async {
        final h = await _open(tester, 'Mirror', size: size);
        expect(find.text('Customise · Mirror'), findsOneWidget);
        for (final row in [
          'Density',
          'Played colour',
          'Unplayed part',
          'Seek feedback',
        ]) {
          expect(find.text(row), findsOneWidget);
        }
        await _pick(tester, 'Dense');
        await _pick(tester, 'By height');
        await _pick(tester, 'Outline');
        await _pick(tester, 'Jelly');
        expect(
          h.container.read(waveSeekOptionsProvider),
          const WaveSeekOptions(
            density: WaveDensity.dense,
            played: WavePlayed.height,
            rest: WaveRest.outline,
            feedback: WaveFeedback.jelly,
          ),
        );
        expect(h.store.read('playback.seek_bar_wave'), isA<Map>());
      });

      testWidgets('the squiggle group shows its rows and the drift note only '
          'while the motion follows the music', (tester) async {
        final h = await _open(tester, 'Squiggle', size: size);
        for (final row in ['Wave height', 'Wave length', 'Motion', 'Thumb']) {
          expect(find.text(row), findsOneWidget);
        }
        const note = 'A track with no waveform drifts steadily.';
        expect(find.text(note), findsNothing);
        await _pick(tester, 'Follow music');
        expect(find.text(note), findsOneWidget);
        await _pick(tester, 'Still');
        expect(find.text(note), findsNothing);
        await _pick(tester, 'High');
        await _pick(tester, 'Long');
        await _pick(tester, 'Dot');
        expect(
          h.container.read(squiggleSeekOptionsProvider),
          const SquiggleSeekOptions(
            amplitude: SquiggleAmplitude.high,
            wavelength: SquiggleWavelength.long,
            motion: SquiggleMotion.still,
            thumb: SeekThumb.dot,
          ),
        );
      });

      testWidgets('the flat group shows its rows and writes at once', (
        tester,
      ) async {
        final h = await _open(tester, 'Flat bar', size: size);
        for (final row in [
          'Thickness',
          'Thumb',
          'Played colour',
          'Effect while playing',
        ]) {
          expect(find.text(row), findsOneWidget);
        }
        await _pick(tester, 'Thin');
        await _pick(tester, 'None');
        await _pick(tester, 'Gradient');
        await _pick(tester, 'Comet');
        expect(
          h.container.read(flatSeekOptionsProvider),
          const FlatSeekOptions(
            thickness: FlatThickness.thin,
            thumb: SeekThumb.none,
            played: FlatPlayed.gradient,
            effect: FlatEffect.comet,
          ),
        );
      });
    });
  }

  testWidgets('reset writes the defaults and disables itself', (tester) async {
    final semantics = tester.ensureSemantics();
    final h = await _open(tester, 'Bars');
    expect(_button('Reset to default', enabled: false), findsOneWidget);
    await _pick(tester, 'Outline');
    expect(_button('Reset to default', enabled: true), findsOneWidget);
    await tester.tap(find.text('Reset to default'));
    await tester.pumpAndSettle();
    expect(h.container.read(waveSeekOptionsProvider), WaveSeekOptions.defaults);
    expect(_button('Reset to default', enabled: false), findsOneWidget);
    // Still open: reset asks nothing and closes nothing.
    expect(find.text('Customise · Bars'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('reset leaves the options of the other groups alone', (
    tester,
  ) async {
    final h = await _open(tester, 'Bars');
    const squiggle = SquiggleSeekOptions(motion: SquiggleMotion.still);
    const flat = FlatSeekOptions(effect: FlatEffect.sparks);
    await h.container.read(squiggleSeekOptionsProvider.notifier).set(squiggle);
    await h.container.read(flatSeekOptionsProvider.notifier).set(flat);
    await _pick(tester, 'Dense');
    await tester.tap(find.text('Reset to default'));
    await tester.pumpAndSettle();
    expect(h.container.read(waveSeekOptionsProvider), WaveSeekOptions.defaults);
    expect(h.container.read(squiggleSeekOptionsProvider), squiggle);
    expect(h.container.read(flatSeekOptionsProvider), flat);
  });

  testWidgets('Esc closes the sheet', (tester) async {
    await _open(tester, 'Bars', size: const Size(1400, 900));
    expect(find.text('Customise · Bars'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Customise · Bars'), findsNothing);
  });

  testWidgets('the close button closes the sheet', (tester) async {
    await _open(tester, 'Bars');
    await tester.tap(byIconButton('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Customise · Bars'), findsNothing);
  });

  testWidgets('a tap on the scrim closes the sheet', (tester) async {
    await _open(tester, 'Bars');
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(find.text('Customise · Bars'), findsNothing);
  });

  testWidgets('Back closes the sheet', (tester) async {
    await _open(tester, 'Bars');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Customise · Bars'), findsNothing);
  });

  testWidgets('the sheet preview follows a changed row', (tester) async {
    await _open(tester, 'Bars');
    KWaveLook look() => tester
        .widget<KWaveformSeekBar>(
          find.descendant(
            of: find.byType(KCustomiseSheetFrame),
            matching: find.byType(KWaveformSeekBar),
          ),
        )
        .look;
    expect(look().density, KWaveDensity.mid);
    await _pick(tester, 'Dense');
    expect(look().density, KWaveDensity.dense);
  });

  testWidgets('focus returns to the button that opened the sheet', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpSettings(
      tester,
      location: SettingsPaths.seekBar,
      size: const Size(1400, 1000),
      reduceMotion: true,
    );
    final focused = find.semantics.byPredicate(
      (n) => n.getSemanticsData().flagsCollection.isFocused == Tristate.isTrue,
      describeMatch: (_) => 'focused node',
    );
    String label() => focused.evaluate().isEmpty
        ? ''
        : focused.evaluate().first.getSemanticsData().label;
    for (var i = 0; i < 80 && !label().contains('Customise'); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(label(), contains('Customise'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Customise · Bars'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Customise · Bars'), findsNothing);
    expect(label(), contains('Customise'));
    semantics.dispose();
  });
}
