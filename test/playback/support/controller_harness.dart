import 'dart:async';
import 'dart:math';

import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/data/db_track_title_lookup.dart';
import 'package:kanaru/src/playback/data/playable_resolver.dart';
import 'package:kanaru/src/playback/data/queue_repository.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/playable.dart';
import 'package:kanaru/src/playback/domain/playback_focus.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';
import 'package:kanaru/src/playback/state/player_controller.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';
import 'fake_audio_engine.dart';

class FakeFocus implements PlaybackFocus {
  bool grant = true;

  /// When set, `activate` never completes (a hung platform call).
  bool hang = false;
  int activations = 0;
  int deactivations = 0;

  @override
  Future<bool> activate() async {
    activations++;
    if (hang) return Completer<bool>().future;
    return grant;
  }

  @override
  Future<void> deactivate() async => deactivations++;
}

const ctx = PlayContext(PlayContextKind.songs);

/// A controller on an in-memory database with a fake engine.
class Harness {
  Harness._(this.db, this.engine, this.focus, this.settings, this.tracks);

  final AppDatabase db;
  final FakeAudioEngine engine;
  final FakeFocus focus;
  final MemorySettingsStore settings;
  final List<TrackId> tracks;
  late PlayerController c;
  final notices = <PlaybackNotice>[];
  int engineCreations = 0;
  int now = 1000;

  static Future<Harness> create({
    int tracks = 6,
    Duration focusTimeout = const Duration(seconds: 2),
    PlayableResolver Function(PlayableResolver real)? wrapResolver,
  }) async {
    final db = openTestDb();
    final src = await addSource(db, root: '/music');
    await addMount(db, src, root: '/music');
    final ids = [
      for (var i = 0; i < tracks; i++)
        TrackId(await addTrack(db, src, locator: 't$i.mp3', title: 'T$i')),
    ];
    final h = Harness._(
      db,
      FakeAudioEngine(),
      FakeFocus(),
      MemorySettingsStore(),
      ids,
    );
    h.c = PlayerController(
      repo: QueueRepository(db),
      resolver: wrapResolver == null
          ? LocalPlayableResolver(db)
          : wrapResolver(LocalPlayableResolver(db)),
      settings: h.settings,
      engineFactory: () {
        h.engineCreations++;
        return h.engine;
      },
      focus: h.focus,
      titles: DbTrackTitleLookup(db),
      clock: () => h.now,
      random: Random(7),
      focusTimeout: focusTimeout,
    );
    h.c.notices.listen(h.notices.add);
    return h;
  }

  Future<void> close() async {
    await c.dispose();
    await db.close();
  }

  /// Plays all tracks from [start].
  Future<void> play({int start = 0, bool shuffle = false}) =>
      c.playTracks(tracks, startIndex: start, shuffle: shuffle, context: ctx);

  /// Waits for the reconcile after the latest commands.
  Future<void> settle() async {
    await c.settled();
    await pumpTicks();
  }

  Future<void> pumpTicks() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    await c.settled();
  }

  Future<void> markMissing(TrackId id) => db.customStatement(
    "UPDATE tracks SET status = '${TrackStatus.missing}', missing_since = 1 WHERE id = ${id.value}",
  );

  /// Indexes into [tracks] in play order.
  List<int> order() => [
    for (final i in c.queueState.items) i.trackId.value - tracks.first.value,
  ];

  EngineToken get loadedToken => engine.loads.last.token;
}

/// Counts `resolve` calls.
class CountingResolver implements PlayableResolver {
  CountingResolver(this.inner);
  final PlayableResolver inner;
  int calls = 0;

  @override
  Future<Map<TrackId, Playable>> resolve(List<TrackId> ids) {
    calls++;
    return inner.resolve(ids);
  }
}
