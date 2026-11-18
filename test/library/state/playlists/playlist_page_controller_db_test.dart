import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_store.dart';
import 'package:kanaru/src/library/state/playlists/playlist_page_controller.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';

import '../../playlists/support/playlist_fixtures.dart';
import 'playlist_test_support.dart';

/// The real repository, but its stored stream can be held back: a snapshot
/// read before a write reaches the controller after that write settled.
class _SlowStreamStore implements PlaylistStore {
  _SlowStreamStore(this._inner);

  final PlaylistStore _inner;
  Completer<void>? _gate;
  bool waiting = false;
  int delivered = 0;

  void hold() => _gate = Completer<void>();

  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Stream<PlaylistDetail?> watchPlaylist(String uid) =>
      _inner.watchPlaylist(uid).asyncMap((d) async {
        final gate = _gate;
        if (gate != null) {
          waiting = true;
          await gate.future;
        }
        delivered++;
        return d;
      });

  @override
  Future<PlaylistDetail?> loadPlaylist(String uid) => _inner.loadPlaylist(uid);

  @override
  Future<PlaylistMove> moveEntry(
    String playlistUid,
    String entryUid, {
    required String? afterEntryUid,
  }) => _inner.moveEntry(playlistUid, entryUid, afterEntryUid: afterEntryUid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'a snapshot read before a move never brings the old order back',
    () async {
      final f = await PlaylistFixture.open();
      final tracks = await f.tracks(4);
      final p = await f.repo.createPlaylist(name: 'P', tracks: tracks);
      final e = [for (final x in await f.live(p)) x.uid];
      final store = _SlowStreamStore(f.repo);
      final c = ProviderContainer(
        overrides: [playlistStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);

      final seen = <List<String>>[];
      final sub = c.listen(playlistPageProvider(p), (_, next) {
        seen.add(uidsOf(next.detail.value));
      });
      addTearDown(sub.close);
      await waitFor(() => sub.read().detail.hasValue, what: 'first detail');
      expect(uidsOf(sub.read().detail.value), e);

      // A write the stream reads, then held before the controller sees it.
      store.hold();
      f.clock = 20000;
      await f.repo.updatePlaylist(p, name: 'Renamed');
      await waitFor(() => store.waiting, what: 'held stream snapshot');

      f.clock = 30000;
      final controller = c.read(playlistPageProvider(p).notifier);
      await controller.move(e[3], afterEntryUid: null);
      await controller.afterWrites();
      final moved = [e[3], e[0], e[1], e[2]];
      expect(uidsOf(sub.read().detail.value), moved);
      expect(sub.read().detail.value!.summary.updatedAt, 30000);

      // Now the old snapshot, then the one the move produced, arrive.
      final before = store.delivered;
      seen.clear();
      store.release();
      await waitFor(
        () => store.delivered >= before + 2,
        what: 'both snapshots',
      );
      await waitFor(
        () => sub.read().detail.value!.summary.name == 'Renamed',
        what: 'newer snapshot taken',
      );
      expect(seen.every((order) => order.join() == moved.join()), isTrue);
      expect(sub.read().busy, isFalse);
    },
  );

  test('moves and removals go through the real store in order', () async {
    final f = await PlaylistFixture.open();
    final tracks = await f.tracks(4);
    final p = await f.repo.createPlaylist(name: 'P', tracks: tracks);
    final e = [for (final x in await f.live(p)) x.uid];
    final c = ProviderContainer(
      overrides: [playlistStoreProvider.overrideWithValue(f.repo)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(playlistPageProvider(p), (_, _) {});
    addTearDown(sub.close);
    await waitFor(() => sub.read().detail.hasValue, what: 'first detail');
    final controller = c.read(playlistPageProvider(p).notifier);

    f.clock = 20000;
    final m1 = controller.move(e[0], afterEntryUid: e[3]);
    final m2 = controller.move(e[1], afterEntryUid: e[3]);
    final removed = controller.remove([e[2]]);
    await Future.wait([m1, m2]);
    expect((await removed)!.entryUids, [e[2]]);
    await controller.afterWrites();

    final expected = [e[3], e[1], e[0]];
    expect(uidsOf(sub.read().detail.value), expected);
    expect([for (final x in await f.live(p)) x.uid], expected);
  });
}
