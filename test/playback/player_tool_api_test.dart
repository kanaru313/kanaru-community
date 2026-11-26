import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/playback/domain/removed_queue_entry.dart';

import 'support/controller_harness.dart';

void main() {
  late Harness h;

  setUp(() async {
    h = await Harness.create();
    await h.play();
    await h.settle();
  });
  tearDown(() => h.close());

  List<int> entryIds() => [for (final i in h.c.queueState.items) i.entryId];

  test('removeEntriesForTool returns only removed entries', () async {
    final items = h.c.queueState.items;
    final removed = await h.c.removeEntriesForTool({
      items[1].entryId,
      items[3].entryId,
      999999,
    });
    await h.settle();
    expect(removed, [
      RemovedQueueEntry(entryId: items[1].entryId, trackId: items[1].trackId),
      RemovedQueueEntry(entryId: items[3].entryId, trackId: items[3].trackId),
    ]);
    expect(h.c.queueState.items, hasLength(4));
    expect(await h.c.removeEntriesForTool({999999}), isEmpty);
    expect(await h.c.removeEntriesForTool(const {}), isEmpty);
    expect(h.c.queueState.items, hasLength(4));
  });

  test("removeEntriesForTool keeps the user's undo token", () async {
    final ids = entryIds();
    final token = await h.c.remove({ids[5]});
    expect(token, isNotNull);
    final removed = await h.c.removeEntriesForTool({ids[2]});
    expect(removed, hasLength(1));
    await h.c.undo(token!);
    await h.settle();
    expect(entryIds(), contains(ids[5]));
    expect(entryIds(), isNot(contains(ids[2])));
  });

  test('removeEntriesForTool of the current entry moves on', () async {
    final cur = h.c.queueState.currentItem!.entryId;
    final removed = await h.c.removeEntriesForTool({cur});
    await h.settle();
    expect(removed.single.entryId, cur);
    expect(h.c.queueState.items.map((i) => i.entryId), isNot(contains(cur)));
  });

  test('playTracksForTool returns the replaced queue and index', () async {
    await h.c.playEntry(h.c.queueState.items[2].entryId);
    await h.settle();
    final next = h.tracks.sublist(1, 4);
    final r = await h.c.playTracksForTool(
      next,
      contextLabel: 'Trợ lý AI',
      startIndex: 1,
    );
    await h.settle();
    expect(r.previous!.tracks, h.tracks);
    expect(r.previous!.next, next);
    expect(r.shuffled, isFalse);
    expect(r.previousIndex, 2);
    expect(h.c.queueState.items.map((i) => i.trackId), next);
    expect(h.c.queueState.currentItem!.trackId, next[1]);
  });

  test(
    'playTracksForTool on an empty queue returns no previous and no index',
    () async {
      await h.c.clearQueue();
      await h.settle();
      final r = await h.c.playTracksForTool(
        h.tracks.sublist(0, 2),
        contextLabel: 'Trợ lý AI',
      );
      expect(r.previous, isNull);
      expect(r.previousIndex, isNull);
      expect(h.c.queueState.items, hasLength(2));
    },
  );

  test('playTracksForTool uses the AI play context', () async {
    await h.c.playTracksForTool(
      h.tracks.sublist(0, 2),
      contextLabel: 'Trợ lý AI',
    );
    await h.settle();
    expect(
      h.c.context,
      const PlayContext(PlayContextKind.selection, label: 'Trợ lý AI'),
    );
  });

  test("playTracksForTool drops the user's pending undo", () async {
    final token = await h.c.remove({entryIds()[5]});
    await h.c.playTracksForTool(
      h.tracks.sublist(0, 2),
      contextLabel: 'Trợ lý AI',
    );
    await h.settle();
    final before = h.c.queueState.items.length;
    await h.c.undo(token!);
    await h.settle();
    expect(h.c.queueState.items, hasLength(before));
  });

  test('playTracksForTool rejects an empty list and a bad start', () async {
    await expectLater(
      h.c.playTracksForTool(const [], contextLabel: 'x'),
      throwsArgumentError,
    );
    await expectLater(
      h.c.playTracksForTool(
        h.tracks.sublist(0, 2),
        contextLabel: 'x',
        startIndex: 2,
      ),
      throwsRangeError,
    );
    await expectLater(
      h.c.playTracksForTool(
        h.tracks.sublist(0, 2),
        contextLabel: 'x',
        startIndex: -1,
      ),
      throwsRangeError,
    );
    expect(h.c.queueState.items, hasLength(6));
  });

  test('runs in command order with a concurrent user edit', () async {
    final ids = entryIds();
    final a = h.c.remove({ids[0]});
    final b = h.c.removeEntriesForTool({ids[0], ids[1]});
    final c = h.c.playTracksForTool(
      h.tracks.sublist(0, 2),
      contextLabel: 'Trợ lý AI',
    );
    final first = await a;
    final removed = await b;
    final play = await c;
    await h.settle();
    expect(first, isNotNull);
    // The user's removal ran first, so the tool saw only the second entry.
    expect(removed.map((e) => e.entryId), [ids[1]]);
    expect(play.previous!.tracks, hasLength(4));
    expect(h.c.queueState.items, hasLength(2));
  });

  test('playTracksForTool reports shuffle was on', () async {
    await h.c.setShuffle(true);
    await h.settle();
    final r = await h.c.playTracksForTool(
      h.tracks.sublist(0, 2),
      contextLabel: 'Trợ lý AI',
    );
    expect(r.shuffled, isTrue);
    expect(r.previous!.tracks, hasLength(6));
  });

  test('tool variants after dispose fail with StateError', () async {
    await h.c.dispose();
    await expectLater(
      h.c.removeEntriesForTool({entryIds().first}),
      throwsStateError,
    );
    await expectLater(
      h.c.playTracksForTool(h.tracks.sublist(0, 2), contextLabel: 'x'),
      throwsStateError,
    );
  });
}
