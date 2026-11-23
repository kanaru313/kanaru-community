import 'dart:async';

import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/lyrics/data/online/lyrics_run_client.dart';
import 'package:kanaru/src/lyrics/data/online/online_backoff.dart';
import 'package:kanaru/src/lyrics/data/online/online_cache_store.dart';
import 'package:kanaru/src/lyrics/data/online/online_lookups.dart';
import 'package:kanaru/src/lyrics/data/online/reject_store.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_outcome.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_target.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_candidate.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../database/support/test_db.dart';
import 'fake_plugin_runner.dart';

/// A timer the test fires by hand.
class ManualTimer implements Timer {
  ManualTimer(this.after, this._run);

  final Duration after;
  final void Function() _run;
  bool _active = true;
  bool fired = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => fired ? 1 : 0;

  @override
  void cancel() => _active = false;

  void fire() {
    if (!_active) return;
    _active = false;
    fired = true;
    _run();
  }
}

LyricsSource fakeSource(
  String id, {
  bool enabled = true,
  SourceProblem? problem,
  DateTime? pausedUntil,
}) => LyricsSource(
  id: id,
  name: id,
  version: 1,
  origin: LyricsSourceOrigin.repo,
  enabled: enabled,
  problem: problem,
  pausedUntil: pausedUntil,
);

/// The song `Song` by `Artist`, 200 s, as the track [id].
LookupTarget songTarget({int id = 1, String title = 'Song'}) => LookupTarget(
  trackId: TrackId(id),
  query: LyricsQuery(
    title: title,
    artist: 'Artist',
    duration: const Duration(seconds: 200),
  ),
  artists: const ['Artist'],
);

const inlineLyrics = '[00:01.00] hello';

/// A database, a fake runner and the lookups service over them, with a clock
/// and the long timers (retry) under the test's hand. Debounce-free: a zero
/// timer is a real one.
class LookupRig {
  LookupRig({int? slots}) : runner = FakePluginRunner(slots: slots) {
    db = openTestDb();
    cache = OnlineCacheStore(db);
    rejects = RejectStore(db);
    backoff = OnlineBackoff(now: () => clock, random: () => 0);
    lookups = OnlineLookups(
      client: LyricsRunClient(runner, run: <R>(f) async => await f()),
      cache: cache,
      rejects: rejects,
      backoff: backoff,
      now: () => clock,
      sources: () => sources,
      onOutcomes: (m) => outcomes = m,
      timer: (after, run) {
        if (after == Duration.zero) return Timer(after, run);
        final t = ManualTimer(after, run);
        timers.add(t);
        return t;
      },
    );
  }

  final FakePluginRunner runner;
  late final AppDatabase db;
  late final OnlineCacheStore cache;
  late final RejectStore rejects;
  late final OnlineBackoff backoff;
  late final OnlineLookups lookups;
  DateTime clock = DateTime.utc(2026, 11, 23, 12);
  List<LyricsSource> sources = [];
  Map<String, LookupOutcome> outcomes = {};
  final timers = <ManualTimer>[];

  Future<void> dispose() async {
    lookups.dispose();
    await db.close();
  }

  int get nowMs => clock.millisecondsSinceEpoch;

  Future<void> settle() async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}
