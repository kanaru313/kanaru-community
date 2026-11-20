import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_change.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/domain/history/history_ranges.dart';
import 'package:kanaru/src/library/state/history/history_providers.dart';
import 'package:kanaru/src/library/state/history/most_played_selection.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';

import 'fake_history_store.dart';

final _now = DateTime(2026, 11, 20, 10);

/// A store whose `top` waits for the test.
class _SlowTop extends FakeHistoryStore {
  Completer<MostPlayed>? gate;

  @override
  Future<MostPlayed> top({({int start, int end})? window, required int limit}) {
    topCalls.add(window);
    return gate?.future ?? Future.value(topAnswer);
  }
}

void main() {
  late _SlowTop store;
  late ProviderContainer c;

  setUp(() {
    store = _SlowTop()
      ..played = (
        first: DateTime(2026, 10, 1).millisecondsSinceEpoch,
        last: DateTime(2026, 11, 19).millisecondsSinceEpoch,
      )
      ..topAnswer = const MostPlayed(entries: [], songs: 3, plays: 9);
    c = ProviderContainer(
      overrides: [
        historyStoreProvider.overrideWithValue(store),
        historyClockProvider.overrideWithValue(() => _now),
      ],
    );
  });
  tearDown(() async {
    c.dispose();
    await store.playsChanged.close();
    await store.tracksChanged.close();
  });

  test('defaults are 30 days and 100, and survive no listeners', () async {
    expect(c.read(mostPlayedRangeProvider).preset, MostPlayedPreset.days30);
    expect(c.read(mostPlayedLimitProvider), 100);
    c.read(mostPlayedLimitProvider.notifier).set(5000);
    expect(c.read(mostPlayedLimitProvider), 1000);
    c.read(mostPlayedLimitProvider.notifier).set(10);
    await pumpEventQueue();
    expect(c.read(mostPlayedLimitProvider), 10);
  });

  test('a window not covering every play is passed to the store', () async {
    c
        .read(mostPlayedRangeProvider.notifier)
        .set(const MostPlayedRange(preset: MostPlayedPreset.days7));
    c.listen(mostPlayedProvider, (_, _) {});
    await pumpEventQueue();
    expect(store.topCalls.single, isNotNull);
    expect(c.read(mostPlayedProvider).data!.plays, 9);
  });

  test('a window covering every play asks all time', () async {
    c.listen(mostPlayedProvider, (_, _) {});
    await pumpEventQueue();
    // 30 days back from tomorrow reaches 21 Oct: first play is 1 Oct, so
    // not covered; widen to a year.
    c
        .read(mostPlayedRangeProvider.notifier)
        .set(const MostPlayedRange(preset: MostPlayedPreset.year));
    await pumpEventQueue();
    expect(store.topCalls.last, isNull);
  });

  test('keeps the previous list while a new range loads', () async {
    c.listen(mostPlayedProvider, (_, _) {});
    await pumpEventQueue();
    expect(c.read(mostPlayedProvider).stale, isFalse);

    store.gate = Completer();
    c
        .read(mostPlayedRangeProvider.notifier)
        .set(const MostPlayedRange(preset: MostPlayedPreset.today));
    await pumpEventQueue();
    final loading = c.read(mostPlayedProvider);
    expect(loading.data!.plays, 9);
    expect(loading.stale, isTrue);

    store.gate!.complete(const MostPlayed(entries: [], songs: 1, plays: 2));
    await pumpEventQueue();
    final done = c.read(mostPlayedProvider);
    expect(done.data!.plays, 2);
    expect(done.stale, isFalse);
  });

  test('re-reads on a change of plays', () async {
    c.listen(mostPlayedProvider, (_, _) {});
    await pumpEventQueue();
    store.playsChanged.add(const HistoryChange(inserted: true));
    await pumpEventQueue();
    expect(store.topCalls.length, 2);
  });

  test('a failed read is reported', () async {
    final bad = _Failing();
    final c2 = ProviderContainer(
      overrides: [
        historyStoreProvider.overrideWithValue(bad),
        historyClockProvider.overrideWithValue(() => _now),
      ],
    );
    addTearDown(c2.dispose);
    c2.listen(mostPlayedProvider, (_, _) {});
    await pumpEventQueue();
    expect(c2.read(mostPlayedProvider).error, isA<StateError>());
  });
}

class _Failing extends FakeHistoryStore {
  @override
  Future<MostPlayed> top({
    ({int start, int end})? window,
    required int limit,
  }) => throw StateError('boom');
}
