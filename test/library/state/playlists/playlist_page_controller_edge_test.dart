import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/playlists/playlist_page_controller.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';

import 'playlist_test_support.dart';

void main() {
  late FakeStore store;
  late ProviderContainer c;
  late ProviderSubscription<PlaylistPageState> sub;

  Future<void> open(PlaylistDetail d) async {
    store = FakeStore(d)..loadResult = d;
    c = ProviderContainer(
      overrides: [playlistStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    sub = c.listen(playlistPageProvider('p'), (_, _) {});
    addTearDown(sub.close);
    await waitFor(() => sub.read().detail.hasValue, what: 'first detail');
  }

  PlaylistPageController ctl() => c.read(playlistPageProvider('p').notifier);
  List<String> shown() => uidsOf(sub.read().detail.value);

  /// Completes with the error of [f] (null when it succeeds).
  Future<Object?> errorOf(Future<Object?> f) async {
    try {
      await f;
      return null;
    } on Object catch (e) {
      return e;
    }
  }

  group('after the page is disposed', () {
    test('a kept notifier still runs undo, in order, and completes', () async {
      await open(detail(['a', 'b', 'c']));
      final n = ctl();
      final removed = n.remove(['a']);
      sub.close();
      c.dispose();
      store.removals[0].result.complete(removal(['a']));
      final r = (await removed)!;

      final undo = n.undo(r);
      await waitFor(() => store.undos.length == 1, what: 'undo reached store');
      store.undos[0].result.complete(1);
      expect(await undo, 1);

      // The gate is idle again: a second one is not stuck behind the first.
      final again = n.undo(removal(['b']));
      await waitFor(() => store.undos.length == 2, what: 'second undo');
      store.undos[1].result.complete(1);
      expect(await again, 1);
    });

    test('a failure cancels the queued writes and touches no state', () async {
      await open(detail(['a', 'b', 'c']));
      final f1 = errorOf(ctl().move('a', afterEntryUid: 'c'));
      final f2 = errorOf(ctl().move('b', afterEntryUid: 'a'));
      sub.close();
      c.dispose();
      store.moves[0].result.completeError(StateError('x'));
      final e1 = await f1;
      final e2 = await f2;
      expect((e1! as PlaylistWriteFailure).cancelled, isFalse);
      expect((e2! as PlaylistWriteFailure).cancelled, isTrue);
      expect(store.loads, 0);
      expect(store.moves, hasLength(1));
    });
  });

  test('invalidating the page keeps the queue and one writer', () async {
    await open(detail(['a', 'b', 'c']));
    final f1 = ctl().move('a', afterEntryUid: 'c');
    final f2 = ctl().move('b', afterEntryUid: 'a');
    var released = false;
    unawaited(ctl().afterWrites().then((_) => released = true));
    c.invalidate(playlistPageProvider('p'));
    sub.read();
    expect(sub.read().busy, isTrue);
    final f3 = ctl().move('c', afterEntryUid: null);
    expect(store.moves, hasLength(1), reason: 'one write in flight');

    store.moves[0].result.complete(PlaylistMove.moved);
    await f1;
    await waitFor(() => store.moves.length == 2, what: 'second write');
    expect(store.moves, hasLength(2));
    store.moves[1].result.complete(PlaylistMove.moved);
    await f2;
    await waitFor(() => store.moves.length == 3, what: 'third write');
    expect(released, isFalse);
    store.loadResult = detail(['c', 'b', 'a'], updatedAt: 3);
    store.moves[2].result.complete(PlaylistMove.moved);
    await f3;
    await ctl().afterWrites();
    expect(released, isTrue);
    expect(sub.read().busy, isFalse);
  });

  test('a held value from before the last write does not win a tie', () async {
    await open(detail(['a', 'b', 'c'], updatedAt: 1));
    final f1 = ctl().move('a', afterEntryUid: 'c'); // b c a
    final f2 = ctl().move('b', afterEntryUid: 'a'); // c a b
    store.moves[0].result.complete(PlaylistMove.moved);
    await f1;
    // Read between the two writes, stamped with the same millisecond.
    store.stream.add(detail(['b', 'c', 'a'], updatedAt: 7));
    await waitFor(() => store.moves.length == 2, what: 'second write');
    store.loadResult = detail(['c', 'a', 'b'], updatedAt: 7);
    store.moves[1].result.complete(PlaylistMove.moved);
    await f2;
    await ctl().afterWrites();
    expect(shown(), ['c', 'a', 'b']);
  });

  test('a held value strictly newer than the settled read is taken', () async {
    await open(detail(['a', 'b', 'c'], updatedAt: 1));
    final f = ctl().move('a', afterEntryUid: 'c');
    store.stream.add(detail(['c', 'b', 'a', 'z'], updatedAt: 9));
    await Future<void>.delayed(Duration.zero);
    store.loadResult = detail(['b', 'c', 'a'], updatedAt: 5);
    store.moves[0].result.complete(PlaylistMove.moved);
    await f;
    await ctl().afterWrites();
    expect(shown(), ['c', 'b', 'a', 'z']);
  });

  test(
    'a failed settle read after a good write keeps the written order',
    () async {
      await open(detail(['a', 'b', 'c']));
      store.loadError = StateError('read');
      final f = ctl().move('a', afterEntryUid: 'c');
      store.moves[0].result.complete(PlaylistMove.moved);
      await f;
      await ctl().afterWrites();
      expect(shown(), ['b', 'c', 'a']);
      store.stream.add(detail(['b', 'c', 'a', 'n'], updatedAt: 2));
      await waitFor(() => shown().length == 4, what: 'stream after the burst');
    },
  );

  test(
    'a write queued during the settle read is applied over the result',
    () async {
      await open(detail(['a', 'b', 'c']));
      final gate = store.loadGate = Completer<void>();
      final f1 = ctl().move('a', afterEntryUid: 'c');
      store.moves[0].result.complete(PlaylistMove.moved);
      await f1;
      await waitFor(() => store.loads == 1, what: 'settle read started');
      final f2 = ctl().move('b', afterEntryUid: 'a');
      expect(shown(), ['c', 'a', 'b']);
      store.loadResult = detail(['b', 'c', 'a'], updatedAt: 2);
      store.loadGate = null;
      gate.complete();
      await waitFor(() => store.moves.length == 2, what: 'queued write ran');
      expect(shown(), ['c', 'a', 'b']);
      store.loadResult = detail(['c', 'a', 'b'], updatedAt: 3);
      store.moves[1].result.complete(PlaylistMove.moved);
      await f2;
      await ctl().afterWrites();
      expect(shown(), ['c', 'a', 'b']);
      expect(store.loads, 2);
    },
  );

  group('stored stream errors', () {
    test('idle: the error is shown, later data recovers', () async {
      await open(detail(['a', 'b']));
      store.stream.addError(StateError('db'));
      await waitFor(() => sub.read().detail.hasError, what: 'error shown');
      store.stream.add(detail(['b', 'a'], updatedAt: 2));
      await waitFor(
        () => !sub.read().detail.hasError && shown().first == 'b',
        what: 'recovered',
      );
    });

    test('busy: the error is ignored', () async {
      await open(detail(['a', 'b']));
      final f = ctl().undo(removal(['x']));
      store.stream.addError(StateError('db'));
      await Future<void>.delayed(Duration.zero);
      expect(sub.read().detail.hasError, isFalse);
      store.undos[0].result.complete(1);
      await f;
      await ctl().afterWrites();
      expect(sub.read().detail.hasError, isFalse);
      expect(shown(), ['a', 'b']);
    });
  });

  test('undo of another playlist is an ArgumentError', () async {
    await open(detail(['a']));
    await expectLater(
      ctl().undo(
        PlaylistRemoval(playlistUid: 'other', entryUids: ['x'], removedAt: 1),
      ),
      throwsArgumentError,
    );
    expect(store.undos, isEmpty);
    expect(sub.read().busy, isFalse);
  });

  settleEdgeTests();
}

void settleEdgeTests() {
  late FakeStore store;
  late ProviderContainer c;
  late ProviderSubscription<PlaylistPageState> sub;

  Future<void> open(PlaylistDetail d) async {
    store = FakeStore(d)..loadResult = d;
    c = ProviderContainer(
      overrides: [playlistStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    sub = c.listen(playlistPageProvider('p'), (_, _) {});
    addTearDown(sub.close);
    await waitFor(() => sub.read().detail.hasValue, what: 'first detail');
  }

  test(
    'a page disposed during the settle read still drains its queue',
    () async {
      await open(detail(['a', 'b', 'c']));
      final n = c.read(playlistPageProvider('p').notifier);
      final gate = store.loadGate = Completer<void>();
      final f = n.move('a', afterEntryUid: 'c');
      store.moves[0].result.complete(PlaylistMove.moved);
      await f;
      await waitFor(() => store.loads == 1, what: 'settle read started');
      final u1 = n.undo(removal(['x']));
      sub.close();
      c.dispose();
      store.loadGate = null;
      gate.complete();
      await waitFor(() => store.undos.length == 1, what: 'queued undo ran');
      store.undos[0].result.complete(1);
      expect(await u1, 1);

      final u2 = n.undo(removal(['y']));
      await waitFor(() => store.undos.length == 2, what: 'next undo ran');
      store.undos[1].result.complete(1);
      expect(await u2, 1);
    },
  );

  test(
    'a failed settle read does not keep edits of writes still queued',
    () async {
      await open(detail(['a', 'b', 'c']));
      final n = c.read(playlistPageProvider('p').notifier);
      store.loadError = StateError('read');
      final gate = store.loadGate = Completer<void>();
      final f1 = n.move('a', afterEntryUid: 'c'); // b c a
      store.moves[0].result.complete(PlaylistMove.moved);
      await f1;
      await waitFor(() => store.loads == 1, what: 'settle read started');
      final f2 = n.move('b', afterEntryUid: 'a'); // c a b, never written
      store.loadGate = null;
      gate.complete();
      await waitFor(() => store.moves.length == 2, what: 'second write');
      store.moves[1].result.completeError(StateError('disk'));
      await expectLater(f2, throwsA(isA<PlaylistWriteFailure>()));
      await n.afterWrites();
      expect(uidsOf(sub.read().detail.value), ['b', 'c', 'a']);
    },
  );
}
