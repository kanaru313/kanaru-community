import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/widgets.dart' show Navigator, Offset, Scrollable, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/run/run_request.dart';
import 'package:kanaru/src/plugins/state/plugin_actions_provider.dart';
import 'package:kanaru/src/plugins/domain/logs/log_redaction.dart' show redactionMask;
import 'package:kanaru/src/plugins/state/plugin_logs_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_services_provider.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/screens/plugins/page/data_block.dart';
import 'package:kanaru/src/screens/settings/ui/settings_scaffold.dart';
import 'package:kanaru/src/screens/plugins/plugin_paths.dart';
import 'package:kanaru_ui/kanaru_ui.dart' show KChip, KIconButton;
import 'package:material_ui/material_ui.dart' show TextButton;

import 'support/harness.dart';

/// The raw value of the plugin's setting; it must never reach the log.
const _secret = 'SECRET-CONFIG-VALUE-123';
const _pluginName = 'Demo Lyrics';

/// Plugin pages with run data on the real app, Linux (window 1400 wide,
/// desktop shell): the store ⋮ menu, a lyrics plugin's page (Dữ liệu,
/// Kết nối "Sắp có"), the clear-storage confirm, the Nhật ký page (Tất cả,
/// Lỗi), the 429 band and the remove dialog. The plugin is installed through
/// the real install path from a zip built here; the run data comes from two
/// real runs of its scripts (no network). Screenshots (app window only, in
/// `$KANARU_SHOT_DIR`, default `/tmp/kanaru-plugin-page-run/shots`) are for
/// comparing with mockup 09 by eye and never fail the test.
///
/// Run: `tool/integration_test.sh linux plugin_page_run_test.dart` (through
/// the main checkout's `main-build.sh`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plugin page run sections, log page, remove dialog', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);

    final app = await startKanaru(tester);
    final container = app.container;
    final router = container.read(routerProvider);

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(Navigator).first));

    final shotDir = Directory(
      Platform.environment['KANARU_SHOT_DIR'] ??
          '/tmp/kanaru-plugin-page-run/shots',
    )..createSync(recursive: true);

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      try {
        final view = tester.binding.renderViews.first;
        final layer = view.debugLayer! as OffsetLayer;
        final image = await layer.toImage(Offset.zero & view.size);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        File('${shotDir.path}/linux-pluginrun-$name.png')
            .writeAsBytesSync(bytes.buffer.asUint8List());
      } on Object catch (e) {
        debugPrint('screenshot $name failed: $e');
      }
    }

    Future<void> goTo(String path, Finder waitFor, String what) async {
      router.go(path);
      await tester.pump();
      await app.pumpUntil(() => waitFor.evaluate().isNotEmpty, what: what);
      await tester.pumpAndSettle();
    }

    // The page is a lazy list: The Dữ liệu block is built only once scrolled to.
    Future<void> scrollTo(Finder target, {bool up = false}) async {
      // The page's list, not the sidebar's.
      await tester.scrollUntilVisible(
        target,
        up ? -300 : 300,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScaffold),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
    }

    // Install from a zip through the real install path.
    final temp = Directory.systemTemp.createTempSync('kanaru-plugin-run-');
    addTearDown(() => temp.deleteSync(recursive: true));
    final zipFile = File('${temp.path}/demo-lyrics.zip')
      ..writeAsBytesSync(_demoZip());
    final held = container.read(pluginServicesProvider).held;
    final prepared = await held
        .prepareFromFile(
          PickedDocument(
            name: 'demo-lyrics.zip',
            handle: zipFile.path,
            localPath: zipFile.path,
          ),
        )
        .result;
    final package = switch (prepared) {
      Ok(:final value) => value,
      Err(:final error) => throw TestFailure('prepare failed: $error'),
    };
    final installId = package.installId;
    final installed = await container
        .read(pluginActionsProvider)
        .installer
        .install(package.token);
    expect(installed, isA<Installed>(), reason: 'install result');

    // Seed run data: a config value, one run that logs it and writes
    // storage, one run that fails.
    await container
        .read(pluginActionsProvider)
        .configWrites
        .setValue(installId, 'apiKey', _secret);
    final runner = container.read(pluginRunnerProvider);
    for (final script in const ['search', 'lyrics']) {
      await runner.run(
        PluginRunRequest(
          installId: installId,
          script: script,
          input: 'demo',
          timeout: const Duration(seconds: 20),
          kinds: const {PluginKind.lyrics},
        ),
      );
    }
    await container.read(pluginRunLogProvider).whenIdle(installId);

    // The log holds both runs and no raw config value.
    final entries = await container.read(
      pluginLogEntriesProvider((installId: installId, errorsOnly: false))
          .future,
    );
    expect(entries.length, 2, reason: 'one console run, one failed run');
    final consoleText = entries.expand((e) => e.console).join('\n');
    expect(
      consoleText,
      contains('key=$redactionMask'),
      reason: 'console line is logged with the value masked',
    );
    expect(
      jsonEncode([for (final e in entries) e.toJson()]),
      isNot(contains(_secret)),
      reason: 'config value is masked in the log',
    );

    final t = l10n();

    // 1. Store with the header ⋮ menu open.
    await goTo(PluginPaths.store, find.text(_pluginName), 'the store page');
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is KIconButton && w.tooltip == t.pluginsMenuTooltip,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.pluginsMenuLogsDesktop), findsOneWidget);
    await shot('01-store-menu');
    await tester.tapAt(const Offset(40, 880));
    await tester.pumpAndSettle();

    // 2. The plugin page: one screenshot per viewport.
    await goTo(
      PluginPaths.plugin(installId),
      find.text(t.pluginsPageConnection),
      'the plugin page',
    );
    await shot('02-page-1');
    await scrollTo(find.text(t.pluginsPageConnectionRow));
    expect(find.text(t.pluginsPageConnection), findsOneWidget);
    expect(find.text(t.appComingSoon), findsWidgets);
    await shot('03-page-connection');
    await scrollTo(find.text(t.pluginsPageOwnStorage));
    expect(find.text(t.pluginsPageData), findsOneWidget);
    expect(find.textContaining(' KB / '), findsOneWidget);
    expect(find.text(t.pluginsDataSavedLyricsNone), findsOneWidget);
    await shot('03b-page-data');

    // 3. Clear-storage confirm, then cancel.
    final clear = find
        .descendant(
          of: find.byType(DataBlock),
          matching: find.widgetWithText(TextButton, t.pluginsDataClear),
        )
        .first;
    await scrollTo(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.text(t.pluginsDataClearStorageTitle), findsOneWidget);
    await shot('04-clear-storage-dialog');
    await tester.tap(find.text(t.pluginsCancel));
    await tester.pumpAndSettle();
    expect(find.text(t.pluginsDataClearStorageTitle), findsNothing);

    // 4. The log page: Tất cả, then Lỗi.
    final logRow = find.text(t.pluginsPageLog);
    await tester.ensureVisible(logRow);
    await tester.pumpAndSettle();
    await tester.tap(logRow);
    await tester.pumpAndSettle();
    await app.pumpUntil(
      () => find.text(t.pluginsLogsAll).evaluate().isNotEmpty,
      what: 'the log page',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('key='), findsOneWidget, reason: 'line shown');
    expect(find.textContaining(_secret), findsNothing);
    expect(find.text(t.pluginsLogsEmpty), findsNothing);
    await shot('05-logs-all');
    final errorsChip = find.widgetWithText(KChip, t.pluginsLogsErrors);
    await tester.tap(errorsChip);
    await tester.pumpAndSettle();
    expect(tester.widget<KChip>(errorsChip).selected, isTrue);
    expect(find.textContaining(_secret), findsNothing);
    await shot('06-logs-errors');

    // 5. The 429 band: a real pause on the plugin's pauses.
    container
        .read(pluginPausesProvider)
        .pause(installId, const Duration(minutes: 5));
    await goTo(
      PluginPaths.plugin(installId),
      find.text(t.pluginsPageConnection),
      'the plugin page again',
    );
    // The page keeps its scroll offset: the band is at the top.
    await scrollTo(find.textContaining('(429)'), up: true);
    expect(find.textContaining('(429)'), findsOneWidget);
    await shot('07-paused-band');

    // 6. The remove dialog, then cancel.
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is KIconButton &&
            w.tooltip == t.pluginsRemoveTooltip(_pluginName),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.pluginsRemoveTitle(_pluginName)), findsOneWidget);
    expect(find.text(t.pluginsRemoveWillDelete), findsOneWidget);
    expect(find.text(t.pluginsRemoveKeep), findsOneWidget);
    await shot('08-remove-dialog');
    await tester.tap(find.text(t.pluginsCancel));
    await tester.pumpAndSettle();
    expect(find.text(t.pluginsRemoveTitle(_pluginName)), findsNothing);
  });
}

/// A small lyrics plugin: `search` logs its setting and writes storage,
/// `lyrics` fails. Nothing fetches.
List<int> _demoZip() {
  final manifest = {
    'metadata': {
      'apiVersion': 1,
      'type': 'lyrics',
      'name': _pluginName,
      'version': 1,
      'hosts': ['music.example.com'],
      'author': 'kanaru-it',
      'description': 'Self-check plugin',
    },
    'script': {'search': 'search.js', 'lyrics': 'lyrics.js'},
    'config': {
      'apiKey': {'title': 'Khoá API', 'mode': 'input', 'format': 'text'},
    },
  };
  final files = <String, String>{
    'plugin.json': jsonEncode(manifest),
    'src/search.js':
        "function execute(q) {\n"
        "  console.log('key=' + localConfig.getItem('apiKey'));\n"
        "  localStorage.setItem('token', 'abc');\n"
        "  return Response.success([]);\n"
        "}",
    'src/lyrics.js': "function execute(id) { return Response.error('boom'); }",
  };
  final archive = Archive();
  for (final e in files.entries) {
    archive.add(ArchiveFile.bytes(e.key, utf8.encode(e.value)));
  }
  return ZipEncoder().encodeBytes(archive);
}
