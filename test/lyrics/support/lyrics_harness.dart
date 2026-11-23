import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/lyrics/state/lyrics_choice_commands.dart';
import 'package:kanaru/src/lyrics/state/lyrics_reader_provider.dart';
import 'package:kanaru/src/lyrics/state/online/online_lookup_providers.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/domain/playable.dart';
import 'package:kanaru/src/playback/state/playback_data_providers.dart';
import 'package:kanaru/src/playback/state/player_ready.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';
import '../../support/player_phase_override.dart';
import '../../plugins/data/store_test_support.dart';
import '../../plugins/domain/plugin_test_support.dart';
import 'fake_local_lyrics_reader.dart';
import 'fake_plugin_runner.dart';

class _Paths implements AppPaths {
  _Paths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => dataDir;
  @override
  Directory get configDir => dataDir;
}

/// A resolver whose answers the test sets; ids without an entry resolve to a
/// local file `/m/<id>.flac`.
class FakeResolver implements PlayableResolver {
  final answers = <TrackId, Playable>{};
  int calls = 0;

  @override
  Future<Map<TrackId, Playable>> resolve(List<TrackId> ids) async {
    calls++;
    return {
      for (final id in ids)
        id: answers[id] ?? LocalFile('/m/${id.value}.flac', null),
    };
  }
}

/// A container over an in-memory database, a fake reader and a fake resolver.
class LyricsHarness {
  LyricsHarness({
    List<Override> extra = const [],
    PlayerPhase phase = PlayerPhase.ready,
    int? runnerSlots,
    Stream<NowPlaying>? nowPlayingStream,
  }) : runner = FakePluginRunner(slots: runnerSlots) {
    db = openTestDb();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsStoreProvider.overrideWithValue(settings),
        localLyricsReaderProvider.overrideWithValue(reader),
        playableResolverProvider.overrideWithValue(resolver),
        playerPhaseOverride(phase),
        appPathsProvider.overrideWithValue(_Paths(Directory.systemTemp)),
        pluginRunnerProvider.overrideWithValue(runner),
        nowPlayingProvider.overrideWith(
          (ref) => nowPlayingStream ?? _nowPlayingStream(),
        ),
        lookupDebounceProvider.overrideWithValue(Duration.zero),
        lyricsParseRunnerProvider.overrideWithValue(<R>(f) async => await f()),
        lyricsClockProvider.overrideWithValue(
          () => clock.millisecondsSinceEpoch,
        ),
        onlineRandomProvider.overrideWithValue(() => 0),
        ...extra,
      ],
    );
  }

  late final AppDatabase db;
  late final ProviderContainer container;
  final settings = MemorySettingsStore();
  final reader = FakeLocalLyricsReader();
  final resolver = FakeResolver();
  final FakePluginRunner runner;

  /// What the player publishes; [play] makes a track "playing". A listener
  /// that comes later still gets the last value.
  final nowPlaying = StreamController<NowPlaying>.broadcast();
  NowPlaying? _lastNowPlaying;

  Stream<NowPlaying> _nowPlayingStream() => Stream.multi((out) {
    final last = _lastNowPlaying;
    if (last != null) out.add(last);
    final sub = nowPlaying.stream.listen(out.add);
    out.onCancel = sub.cancel;
  });

  /// The time of the lyrics code; move it to cross a backoff or a retry.
  DateTime clock = DateTime.utc(2026, 11, 23, 12);
  int _plugins = 0;
  int _sources = 0;
  int? _source;

  Future<void> dispose() async {
    container.dispose();
    await nowPlaying.close();
    await db.close();
  }

  /// Adds a track and returns its id.
  Future<TrackId> addTrackRow(
    String locator, {
    String? lrcLocator,
    String? lrcRevision,
  }) async {
    _source ??= await addSource(db, name: 'm${_sources++}');
    final id = await addTrack(db, _source!, locator: locator);
    if (lrcLocator != null) {
      await db
          .into(db.trackDetails)
          .insert(
            TrackDetailsCompanion.insert(
              trackId: Value(id),
              lrcLocator: Value(lrcLocator),
              lrcRevision: Value(lrcRevision),
            ),
          );
    }
    return TrackId(id);
  }

  /// Adds a track tagged [title] by `Artist`, 200 s.
  Future<TrackId> addSongRow(String locator, {String title = 'Song'}) async {
    final id = await addTrackRow(locator);
    await (db.update(db.tracks)..where((t) => t.id.equals(id.value))).write(
      TracksCompanion(
        title: Value(title),
        artist: const Value('Artist'),
        durationMs: const Value(200000),
      ),
    );
    return id;
  }

  /// Makes [id] the playing track.
  void play(TrackId id, {int entryId = 1}) {
    final entry = NowPlaying(entryId: entryId, trackId: id, playing: true);
    _lastNowPlaying = entry;
    nowPlaying.add(entry);
  }

  /// Installs a lyrics plugin [name] and returns its install id. Repository
  /// installs start on (see `defaultSourceEnabled`).
  Future<String> installLyrics(
    String name, {
    Map<String, Object?>? config,
    bool fromRepo = true,
  }) async {
    final n = ++_plugins;
    final manifest = validManifest();
    (manifest['metadata']! as Map<String, Object?>)['name'] = name;
    if (config != null) manifest['config'] = config;
    await container
        .read(pluginRowsProvider)
        .installOrRevive(
          testInstallId(n),
          draftOf(packageOf(manifest, const {})),
          fromRepo
              ? PluginSource.repo('https://r.example.com/p.json', 'repo$n')
              : const PluginSource.file('demo.zip'),
        );
    return testInstallId(n);
  }

  /// Runs the event loop until [done] holds.
  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await pumpEventQueue();
    }
    expect(done(), isTrue, reason: 'condition not reached');
  }
}
