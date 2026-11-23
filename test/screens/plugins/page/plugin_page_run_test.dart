import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show TextButton;
import 'package:intl/intl.dart';
import 'package:kanaru/src/plugins/data/run/plugin_pauses.dart';
import 'package:kanaru/src/plugins/state/alerts_provider.dart';
import 'package:kanaru/src/screens/settings/ui/lyrics/lyrics_settings_page.dart';

import '../support/install_fixtures.dart';
import '../support/page_fixtures.dart';
import '../support/plugin_fixtures.dart';
import '../support/run_fixtures.dart';

const _lyricsOn = 'In use · 2 of 3 · change in Settings › Lyrics › Sources';
const _lyricsOff =
    'Off: searches only when you tap “Find lyrics online…” · '
    'change in Settings › Lyrics › Sources';

Future<void> _pump(
  WidgetTester tester, {
  required RunState run,
  String kind = 'lyrics',
  Set<PluginAlert> alerts = const {},
  List<String> missingConfig = const [],
  Size size = narrowWindow,
}) {
  tester.view.devicePixelRatio = 1;
  return pumpPlugins(
    tester,
    StoreFixture(),
    location: pagePath,
    size: Size(size.width, 2400),
    overrides: [
      ...pageOverrides(
        AsyncData(
          pageData(
            row: pageRow(kind: kind),
            alerts: alerts,
            missingConfig: missingConfig,
          ),
        ),
        ops: FakeInstallOps(),
      ),
      ...run.overrides,
    ],
  );
}

void main() {
  for (final (name, size) in [('narrow', narrowWindow), ('wide', wideWindow)]) {
    group('lyrics row of the head card on $name', () {
      testWidgets('says the place in the order and opens Lời bài', (
        tester,
      ) async {
        final run = RunState(
          sources: [
            lyricsSource('id-a'),
            lyricsSource('id-demo'),
            lyricsSource('id-c', enabled: false),
          ],
        );
        await _pump(tester, run: run, size: size);
        expect(find.text('Find lyrics automatically'), findsOneWidget);
        expect(find.text(_lyricsOn), findsOneWidget);
        await tester.tap(find.text('Find lyrics automatically'));
        await tester.pumpAndSettle();
        expect(find.byType(LyricsSettingsPage), findsOneWidget);
      });

      testWidgets('a source that is switched off says it searches on demand', (
        tester,
      ) async {
        final run = RunState(
          sources: [lyricsSource('id-demo', enabled: false)],
        );
        await _pump(tester, run: run, size: size);
        expect(find.text(_lyricsOff), findsOneWidget);
      });

      testWidgets('before the sources are read there is no state line', (
        tester,
      ) async {
        await _pump(tester, run: RunState(), size: size);
        expect(find.text('Find lyrics automatically'), findsOneWidget);
        expect(find.textContaining('In use'), findsNothing);
        expect(find.textContaining('Off:'), findsNothing);
      });
    });
  }

  testWidgets('a translation plugin keeps its dimmed row', (tester) async {
    await _pump(tester, run: RunState(), kind: 'translate');
    expect(find.text('Default translation service'), findsOneWidget);
    expect(find.text('Find lyrics automatically'), findsNothing);
  });

  group('the 429 band', () {
    testWidgets('says how long and until when, and opens the log', (
      tester,
    ) async {
      final until = DateTime.now().add(const Duration(seconds: 60));
      await _pump(tester, run: RunState(pausedUntil: until));
      expect(
        find.text(
          'Paused for 1 minute: the server says too many requests (429)',
        ),
        findsOneWidget,
      );
      final time = DateFormat('HH:mm').format(until.toLocal());
      expect(
        find.text(
          'Kanaru asks this source again after $time. '
          'Other sources still search as usual.',
        ),
        findsOneWidget,
      );
      // The band's [Log] button; the Data block has a row of the same name.
      await tester.tap(find.widgetWithText(TextButton, 'Log'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Every time the plugin fails'),
        findsOneWidget,
      );
    });

    testWidgets('a longer pause is rounded up to whole minutes', (
      tester,
    ) async {
      final until = DateTime.now().add(const Duration(seconds: 150));
      await _pump(tester, run: RunState(pausedUntil: until));
      expect(
        find.text(
          'Paused for 3 minutes: the server says too many requests (429)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('no pause, no band', (tester) async {
      await _pump(tester, run: RunState());
      expect(find.textContaining('(429)'), findsNothing);
    });

    testWidgets('a plugin that needs settings shows that band, not this', (
      tester,
    ) async {
      final until = DateTime.now().add(const Duration(seconds: 60));
      await _pump(
        tester,
        run: RunState(pausedUntil: until),
        alerts: {PluginAlert.missingRequiredConfig},
        missingConfig: ['API key'],
      );
      expect(find.text('Demo needs to be set up'), findsOneWidget);
      expect(find.textContaining('(429)'), findsNothing);
    });

    testWidgets('the band goes away when the pause ends', (tester) async {
      var now = DateTime(2026, 11, 23, 21);
      final pauses = PluginPauses(now: () => now);
      addTearDown(pauses.dispose);
      await _pump(tester, run: RunState(pauses: pauses));
      expect(find.textContaining('(429)'), findsNothing);
      pauses.pause('id-demo', const Duration(seconds: 60));
      await tester.pump();
      expect(find.textContaining('(429)'), findsOneWidget);
      now = now.add(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 61));
      await tester.pump();
      expect(find.textContaining('(429)'), findsNothing);
    });
  });

  testWidgets('the log summary is read again when a pause starts', (
    tester,
  ) async {
    var reads = 0;
    final now = DateTime(2026, 11, 23, 21);
    final pauses = PluginPauses(now: () => now);
    addTearDown(pauses.dispose);
    final run = RunState(
      pauses: pauses,
      summaryOf: (_) async {
        reads++;
        return (errorsToday: reads, total: reads);
      },
    );
    tester.view.devicePixelRatio = 1;
    await pumpPlugins(
      tester,
      StoreFixture(),
      location: pagePath,
      size: const Size(400, 2400),
      overrides: [
        ...pageOverrides(AsyncData(pageData()), ops: FakeInstallOps()),
        ...run.overrides,
      ],
    );
    expect(find.text('1 error today · 1 entry'), findsOneWidget);
    pauses.pause('id-demo', const Duration(seconds: 60));
    await tester.pump();
    await tester.pump();
    expect(find.text('2 errors today · 2 entries'), findsOneWidget);
    // Ends the pending pause timer before the test does.
    pauses.dispose();
  });
}
