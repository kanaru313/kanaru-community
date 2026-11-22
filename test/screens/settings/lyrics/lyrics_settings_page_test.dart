import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../support/settings_host.dart';

const _mobile = Size(400, 3000);
const _desktop = Size(1400, 3000);

Future<SettingsHarness> _open(
  WidgetTester tester, {
  Size size = _mobile,
  double textScale = 1,
}) => pumpSettings(
  tester,
  location: SettingsPaths.lyrics,
  size: size,
  textScale: textScale,
);

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SetupValueRow));

void main() {
  /// Each live row: its title, caption (null when none), option to choose,
  /// the stored key and the stored name of that option.
  final live = <(String, String?, String, String, String)>[
    (
      'Lyrics text size',
      'Applies to the lyrics screen, the Lyrics tab and the lyrics card.',
      'Large',
      'lyrics.font_scale',
      'large',
    ),
    ('Lyrics alignment', null, 'Center', 'lyrics.align', 'center'),
    (
      'Return to the current line',
      'After you scroll the lyrics by hand. Off keeps the lyrics still until '
          'you tap “Back to current line”.',
      '5 seconds',
      'lyrics.auto_return',
      's5',
    ),
    (
      'Dim the lines not being sung',
      null,
      'Strongly dimmed',
      'lyrics.dim',
      'strong',
    ),
    (
      'Lyrics on this device',
      'Synced lyrics always win over plain ones.',
      '.lrc file first',
      'lyrics.local_first',
      'lrc',
    ),
  ];

  for (final (title, caption, option, key, stored) in live) {
    testWidgets('$title opens its picker and writes $key', (tester) async {
      final h = await _open(tester);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      if (caption != null) expect(find.text(caption), findsOneWidget);
      await tester.tap(find.text(option));
      await tester.pumpAndSettle();
      expect(h.store.read(key), stored);
      // Picker closed; the row's line shows the new choice.
      expect(
        find.descendant(of: _row(title), matching: find.text(option)),
        findsOneWidget,
      );
    });
  }

  testWidgets('dismissing a picker without choosing keeps the stored value', (
    tester,
  ) async {
    final h = await _open(tester, size: _desktop);
    final before = h.store.read('lyrics.font_scale');
    await tester.tap(find.text('Lyrics text size'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectionRow), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(SelectionRow), findsNothing);
    expect(h.store.read('lyrics.font_scale'), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a default option says so', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Lyrics alignment'));
    await tester.pumpAndSettle();
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('soon rows are inert and marked coming soon', (tester) async {
    final h = await _open(tester);
    const soon = [
      'Transliteration',
      'Keep the screen on',
      'Find lyrics for songs without any',
      'Save found lyrics as .lrc',
      'Add an online lyrics source',
      'Lyrics on the lock screen and notification',
      'Default translation service',
      'Default translation language',
      'Translate ahead',
      'Add a translation service',
      'Add a speech-to-text plugin',
    ];
    for (final title in soon) {
      final row = tester.widget<SetupValueRow>(_row(title));
      expect(row.comingSoon, isTrue, reason: title);
      expect(row.onTap, isNull, reason: title);
    }
    expect(find.text('Coming soon'), findsNWidgets(soon.length));
    await tester.tap(find.text('Transliteration'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectionRow), findsNothing);
    expect(h.store.read('lyrics.font_scale'), isNull);
  });

  testWidgets('mobile shows keep-screen-on and lock screen, not floating', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('Keep the screen on'), findsOneWidget);
    expect(
      find.text('Lyrics on the lock screen and notification'),
      findsOneWidget,
    );
    expect(find.text('Floating lyrics'), findsNothing);
    expect(find.byType(ProBadge), findsNothing);
  });

  testWidgets('desktop shows floating lyrics with Pro, not the mobile rows', (
    tester,
  ) async {
    await _open(tester, size: _desktop);
    expect(find.text('Floating lyrics'), findsOneWidget);
    expect(find.byType(ProBadge), findsOneWidget);
    expect(find.text('Keep the screen on'), findsNothing);
    expect(
      find.text('Lyrics on the lock screen and notification'),
      findsNothing,
    );
  });

  testWidgets('the speech section has its hint', (tester) async {
    await _open(tester);
    expect(find.text('Create lyrics from audio'), findsOneWidget);
    expect(byIconButton('About Create lyrics from audio'), findsOneWidget);
  });

  testWidgets('200 % text scale does not overflow', (tester) async {
    await _open(tester, textScale: 2);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop: Tab to a row and Enter opens its picker', (
    tester,
  ) async {
    await _open(tester, size: _desktop);
    var focused = false;
    for (var i = 0; i < 12 && !focused; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final ctx = FocusManager.instance.primaryFocus?.context;
      focused =
          ctx != null &&
          find
              .descendant(
                of: find.byWidget(ctx.widget),
                matching: find.text('Lyrics text size'),
              )
              .evaluate()
              .isNotEmpty;
      if (!focused && ctx != null) {
        focused = find
            .ancestor(
              of: find.byWidget(ctx.widget),
              matching: _row('Lyrics text size'),
            )
            .evaluate()
            .isNotEmpty;
      }
    }
    expect(focused, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(SelectionRow), findsNWidgets(3));
  });

  testWidgets('back arrow leads to the root', (tester) async {
    final h = await _open(tester);
    await tester.tap(byIconButton('Back'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.root,
    );
  });
}
