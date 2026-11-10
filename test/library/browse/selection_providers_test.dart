import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/data/browse/menu_queries.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../database/support/test_db.dart';
import 'support/wait.dart';
import 'support/library_fixture.dart';

List<TrackId> ids(Iterable<int> v) => [for (final i in v) TrackId(i)];

void main() {
  late ProviderContainer c;
  late LibrarySelection sel;

  setUp(() {
    c = ProviderContainer();
    addTearDown(c.dispose);
    sel = c.read(librarySelectionProvider.notifier);
  });

  SelectionState state() => c.read(librarySelectionProvider);
  List<int> order() => [for (final i in state().ids) i.value];

  test('toggle adds in order, removes, and sets the anchor', () {
    sel.toggle(const TrackId(3));
    sel.toggle(const TrackId(1));
    expect(order(), [3, 1]);
    expect(state().anchor, const TrackId(1));
    sel.toggle(const TrackId(3));
    expect(order(), [1]);
    expect(sel.contains(const TrackId(1)), isTrue);
    expect(sel.contains(const TrackId(3)), isFalse);
  });

  test('addRange skips what is selected', () {
    sel.toggle(const TrackId(2));
    sel.addRange(ids([1, 2, 3, 3]));
    expect(order(), [2, 1, 3]);
    expect(state().set, {const TrackId(1), const TrackId(2), const TrackId(3)});
  });

  test('range from the anchor over the order on screen, either way', () {
    final shown = ids([10, 20, 30, 40, 50]);
    sel.toggle(const TrackId(20));
    sel.selectRangeTo(shown, const TrackId(40));
    expect(order(), [20, 30, 40]);
    // The anchor moved to the clicked row: the next range grows from it.
    sel.selectRangeTo(shown, const TrackId(10));
    expect(order(), [20, 30, 40, 10]);
  });

  test('range without a usable anchor adds the clicked track only', () {
    sel.selectRangeTo(ids([1, 2, 3]), const TrackId(2));
    expect(order(), [2]);
    sel.selectRangeTo(ids([5, 6]), const TrackId(7)); // not in the order
    expect(order(), [2]);
  });

  test('selectAll replaces and deduplicates', () {
    sel.toggle(const TrackId(9));
    sel.selectAll(ids([1, 2, 2, 3]));
    expect(order(), [1, 2, 3]);
    sel.selectAll(const []);
    expect(state().isEmpty, isTrue);
  });

  test('removing the last track clears the panel state', () {
    sel.toggle(const TrackId(1));
    sel.setExpanded(true);
    expect(state().expanded, isTrue);
    sel.toggle(const TrackId(1));
    expect(state().expanded, isFalse);
    expect(state().anchor, isNull);
  });

  test('the panel only opens with something selected', () {
    sel.setExpanded(true);
    expect(state().expanded, isFalse);
    sel.toggle(const TrackId(1));
    sel.setExpanded(true);
    sel.clear();
    expect(state().isEmpty, isTrue);
    expect(state().expanded, isFalse);
  });

  test('removeAll keeps the order of the rest', () {
    sel.selectAll(ids([1, 2, 3, 4]));
    sel.removeAll(ids([2, 4, 99]));
    expect(order(), [1, 3]);
    expect(state().set, {const TrackId(1), const TrackId(3)});
  });

  test('reorder moves to the index after removal', () {
    sel.selectAll(ids([1, 2, 3, 4]));
    sel.reorder(0, 2);
    expect(order(), [2, 3, 1, 4]);
    sel.reorder(3, 0);
    expect(order(), [4, 2, 3, 1]);
    expect(() => sel.reorder(0, 4), throwsRangeError);
    expect(() => sel.reorder(-1, 0), throwsRangeError);
  });

  test('a tile rebuilds only when its own answer flips', () async {
    var rebuilds = 0;
    c.listen(isSelectedProvider(const TrackId(1)), (_, _) => rebuilds++);
    sel.toggle(const TrackId(2));
    sel.toggle(const TrackId(3));
    await pumpEventQueue();
    expect(rebuilds, 0);
    sel.toggle(const TrackId(1));
    await pumpEventQueue();
    expect(rebuilds, 1);
    expect(c.read(isSelectedProvider(const TrackId(1))), isTrue);
    expect(c.read(hasSelectionProvider), isTrue);
    sel.clear();
    await pumpEventQueue();
    expect(c.read(hasSelectionProvider), isFalse);
    expect(rebuilds, 2);
  });

  test('20k selected then one toggled: no rows are loaded', () {
    // The notifier has no database at all; this would fail to build if it
    // tried to read rows.
    final all = ids(List.generate(20000, (i) => i));
    sel.selectAll(all);
    final sw = Stopwatch()..start();
    sel.toggle(const TrackId(7));
    expect(state().ids, hasLength(19999));
    expect(state().set.contains(const TrackId(7)), isFalse);
    expect(sw.elapsedMilliseconds, lessThan(200));
  });

  test('active list: clear only drops the list that registered itself', () {
    final active = c.read(activeTrackListProvider.notifier);
    final a = ids([1]);
    final b = ids([2]);
    active.set(a);
    active.set(b);
    active.clear(a);
    expect(c.read(activeTrackListProvider), b);
    active.clear(b);
    expect(c.read(activeTrackListProvider), isNull);
  });

  group('summary', () {
    late AppDatabase db;
    late int src;
    late List<List<TrackId>> reads;

    setUp(() async {
      db = openTestDb();
      addTearDown(db.close);
      src = await addSource(db);
      reads = [];
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          selectionDurationReaderProvider.overrideWithValue((db, ids) {
            reads.add(ids);
            return selectionDuration(db, ids);
          }),
        ],
      );
      addTearDown(c.dispose);
      sel = c.read(librarySelectionProvider.notifier);
    });

    test(
      'duration of the selection; gone tracks are dropped from it',
      () async {
        final a = await addLibraryTrack(
          db,
          source: src,
          locator: 'a.flac',
          durationMs: 100,
        );
        final b = await addLibraryTrack(
          db,
          source: src,
          locator: 'b.flac',
          durationMs: 50,
        );
        sel.selectAll(ids([a, b, 9999]));
        final sub = c.listen(selectionSummaryProvider, (_, _) {});
        addTearDown(sub.close);
        // The first answer is for the old selection and ends up replaced.
        await until(
          () =>
              [for (final i in state().ids) i.value].length == 2 &&
              c.read(selectionSummaryProvider).value?.durationMs == 150,
        );
        expect([for (final i in state().ids) i.value], [a, b]);
      },
    );

    test('a burst of changes costs one read', () async {
      final tracks = [
        for (var i = 0; i < 6; i++)
          await addLibraryTrack(
            db,
            source: src,
            locator: '$i.flac',
            durationMs: 10,
          ),
      ];
      final sub = c.listen(selectionSummaryProvider, (_, _) {});
      addTearDown(sub.close);
      for (final t in tracks) {
        sel.toggle(TrackId(t));
      }
      await until(
        () => c.read(selectionSummaryProvider).value?.durationMs == 60,
      );
      // Quiet period: no late second read for the same burst.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(reads, hasLength(1));
      expect(reads.single, hasLength(6));
    });

    test('a scan re-reads the selection at most once per interval', () async {
      final tracks = [
        for (var i = 0; i < 3; i++)
          await addLibraryTrack(
            db,
            source: src,
            locator: '$i.flac',
            durationMs: 10,
          ),
      ];
      c.dispose();
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          browseRefreshIntervalProvider.overrideWithValue(
            const Duration(milliseconds: 400),
          ),
          selectionDurationReaderProvider.overrideWithValue((db, ids) {
            reads.add(ids);
            return selectionDuration(db, ids);
          }),
        ],
      );
      addTearDown(c.dispose);
      sel = c.read(librarySelectionProvider.notifier);
      sel.selectAll(ids(tracks));
      final sub = c.listen(selectionSummaryProvider, (_, _) {});
      addTearDown(sub.close);
      await until(
        () => c.read(selectionSummaryProvider).value?.durationMs == 30,
      );
      expect(reads, hasLength(1));
      // A scan writes in a stream of small transactions.
      for (var i = 0; i < 5; i++) {
        await addLibraryTrack(
          db,
          source: src,
          locator: 'x$i.flac',
          durationMs: 10,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(reads, hasLength(1), reason: 'inside the interval');
      await until(() => reads.length == 2);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(reads, hasLength(2), reason: 'the writes were one reload');
    });
  });
}
