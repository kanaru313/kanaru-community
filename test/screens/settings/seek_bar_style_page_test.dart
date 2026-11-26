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

void main() {
  for (final (name, size) in [
    ('mobile', const Size(400, 900)),
    ('desktop', const Size(1400, 900)),
  ]) {
    group(name, () {
      testWidgets('waveform is the default choice', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpSettings(tester, location: SettingsPaths.seekBar, size: size);
        expect(
          find.text('Used in Now Playing and the lyrics screen.'),
          findsOne,
        );
        expect(_selected('Waveform'), findsOneWidget);
        expect(_selected('Flat bar'), findsNothing);
        semantics.dispose();
      });

      testWidgets('choosing a card writes playback.seek_bar_style', (
        tester,
      ) async {
        final h = await pumpSettings(
          tester,
          location: SettingsPaths.seekBar,
          size: size,
        );
        await tester.tap(find.text('Flat bar'));
        await tester.pumpAndSettle();
        expect(h.store.read('playback.seek_bar_style'), 'flat');
        await tester.tap(find.text('Waveform'));
        await tester.pumpAndSettle();
        expect(h.store.read('playback.seek_bar_style'), 'bars');
      });
    });
  }

  testWidgets('a style stored before the split loads as bars, unchanged', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final h = await pumpSettings(tester, location: SettingsPaths.seekBar);
    await h.store.write('playback.seek_bar_style', 'waveform');
    await tester.pumpAndSettle();
    expect(_selected('Waveform'), findsOneWidget);
    expect(h.store.read('playback.seek_bar_style'), 'waveform');
    semantics.dispose();
  });

  testWidgets('an unknown stored style falls back to the waveform', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final h = await pumpSettings(tester, location: SettingsPaths.seekBar);
    await h.store.write('playback.seek_bar_style', 'sparkle');
    await tester.pumpAndSettle();
    expect(_selected('Waveform'), findsOneWidget);
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
