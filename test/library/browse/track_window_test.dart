import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/browse/track_window.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

TrackInfo info(
  int id, [
  String? title,
  TrackAvailability status = TrackAvailability.present,
]) => TrackInfo(
  id: TrackId(id),
  title: title ?? 't$id',
  status: status,
  relPath: '$id.flac',
);

List<TrackId> idList(Iterable<int> ids) => [for (final i in ids) TrackId(i)];

/// A loader the test releases by hand.
class FakeLoader {
  final calls = <List<TrackId>>[];
  final _pending = <Completer<List<TrackInfo>>>[];
  final Set<int> missing = {};
  final Set<int> hidden = {};

  /// Titles served instead of the default.
  final Map<int, String> titles = {};
  bool autoComplete = false;

  Future<List<TrackInfo>> call(List<TrackId> ids) {
    calls.add(ids);
    if (autoComplete) return Future.value(_answer(ids));
    final c = Completer<List<TrackInfo>>();
    _pending.add(c);
    return c.future;
  }

  List<TrackInfo> _answer(List<TrackId> ids) => [
    for (final id in ids)
      if (!missing.contains(id.value))
        info(
          id.value,
          titles[id.value],
          hidden.contains(id.value)
              ? TrackAvailability.hidden
              : TrackAvailability.present,
        ),
  ];

  /// Completes the oldest unanswered call.
  void answerNext() {
    final i = calls.length - _pending.length;
    final c = _pending.removeAt(0);
    c.complete(_answer(calls[i]));
  }

  int get unanswered => _pending.length;
}

void main() {
  late FakeLoader loader;
  late int changes;
  late TrackWindow window;

  TrackWindow make({int pageSize = 10, int maxRows = 1200, int maxReads = 2}) {
    loader = FakeLoader();
    changes = 0;
    return window = TrackWindow(
      load: loader.call,
      onChanged: () => changes++,
      pageSize: pageSize,
      maxRows: maxRows,
      maxReads: maxReads,
    );
  }

  tearDown(() => window.dispose());

  test('reads the pages of the viewport and nothing else', () async {
    make();
    loader.autoComplete = true;
    window.setIds(idList(List.generate(100, (i) => i)));
    expect(window.rowAt(0), isNull);
    window.viewport(5, 14);
    await pumpEventQueue();
    expect(loader.calls.map((c) => c.first.value), [0, 10]);
    expect(window.rowAt(5)!.id, const TrackId(5));
    expect(window.rowAt(14)!.id, const TrackId(14));
    expect(window.rowAt(20), isNull);
    expect(changes, 2);
  });

  test(
    'a row inserted at the top never shows the old row at that index',
    () async {
      make();
      loader.autoComplete = true;
      window.setIds(idList(List.generate(20, (i) => i + 1)));
      window.viewport(0, 9);
      await pumpEventQueue();
      expect(window.rowAt(0)!.id, const TrackId(1));
      // id 99 arrives at the top while the others shift down by one.
      loader.autoComplete = false;
      window.setIds(idList([99, ...List.generate(20, (i) => i + 1)]));
      for (var i = 0; i < 21; i++) {
        final row = window.rowAt(i);
        expect(
          row == null || row.id == window.ids[i],
          isTrue,
          reason: 'index $i',
        );
      }
      expect(window.rowAt(0), isNull);
      expect(window.rowAt(1)!.id, const TrackId(1));
    },
  );

  test(
    'cached rows of listed ids are re-read when their page is in view',
    () async {
      make();
      loader.autoComplete = true;
      window.setIds(idList([1, 2, 3]));
      window.viewport(0, 2);
      await pumpEventQueue();
      expect(loader.calls, hasLength(1));
      window.setIds(idList([3, 2, 1]));
      await pumpEventQueue();
      expect(loader.calls, hasLength(2));
      expect(window.rowAt(0)!.id, const TrackId(3));
    },
  );

  test('an answer of an older id list only fills ids still listed', () async {
    make();
    window.setIds(idList([1, 2, 3]));
    window.viewport(0, 2);
    expect(loader.calls, hasLength(1));
    window.setIds(idList([2, 3]));
    loader.answerNext(); // answers [1, 2, 3] for the old list
    await pumpEventQueue();
    expect(window.rowAt(0)!.id, const TrackId(2));
    expect(window.rowAt(1)!.id, const TrackId(3));
    // The old read did not cover the new generation: it is read again.
    expect(loader.calls, hasLength(2));
  });

  test('least recently used rows are evicted by id', () async {
    make(pageSize: 2, maxRows: 4);
    loader.autoComplete = true;
    window.setIds(idList(List.generate(10, (i) => i)));
    window.viewport(0, 1);
    await pumpEventQueue();
    window.viewport(2, 3);
    await pumpEventQueue();
    expect(window.rowAt(0), isNotNull); // touch 0: now newest of the first page
    window.viewport(4, 5);
    await pumpEventQueue();
    expect(window.cachedRows, 4);
    expect(window.rowAt(1), isNull); // oldest untouched, evicted
    expect(window.rowAt(0), isNotNull);
    expect(window.rowAt(5), isNotNull);
  });

  test('at most maxReads in flight, nearest page first', () async {
    make(maxReads: 2);
    window.setIds(idList(List.generate(100, (i) => i)));
    window.viewport(0, 49); // pages 0..4, centre page 2
    expect(loader.calls.map((c) => c.first.value), [20, 10]);
    expect(loader.unanswered, 2);
    loader.answerNext();
    await pumpEventQueue();
    expect(loader.calls, hasLength(3));
    expect(loader.unanswered, 2);
  });

  test('pages that left the viewport are dropped without a read', () async {
    make(maxReads: 1);
    window.setIds(idList(List.generate(300, (i) => i)));
    window.viewport(0, 9); // page 0 in flight
    window.viewport(100, 109); // fling: page 10 wanted, queue is page 10 only
    window.viewport(200, 209); // page 20 wanted, page 10 dropped
    loader.answerNext();
    await pumpEventQueue();
    expect(loader.calls.map((c) => c.first.value), [0, 200]);
  });

  test('ids with no row are treated as absent and not re-read', () async {
    make();
    loader.autoComplete = true;
    loader.missing.add(2);
    window.setIds(idList([1, 2, 3]));
    window.viewport(0, 2);
    await pumpEventQueue();
    expect(window.rowAt(1), isNull);
    expect(window.rowAt(2)!.id, const TrackId(3));
    expect(loader.calls, hasLength(1));
    window.viewport(0, 2);
    await pumpEventQueue();
    expect(loader.calls, hasLength(1));
  });

  test(
    'a failed read is reported and not retried until the ids change',
    () async {
      make();
      window = TrackWindow(
        load: (ids) async {
          loader.calls.add(ids);
          throw StateError('db closed');
        },
        onChanged: () => changes++,
        pageSize: 10,
      );
      window.setIds(idList([1, 2]));
      window.viewport(0, 1);
      await pumpEventQueue();
      window.viewport(0, 1);
      await pumpEventQueue();
      expect(loader.calls, hasLength(1));
      expect(window.error, isA<StateError>());
      window.setIds(idList([1, 2]));
      window.viewport(0, 1);
      await pumpEventQueue();
      expect(loader.calls, hasLength(2));
    },
  );

  test('invalidate re-reads rows whose data changed, ids unchanged', () async {
    make();
    loader.autoComplete = true;
    window.setIds(idList([1, 2, 3]));
    window.viewport(0, 2);
    await pumpEventQueue();
    expect(window.rowAt(1)!.title, 't2');
    loader.titles[2] = 'renamed';
    window.invalidate();
    await pumpEventQueue();
    expect(loader.calls, hasLength(2));
    // The old row stays on screen until the new one arrives, then swaps.
    expect(window.rowAt(1)!.title, 'renamed');
    expect(window.rowAt(0)!.id, const TrackId(1));
  });

  test('a read in flight during invalidate is read again', () async {
    make();
    window.setIds(idList([1, 2]));
    window.viewport(0, 1);
    window.invalidate();
    loader.answerNext(); // the answer predates the change
    await pumpEventQueue();
    expect(loader.calls, hasLength(2));
  });

  test('hidden rows are treated as absent', () async {
    make();
    loader.autoComplete = true;
    loader.hidden.add(2);
    window.setIds(idList([1, 2, 3]));
    window.viewport(0, 2);
    await pumpEventQueue();
    expect(window.rowAt(1), isNull);
    expect(window.rowAt(0)!.id, const TrackId(1));
    expect(loader.calls, hasLength(1));
    window.viewport(0, 2);
    await pumpEventQueue();
    expect(loader.calls, hasLength(1));
  });

  test('a cached row that turns hidden is dropped on the next read', () async {
    make();
    loader.autoComplete = true;
    window.setIds(idList([1, 2, 3]));
    window.viewport(0, 2);
    await pumpEventQueue();
    expect(window.rowAt(1)!.id, const TrackId(2));
    loader.hidden.add(2);
    window.invalidate();
    await pumpEventQueue();
    expect(window.rowAt(1), isNull);
    expect(window.rowAt(0)!.id, const TrackId(1));
    expect(window.cachedRows, 2);
  });

  test('out of range indexes and dispose', () async {
    make();
    loader.autoComplete = true;
    window.setIds(idList([1]));
    expect(window.rowAt(-1), isNull);
    expect(window.rowAt(5), isNull);
    window.viewport(0, 0);
    window.dispose();
    await pumpEventQueue();
    expect(changes, 0);
    window.viewport(0, 0);
    expect(loader.calls, hasLength(1));
  });
}
