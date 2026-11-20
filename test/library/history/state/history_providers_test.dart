import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/history/history_repository.dart';
import 'package:kanaru/src/library/domain/history/history_change.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/state/history/history_providers.dart';
import 'package:kanaru/src/library/state/history/history_year_selection.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';

import '../../../database/support/test_db.dart';
import '../data/history_fixture.dart';
import 'fake_history_store.dart';

final _now = DateTime(2026, 11, 20, 10);

void main() {
  late FakeHistoryStore store;
  late ProviderContainer c;

  ProviderContainer make(FakeHistoryStore s) => ProviderContainer(
    overrides: [
      historyStoreProvider.overrideWithValue(s),
      historyClockProvider.overrideWithValue(() => _now),
    ],
  );

  setUp(() {
    store = FakeHistoryStore()
      ..byYear = {
        2026: [play(1, 2026), play(2, 2026)],
        2025: [play(3, 2025)],
      }
      ..yearsAnswer = [2026, 2025];
    c = make(store);
  });
  tearDown(() async {
    c.dispose();
    await store.playsChanged.close();
    await store.tracksChanged.close();
  });

  void keep(ProviderListenable<Object?> p) => c.listen(p, (_, _) {});

  group('year', () {
    test('the current year re-reads on an insert and on a delete', () async {
      keep(historyYearProvider(2026));
      await c.read(historyYearProvider(2026).future);
      store.playsChanged.add(const HistoryChange(inserted: true));
      await pumpEventQueue();
      store.playsChanged.add(const HistoryChange(removed: true));
      await pumpEventQueue();
      expect(store.yearReads, [2026, 2026, 2026]);
    });

    test(
      'an older year ignores inserts, re-reads on delete and undo',
      () async {
        keep(historyYearProvider(2025));
        await c.read(historyYearProvider(2025).future);
        store.playsChanged.add(const HistoryChange(inserted: true));
        await pumpEventQueue();
        expect(store.yearReads, [2025]);
        store.playsChanged.add(const HistoryChange(removed: true));
        await pumpEventQueue();
        store.playsChanged.add(
          const HistoryChange(inserted: true, removed: true),
        );
        await pumpEventQueue();
        expect(store.yearReads, [2025, 2025, 2025]);
      },
    );

    test('a tracks change reloads infos only', () async {
      keep(historyYearProvider(2026));
      await c.read(historyYearProvider(2026).future);
      store.tracksChanged.add(null);
      await pumpEventQueue();
      expect(store.yearReads, [2026]);
      expect(store.refreshCalls, 1);
      expect(c.read(historyYearProvider(2026)).value!.first.track.title, 'New');
    });

    test('a tracks change during a re-read does not bring back a deleted '
        'play', () async {
      keep(historyYearProvider(2026));
      await c.read(historyYearProvider(2026).future);
      final gate = Completer<void>();
      store.yearGate = gate;
      store.byYear[2026] = [play(2, 2026)];
      store.playsChanged.add(const HistoryChange(removed: true));
      await pumpEventQueue();
      expect(c.read(historyYearProvider(2026)).isLoading, isTrue);
      store.tracksChanged.add(null);
      await pumpEventQueue();
      gate.complete();
      await c.read(historyYearProvider(2026).future);
      await pumpEventQueue();
      expect(c.read(historyYearProvider(2026)).value!.map((p) => p.id), [2]);
    });

    test('disposing cancels the subscriptions', () async {
      final sub = c.listen(historyYearProvider(2026), (_, _) {});
      await c.read(historyYearProvider(2026).future);
      expect(store.playsChanged.hasListener, isTrue);
      sub.close();
      await pumpEventQueue();
      expect(store.playsChanged.hasListener, isFalse);
      expect(store.tracksChanged.hasListener, isFalse);
    });

    test('a failed read is an error value', () async {
      final bad = FakeHistoryStore();
      final c2 = ProviderContainer(
        overrides: [
          historyStoreProvider.overrideWithValue(_Throwing(bad)),
          historyClockProvider.overrideWithValue(() => _now),
        ],
      );
      addTearDown(c2.dispose);
      c2.listen(historyYearProvider(2026), (_, _) {});
      await expectLater(
        c2.read(historyYearProvider(2026).future),
        throwsStateError,
      );
    });
  });

  group('selection', () {
    test('null shows the newest, a picked year wins', () async {
      keep(historyShownYearProvider);
      await c.read(historyYearsProvider.future);
      expect(c.read(historyShownYearProvider), 2026);
      c.read(historySelectedYearProvider.notifier).select(2025);
      expect(c.read(historyShownYearProvider), 2025);
    });

    test('falls back when the picked year empties', () async {
      keep(historyShownYearProvider);
      keep(historySelectedYearProvider);
      await c.read(historyYearsProvider.future);
      c.read(historySelectedYearProvider.notifier).select(2025);
      store.yearsAnswer = [2026];
      store.playsChanged.add(const HistoryChange(removed: true));
      await pumpEventQueue();
      expect(c.read(historySelectedYearProvider), isNull);
      expect(c.read(historyShownYearProvider), 2026);
    });
  });

  group('filter', () {
    test('matches folded text and reports the cap', () async {
      store.byYear[2026] = [
        for (var i = 1; i <= 1200; i++)
          play(i, 2026, track: info(i, title: i == 7 ? 'Vũ trụ' : 'Song $i')),
      ];
      keep(historyYearProvider(2026));
      await c.read(historyYearProvider(2026).future);
      final all = c.read(historyFilterProvider((year: 2026, query: 'song')));
      expect(all.value!.plays.length, historyFilterCap);
      expect(all.value!.matched, 1199);
      expect(all.value!.capped, isTrue);
      final one = c.read(historyFilterProvider((year: 2026, query: 'vu tru')));
      expect(one.value!.plays.single.id, 7);
      expect(one.value!.capped, isFalse);
    });
  });

  group('overview and flags', () {
    test('overview re-reads on a change', () async {
      keep(historyOverviewProvider);
      await c.read(historyOverviewProvider.future);
      store.playsChanged.add(const HistoryChange(inserted: true));
      await pumpEventQueue();
      expect(store.overviewReads, 2);
    });
  });

  group('real repository', () {
    late AppDatabase db;
    setUp(() => db = openTestDb());
    tearDown(() => db.close());

    test('inserts re-read, listened_ms checkpoints do not', () async {
      final ids = await addTracks(db, 1);
      final id = await addPlay(db, ids.first, playedAt: ms(2026, 11, 1));
      final real = ProviderContainer(
        overrides: [
          historyStoreProvider.overrideWithValue(HistoryRepository(db)),
          historyClockProvider.overrideWithValue(() => _now),
        ],
      );
      addTearDown(real.dispose);
      var emissions = 0;
      real.listen(historyYearProvider(2026), (_, _) => emissions++);
      expect((await real.read(historyYearProvider(2026).future)).length, 1);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final base = emissions;

      await db.customStatement(
        'UPDATE play_log SET listened_ms = ? WHERE id = ?',
        [5000, id],
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(emissions, base, reason: 'a checkpoint is not a change');

      await addPlay(db, ids.first, playedAt: ms(2026, 11, 2));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect((await real.read(historyYearProvider(2026).future)).length, 2);
      expect(emissions, greaterThan(base));
    });
  });
}

/// A store whose year read fails.
class _Throwing extends FakeHistoryStore {
  _Throwing(FakeHistoryStore _);

  @override
  Future<List<HistoryPlay>> yearPlays(int year) => throw StateError('boom');
}
