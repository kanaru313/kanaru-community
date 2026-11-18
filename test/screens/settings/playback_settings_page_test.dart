import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/icon_button_finders.dart';
import 'support/settings_host.dart';

const _listenKey = 'playback.listen_rule';

/// The slider whose spoken value is [label] (its live label).
Finder bySliderValue(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is Slider &&
      widget.semanticFormatterCallback?.call(widget.value) == label,
  description: 'Slider at "$label"',
);

/// The listen row's line under the title, read from the row's own subtree.
Finder _listenRow() => find.ancestor(
  of: find.text('Count a listen after'),
  matching: find.byType(SetupValueRow),
);

SetupValueRow _row(WidgetTester tester) =>
    tester.widget<SetupValueRow>(_listenRow());

void main() {
  const tall = Size(400, 1800);

  Future<SettingsHarness> open(WidgetTester tester, {Size size = tall}) =>
      pumpSettings(tester, location: SettingsPaths.playback, size: size);

  testWidgets('shows the three blocks; sound and some play rows are soon', (
    tester,
  ) async {
    await open(tester);
    for (final text in [
      'Playback',
      'Gapless playback',
      'Fade in when playing',
      'Fade out when pausing',
      'Previous button',
      'Crossfade',
      'ReplayGain',
      'Preamp',
      'Prevent clipping',
      'Record listening history',
      'Count a listen after',
    ]) {
      expect(find.text(text), findsAtLeastNWidgets(1), reason: text);
    }
    // Output device is desktop only.
    expect(find.text('Output device'), findsNothing);
    // Gapless, fade in, fade out, crossfade, ReplayGain, preamp, clipping.
    expect(find.text('Coming soon'), findsNWidgets(7));
  });

  testWidgets('desktop adds the output device row, coming soon', (
    tester,
  ) async {
    await open(tester, size: const Size(1400, 1800));
    expect(find.text('Output device'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(8));
  });

  group('Previous button', () {
    testWidgets('default value, then the picker writes the key', (
      tester,
    ) async {
      final h = await open(tester);
      expect(find.text('Always go to the previous track'), findsOneWidget);
      await tester.tap(find.text('Previous button'));
      await tester.pumpAndSettle();
      expect(find.text('Default'), findsOneWidget);
      await tester.tap(find.text('Restart after 3 seconds'));
      await tester.pumpAndSettle();
      expect(h.store.read('playback.previous_button'), 'restartAfter3s');
      expect(find.text('Restart after 3 seconds'), findsOneWidget);
      expect(find.text('Always go to the previous track'), findsNothing);
    });

    testWidgets('an unknown stored value reads as the default', (tester) async {
      final h = await open(tester);
      await h.store.write('playback.previous_button', 'nope');
      await tester.pumpAndSettle();
      expect(find.text('Always go to the previous track'), findsOneWidget);
    });
  });

  group('Listen rule', () {
    testWidgets('value line follows the stored rule', (tester) async {
      final h = await open(tester);
      expect(find.text('4 minutes or 50 %'), findsOneWidget);
      await h.store.write(_listenKey, {'afterMs': 0, 'percent': 100});
      await tester.pumpAndSettle();
      expect(find.text('Listen to the end'), findsOneWidget);
      await h.store.write(_listenKey, {'afterMs': 0, 'percent': 50});
      await tester.pumpAndSettle();
      expect(find.text('50 % of the track'), findsOneWidget);
      await h.store.write(_listenKey, {'afterMs': 90000, 'percent': 100});
      await tester.pumpAndSettle();
      expect(find.text('1 min 30 s or the whole track'), findsOneWidget);
      await h.store.write(_listenKey, {'afterMs': 600000, 'percent': 75});
      await tester.pumpAndSettle();
      expect(find.text('10 minutes or 75 %'), findsOneWidget);
    });

    testWidgets('a bad stored rule reads as the default', (tester) async {
      final h = await open(tester);
      await h.store.write(_listenKey, {'afterMs': 'x'});
      await tester.pumpAndSettle();
      expect(find.text('4 minutes or 50 %'), findsOneWidget);
    });

    testWidgets('the sheet shows both sliders; each keeps the other', (
      tester,
    ) async {
      final h = await open(tester);
      await tester.tap(find.text('Count a listen after').first);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'A track counts as a listen when it reaches whichever '
          'comes first.',
        ),
        findsOneWidget,
      );
      expect(find.byType(Slider), findsNWidgets(2));
      expect(bySliderValue('After 4 minutes of listening'), findsOneWidget);
      expect(bySliderValue('or after 50 % of the track'), findsOneWidget);

      // Focus is on the first (time) slider: one stop right = 5 minutes.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(h.store.read(_listenKey), {'afterMs': 300000, 'percent': 50});
      // Home = "Not used".
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(h.store.read(_listenKey), {'afterMs': 0, 'percent': 50});

      // Move the percent slider: the time part stays 0.
      await tester.tap(find.byType(Slider).last);
      await tester.pumpAndSettle();
      final stored = h.store.read(_listenKey)! as Map;
      expect(stored['afterMs'], 0);
    });

    testWidgets('dimmed with a reason while history is off; no sheet', (
      tester,
    ) async {
      final h = await open(tester);
      expect(_row(tester).enabled, isTrue);
      await tester.tap(find.text('Record listening history'));
      await tester.pumpAndSettle();
      expect(h.store.read('playback.history_enabled'), false);
      expect(_row(tester).enabled, isFalse);
      expect(
        find.text('Turn on Record listening history to use this'),
        findsOneWidget,
      );
      expect(find.textContaining('what was recorded stays'), findsOneWidget);
      await tester.tap(find.text('Count a listen after'));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNothing);
      // On again: the row is live and the reason is gone.
      await tester.tap(find.text('Record listening history'));
      await tester.pumpAndSettle();
      expect(h.store.read('playback.history_enabled'), true);
      expect(_row(tester).enabled, isTrue);
    });
  });

  testWidgets('back arrow leads to the root', (tester) async {
    final h = await open(tester);
    await tester.tap(byIconButton('Back'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.root,
    );
  });
}
