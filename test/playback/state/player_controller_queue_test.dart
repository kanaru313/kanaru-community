import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/cleanup_kind.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/data/queue_repository.dart';

import '../support/controller_harness.dart';

void main() {
  late Harness h;
  setUp(() async => h = await Harness.create());
  tearDown(() => h.close());

  int entryAt(int i) => h.c.queueState.items[i].entryId;

  test(
    'removing the current entry while playing loads the next and keeps playing',
    () async {
      await h.play(start: 1);
      await h.settle();
      final token = await h.c.remove({entryAt(1)});
      await h.settle();
      expect(token, isNotNull);
      expect(h.c.queueState.currentItem?.trackId, h.tracks[2]);
      expect(h.c.intent, PlayIntent.playing);
      expect(h.engine.loads, hasLength(2));
      expect(h.engine.lastLoadPlay, isTrue);
    },
  );

  test('removing the current entry while paused stays paused', () async {
    await h.play(start: 1);
    await h.c.pause();
    await h.settle();
    await h.c.remove({entryAt(1)});
    await h.settle();
    expect(h.c.intent, PlayIntent.paused);
    expect(h.engine.lastLoadPlay, isFalse);
  });

  test('removing the last entry falls back to the previous one', () async {
    await h.play(start: 5);
    await h.settle();
    await h.c.remove({entryAt(5)});
    expect(h.c.queueState.currentItem?.trackId, h.tracks[4]);
  });

  test('removing the only entry empties the player', () async {
    final one = await Harness.create(tracks: 1);
    addTearDown(one.close);
    await one.play();
    await one.settle();
    await one.c.remove({one.c.queueState.items.single.entryId});
    await one.settle();
    final now = await one.c.nowPlaying.first;
    expect(now.hasTrack, isFalse);
    expect(now.length, 0);
    expect(one.c.intent, PlayIntent.stopped);
    expect(one.engine.commands.last, 'stop');
    // Undo brings it back and resumes.
  });

  test(
    'undo restores the entries, the current entry and the position',
    () async {
      await h.play(start: 2);
      await h.settle();
      await h.c.seek(const Duration(seconds: 42));
      final before = h.c.queueState;
      final token = await h.c.remove({entryAt(2)});
      await h.settle();
      expect(h.c.queueState.currentItem?.trackId, h.tracks[3]);
      await h.c.undo(token!);
      await h.settle();
      expect(h.c.queueState, before);
      expect(h.c.intent, PlayIntent.playing);
      expect(h.engine.loads.last.path, '/music/t2.mp3');
      expect(h.engine.lastStart, const Duration(seconds: 42));
      expect(
        await QueueRepository(h.db).load(shuffled: false),
        h.c.queueState.items,
      );
    },
  );

  test('undo restores the only entry and playing', () async {
    final one = await Harness.create(tracks: 1);
    addTearDown(one.close);
    await one.play();
    await one.settle();
    final token = await one.c.remove({one.c.queueState.items.single.entryId});
    await one.settle();
    await one.c.undo(token!);
    await one.settle();
    expect(one.c.intent, PlayIntent.playing);
    expect(one.c.queueState.length, 1);
    expect(one.engine.loads, hasLength(2));
  });

  test('undo after the window, or of an older removal, does nothing', () async {
    await h.play();
    await h.settle();
    final first = await h.c.remove({entryAt(3)});
    final second = await h.c.remove({entryAt(3)});
    await h.c.undo(first!);
    expect(h.c.queueState.length, 4, reason: 'replaced by the newer removal');
    h.now += 5000;
    await h.c.undo(second!);
    expect(h.c.queueState.length, 4, reason: 'window of 4 s is over');
  });

  test(
    'a play next inside the window does not break the undo (keys stay unique)',
    () async {
      await h.play();
      await h.settle();
      final token = await h.c.remove({entryAt(1)});
      await h.c.playNext([h.tracks[5]]);
      await h.c.undo(token!);
      await h.settle();
      final keys = {for (final i in h.c.queueState.items) i.sortKey};
      expect(keys, hasLength(h.c.queueState.length));
      expect(h.c.queueState.length, 7);
      expect(
        await QueueRepository(h.db).load(shuffled: false),
        h.c.queueState.items,
      );
    },
  );

  test('replacing the queue drops the undo of the old one', () async {
    await h.play();
    await h.settle();
    final token = await h.c.remove({entryAt(2)});
    await h.play(start: 1);
    await h.c.undo(token!);
    expect(h.c.queueState.length, 6, reason: 'the new queue is untouched');
    expect(
      await QueueRepository(h.db).load(shuffled: false),
      h.c.queueState.items,
    );
  });

  test('cleanup removes by kind and returns a token', () async {
    await h.c.playTracks(
      [h.tracks[0], h.tracks[1], h.tracks[0], h.tracks[2]],
      startIndex: 2,
      context: ctx,
    );
    await h.settle();
    expect(await h.c.cleanup(CleanupKind.before), isNotNull);
    expect(h.c.queueState.length, 2);
    expect(await h.c.cleanup(CleanupKind.before), isNull);
    final t = await h.c.cleanup(CleanupKind.allButCurrent);
    expect(h.c.queueState.length, 1);
    await h.c.undo(t!);
    expect(h.c.queueState.length, 2);
  });

  test('cleanup of duplicates keeps the current entry', () async {
    await h.c.playTracks(
      [h.tracks[0], h.tracks[0], h.tracks[0]],
      startIndex: 1,
      context: ctx,
    );
    await h.settle();
    final keptEntry = entryAt(1);
    await h.c.cleanup(CleanupKind.duplicates);
    expect(h.c.queueState.items.single.entryId, keptEntry);
    expect(
      h.engine.loads,
      hasLength(1),
      reason: 'the current entry did not reload',
    );
  });

  test('move changes the next entry that is handed to the engine', () async {
    await h.play();
    await h.settle();
    await h.c.move(entryAt(4), 1);
    await h.settle();
    expect(h.order().sublist(0, 3), [0, 4, 1]);
    expect(h.engine.nexts.last?.path, '/music/t4.mp3');
    expect(
      await QueueRepository(h.db).load(shuffled: false),
      h.c.queueState.items,
    );
  });

  test('playEntry jumps and plays', () async {
    await h.play();
    await h.c.pause();
    await h.settle();
    await h.c.playEntry(entryAt(3));
    await h.settle();
    expect(h.c.queueState.current, 3);
    expect(h.c.intent, PlayIntent.playing);
    expect(h.engine.loads.last.path, '/music/t3.mp3');
  });

  test('the engine events come from the controller tokens', () async {
    await h.play();
    await h.settle();
    final t = h.loadedToken;
    expect(t, isA<EngineToken>());
    expect(t.entryId, entryAt(0));
  });
}
