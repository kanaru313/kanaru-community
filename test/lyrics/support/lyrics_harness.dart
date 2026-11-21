import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/lyrics/state/lyrics_reader_provider.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/domain/playable.dart';
import 'package:kanaru/src/playback/state/playback_data_providers.dart';
import 'package:kanaru/src/playback/state/player_ready.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';
import '../../support/player_phase_override.dart';
import 'fake_local_lyrics_reader.dart';

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
  }) {
    db = openTestDb();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsStoreProvider.overrideWithValue(settings),
        localLyricsReaderProvider.overrideWithValue(reader),
        playableResolverProvider.overrideWithValue(resolver),
        playerPhaseOverride(phase),
        ...extra,
      ],
    );
  }

  late final AppDatabase db;
  late final ProviderContainer container;
  final settings = MemorySettingsStore();
  final reader = FakeLocalLyricsReader();
  final resolver = FakeResolver();
  int _sources = 0;
  int? _source;

  Future<void> dispose() async {
    container.dispose();
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

  /// Runs the event loop until [done] holds.
  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await pumpEventQueue();
    }
    expect(done(), isTrue, reason: 'condition not reached');
  }
}
