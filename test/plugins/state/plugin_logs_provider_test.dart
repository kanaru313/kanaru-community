import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_log_reader.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_run_log.dart';
import 'package:kanaru/src/plugins/domain/logs/log_redaction.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_event.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_limits.dart';
import 'package:kanaru/src/plugins/state/plugin_actions_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_logs_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_services_provider.dart';

import '../data/store_test_support.dart';

void main() {
  late Directory dir;
  late PluginRunLog log;
  late ProviderContainer container;
  final id = testInstallId();

  setUp(() {
    dir = Directory.systemTemp.createTempSync('plugin-logs-state');
    log = PluginRunLog(dir);
    container = ProviderContainer(
      overrides: [
        pluginRunLogProvider.overrideWithValue(log),
        pluginLogReaderProvider.overrideWithValue(PluginLogReader(log)),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    dir.deleteSync(recursive: true);
  });

  RunLogEvent event({
    required Duration ago,
    String kind = runLogKindOk,
    List<String> console = const [],
    String? message,
  }) => RunLogEvent(
    time: DateTime.now().subtract(ago),
    installId: id,
    pluginName: 'Demo',
    version: '3',
    script: 'search',
    kind: kind,
    message: message,
    console: console,
  );

  Future<List<RunLogEvent>> entries({bool errorsOnly = false}) =>
      container.read(
        pluginLogEntriesProvider((installId: id, errorsOnly: errorsOnly))
            .future,
      );

  test('a plugin with no log has no entries and no errors', () async {
    expect(await entries(), isEmpty);
    final summary = await container.read(pluginLogSummaryProvider(id).future);
    expect(summary, (errorsToday: 0, total: 0));
  });

  test('lists newest first; errors only keeps the failures', () async {
    log.append(event(ago: const Duration(minutes: 30), console: ['a']));
    log.append(event(ago: const Duration(minutes: 20), kind: 'timeout'));
    log.append(event(ago: const Duration(minutes: 10), console: ['b']));
    expect((await entries()).map((e) => e.kind), [
      runLogKindOk,
      'timeout',
      runLogKindOk,
    ]);
    expect((await entries()).first.console, ['b']);
    expect((await entries(errorsOnly: true)).map((e) => e.kind), ['timeout']);
  });

  test('the summary counts failures of today and every entry', () async {
    log.append(event(ago: Duration.zero, kind: 'rateLimited'));
    log.append(event(ago: Duration.zero, kind: 'server'));
    log.append(event(ago: Duration.zero, console: ['x']));
    // Three days back is never "today".
    log.append(event(ago: const Duration(days: 3), kind: 'timeout'));
    final summary = await container.read(pluginLogSummaryProvider(id).future);
    expect(summary, (errorsToday: 2, total: 4));
  });

  test('an entry older than the age limit is not listed', () async {
    log.append(event(ago: const Duration(days: 8), kind: 'timeout'));
    expect(await entries(), isEmpty);
  });

  test('a configured value in a console line never reaches the list', () async {
    const secret = 'sk-live-0123456789abcdef';
    final redacted = capRunLogEvent(
      LogRedactor(configAppend: [secret]).apply(
        event(
          ago: Duration.zero,
          console: ['calling with $secret'],
          message: 'bad key $secret',
          kind: 'auth',
        ),
      ),
    );
    log.append(redacted);
    final read = await entries();
    expect(read, hasLength(1));
    expect(read.single.console.single, isNot(contains(secret)));
    expect(read.single.message, isNot(contains(secret)));
    expect(read.single.console.single, contains(redactionMask));
  });

  test('a big log is read whole on another isolate, capped', () async {
    // Each line is a few hundred bytes: well over the isolate threshold.
    final line = List.filled(4, 'x' * 90);
    for (var i = 0; i < 700; i++) {
      log.append(
        event(
          ago: Duration(seconds: 700 - i),
          console: line,
        ),
      );
    }
    await log.whenIdle(id);
    final bytes =
        (log.fileOf(id)!.lengthSync()) +
        (log.previousFileOf(id)!.existsSync()
            ? log.previousFileOf(id)!.lengthSync()
            : 0);
    expect(bytes, greaterThan(logIsolateThresholdBytes));
    final read = await entries();
    expect(read, hasLength(runLogReadCap));
    for (var i = 1; i < read.length; i++) {
      expect(read[i - 1].time.isBefore(read[i].time), isFalse);
    }
  });

  test('clearing deletes the log and refreshes the summary', () async {
    log.append(event(ago: Duration.zero, kind: 'server'));
    expect(
      (await container.read(pluginLogSummaryProvider(id).future)).total,
      1,
    );
    await container.read(pluginLogOpsProvider).clear(id);
    expect(await entries(), isEmpty);
    expect(log.fileOf(id)!.existsSync(), isFalse);
    expect(
      (await container.read(pluginLogSummaryProvider(id).future)).total,
      0,
    );
  });
}
