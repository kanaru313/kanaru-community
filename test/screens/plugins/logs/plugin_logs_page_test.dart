import 'dart:io';

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_log_reader.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_run_log.dart';
import 'package:kanaru/src/plugins/domain/logs/log_redaction.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_limits.dart';
import 'package:kanaru/src/plugins/state/plugin_actions_provider.dart';
import 'package:kanaru/src/screens/plugins/logs/log_rows.dart'
    show logKindLabel;
import 'package:kanaru_ui/kanaru_ui.dart' show KChip, KIconButton;
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';

import '../support/install_fixtures.dart';
import '../support/page_fixtures.dart';
import '../support/plugin_fixtures.dart';
import '../support/run_fixtures.dart';

const _logsPath = '$pagePath/logs';

/// Records which plugin's log was cleared; reads nothing.
class _SpyReader extends PluginLogReader {
  _SpyReader() : super(PluginRunLog(Directory('/nonexistent/plugin-logs')));

  final cleared = <String>[];

  @override
  Future<void> clearLog(String installId) async => cleared.add(installId);
}

Future<void> _pump(
  WidgetTester tester, {
  required RunState run,
  Size size = narrowWindow,
  double textScale = 1,
  _SpyReader? reader,
}) async {
  tester.view.devicePixelRatio = 1;
  await pumpPlugins(
    tester,
    StoreFixture(),
    location: _logsPath,
    size: size,
    textScale: textScale,
    overrides: [
      ...pageOverrides(AsyncData(pageData()), ops: FakeInstallOps()),
      ...run.overrides,
      if (reader != null) pluginLogReaderProvider.overrideWithValue(reader),
    ],
  );
}

Finder _chip(String label) => find.widgetWithText(KChip, label);

/// The header button with [tooltip] (the app's tooltip is not the Material
/// one, so `find.byTooltip` cannot see it).
Finder _button(String tooltip) =>
    find.byWidgetPredicate((w) => w is KIconButton && w.tooltip == tooltip);

/// Whether the header button with [tooltip] can be pressed.
bool _enabled(WidgetTester tester, String tooltip) =>
    tester.widget<KIconButton>(_button(tooltip)).onPressed != null;

void main() {
  test('network, unavailable and unsupported kinds read in words', () {
    final en = AppLocalizationsEn();
    final vi = AppLocalizationsVi();
    expect(logKindLabel(en, 'network'), 'network error');
    expect(logKindLabel(en, 'unavailable'), 'no longer on the source');
    expect(logKindLabel(en, 'unsupported'), 'not supported');
    expect(logKindLabel(vi, 'network'), 'lỗi mạng');
    expect(logKindLabel(vi, 'unavailable'), 'không còn trên nguồn');
    expect(logKindLabel(vi, 'unsupported'), 'không hỗ trợ');
    expect(logKindLabel(en, 'weird'), 'weird');
  });

  testWidgets('empty: caption, footer with the file, "No entries yet"', (
    tester,
  ) async {
    await _pump(tester, run: RunState());
    expect(
      find.text(
        'Every time the plugin fails or writes to the console. Kanaru hides '
        'the settings values, own storage and tokens it knows of. A plugin '
        'can still write other information: look before you share.',
      ),
      findsOneWidget,
    );
    expect(find.text('No entries yet'), findsOneWidget);
    expect(
      find.text(
        'Kept for the last 7 days (at most 1 MB per plugin). '
        'File: /data/plugin-logs/id-demo.jsonl',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rows: failure in words, console lines, target, time', (
    tester,
  ) async {
    final run = RunState(
      entries: [
        logEvent(
          script: 'lyrics',
          kind: 'rateLimited',
          query: {'title': 'Nắng ấm xa dần'},
        ),
        logEvent(
          ago: const Duration(minutes: 5),
          script: 'search',
          console: ['[warn] fallback to interface3'],
        ),
        logEvent(
          ago: const Duration(days: 2),
          kind: 'timeout',
          message: 'no answer in 10 s',
        ),
      ],
    );
    await _pump(tester, run: run);
    expect(find.text('lyrics · “Nắng ấm xa dần”'), findsOneWidget);
    expect(find.text('Error: too many requests (429)'), findsOneWidget);
    expect(find.text('Console output only'), findsOneWidget);
    expect(find.text('[warn] fallback to interface3'), findsOneWidget);
    expect(find.text('Error: timed out · no answer in 10 s'), findsOneWidget);
  });

  testWidgets('Errors keeps the failures; the chip says which is chosen', (
    tester,
  ) async {
    final run = RunState(
      entries: [
        logEvent(kind: 'server'),
        logEvent(ago: const Duration(minutes: 1), console: ['hello']),
      ],
    );
    await _pump(tester, run: run);
    expect(tester.getSemantics(_chip('All')), isSemantics(isSelected: true));
    expect(find.text('hello'), findsOneWidget);
    await tester.tap(_chip('Errors'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(_chip('Errors')), isSemantics(isSelected: true));
    expect(find.text('Error: server error'), findsOneWidget);
    expect(find.text('hello'), findsNothing);
  });

  testWidgets('a configured value is never shown, only what the log kept', (
    tester,
  ) async {
    const secret = 'sk-live-0123456789abcdef';
    final event = capRunLogEvent(
      LogRedactor(configAppend: [secret]).apply(
        logEvent(
          kind: 'auth',
          message: 'rejected $secret',
          console: ['sending $secret'],
        ),
      ),
    );
    await _pump(tester, run: RunState(entries: [event]));
    expect(find.textContaining(secret), findsNothing);
    expect(find.textContaining(redactionMask), findsWidgets);
  });

  testWidgets('a long message at 200 % text lays out without overflow', (
    tester,
  ) async {
    final run = RunState(
      entries: [
        logEvent(
          kind: 'invalidResponse',
          message: 'Tên bài hát rất dài ' * 40,
          query: {'title': 'Một bài hát có tên rất dài ' * 5},
        ),
      ],
    );
    await _pump(tester, run: run, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  group('phone', () {
    testWidgets('share is dimmed "Coming soon", no folder button', (
      tester,
    ) async {
      await _pump(tester, run: RunState());
      expect(_button('Open the log folder'), findsNothing);
      expect(_button('Share · Coming soon'), findsOneWidget);
      expect(_enabled(tester, 'Share · Coming soon'), isFalse);
      expect(_enabled(tester, 'Clear the log'), isTrue);
    });
  });

  group('desktop', () {
    testWidgets('the folder button shows the log folder in the file manager', (
      tester,
    ) async {
      final run = RunState();
      await _pump(tester, run: run, size: wideWindow);
      expect(_button('Share · Coming soon'), findsNothing);
      await tester.tap(_button('Open the log folder'));
      await tester.pumpAndSettle();
      expect(run.files.revealed, ['/data/plugin-logs']);
    });

    testWidgets('a folder that cannot be opened says so', (tester) async {
      final run = RunState();
      run.files.fails = true;
      await _pump(tester, run: run, size: wideWindow);
      await tester.tap(_button('Open the log folder'));
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t open the log folder'), findsOneWidget);
    });
  });

  for (final (name, size) in [('narrow', narrowWindow), ('wide', wideWindow)]) {
    group('clear on $name', () {
      testWidgets('asks first, naming the plugin, then clears and says so', (
        tester,
      ) async {
        final reader = _SpyReader();
        await _pump(tester, run: RunState(), size: size, reader: reader);
        await tester.tap(_button('Clear the log'));
        await tester.pumpAndSettle();
        expect(find.text('Clear the plugin’s log?'), findsOneWidget);
        expect(
          find.text(
            'The log entries of Demo will be deleted. The plugin is not '
            'affected.',
          ),
          findsOneWidget,
        );
        expect(reader.cleared, isEmpty, reason: 'nothing before Clear');
        await tester.tap(find.text('Clear').last);
        await tester.pumpAndSettle();
        expect(reader.cleared, ['id-demo']);
        expect(find.text('Log cleared'), findsOneWidget);
      });

      testWidgets('Cancel keeps the log', (tester) async {
        final reader = _SpyReader();
        await _pump(tester, run: RunState(), size: size, reader: reader);
        await tester.tap(_button('Clear the log'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(reader.cleared, isEmpty);
        expect(find.text('Log cleared'), findsNothing);
      });
    });
  }
}
