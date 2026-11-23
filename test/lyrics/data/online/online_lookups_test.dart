import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_outcome.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import 'package:kanaru/src/media/domain/track_id.dart';

import '../../../database/support/test_db.dart';
import '../../support/fake_plugin_runner.dart';
import '../../support/online_lookup_rig.dart';

void main() {
  late LookupRig r;
  setUp(() => r = LookupRig());
  tearDown(() => r.dispose());

  final key = songTarget().cacheKey;

  Future<List<OnlineLyricsRow>> rows() => r.cache.readFresh(key, now: r.nowMs);

  void found(String id) => r.runner.answer(
    id,
    'search',
    searchAnswer([searchItem(id: 'r-$id', lyrics: inlineLyrics)]),
  );

  void miss(String id) => r.runner.answer(id, 'search', searchAnswer([]));

  test('sources are asked in order and the first result stops it', () async {
    r.sources = [fakeSource('a'), fakeSource('b'), fakeSource('c')];
    miss('a');
    found('b');
    found('c');
    r.lookups.watch(songTarget());
    await r.settle();
    expect(r.runner.callsOf('a'), 1);
    expect(r.runner.callsOf('b'), 1);
    expect(r.runner.callsOf('c'), 0);
    final saved = await rows();
    expect(
      [for (final x in saved) (x.providerId, x.status)],
      [('a', OnlineLyricsStatus.notFound), ('b', OnlineLyricsStatus.found)],
    );
    expect(r.outcomes, isEmpty);
  });

  test('a failure is never cached; it pauses only that source', () async {
    r.sources = [fakeSource('a'), fakeSource('b')];
    r.runner.answer('a', 'search', const RunFailed(RunFailReason.timeout));
    miss('b');
    r.lookups.watch(songTarget());
    await r.settle();
    expect([for (final x in await rows()) x.providerId], ['b']);
    expect(r.backoff.of('a'), isNotNull);
    expect(r.backoff.of('b'), isNull);
    final outcome = r.outcomes[key] as LookupFailed;
    expect(outcome.reason, LookupFailReason.network);
    expect(outcome.retryAt, r.clock.add(const Duration(seconds: 60)));
  });

  test(
    'an empty answer with a failed fetch inside is not "not found"',
    () async {
      r.sources = [fakeSource('a')];
      r.runner.answer(
        'a',
        'search',
        const RunOk(
          '[]',
          fetchFailure: FetchFailureInfo(kind: FetchFailureKind.network),
        ),
      );
      r.lookups.watch(songTarget());
      await r.settle();
      expect(await rows(), isEmpty);
      expect(r.backoff.of('a'), isNotNull);
      expect(r.outcomes[key], isA<LookupFailed>());
    },
  );

  test('busy and a plugin being switched skip without backoff', () async {
    r.sources = [fakeSource('a'), fakeSource('b'), fakeSource('c')];
    r.runner.answer('a', 'search', const RunBusy());
    r.runner.answer(
      'b',
      'search',
      const RunCancelled(RunCancelReason.pluginChanged),
    );
    r.runner.answer(
      'c',
      'search',
      const RunUnavailable(RunUnavailableReason.notInstalled),
    );
    r.lookups.watch(songTarget());
    await r.settle();
    for (final id in ['a', 'b', 'c']) {
      expect(r.backoff.of(id), isNull);
    }
    expect(await rows(), isEmpty);
    // Nothing failed, but the track must not spin: a later retry is set.
    final outcome = r.outcomes[key] as LookupFailed;
    expect(outcome.retryAt, r.clock.add(const Duration(seconds: 30)));
  });

  test(
    'every source needing configuration: no run, failed, no retry',
    () async {
      r.sources = [
        fakeSource('a', problem: SourceProblem.needsConfig),
        fakeSource('b', problem: SourceProblem.needsConfig),
      ];
      r.lookups.watch(songTarget());
      await r.settle();
      expect(r.runner.calls, isEmpty);
      final outcome = r.outcomes[key] as LookupFailed;
      expect(outcome.reason, LookupFailReason.needsConfig);
      expect(outcome.retryAt, isNull);
      expect(r.timers, isEmpty);
    },
  );

  test(
    'every source paused: recorded as paused until the earliest end',
    () async {
      final until = r.clock.add(const Duration(minutes: 2));
      r.sources = [
        fakeSource('a', problem: SourceProblem.paused, pausedUntil: until),
      ];
      r.lookups.watch(songTarget());
      await r.settle();
      expect(r.runner.calls, isEmpty);
      expect(r.outcomes[key], isA<LookupPaused>());
      expect((r.outcomes[key] as LookupPaused).until, until);
    },
  );

  test(
    'all in backoff: failed with the end; watched again after it, found',
    () async {
      r.sources = [fakeSource('a'), fakeSource('b')];
      r.runner.answer('a', 'search', const RunFailed(RunFailReason.timeout));
      r.runner.answer('b', 'search', const RunFailed(RunFailReason.timeout));
      final w = r.lookups.watch(songTarget());
      await r.settle();
      expect(r.runner.calls, hasLength(2));
      expect(
        (r.outcomes[key] as LookupFailed).retryAt,
        r.clock.add(const Duration(seconds: 60)),
      );
      expect(r.timers, isEmpty, reason: 'the service keeps no retry clock');
      w.release();
      await r.settle();

      // Network is back; the end has passed; the caller watches again.
      found('a');
      found('b');
      r.clock = r.clock.add(const Duration(seconds: 61));
      r.lookups.watch(songTarget());
      await r.settle();
      expect(r.runner.calls, hasLength(3));
      expect((await rows()).single.providerId, 'a');
      expect(r.outcomes, isEmpty);
    },
  );
  test('watching again inside the backoff asks nobody', () async {
    r.sources = [fakeSource('a')];
    r.runner.answer('a', 'search', const RunFailed(RunFailReason.timeout));
    final w = r.lookups.watch(songTarget());
    await r.settle();
    w.release();
    await r.settle();
    r.lookups.watch(songTarget());
    await r.settle();
    expect(r.runner.callsOf('a'), 1);
  });

  test(
    'the last watcher leaving cancels the run and asks no further source',
    () async {
      r.sources = [fakeSource('a'), fakeSource('b')];
      r.runner.blockUntilCancelled('a', 'search');
      found('b');
      final w = r.lookups.watch(songTarget());
      await r.settle();
      expect(r.runner.callsOf('a'), 1);
      w.release();
      await r.settle();
      expect(r.runner.cancelled.single.installId, 'a');
      expect(r.runner.callsOf('b'), 0);
      expect(await rows(), isEmpty);
      expect(r.outcomes, isEmpty);
    },
  );

  test('watchers of one key share one lookup; it ends with the last', () async {
    r.sources = [fakeSource('a')];
    r.runner.blockUntilCancelled('a', 'search');
    final first = r.lookups.watch(songTarget(id: 1));
    final second = r.lookups.watch(songTarget(id: 2));
    await r.settle();
    expect(r.runner.callsOf('a'), 1);
    expect(r.lookups.runningJobs, 1);
    first.release();
    await r.settle();
    expect(r.runner.cancelled, isEmpty);
    second.release();
    await r.settle();
    expect(r.runner.cancelled, hasLength(1));
  });

  test('a release and a watch in the same turn keep the run', () async {
    r.sources = [fakeSource('a')];
    r.runner.blockUntilCancelled('a', 'search');
    final w = r.lookups.watch(songTarget());
    await r.settle();
    w.release();
    r.lookups.watch(songTarget());
    await r.settle();
    expect(r.runner.cancelled, isEmpty);
    expect(r.runner.callsOf('a'), 1);
  });

  test(
    'skipping tracks quickly: the old run is cancelled, one new starts',
    () async {
      r.sources = [fakeSource('a')];
      r.runner.blockUntilCancelled('a', 'search');
      final one = r.lookups.watch(songTarget(title: 'One'));
      await r.settle();
      one.release();
      final two = r.lookups.watch(songTarget(title: 'Two'));
      await r.settle();
      expect(r.runner.cancelled, hasLength(1));
      expect(r.runner.callsOf('a'), 2);
      two.release();
    },
  );

  test(
    'a change of sources restarts the lookup and drops recorded ends',
    () async {
      r.sources = [fakeSource('a')];
      r.runner.answer('a', 'search', const RunFailed(RunFailReason.timeout));
      r.lookups.watch(songTarget());
      await r.settle();
      expect(r.outcomes, isNotEmpty);
      r.sources = [fakeSource('a'), fakeSource('b')];
      found('b');
      r.lookups.reset();
      await r.settle();
      expect(r.runner.callsOf('b'), 1);
      expect(r.outcomes, isEmpty);
      expect((await rows()).single.providerId, 'b');
    },
  );

  test('retryAll lifts the backoff and asks again', () async {
    r.sources = [fakeSource('a')];
    r.runner.answer('a', 'search', const RunFailed(RunFailReason.timeout));
    r.lookups.watch(songTarget());
    await r.settle();
    found('a');
    r.lookups.retryAll();
    await r.settle();
    expect(r.runner.callsOf('a'), 2);
    expect((await rows()).single.providerId, 'a');
  });

  test('dispose cancels the runs and writes nothing afterwards', () async {
    r.sources = [fakeSource('a')];
    r.runner.on('a', 'search', (_, cancel) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return searchAnswer([searchItem(lyrics: inlineLyrics)]);
    });
    r.lookups.watch(songTarget());
    await r.settle();
    r.lookups.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(await rows(), isEmpty);
  });

  test(
    'a found row that does not fit this track is not asked or overwritten',
    () async {
      r.sources = [fakeSource('a')];
      await r.cache.putFound(
        key,
        'a',
        remoteId: 'x',
        syncedText: inlineLyrics,
        remoteDurationMs: 205000,
        now: r.nowMs,
      );
      miss('a');
      r.lookups.watch(songTarget());
      await r.settle();
      expect(r.runner.calls, isEmpty);
      final saved = await rows();
      expect(saved.single.status, OnlineLyricsStatus.found);
    },
  );

  test(
    'a refused cached result opens its source and the next candidate wins',
    () async {
      r.sources = [fakeSource('a')];
      await r.cache.putFound(
        key,
        'a',
        remoteId: 'old',
        syncedText: inlineLyrics,
        remoteDurationMs: 200000,
        now: r.nowMs,
      );
      r.runner.answer(
        'a',
        'search',
        searchAnswer([
          searchItem(id: 'old', lyrics: inlineLyrics),
          searchItem(id: 'new', lyrics: '[00:01.00] fresh'),
        ]),
      );
      final source = await _addTrack(r);
      await r.rejects.add(
        source,
        providerId: 'a',
        remoteId: 'old',
        now: r.nowMs,
      );
      r.lookups.watch(songTarget(id: source.value));
      await r.settle();
      final saved = await rows();
      expect(saved.single.remoteId, 'new');
    },
  );

  test('a miss never replaces a found row this track refused', () async {
    r.sources = [fakeSource('a')];
    await r.cache.putFound(
      key,
      'a',
      remoteId: 'x',
      syncedText: inlineLyrics,
      remoteDurationMs: 200000,
      now: r.nowMs,
    );
    final track = await _addTrack(r);
    await r.rejects.add(track, providerId: 'a', remoteId: 'x', now: r.nowMs);
    miss('a');
    r.lookups.watch(songTarget(id: track.value));
    await r.settle();
    expect(r.runner.callsOf('a'), 1);
    final saved = await rows();
    expect(saved.single.status, OnlineLyricsStatus.found);
    expect(saved.single.remoteId, 'x');
  });

  test('a runner pause or missing setting still leaves a retry time', () async {
    r.sources = [fakeSource('a'), fakeSource('b')];
    final until = r.clock.add(const Duration(minutes: 3));
    r.runner.answer('a', 'search', RunPaused(until));
    r.runner.answer('b', 'search', const RunNeedsConfig(['Key']));
    r.lookups.watch(songTarget());
    await r.settle();
    expect(
      (r.outcomes[key] as LookupFailed).retryAt,
      r.clock.add(const Duration(seconds: 30)),
    );
    expect(r.backoff.snapshot(), isEmpty);

    final other = LookupRig();
    addTearDown(other.dispose);
    other.sources = [fakeSource('a')];
    other.runner.answer('a', 'search', RunPaused(until));
    other.lookups.watch(songTarget());
    await other.settle();
    expect((other.outcomes[key] as LookupFailed).retryAt, until);
  });

  test(
    'the debounce: skipping within it sends nothing, staying sends',
    () async {
      final d = LookupRig(debounce: const Duration(seconds: 1));
      addTearDown(d.dispose);
      d.sources = [fakeSource('a')];
      d.runner.answer('a', 'search', searchAnswer([]));
      final one = d.lookups.watch(songTarget(title: 'One'));
      await d.settle();
      one.release();
      await d.settle();
      d.lookups.watch(songTarget(title: 'Two'));
      await d.settle();
      expect(d.runner.calls, isEmpty);
      for (final t in d.timers) {
        expect(t.after, const Duration(seconds: 1));
        t.fire();
      }
      await d.settle();
      expect(d.runner.calls, hasLength(1));
      expect(d.runner.calls.single.input['title'], 'Two');
    },
  );

  test(
    'a target without title, artist or duration is never looked up',
    () async {
      r.sources = [fakeSource('a')];
      final watch = r.lookups.watch(songTarget(title: ' '));
      await r.settle();
      expect(r.runner.calls, isEmpty);
      watch.release();
    },
  );

  test('ends whose time has passed are pruned from the map', () async {
    r.sources = [fakeSource('a')];
    r.runner.answer('a', 'search', const RunBusy());
    final w = r.lookups.watch(songTarget(title: 'One'));
    await r.settle();
    expect(r.outcomes, hasLength(1));
    w.release();
    await r.settle();
    r.clock = r.clock.add(const Duration(minutes: 5));
    r.lookups.watch(songTarget(title: 'Two'));
    await r.settle();
    expect(r.outcomes.keys, [songTarget(title: 'Two').cacheKey]);
  });
}

Future<TrackId> _addTrack(LookupRig r) async {
  final source = await addSource(r.db);
  return TrackId(await addTrack(r.db, source, locator: 'a.flac'));
}
