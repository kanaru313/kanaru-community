import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';

import '../../support/icon_button_finders.dart';
import 'support/settings_host.dart';

/// The preview card labelled [label] that reports itself selected.
Finder _selected(String label) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.properties.label == label &&
      w.properties.selected == true,
  description: 'selected "$label"',
);

const _names = {
  'bars': 'Bars',
  'dots': 'Dots',
  'line': 'Line',
  'mirror': 'Mirror',
  'squiggle': 'Squiggle',
  'flat': 'Flat bar',
};

void main() {
  for (final (name, size) in [
    ('mobile', const Size(400, 900)),
    ('desktop', const Size(1400, 900)),
  ]) {
    group(name, () {
      testWidgets('six cards, bars chosen by default, no caption line', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpSettings(tester, location: SettingsPaths.seekBar, size: size);
        expect(
          find.text('Used in Now Playing and the lyrics screen.'),
          findsNothing,
        );
        for (final label in _names.values) {
          expect(find.text(label), findsOneWidget);
        }
        expect(_selected('Bars'), findsOneWidget);
        for (final label in _names.values.skip(1)) {
          expect(_selected(label), findsNothing);
        }
        semantics.dispose();
      });

      testWidgets('choosing each card writes playback.seek_bar_style', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final h = await pumpSettings(
          tester,
          location: SettingsPaths.seekBar,
          size: size,
        );
        for (final MapEntry(key: stored, value: label) in _names.entries) {
          await tester.ensureVisible(find.text(label));
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(h.store.read('playback.seek_bar_style'), stored);
          expect(_selected(label), findsOneWidget);
        }
        semantics.dispose();
      });
    });
  }

  testWidgets('a style stored before the split shows bars, unchanged', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final h = await pumpSettings(tester, location: SettingsPaths.seekBar);
    await h.store.write('playback.seek_bar_style', 'waveform');
    await tester.pumpAndSettle();
    expect(_selected('Bars'), findsOneWidget);
    expect(h.store.read('playback.seek_bar_style'), 'waveform');
    semantics.dispose();
  });

  testWidgets('an unknown stored style shows bars', (tester) async {
    final semantics = tester.ensureSemantics();
    final h = await pumpSettings(tester, location: SettingsPaths.seekBar);
    await h.store.write('playback.seek_bar_style', 'sparkle');
    await tester.pumpAndSettle();
    expect(_selected('Bars'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('header back goes to Appearance when opened directly', (
    tester,
  ) async {
    final h = await pumpSettings(tester, location: SettingsPaths.seekBar);
    await tester.tap(byIconButton('Back'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.appearance,
    );
  });
}
