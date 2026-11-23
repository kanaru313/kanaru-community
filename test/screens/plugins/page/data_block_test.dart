import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/state/plugin_run_info_provider.dart';
import 'package:kanaru/src/screens/plugins/page/soon_blocks.dart';
import 'package:kanaru_ui/kanaru_ui.dart' show SetupRowFrame;
import 'package:material_ui/material_ui.dart' show TextButton;

import '../../settings/support/settings_host.dart' show SettingsHarness;
import '../support/install_fixtures.dart';
import '../support/page_fixtures.dart';
import '../support/plugin_fixtures.dart';
import '../support/run_fixtures.dart';

Future<SettingsHarness> _pump(
  WidgetTester tester, {
  required RunState run,
  String kind = 'lyrics',
  Size size = narrowWindow,
}) async {
  tester.view.devicePixelRatio = 1;
  final fixture = StoreFixture();
  return pumpPlugins(
    tester,
    fixture,
    location: pagePath,
    size: Size(size.width, 2400),
    overrides: [
      ...pageOverrides(
        AsyncData(pageData(row: pageRow(kind: kind))),
        ops: FakeInstallOps(),
      ),
      ...run.overrides,
    ],
  );
}

/// Whether the [Clear] button of the row titled [title] can be pressed.
bool _clearEnabled(WidgetTester tester, String title) {
  final row = find.ancestor(
    of: find.text(title),
    matching: find.byType(SetupRowFrame),
  );
  final button = find.descendant(
    of: row.first,
    matching: find.widgetWithText(TextButton, 'Clear'),
  );
  return tester.widget<TextButton>(button).onPressed != null;
}

void main() {
  for (final (name, size) in [('narrow', narrowWindow), ('wide', wideWindow)]) {
    group(name, () {
      testWidgets('Connection stays a dimmed "Coming soon" block', (
        tester,
      ) async {
        await _pump(tester, run: RunState(), size: size);
        expect(find.text('Connection'), findsOneWidget);
        final soon = find.descendant(
          of: find.byType(ConnectionBlock),
          matching: find.text('Coming soon'),
        );
        expect(soon, findsOneWidget);
      });

      testWidgets('empty storage: value shown, Clear dimmed', (tester) async {
        await _pump(tester, run: RunState(), size: size);
        expect(find.text('0 KB / 64 KB'), findsOneWidget);
        expect(_clearEnabled(tester, 'Plugin’s own storage'), isFalse);
      });

      testWidgets('Clear asks, clears the storage and says so', (tester) async {
        final run = RunState(storageBytes: 38 * 1024);
        await _pump(tester, run: run, size: size);
        expect(find.text('38 KB / 64 KB'), findsOneWidget);
        expect(_clearEnabled(tester, 'Plugin’s own storage'), isTrue);
        await tester.tap(find.widgetWithText(TextButton, 'Clear').first);
        await tester.pumpAndSettle();
        expect(find.text('Clear the plugin’s own storage?'), findsOneWidget);
        expect(
          find.text('The plugin may need to sign in or be set up again.'),
          findsOneWidget,
        );
        expect(run.ops.storageCleared, isEmpty, reason: 'nothing before OK');
        await tester.tap(find.text('Clear').last);
        await tester.pumpAndSettle();
        expect(run.ops.storageCleared, ['id-demo']);
        expect(find.text('Own storage cleared'), findsOneWidget);
      });

      testWidgets('leaving the page while the dialog is open still clears', (
        tester,
      ) async {
        final run = RunState(storageBytes: 2048);
        final h = await _pump(tester, run: run, size: size);
        await tester.tap(find.widgetWithText(TextButton, 'Clear').first);
        await tester.pumpAndSettle();
        // The plugin disappears: the page goes while the dialog stays.
        h.container.read(pageHolder.notifier).set(const AsyncData(null));
        await tester.pump();
        await tester.tap(find.text('Clear').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(run.ops.storageCleared, ['id-demo']);
        expect(find.text('Couldn’t clear the data'), findsNothing);
      });

      testWidgets('Cancel clears nothing', (tester) async {
        final run = RunState(storageBytes: 2048);
        await _pump(tester, run: run, size: size);
        await tester.tap(find.widgetWithText(TextButton, 'Clear').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(run.ops.storageCleared, isEmpty);
        expect(find.text('Own storage cleared'), findsNothing);
      });

      testWidgets('a failing clear says so', (tester) async {
        final run = RunState(storageBytes: 2048);
        run.ops.fail = true;
        await _pump(tester, run: run, size: size);
        await tester.tap(find.widgetWithText(TextButton, 'Clear').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clear').last);
        await tester.pumpAndSettle();
        expect(find.text('Couldn’t clear the data'), findsOneWidget);
        expect(find.text('Own storage cleared'), findsNothing);
      });

      testWidgets('no saved lyrics: "None yet", Clear dimmed', (tester) async {
        await _pump(tester, run: RunState(), size: size);
        expect(find.text('None yet'), findsOneWidget);
        expect(_clearEnabled(tester, 'Lyrics saved from this source'), isFalse);
      });

      testWidgets('saved lyrics: count and size, Clear keeps pins', (
        tester,
      ) async {
        final run = RunState(
          savedLyrics: const SavedLyricsStats(count: 86, bytes: 1300000),
        );
        await _pump(tester, run: run, size: size);
        expect(find.text('86 songs · 1.2 MB'), findsOneWidget);
        expect(_clearEnabled(tester, 'Lyrics saved from this source'), isTrue);
        await tester.tap(find.widgetWithText(TextButton, 'Clear').last);
        await tester.pumpAndSettle();
        expect(
          find.text('Clear the lyrics saved from this source?'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Lyrics saved from this source will be deleted. Pinned lyrics '
            'and .lrc files are kept.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Clear').last);
        await tester.pumpAndSettle();
        expect(run.ops.lyricsCleared, ['id-demo']);
        expect(run.ops.storageCleared, isEmpty);
        expect(find.text('Saved lyrics cleared'), findsOneWidget);
      });

      testWidgets('a source with a few bytes shows KB, not 0', (tester) async {
        final run = RunState(
          savedLyrics: const SavedLyricsStats(count: 1, bytes: 300),
        );
        await _pump(tester, run: run, size: size);
        expect(find.text('1 song · 1 KB'), findsOneWidget);
      });

      testWidgets('a music source has the cache row, no saved lyrics', (
        tester,
      ) async {
        await _pump(tester, run: RunState(), kind: 'streaming', size: size);
        expect(find.text('Lyrics saved from this source'), findsNothing);
        final row = find.ancestor(
          of: find.text('Track and cover cache'),
          matching: find.byType(SetupRowFrame),
        );
        expect(
          find.descendant(of: row.first, matching: find.text('Coming soon')),
          findsOneWidget,
        );
      });

      testWidgets('the log row says the errors of today and opens the log', (
        tester,
      ) async {
        final run = RunState(
          errorsToday: 2,
          entries: [
            for (var i = 0; i < 6; i++)
              logEvent(
                ago: Duration(minutes: i),
                kind: i < 2 ? 'server' : 'ok',
              ),
          ],
        );
        await _pump(tester, run: run, size: size);
        expect(find.text('2 errors today · 6 entries'), findsOneWidget);
        await tester.ensureVisible(find.text('2 errors today · 6 entries'));
        await tester.tap(find.text('2 errors today · 6 entries'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Every time the plugin fails'),
          findsOneWidget,
        );
      });

      testWidgets('no failure today says "No errors"', (tester) async {
        await _pump(tester, run: RunState(), size: size);
        expect(find.text('No errors'), findsOneWidget);
      });
    });
  }
}
