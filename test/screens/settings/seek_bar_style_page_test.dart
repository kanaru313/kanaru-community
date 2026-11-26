import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/settings/ui/appearance/seek_bar_preview_card.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
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

bool _isHelpButton(Widget w) => w is KHelpIcon;

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
        await pumpSettings(
          tester,
          location: SettingsPaths.seekBar,
          size: size,
          reduceMotion: true,
        );
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
          reduceMotion: true,
        );
        // Bars is chosen first: tapping it again opens its options, so it goes last.
        final order = [..._names.entries.skip(1), _names.entries.first];
        for (final MapEntry(key: stored, value: label) in order) {
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
    final h = await pumpSettings(
      tester,
      location: SettingsPaths.seekBar,
      reduceMotion: true,
    );
    await h.store.write('playback.seek_bar_style', 'waveform');
    await tester.pumpAndSettle();
    expect(_selected('Bars'), findsOneWidget);
    expect(h.store.read('playback.seek_bar_style'), 'waveform');
    semantics.dispose();
  });

  testWidgets('an unknown stored style shows bars', (tester) async {
    final semantics = tester.ensureSemantics();
    final h = await pumpSettings(
      tester,
      location: SettingsPaths.seekBar,
      reduceMotion: true,
    );
    await h.store.write('playback.seek_bar_style', 'sparkle');
    await tester.pumpAndSettle();
    expect(_selected('Bars'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('header back goes to Appearance when opened directly', (
    tester,
  ) async {
    final h = await pumpSettings(
      tester,
      location: SettingsPaths.seekBar,
      reduceMotion: true,
    );
    await tester.tap(byIconButton('Back'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.appearance,
    );
  });

  testWidgets('no plugin block; one ⓘ, after the Style title only', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.seekBar,
      reduceMotion: true,
    );
    expect(find.text('Style'), findsOneWidget);
    expect(find.text('From plugins'), findsNothing);
    expect(byIconButton('About Style'), findsOneWidget);
    expect(find.byWidgetPredicate(_isHelpButton), findsOneWidget);
    expect(
      find.text('Tap or drag to try seeking · drag up to cancel'),
      findsOneWidget,
    );
  });

  testWidgets('the preview starts paused under reduced motion; its button '
      'toggles it', (tester) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.seekBar,
      reduceMotion: true,
    );
    expect(byIconButton('Play'), findsOneWidget);
    expect(byIconButton('Pause'), findsNothing);
    await tester.tap(byIconButton('Play'));
    await tester.pump();
    final clock = tester.widget<SeekDemoBar>(find.byType(SeekDemoBar)).clock;
    final at = clock.position;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(byIconButton('Pause'), findsOneWidget);
    expect(clock.position, greaterThan(at));
    await tester.tap(byIconButton('Pause'));
    await tester.pump();
    expect(byIconButton('Play'), findsOneWidget);
  });

  testWidgets('the preview seeks its own clock and no player', (tester) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.seekBar,
      reduceMotion: true,
    );
    final clock = tester.widget<SeekDemoBar>(find.byType(SeekDemoBar)).clock;
    final start = clock.position;
    await tester.tapAt(tester.getCenter(find.byType(SeekDemoBar)));
    await tester.pump();
    expect(clock.position, isNot(start));
  });

  group('fallback star', () {
    const useSquiggle = 'Use Squiggle while a track has no waveform';
    const useFlat = 'Use Flat bar while a track has no waveform';
    const shown = 'Shown while a track has no waveform';

    testWidgets('only Squiggle and Flat bar carry one', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.seekBar,
        reduceMotion: true,
        size: const Size(400, 1400),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is KIconButton && w.tooltip.contains('no waveform'),
        ),
        findsNWidgets(2),
      );
      // Flat bar has it by default.
      expect(byIconButton(shown), findsOneWidget);
      expect(byIconButton(useSquiggle), findsOneWidget);
    });

    testWidgets('moves to Squiggle without changing the chosen style; the '
        'filled one does nothing', (tester) async {
      final h = await pumpSettings(
        tester,
        location: SettingsPaths.seekBar,
        reduceMotion: true,
        size: const Size(400, 1400),
      );
      await tester.tap(byIconButton(useSquiggle));
      await tester.pumpAndSettle();
      expect(h.store.read('playback.seek_bar_fallback'), 'squiggle');
      expect(h.store.read('playback.seek_bar_style'), isNull);
      expect(byIconButton(useFlat), findsOneWidget);
      await tester.tap(byIconButton(shown));
      await tester.pumpAndSettle();
      expect(h.store.read('playback.seek_bar_fallback'), 'squiggle');
      await tester.tap(byIconButton(useFlat));
      await tester.pumpAndSettle();
      expect(h.store.read('playback.seek_bar_fallback'), 'flat');
      expect(h.store.read('playback.seek_bar_style'), isNull);
    });
  });

  group('customise', () {
    testWidgets('only the chosen card has the button', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.seekBar,
        reduceMotion: true,
        size: const Size(400, 1400),
      );
      expect(find.text('Customise'), findsOneWidget);
      await tester.tap(find.text('Dots'));
      await tester.pumpAndSettle();
      expect(find.text('Customise'), findsOneWidget);
    });

    testWidgets('tapping the chosen card again opens its sheet', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.seekBar,
        reduceMotion: true,
        size: const Size(400, 1400),
      );
      await tester.tap(find.text('Flat bar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Customise ·'), findsNothing);
      await tester.tap(find.text('Flat bar'));
      await tester.pumpAndSettle();
      expect(find.text('Customise · Flat bar'), findsOneWidget);
      expect(find.text('Effect while playing'), findsOneWidget);
    });
  });

  testWidgets('desktop: Tab goes card, star, then the card button', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.seekBar,
      size: const Size(1400, 1000),
      reduceMotion: true,
    );
    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('Squiggle'));
    await tester.pumpAndSettle();
    final focused = find.semantics.byPredicate(
      (node) =>
          node.getSemanticsData().flagsCollection.isFocused == Tristate.isTrue,
      describeMatch: (_) => 'focused node',
    );
    final order = <String>[];
    for (var i = 0; i < 80 && !order.contains('action'); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      for (final node in focused.evaluate()) {
        final label = node.getSemanticsData().label;
        final tag = label.startsWith('Squiggle')
            ? 'card'
            : label.contains('Use Squiggle')
            ? 'star'
            : label.contains('Customise')
            ? 'action'
            : null;
        if (tag != null && (order.isEmpty || order.last != tag)) {
          order.add(tag);
        }
      }
    }
    semantics.dispose();
    expect(order, ['card', 'star', 'action']);
  });

  testWidgets('desktop content is 760 wide here and 720 on other pages', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.seekBar,
      size: const Size(1600, 1000),
      reduceMotion: true,
    );
    final seek = tester.getSize(find.byType(PageHeader)).width;
    await pumpSettings(
      tester,
      location: SettingsPaths.appearance,
      size: const Size(1600, 1000),
      reduceMotion: true,
    );
    final other = tester.getSize(find.byType(PageHeader)).width;
    expect(seek - other, KLayout.settingsWide - KLayout.settings);
    expect(KLayout.settings, 720);
    expect(KLayout.settingsWide, 760);
  });
}
