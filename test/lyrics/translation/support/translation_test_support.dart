import 'dart:async';
import 'dart:convert';

import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/lyrics/data/translation/translate_runner.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/translation/lyrics_content_hash.dart';
import 'package:kanaru/src/lyrics/data/translation/translation_cache_store.dart';
import 'package:kanaru/src/lyrics/data/translation/translation_job_types.dart';
import 'package:kanaru/src/lyrics/data/translation/translation_jobs.dart';
import 'package:kanaru/src/lyrics/data/translation/translation_services.dart';
import 'package:kanaru/src/plugins/data/run/plugin_pauses.dart';
import 'package:kanaru/src/plugins/domain/package/translate_spec.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/plugins/domain/run/run_request.dart';

import '../../../database/support/test_db.dart';
import '../../support/fake_plugin_runner.dart';

/// The lines a `translate` request carries.
List<String> sentLines(PluginRunRequest request) =>
    ((request.input! as Map)['lines'] as List).cast<String>();

/// The answer of a plugin that translates every sent line to `T:<line>` and
/// saw [detected].
RunOk translated(PluginRunRequest request, {String? detected = 'ja'}) => RunOk(
  jsonEncode([
    for (final line in sentLines(request))
      {'text': 'T:$line', 'detected': ?detected},
  ]),
);

/// The answer of a plugin that gives every line back unchanged.
RunOk echoed(PluginRunRequest request) => RunOk(
  jsonEncode([
    for (final line in sentLines(request)) {'text': line},
  ]),
);

/// A script that is answered by hand: each run waits for [next] and the test
/// completes it.
class HandRuns {
  final _pending = <(PluginRunRequest, Completer<RunOutcome>)>[];

  /// Requests that are running now, oldest first.
  List<PluginRunRequest> get running => [for (final p in _pending) p.$1];

  Future<RunOutcome> call(PluginRunRequest request, Object? cancel) {
    final done = Completer<RunOutcome>();
    _pending.add((request, done));
    return done.future;
  }

  /// Answers the oldest running request.
  void answer(RunOutcome Function(PluginRunRequest request) outcome) {
    final (request, done) = _pending.removeAt(0);
    done.complete(outcome(request));
  }
}

/// A snapshot of a plugin whose chunks hold at most [maxLines] lines.
ServiceSnapshot snapshotOf(
  String installId, {
  int version = 1,
  int maxLines = 50,
  String settings = '{"pluginVersion":1}',
}) => ServiceSnapshot(
  installId: installId,
  version: version,
  spec: TranslateSpec(languages: const ['vi', 'en'], maxLines: maxLines),
  settingsJson: settings,
);

/// [TranslationServices] the test sets: [plugins] answers `snapshot`, and
/// [saveConfig] makes the plugin's settings emit like a saved form.
class FakeTranslationServices implements TranslationServices {
  final plugins = <String, ServiceSnapshot?>{};
  final _configs = <String, StreamController<Object?>>{};
  bool failSnapshot = false;

  @override
  Future<ServiceSnapshot?> snapshot(String installId) async {
    if (failSnapshot) throw StateError('db down');
    return plugins[installId];
  }

  @override
  Stream<Object?> configChanges(String installId) => Stream.multi((out) {
    out.add(null); // the baseline, as the store's stream does
    final controller = _configs.putIfAbsent(
      installId,
      () => StreamController<Object?>.broadcast(),
    );
    final sub = controller.stream.listen(out.add);
    out.onCancel = sub.cancel;
  });

  /// The plugin's settings were saved.
  void saveConfig(String installId) => _configs[installId]?.add(null);

  /// Listeners on the plugin's settings.
  bool isWatching(String installId) =>
      _configs[installId]?.hasListener ?? false;
}

/// A cache store whose reads fail.
class BrokenCacheStore extends TranslationCacheStore {
  BrokenCacheStore(super.db);

  @override
  Future<TranslationCacheRow?> lookup(TranslationKey key) =>
      throw StateError('read failed');
}

/// An engine over an in-memory database and the fake runner.
class EngineRig {
  EngineRig({TranslationCacheStore Function(AppDatabase)? cache}) {
    db = openTestDb();
    store = cache?.call(db) ?? TranslationCacheStore(db);
    jobs = newEngine();
  }

  late final AppDatabase db;
  late final TranslationCacheStore store;
  final runner = FakePluginRunner();
  final services = FakeTranslationServices();
  DateTime clock = DateTime.utc(2026, 11, 24, 12);
  late final pauses = PluginPauses(now: () => clock);

  /// Translation switch and chosen service, as `mayRun` reads them.
  bool on = true;
  String? service = 'plugin-a';
  late TranslationJobs jobs;
  int changes = 0;

  /// The statuses after every change, oldest first.
  final seen = <Map<JobKey, JobStatus>>[];

  TranslationJobs newEngine() => TranslationJobs(
    runner: TranslateRunner(runner, pauses, now: () => clock),
    cache: store,
    services: services,
    mayRun: (id) => on && service == id,
    now: () => clock.millisecondsSinceEpoch,
    onChange: () {
      changes++;
      seen.add(jobs.statuses);
    },
  );

  Future<void> dispose() async {
    jobs.dispose();
    pauses.dispose();
    await db.close();
  }
}

JobKey keyOf(String hash, {String install = 'plugin-a', String to = 'vi'}) =>
    (hash: hash, installId: install, target: to);

/// The cache hash of lyrics made of [lines].
String hashOf(List<String> lines) =>
    lyricsContentHash([for (final l in lines) LyricLine(Duration.zero, l)]);
