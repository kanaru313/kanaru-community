import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_log_reader.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_run_log.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_event.dart';
import 'package:logging/logging.dart';

import 'services_test_support.dart';

final id = 'plugin-${'a' * 32}';
final otherId = 'plugin-${'b' * 32}';
final now = DateTime.utc(2026, 11, 23, 12);

RunLogEvent ev({
  DateTime? time,
  String kind = 'server',
  String message = 'm',
  String? installId,
}) => RunLogEvent(
  time: time ?? now,
  installId: installId ?? id,
  pluginName: 'Demo',
  version: '3',
  script: 'search',
  kind: kind,
  message: message,
);

void main() {
  late Directory root;
  late Directory logDir;
  late PluginRunLog log;
  late PluginLogReader reader;

  PluginRunLog make({int? maxBytes}) => PluginRunLog(
    logDir,
    maxBytes: maxBytes ?? runLogMaxBytes,
    clock: () => now,
  );

  setUp(() {
    root = tempDir();
    logDir = Directory('${root.path}/plugin-logs');
    log = make();
    reader = PluginLogReader(log, clock: () => now);
  });
  tearDown(() async {
    await log.whenIdle();
    root.deleteSync(recursive: true);
  });

  test('append writes one JSON line and the reader returns it', () async {
    log.append(ev(message: 'first'));
    final events = await reader.readLog(id);
    expect(events.single.message, 'first');
    expect(reader.logFolder.path, logDir.path);
    final text = await File('${logDir.path}/$id.jsonl').readAsString();
    expect(text.trim().split('\n'), hasLength(1));
    expect(jsonDecode(text.trim()), isA<Map>());
  });

  test('append returns before the write finishes', () async {
    // Nothing is on disk when append returns: the write is only queued.
    log.append(ev(message: 'queued'));
    expect(File('${logDir.path}/$id.jsonl').existsSync(), isFalse);
    await log.whenIdle();
    expect(File('${logDir.path}/$id.jsonl').existsSync(), isTrue);
    log.append(ev(installId: 'not-an-id'));
  });

  test('an event started before a delete is dropped at append', () async {
    final started = log.deletionsOf(id);
    await log.delete(id);
    log.append(ev(message: 'stale'), deletionsAtStart: started);
    log.append(ev(message: 'fresh'));
    await log.whenIdle();
    final events = await reader.readLog(id);
    expect(events.map((e) => e.message), ['fresh']);
  });

  test('an oversize line does not spend the write-failure report', () async {
    final lines = <String>[];
    final sub = Logger.root.onRecord.listen((r) => lines.add(r.message));
    addTearDown(sub.cancel);
    final oldLevel = Logger.root.level;
    addTearDown(() => Logger.root.level = oldLevel);
    Logger.root.level = Level.ALL;
    log = make(maxBytes: 500);
    log.append(ev(message: 'z' * 2000));
    await log.whenIdle();
    File(logDir.path).writeAsStringSync('in the way');
    log.append(ev());
    await log.whenIdle();
    // The oversize line has its own report; the later write failure still gets
    // the write-failure one, with the real error.
    expect(
      lines.where((l) => l.startsWith('A plugin log line over the size limit')),
      hasLength(1),
    );
    expect(
      lines.where((l) => l.contains('Could not write')).single,
      isNot(contains('FormatException')),
    );
    File(logDir.path).deleteSync();
  });

  test('newest first, seven days only, capped at 500', () async {
    log = make();
    reader = PluginLogReader(log, clock: () => now);
    // One write for the bulk (a flushed append per line is slow under load),
    // then one append through the writer, which the reader must wait for.
    await logDir.create(recursive: true);
    final seeded = [
      for (var i = 0; i < 519; i++)
        jsonEncode(
          ev(
            time: now.subtract(Duration(seconds: 520 - i)),
            message: '$i',
          ).toJson(),
        ),
    ];
    await File('${logDir.path}/$id.jsonl')
        .writeAsString('${seeded.join('\n')}\n');
    log.append(
      ev(time: now.subtract(const Duration(seconds: 1)), message: '519'),
    );
    log.append(ev(time: now.subtract(const Duration(days: 8)), message: 'old'));
    final events = await reader.readLog(id);
    expect(events, hasLength(500));
    expect(events.first.message, '519');
    expect(events.map((e) => e.message), isNot(contains('old')));
    for (var i = 1; i < events.length; i++) {
      expect(events[i].time.isAfter(events[i - 1].time), isFalse);
    }
  });

  test('errorsOnly drops runs that only printed to the console', () async {
    log.append(ev(kind: 'ok', message: 'printed'));
    log.append(ev(kind: 'timeout', message: 'failed'));
    expect((await reader.readLog(id)), hasLength(2));
    final errors = await reader.readLog(id, errorsOnly: true);
    expect(errors.single.message, 'failed');
  });

  test('corrupt lines and lines of other shapes are skipped', () async {
    log.append(ev(message: 'good'));
    await log.whenIdle(id);
    await File('${logDir.path}/$id.jsonl').writeAsString(
      'not json\n{"ts":"x"}\n[1]\n\n{"ts":"${now.toIso8601String()}","kind":"k"\n',
      mode: FileMode.append,
    );
    log.append(ev(message: 'after'));
    final events = await reader.readLog(id);
    expect(events.map((e) => e.message), unorderedEquals(['good', 'after']));
  });

  test('rotation keeps both files under the limit and replaces .1', () async {
    log = make(maxBytes: 4000);
    reader = PluginLogReader(log, clock: () => now);
    String line(int i) => jsonEncode(
      ev(
        time: now.subtract(Duration(seconds: 200 - i)),
        message: 'line $i ${'x' * 100}',
      ).toJson(),
    );
    // Seed most lines in one write, then append the ones that rotate.
    await logDir.create(recursive: true);
    await File(
      '${logDir.path}/$id.jsonl',
    ).writeAsString('${[for (var i = 0; i < 180; i++) line(i)].join('\n')}\n');
    for (var i = 180; i < 200; i++) {
      log.append(
        ev(
          time: now.subtract(Duration(seconds: 200 - i)),
          message: 'line $i ${'x' * 100}',
        ),
      );
    }
    await log.whenIdle();
    final current = File('${logDir.path}/$id.jsonl');
    final previous = File('${logDir.path}/$id.jsonl.1');
    expect(await previous.exists(), isTrue);
    expect(await current.length(), lessThanOrEqualTo(4000));
    expect(await previous.length(), lessThanOrEqualTo(4000));
    final events = await reader.readLog(id);
    // The newest line survives, the oldest were replaced.
    expect(events.first.message, startsWith('line 199'));
    expect(events.length, lessThan(200));
  });

  test('rotation drops lines older than seven days', () async {
    log = make(maxBytes: 1500);
    final file = File('${logDir.path}/$id.jsonl');
    await logDir.create(recursive: true);
    final oldLine = jsonEncode(
      ev(time: now.subtract(const Duration(days: 9)), message: 'old').toJson(),
    );
    final freshLine = jsonEncode(ev(message: 'fresh').toJson());
    await file.writeAsString('$oldLine\n$freshLine\n');
    log.append(ev(message: 'y' * 1200));
    await log.whenIdle();
    final previous = await File('${file.path}.1').readAsString();
    expect(previous, contains('fresh'));
    expect(previous, isNot(contains('old')));
  });

  test('a line over the size limit is not written', () async {
    log = make(maxBytes: 500);
    log.append(ev(message: 'z' * 2000));
    await log.whenIdle();
    expect(File('${logDir.path}/$id.jsonl').existsSync(), isFalse);
  });

  test('delete removes both files and drops writes queued before it', () async {
    log = make(maxBytes: 1500);
    for (var i = 0; i < 6; i++) {
      log.append(ev(message: 'w$i ${'x' * 300}'));
    }
    await log.whenIdle();
    expect(File('${logDir.path}/$id.jsonl.1').existsSync(), isTrue);

    log.append(ev(message: 'queued before'));
    final deleted = log.delete(id);
    log.append(ev(message: 'queued after'));
    await deleted;
    await log.whenIdle();

    expect(File('${logDir.path}/$id.jsonl.1').existsSync(), isFalse);
    final events = await PluginLogReader(log, clock: () => now).readLog(id);
    expect(events.map((e) => e.message), ['queued after']);
  });

  test('clearLog deletes the log of one plugin only', () async {
    log.append(ev());
    log.append(ev(installId: otherId));
    await reader.clearLog(id);
    expect(await reader.readLog(id), isEmpty);
    expect(await reader.readLog(otherId), hasLength(1));
  });

  test('deleteOrphans keeps live ids and ignores other files', () async {
    log.append(ev());
    log.append(ev(installId: otherId));
    await log.whenIdle();
    File('${logDir.path}/notes.txt').writeAsStringSync('keep');
    File('${logDir.path}/not-an-id.jsonl').writeAsStringSync('keep');

    expect(await log.deleteOrphans({id}), 1);

    expect(File('${logDir.path}/$id.jsonl').existsSync(), isTrue);
    expect(File('${logDir.path}/$otherId.jsonl').existsSync(), isFalse);
    expect(File('${logDir.path}/notes.txt').existsSync(), isTrue);
    expect(File('${logDir.path}/not-an-id.jsonl').existsSync(), isTrue);
    expect(
      await PluginRunLog(Directory('${root.path}/none')).deleteOrphans({}),
      0,
    );
  });

  test('a write failure is logged once, with its type only', () async {
    // A file where the folder should be: every write fails.
    File(logDir.path).writeAsStringSync('in the way');
    final lines = <String>[];
    final sub = Logger.root.onRecord.listen((r) => lines.add(r.message));
    addTearDown(sub.cancel);
    final oldLevel = Logger.root.level;
    addTearDown(() => Logger.root.level = oldLevel);
    Logger.root.level = Level.ALL;

    log.append(ev());
    log.append(ev());
    await log.whenIdle();

    final failures = lines.where((l) => l.contains('Could not write'));
    expect(failures, hasLength(1));
    expect(failures.single, isNot(contains(root.path)));
    File(logDir.path).deleteSync();
  });

  test('an id that is not an install id never reaches a path', () async {
    expect(log.fileOf('../x'), isNull);
    expect(await reader.readLog('../x'), isEmpty);
    await log.delete('../x');
  });
}
