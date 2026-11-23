import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_outcome.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/lyrics/domain/online/online_resolution.dart';
import 'package:kanaru/src/lyrics/domain/online/online_rows.dart';
import 'package:kanaru/src/lyrics/domain/online/online_text.dart';

final _now = DateTime.utc(2026, 11, 23, 12);

const _local = Lyrics(
  lines: [LyricLine(Duration.zero, 'local')],
  synced: false,
  origin: LyricsOrigin.tag,
);

const _text = OnlineText([LyricLine(Duration.zero, 'online')], synced: false);

LyricsSource _source(
  String id, {
  bool enabled = true,
  SourceProblem? problem,
  DateTime? pausedUntil,
}) => LyricsSource(
  id: id,
  name: 'Plugin $id',
  version: 1,
  origin: LyricsSourceOrigin.repo,
  enabled: enabled,
  problem: problem,
  pausedUntil: pausedUntil,
);

OnlineCacheEntry _found(
  String id, {
  OnlineText? text = _text,
  bool instrumental = false,
  int? durationMs,
}) => OnlineCacheEntry(
  providerId: id,
  fetchedAt: _now,
  found: true,
  remoteId: 'r-$id',
  text: text,
  instrumental: instrumental,
  remoteDurationMs: durationMs,
);

OnlineCacheEntry _missed(String id, {Duration age = Duration.zero}) =>
    OnlineCacheEntry(providerId: id, fetchedAt: _now.subtract(age));

const _pin = OnlinePick(
  providerId: 'gone',
  providerName: 'Old name',
  remoteId: 'pin-1',
  text: _text,
  remoteDurationMs: 201000,
);

LyricsResolution _resolve({
  LyricsChoice? choice,
  OnlinePick? pin,
  Lyrics? local,
  List<OnlineCacheEntry> cache = const [],
  List<LyricsSource>? sources,
  bool autoOn = true,
  bool autoSearchable = true,
  Duration? trackDuration = const Duration(seconds: 200),
  Map<String, SourceBackoff> backoff = const {},
  LookupOutcome? lookup,
}) => resolveTrackLyrics(
  choice: choice,
  pin: pin,
  local: local,
  cache: cache,
  sources: sources ?? [_source('a'), _source('b')],
  autoOn: autoOn,
  autoSearchable: autoSearchable,
  now: _now,
  trackDuration: trackDuration,
  backoff: backoff,
  lookup: lookup,
);

OnlineLyricsRef _ref(TrackLyrics state) => switch (state) {
  LyricsShown(:final lyrics) => lyrics.online!,
  LyricsInstrumental(:final ref) => ref,
  _ => throw StateError('no ref in $state'),
};

void main() {
  group('choice and local order', () {
    test('off wins over everything and keeps what automatic would show', () {
      final r = _resolve(choice: LyricsChoice.off, pin: _pin, local: _local);
      final off = r.state as LyricsOff;
      expect(off.available!.online!.how, OnlineHow.kept);
      expect(r.needsLookup, isFalse);
      final noPin = _resolve(choice: LyricsChoice.off, local: _local);
      expect((noPin.state as LyricsOff).available, _local);
      expect(
        (_resolve(choice: LyricsChoice.off).state as LyricsOff).available,
        isNull,
      );
    });

    test('file shows the local lyrics even with a kept copy', () {
      final r = _resolve(choice: LyricsChoice.file, pin: _pin, local: _local);
      expect(r.state, const LyricsShown(_local));
    });

    test('file without local lyrics falls back to the kept copy', () {
      final r = _resolve(choice: LyricsChoice.file, pin: _pin);
      expect(_ref(r.state).how, OnlineHow.kept);
    });

    test('a kept copy beats local lyrics and survives its plugin', () {
      final r = _resolve(pin: _pin, local: _local, sources: [_source('a')]);
      final ref = _ref(r.state);
      expect(
        (ref.how, ref.providerName, ref.remoteDurationMs),
        (OnlineHow.kept, 'Old name', 201000),
      );
      expect((r.state as LyricsShown).lyrics.origin, LyricsOrigin.online);
    });

    test('a kept instrumental copy is instrumental', () {
      const pin = OnlinePick(
        providerId: 'a',
        providerName: 'A',
        remoteId: 'x',
        instrumental: true,
      );
      expect(_resolve(pin: pin).state, isA<LyricsInstrumental>());
    });

    test('a kept copy with nothing usable is ignored', () {
      const pin = OnlinePick(providerId: 'a', providerName: 'A', remoteId: 'x');
      expect(
        _resolve(pin: pin, local: _local).state,
        const LyricsShown(_local),
      );
    });

    test('local lyrics beat the cache and never start a lookup', () {
      final r = _resolve(local: _local, cache: [_found('a')]);
      expect(r.state, const LyricsShown(_local));
      expect(r.needsLookup, isFalse);
    });
  });

  group('cache', () {
    test(
      'a found row shows as automatic online lyrics under the live name',
      () {
        final r = _resolve(cache: [_found('b')]);
        final ref = _ref(r.state);
        expect(
          (ref.how, ref.providerId, ref.providerName, ref.remoteId),
          (OnlineHow.auto, 'b', 'Plugin b', 'r-b'),
        );
        expect(r.needsLookup, isFalse);
      },
    );

    test('lyrics beat instrumental, sources keep their order', () {
      final r = _resolve(
        cache: [_found('a', text: null, instrumental: true), _found('b')],
      );
      expect(r.state, isA<LyricsShown>());
      final both = _resolve(cache: [_found('b'), _found('a')]);
      expect(_ref(both.state).providerId, 'a');
    });

    test('instrumental alone is instrumental', () {
      final r = _resolve(cache: [_found('a', text: null, instrumental: true)]);
      expect(r.state, isA<LyricsInstrumental>());
    });

    test(
      'a result of a disabled source still counts, of a removed one not',
      () {
        final off = _resolve(
          cache: [_found('a')],
          sources: [_source('a', enabled: false)],
        );
        expect(off.state, isA<LyricsShown>());
        final gone = _resolve(cache: [_found('zzz')], sources: [_source('a')]);
        expect(gone.state, isA<LyricsSearching>());
      },
    );

    test(
      'a duration too far from the track is ignored, none or near is fine',
      () {
        expect(
          _resolve(cache: [_found('a', durationMs: 203000)]).state,
          isA<LyricsShown>(),
        );
        expect(
          _resolve(cache: [_found('a', durationMs: 203001)]).state,
          isA<LyricsSearching>(),
        );
        expect(
          _resolve(cache: [_found('a')], trackDuration: null).state,
          isA<LyricsShown>(),
        );
      },
    );

    test('a found row with no text and no flag is a miss', () {
      final r = _resolve(
        cache: [_found('a', text: null), _found('b', text: null)],
      );
      expect(r.state, const LyricsNotFound(asked: 2, off: 0));
    });
  });

  group('not found, no source, auto off', () {
    test('every enabled source has a fresh miss: not found', () {
      final r = _resolve(
        cache: [_missed('a'), _missed('b')],
        sources: [_source('a'), _source('b'), _source('c', enabled: false)],
      );
      expect(r.state, const LyricsNotFound(asked: 2, off: 1));
      expect(r.needsLookup, isFalse);
    });

    test('a miss of a disabled source does not hide the others', () {
      final r = _resolve(
        cache: [_missed('c')],
        sources: [_source('a'), _source('c', enabled: false)],
      );
      expect(r.state, const LyricsSearching(1));
      expect(r.sourcesToAsk, ['a']);
    });

    test('a miss older than 14 days is asked again, 13 days is not', () {
      final stale = _resolve(
        cache: [
          _missed('a', age: notFoundTtl),
          _missed('b', age: const Duration(days: 13)),
        ],
      );
      expect(stale.sourcesToAsk, ['a']);
      final fresh = _resolve(
        cache: [_missed('a', age: const Duration(days: 13, hours: 23))],
        sources: [_source('a')],
      );
      expect(fresh.state, isA<LyricsNotFound>());
    });

    test('no source enabled: not found with nothing asked', () {
      final r = _resolve(
        sources: [_source('a', enabled: false), _source('b', enabled: false)],
      );
      expect(r.state, const LyricsNotFound(asked: 0, off: 2));
    });

    test('no lyrics plugin installed', () {
      expect(_resolve(sources: const []).state, isA<LyricsNoSource>());
      expect(
        _resolve(sources: const [], autoOn: false).state,
        isA<LyricsNoSource>(),
      );
    });

    test('auto search off, or a song with no usable tags: none', () {
      expect(_resolve(autoOn: false).state, isA<LyricsNone>());
      expect(_resolve(autoSearchable: false).state, isA<LyricsNone>());
      expect(
        _resolve(autoOn: false, cache: [_missed('a'), _missed('b')]).state,
        isA<LyricsNone>(),
      );
    });
  });

  group('lookup', () {
    test('needs a lookup over the open sources in the user order', () {
      final r = _resolve(
        sources: [_source('b'), _source('a'), _source('c', enabled: false)],
        cache: [_missed('a')],
      );
      expect(r.state, const LyricsSearching(2));
      expect(r.sourcesToAsk, ['b']);
      expect(r.needsLookup, isTrue);
    });

    test('skips sources in backoff, needing config, paused or broken', () {
      final later = _now.add(const Duration(minutes: 1));
      final r = _resolve(
        sources: [
          _source('a', problem: SourceProblem.needsConfig),
          _source('b'),
          _source('c', problem: SourceProblem.paused, pausedUntil: later),
          _source('d', problem: SourceProblem.broken),
          _source('e'),
        ],
        backoff: {'b': SourceBackoff(until: later, network: true)},
      );
      expect(r.sourcesToAsk, ['e']);
      expect(r.state, const LyricsSearching(5));
    });

    test('a backoff that has ended is asked again', () {
      final r = _resolve(
        sources: [_source('a')],
        backoff: {
          'a': SourceBackoff(
            until: _now.subtract(const Duration(seconds: 1)),
            network: true,
          ),
        },
      );
      expect(r.sourcesToAsk, ['a']);
    });

    test('a recorded failure shows as failed until its retry time', () {
      final retry = _now.add(const Duration(minutes: 5));
      final failed = LookupFailed(
        reason: LookupFailReason.network,
        asked: 2,
        retryAt: retry,
      );
      final r = _resolve(lookup: failed);
      expect(
        r.state,
        LyricsLookupFailed(
          reason: LookupFailReason.network,
          asked: 2,
          retryAt: retry,
        ),
      );
      expect(r.needsLookup, isFalse);
      final due = _resolve(
        lookup: LookupFailed(
          reason: LookupFailReason.network,
          asked: 2,
          retryAt: _now,
        ),
      );
      expect(due.state, const LyricsSearching(2));
      expect(due.needsLookup, isTrue);
    });

    test('a failure without a retry time stays until cleared', () {
      final r = _resolve(
        lookup: const LookupFailed(
          reason: LookupFailReason.needsConfig,
          asked: 1,
        ),
      );
      expect(
        r.state,
        const LyricsLookupFailed(
          reason: LookupFailReason.needsConfig,
          asked: 1,
        ),
      );
    });

    test('a recorded pause shows as paused until it ends', () {
      final until = _now.add(const Duration(minutes: 3));
      expect(
        _resolve(lookup: LookupPaused(until)).state,
        LyricsLookupPaused(until),
      );
      expect(
        _resolve(lookup: LookupPaused(_now)).state,
        isA<LyricsSearching>(),
      );
    });

    test('a found cache row beats a recorded failure', () {
      final r = _resolve(
        cache: [_found('a')],
        lookup: const LookupFailed(reason: LookupFailReason.network, asked: 2),
      );
      expect(r.state, isA<LyricsShown>());
    });
  });

  group('nothing left to ask, no run', () {
    DateTime at(int minutes) => _now.add(Duration(minutes: minutes));

    test('all need configuration', () {
      final r = _resolve(
        sources: [
          _source('a', problem: SourceProblem.needsConfig),
          _source('b', problem: SourceProblem.needsConfig),
        ],
      );
      expect(
        r.state,
        const LyricsLookupFailed(
          reason: LookupFailReason.needsConfig,
          asked: 2,
        ),
      );
      expect(r.needsLookup, isFalse);
    });

    test(
      'all in backoff after a network failure: retry at the earliest end',
      () {
        final r = _resolve(
          sources: [_source('a'), _source('b')],
          backoff: {
            'a': SourceBackoff(until: at(5), network: true),
            'b': SourceBackoff(until: at(2), network: true),
          },
        );
        expect(
          r.state,
          LyricsLookupFailed(
            reason: LookupFailReason.network,
            asked: 2,
            retryAt: at(2),
          ),
        );
      },
    );

    test('backoff after a bad answer is no answer', () {
      final r = _resolve(
        sources: [_source('a')],
        backoff: {'a': SourceBackoff(until: at(1), network: false)},
      );
      expect((r.state as LyricsLookupFailed).reason, LookupFailReason.noAnswer);
    });

    test('all paused: paused until the earliest end', () {
      final r = _resolve(
        sources: [
          _source('a', problem: SourceProblem.paused, pausedUntil: at(9)),
          _source('b', problem: SourceProblem.paused, pausedUntil: at(4)),
        ],
      );
      expect(r.state, LyricsLookupPaused(at(4)));
      expect(r.needsLookup, isFalse);
    });

    test('mixed reasons: the most frequent, a tie goes to the network', () {
      final mostly = _resolve(
        sources: [
          _source('a', problem: SourceProblem.needsConfig),
          _source('b', problem: SourceProblem.needsConfig),
          _source('c', problem: SourceProblem.broken),
          _source('d', problem: SourceProblem.paused, pausedUntil: at(3)),
        ],
      );
      final failed = mostly.state as LyricsLookupFailed;
      expect(failed.reason, LookupFailReason.needsConfig);
      expect(failed.retryAt, at(3));
      final tie = _resolve(
        sources: [
          _source('a', problem: SourceProblem.needsConfig),
          _source('b', problem: SourceProblem.paused, pausedUntil: at(3)),
        ],
      );
      expect(
        (tie.state as LyricsLookupFailed).reason,
        LookupFailReason.network,
      );
    });

    test('a source with a fresh miss is not counted among the skipped', () {
      final r = _resolve(
        cache: [_missed('a')],
        sources: [
          _source('a'),
          _source('b', problem: SourceProblem.needsConfig),
        ],
      );
      expect(
        r.state,
        const LyricsLookupFailed(
          reason: LookupFailReason.needsConfig,
          asked: 2,
        ),
      );
    });
  });

  test('the new states compare by value', () {
    expect(const LyricsSearching(2), const LyricsSearching(2));
    expect(const LyricsSearching(2), isNot(const LyricsSearching(3)));
    expect(
      const LyricsNotFound(asked: 1, off: 2),
      const LyricsNotFound(asked: 1, off: 2),
    );
    expect(const LyricsNoSource(), const LyricsNoSource());
    expect(LyricsLookupPaused(_now), LyricsLookupPaused(_now));
    expect(
      const LyricsLookupFailed(reason: LookupFailReason.network, asked: 1),
      isNot(
        const LyricsLookupFailed(reason: LookupFailReason.noAnswer, asked: 1),
      ),
    );
  });
}
