import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' show pumpEventQueue;
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_engine_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../../../plugins/data/store_test_support.dart';
import '../../../plugins/domain/plugin_test_support.dart';
import '../../support/lyrics_harness.dart';
import '../../support/online_lookup_rig.dart' show ManualTimer;
import 'translation_test_support.dart';

/// The shown lyrics of every track, set by the test.
class LyricsBox extends Notifier<Map<TrackId, TrackLyrics>> {
  @override
  Map<TrackId, TrackLyrics> build() => const {};

  void show(TrackId id, List<String> lines) => state = {
    ...state,
    id: LyricsShown(
      Lyrics(
        lines: [for (final l in lines) LyricLine(Duration.zero, l)],
        synced: false,
        origin: LyricsOrigin.tag,
      ),
    ),
  };

  void clear(TrackId id) => state = {...state}..remove(id);
}

final lyricsBoxProvider =
    NotifierProvider<LyricsBox, Map<TrackId, TrackLyrics>>(LyricsBox.new);

/// What `effectiveTranslationServiceProvider` says, set by the test.
class ServiceBox extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  void set(AsyncValue<String?> value) => state = value;
}

final serviceBoxProvider = NotifierProvider<ServiceBox, AsyncValue<String?>>(
  ServiceBox.new,
);

/// A lyrics harness with shown lyrics, a chosen service and the debounce
/// timer under the test's control, over a real in-memory database and the
/// fake plugin runner.
class TranslationHarness {
  TranslationHarness({bool brokenCache = false, String language = 'vi'}) {
    h = LyricsHarness(
      extra: [
        trackLyricsProvider.overrideWith(
          (ref, id) => ref.watch(lyricsBoxProvider)[id] ?? const LyricsNone(),
        ),
        effectiveTranslationServiceProvider.overrideWith(
          (ref) => ref.watch(serviceBoxProvider),
        ),
        translationAppLanguageProvider.overrideWithValue(language),
        translationTimerProvider.overrideWithValue((after, run) {
          final timer = ManualTimer(after, run);
          timers.add(timer);
          return timer;
        }),
        if (brokenCache)
          translationCacheStoreProvider.overrideWith(
            (ref) => BrokenCacheStore(ref.watch(appDatabaseProvider)),
          ),
      ],
    );
  }

  late final LyricsHarness h;

  /// Every debounce timer that was armed, oldest first.
  final timers = <ManualTimer>[];

  ProviderContainer get c => h.container;
  int _plugins = 0;

  /// Debounce timers that can still fire.
  List<ManualTimer> get armed => [
    for (final t in timers)
      if (t.isActive) t,
  ];

  Future<void> dispose() => h.dispose();

  /// Installs a translate plugin and returns its install id.
  Future<String> install({
    Map<String, Object?> Function()? manifest,
    int maxLines = 10,
  }) async {
    final n = ++_plugins;
    final json = (manifest ?? translateManifest)();
    (json['metadata']! as Map<String, Object?>)['name'] = 'Plugin $n';
    json['translate'] = <String, Object?>{
      ...(json['translate']! as Map<String, Object?>),
      'maxLines': maxLines,
    };
    await c
        .read(pluginRowsProvider)
        .installOrRevive(
          testInstallId(n),
          draftOf(
            packageOf(json, const {
              'src/translate.js': 'function execute(i) { return i; }',
            }),
          ),
          PluginSource.repo('https://r.example.com/p.json', 'repo$n'),
        );
    return testInstallId(n);
  }

  /// A track tagged `Song` by `Artist`.
  Future<TrackId> song(String locator) => h.addSongRow(locator);

  void show(TrackId id, List<String> lines) =>
      c.read(lyricsBoxProvider.notifier).show(id, lines);

  void chooseService(String? installId) =>
      c.read(serviceBoxProvider.notifier).set(AsyncData(installId));

  Future<void> turnOn([bool on = true]) =>
      c.read(translationOnProvider.notifier).set(on);

  /// Runs the event loop a few rounds.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await pumpEventQueue();
    }
  }
}
