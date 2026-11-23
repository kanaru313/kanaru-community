import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../online/online_ui_overrides.dart';
import 'picker_harness.dart';

List<Override> _sources() =>
    onlineUiOverrides(sources: [lyricsSource('lrclib', name: 'LRCLIB')]);

SearchScript _script() => SearchScript()
  ..answers['*'] = {
    'lrclib': results([
      candidate('lrclib', 'a'),
      candidate('lrclib', 'b', body: plainBody),
    ]),
  };

Finder _row(String title) => find
    .ancestor(of: find.text(title), matching: find.byType(SelectionRow))
    .first;

Finder _use() => find.widgetWithText(KModalButton, 'Use these lyrics');

/// Presses Tab until the row [title] has the keyboard focus.
Future<void> _tabTo(WidgetTester tester, String title) async {
  for (var i = 0; i < 40; i++) {
    final focus = Focus.maybeOf(tester.element(find.text(title)));
    if (focus?.hasPrimaryFocus ?? false) return;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Tab never reached "$title"');
}

void main() {
  testWidgets('the first result starts chosen and its lyrics show with '
      'timestamps and a gap mark', (tester) async {
    final handle = tester.ensureSemantics();
    await openPicker(
      tester,
      script: _script(),
      overrides: _sources(),
      size: desktopSize,
    );
    await settle(tester);
    expect(tester.getSemantics(_row('Song a')), isSemantics(isSelected: true));
    expect(tester.getSemantics(_row('Song b')), isSemantics(isSelected: false));
    expect(find.text('Preview · LRCLIB'), findsOneWidget);
    expect(find.text('First line'), findsOneWidget);
    expect(find.text('0:12'), findsOneWidget);
    expect(find.text('0:41'), findsOneWidget);
    expect(find.text('♪'), findsOneWidget);
    expect(find.text('For this song only'), findsOneWidget);
    expect(tester.getSemantics(_use()), isSemantics(isEnabled: true));
    handle.dispose();
  });

  testWidgets('choosing another result swaps the preview: plain lyrics have '
      'no timestamps', (tester) async {
    final handle = tester.ensureSemantics();
    await openPicker(
      tester,
      script: _script(),
      overrides: _sources(),
      size: desktopSize,
    );
    await settle(tester);
    await tester.tap(find.text('Song b'));
    await tester.pump();
    expect(tester.getSemantics(_row('Song b')), isSemantics(isSelected: true));
    expect(tester.getSemantics(_row('Song a')), isSemantics(isSelected: false));
    expect(find.text('Plain one'), findsOneWidget);
    expect(find.text('First line'), findsNothing);
    expect(find.text('0:12'), findsNothing);
    handle.dispose();
  });

  testWidgets('without results there is nothing chosen and Use is off', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await openPicker(
      tester,
      script: SearchScript(),
      overrides: _sources(),
      size: desktopSize,
    );
    await settle(tester);
    expect(find.text('Choose a result'), findsOneWidget);
    expect(tester.getSemantics(_use()), isSemantics(isEnabled: false));
    handle.dispose();
  });

  testWidgets('a result without lyrics is fetched; Use waits for them', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final script = SearchScript()
      ..answers['*'] = {
        'lrclib': results([candidate('lrclib', 'two', body: null)]),
      }
      ..bodies['two'] = syncedBody
      ..fetchGates['two'] = Completer<void>();
    await openPicker(
      tester,
      script: script,
      overrides: _sources(),
      size: desktopSize,
    );
    await settle(tester);
    expect(script.fetched, ['two']);
    expect(find.text('Loading lyrics…'), findsOneWidget);
    expect(tester.getSemantics(_use()), isSemantics(isEnabled: false));
    script.fetchGates['two']!.complete();
    await settle(tester);
    expect(find.text('First line'), findsOneWidget);
    expect(tester.getSemantics(_use()), isSemantics(isEnabled: true));
    handle.dispose();
  });

  testWidgets('a failed lyrics fetch says so and keeps Use off', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final script = SearchScript()
      ..answers['*'] = {
        'lrclib': results([candidate('lrclib', 'two', body: null)]),
      };
    await openPicker(
      tester,
      script: script,
      overrides: _sources(),
      size: desktopSize,
    );
    await settle(tester);
    expect(
      find.text('Could not load the lyrics of this result'),
      findsOneWidget,
    );
    expect(tester.getSemantics(_use()), isSemantics(isEnabled: false));
    handle.dispose();
  });

  testWidgets('Use these lyrics closes the picker and keeps the result', (
    tester,
  ) async {
    final picker = await openPicker(
      tester,
      script: _script(),
      overrides: _sources(),
      size: desktopSize,
    );
    await settle(tester);
    await tester.tap(find.text('Song b'));
    await tester.pump();
    await tester.tap(_use());
    await tester.pumpAndSettle();
    expect(find.text('Choose lyrics'), findsNothing);
    expect(picker.online.calls, ['keep:1:lrclib:b:LRCLIB']);
    expect(picker.log, isEmpty);
  });

  testWidgets('Cancel goes back like ←, without writing', (tester) async {
    final picker = await openPicker(
      tester,
      script: _script(),
      overrides: _sources(),
      size: desktopSize,
    );
    await settle(tester);
    await tester.tap(find.widgetWithText(KModalButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Choose lyrics'), findsNothing);
    expect(picker.online.calls, isEmpty);
    expect(picker.log, ['back']);
  });

  testWidgets('✕ closes for good: no way back, nothing written', (
    tester,
  ) async {
    final picker = await openPicker(
      tester,
      script: _script(),
      overrides: _sources(),
      size: desktopSize,
    );
    await settle(tester);
    await tester.tap(
      find.byWidgetPredicate((w) => w is KIconButton && w.tooltip == 'Close'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose lyrics'), findsNothing);
    expect(picker.online.calls, isEmpty);
    expect(picker.log, isEmpty);
  });

  testWidgets('← closes the picker and goes back', (tester) async {
    final picker = await openPicker(
      tester,
      script: _script(),
      overrides: _sources(),
      size: desktopSize,
    );
    await settle(tester);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is KIconButton && w.tooltip == 'Back to Lyrics for this song',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose lyrics'), findsNothing);
    expect(picker.log, ['back']);
  });

  testWidgets(
    'keyboard: Tab reaches a result, Enter chooses it, Esc goes back',
    (tester) async {
      final handle = tester.ensureSemantics();
      final picker = await openPicker(
        tester,
        script: _script(),
        overrides: _sources(),
        size: desktopSize,
      );
      await settle(tester);
      await _tabTo(tester, 'Song b');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        tester.getSemantics(_row('Song b')),
        isSemantics(isSelected: true),
      );
      expect(tester.getSemantics(_use()), isSemantics(isEnabled: true));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Choose lyrics'), findsNothing);
      expect(picker.online.calls, isEmpty);
      // Esc is the way back, like ←.
      expect(picker.log, ['back']);
      handle.dispose();
    },
  );

  testWidgets('following the playing song: a track change closes it once', (
    tester,
  ) async {
    final picker = await openPicker(
      tester,
      script: _script(),
      overrides: _sources(),
      size: desktopSize,
    );
    await settle(tester);
    picker.play(2);
    await tester.pump();
    picker.play(3);
    await tester.pumpAndSettle();
    expect(find.text('Choose lyrics'), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('animations off: the choice and the preview still update', (
    tester,
  ) async {
    await openPicker(
      tester,
      script: _script(),
      overrides: _sources(),
      size: desktopSize,
      disableAnimations: true,
    );
    await settle(tester);
    await tester.tap(find.text('Song b'));
    await tester.pump();
    expect(find.text('Plain one'), findsOneWidget);
  });

  testWidgets('200 % text in a short window does not overflow', (tester) async {
    await openPicker(
      tester,
      script: _script(),
      overrides: _sources(),
      size: const Size(1200, 560),
      textScale: 2,
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Choose lyrics'), findsOneWidget);
  });
}
