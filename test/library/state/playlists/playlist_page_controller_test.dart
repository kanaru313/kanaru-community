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
  bool failedWith(Object? e, {required bool cancelled}) =>
      e is PlaylistWriteFailure && e.cancelled == cancelled;

  test(
    'move shows the new order before the call returns, one write at once',
    () async {
      await open(detail(['a', 'b', 'c']));
      final f = ctl().move('a', afterEntryUid: 'c');
      // No pump between the call and the check.
      expect(shown(), ['b', 'c', 'a']);
      expect(sub.read().busy, isTrue);
      store.loadResult = detail(['b', 'c', 'a'], updatedAt: 2);
      store.moves.single.result.complete(PlaylistMove.moved);
      await f;
      await ctl().afterWrites();
      expect(sub.read().busy, isFalse);
      expect(shown(), ['b', 'c', 'a']);
      expect(store.loads, 1);
    },
  );

  test('afterWrites is immediate when idle and waits for the settle', () async {
    await open(detail(['a', 'b']));
    await ctl().afterWrites();
    final gate = store.loadGate = Completer<void>();
    final f = ctl().move('a', afterEntryUid: 'b');
    var released = false;
    final waiter = ctl().afterWrites().then((_) => released = true);
    store.moves.single.result.complete(PlaylistMove.moved);
    await f;
    await waitFor(() => store.loads == 1, what: 'settle read started');
    expect(released, isFalse);
    expect(sub.read().busy, isTrue);
    gate.complete();
    await waiter;
    expect(sub.read().busy, isFalse);
  });

  test('queued moves reach the store in call order', () async {
    await open(detail(['a', 'b', 'c']));
    final f1 = ctl().move('a', afterEntryUid: 'b');
    final f2 = ctl().move('c', afterEntryUid: null);
    expect(shown(), ['c', 'b', 'a']);
    expect(store.moves, hasLength(1));
    store.moves[0].result.complete(PlaylistMove.moved);
    await f1;
    await waitFor(() => store.moves.length == 2, what: 'second write');
    expect(store.moves[1].args, ['c', null]);
    store.loadResult = detail(['c', 'b', 'a'], updatedAt: 2);
    store.moves[1].result.complete(PlaylistMove.moved);
    await f2;
    await ctl().afterWrites();
    expect(shown(), ['c', 'b', 'a']);
    expect(store.loads, 1);
  });

  test('a failed write cancels the queued ones and reloads once', () async {
    await open(detail(['a', 'b', 'c']));
    final f1 = ctl().move('a', afterEntryUid: 'c');
    final f2 = ctl().move('b', afterEntryUid: 'c');
    final f3 = ctl().remove(['c']);
    final errors = <Object?>[];
    Future<void> collect(Future<Object?> f) async {
      try {
        await f;
      } on Object catch (e) {
        errors.add(e);
      }
    }

    final all = Future.wait([collect(f1), collect(f2), collect(f3)]);
    store.loadResult = detail(['a', 'b', 'c'], updatedAt: 1);
    store.moves[0].result.completeError(StateError('disk'));
    await all;
    await ctl().afterWrites();
    expect(errors, hasLength(3));
    expect(failedWith(errors[0], cancelled: false), isTrue);
    expect(errors.skip(1).every((e) => failedWith(e, cancelled: true)), isTrue);
    expect(((errors[1]) as PlaylistWriteFailure).cause, isA<StateError>());
    expect(store.moves, hasLength(1));
    expect(store.removals, isEmpty);
    expect(store.loads, 1);
    expect(shown(), ['a', 'b', 'c']);
    expect(sub.read().busy, isFalse);
  });

  test('a failed settle read keeps the last saved detail', () async {
    await open(detail(['a', 'b']));
    store.loadError = StateError('read');
    final f = ctl().move('a', afterEntryUid: 'b');
    store.moves[0].result.complete(PlaylistMove.gone);
    await expectLater(f, throwsA(isA<PlaylistWriteFailure>()));
    await ctl().afterWrites();
    expect(shown(), ['a', 'b']);
    expect(store.loads, 1);
  });

  test('unchanged is success, gone is a failure', () async {
    await open(detail(['a', 'b']));
    final ok = ctl().move('a', afterEntryUid: null);
    store.moves[0].result.complete(PlaylistMove.unchanged);
    await ok;
    await ctl().afterWrites();
    final gone = ctl().move('a', afterEntryUid: 'b');
    final check = expectLater(
      gone,
      throwsA(
        isA<PlaylistWriteFailure>().having(
          (e) => e.cancelled,
          'cancelled',
          false,
        ),
      ),
    );
    await waitFor(() => store.moves.length == 2, what: 'second move');
    store.moves[1].result.complete(PlaylistMove.gone);
    await check;
  });

  test('remove returns the removal; a null removal is a failure', () async {
    await open(detail(['a', 'b', 'c']));
    final r = removal(['b']);
    final f = ctl().remove(['b', 'zzz']);
    expect(shown(), ['a', 'c']);
    expect(store.removals.single.args.single, ['b']);
    store.loadResult = detail(['a', 'c'], updatedAt: 2);
    store.removals[0].result.complete(r);
    expect(await f, r);
    await ctl().afterWrites();

    final g = ctl().remove(['a']);
    final check = expectLater(g, throwsA(isA<PlaylistWriteFailure>()));
    store.removals[1].result.complete(null);
    await check;
    await ctl().afterWrites();
  });

  test('removing nothing shown does not write', () async {
    await open(detail(['a', 'b']));
    expect(await ctl().remove(['zzz']), isNull);
    expect(await ctl().removeDuplicates(), isNull);
    expect(await ctl().removeUnavailable(), isNull);
    expect(store.removals, isEmpty);
    expect(sub.read().busy, isFalse);
  });

  test('removeDuplicates keeps the first of each track', () async {
    await open(detail(['a', 'b', 'c'], trackOf: {'a': 1, 'b': 2, 'c': 1}));
    final f = ctl().removeDuplicates();
    expect(shown(), ['a', 'b']);
    store.loadResult = detail(['a', 'b'], updatedAt: 2);
    store.removals[0].result.complete(removal(['c']));
    await f;
    await ctl().afterWrites();
  });

  test('removeUnavailable uses the entries shown at call time', () async {
    await open(detail(['a', 'b', 'c'], unavailable: {'b', 'c'}));
    final f1 = ctl().remove(['b']);
    expect(shown(), ['a', 'c']);
    final f2 = ctl().removeUnavailable();
    store.removals[0].result.complete(removal(['b']));
    await f1;
    await waitFor(() => store.removals.length == 2, what: 'second removal');
    expect(store.removals[1].args.single, ['c']);
    store.loadResult = detail(['a'], updatedAt: 2);
    store.removals[1].result.complete(removal(['c']));
    await f2;
    await ctl().afterWrites();
    expect(shown(), ['a']);
  });

  test('undo waits for the writes queued before it', () async {
    await open(detail(['a', 'b']));
    final f1 = ctl().move('a', afterEntryUid: 'b');
    final f2 = ctl().undo(removal(['x']));
    expect(store.undos, isEmpty);
    store.moves[0].result.complete(PlaylistMove.moved);
    await f1;
    await waitFor(() => store.undos.length == 1, what: 'undo call');
    store.loadResult = detail(['b', 'a', 'x'], updatedAt: 3);
    store.undos[0].result.complete(1);
    expect(await f2, 1);
    await ctl().afterWrites();
    expect(shown(), ['b', 'a', 'x']);
  });

  test('a failed undo after a failed move is cancelled', () async {
    await open(detail(['a', 'b']));
    final f1 = ctl().move('a', afterEntryUid: 'b');
    final f2 = ctl().undo(removal(['x']));
    final c1 = expectLater(f1, throwsA(isA<PlaylistWriteFailure>()));
    final c2 = expectLater(
      f2,
      throwsA(
        isA<PlaylistWriteFailure>().having(
          (e) => e.cancelled,
          'cancelled',
          true,
        ),
      ),
    );
    store.moves[0].result.completeError(StateError('x'));
    await Future.wait([c1, c2]);
    expect(store.undos, isEmpty);
  });

  test('disposing the page releases afterWrites waiters', () async {
    await open(detail(['a', 'b']));
    unawaited(
      ctl().move('a', afterEntryUid: 'b').then<void>((_) {}, onError: (_) {}),
    );
    var released = false;
    final waiter = ctl().afterWrites().then((_) => released = true);
    expect(released, isFalse);
    sub.close();
    c.dispose();
    await waiter;
    expect(released, isTrue);
  });

  group('stored emissions', () {
    test(
      'a value that arrives while busy is held, older ones never win',
      () async {
        await open(detail(['a', 'b', 'c'], updatedAt: 1));
        // An undo has no optimistic edit, so a value taken now would show.
        final f = ctl().undo(removal(['x']));
        store.stream.add(detail(['c', 'b', 'a'], updatedAt: 1));
        await Future<void>.delayed(Duration.zero);
        expect(shown(), ['a', 'b', 'c']);
        store.loadResult = detail(['a', 'b', 'c', 'x'], updatedAt: 5);
        store.undos[0].result.complete(1);
        await f;
        await ctl().afterWrites();
        expect(shown(), ['a', 'b', 'c', 'x']);

        store.stream.add(detail(['a', 'b', 'c'], updatedAt: 1));
        await Future<void>.delayed(Duration.zero);
        expect(shown(), ['a', 'b', 'c', 'x']);
      },
    );

    test('a newer or equal value is taken when idle', () async {
      await open(detail(['a', 'b'], updatedAt: 3));
      store.stream.add(detail(['b', 'a'], updatedAt: 3));
      await waitFor(() => shown().first == 'b', what: 'equal updatedAt');
      store.stream.add(detail(['a'], updatedAt: 4));
      await waitFor(() => shown().length == 1, what: 'newer updatedAt');
      store.stream.add(null);
      await waitFor(() => sub.read().detail.value == null, what: 'deleted');
    });
  });
}
