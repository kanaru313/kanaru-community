import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_store.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';

import 'playlist_test_support.dart';

class _Store implements PlaylistStore {
  _Store(this.details);

  final Map<String, PlaylistDetail?> details;

  @override
  Stream<PlaylistDetail?> watchPlaylist(String uid) =>
      Stream.value(details[uid]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PlaylistDetail _queueDetail() => PlaylistDetail(
  summary: PlaylistSummary(
    id: 0,
    uid: 'q1',
    name: 'Queue',
    description: '',
    isFavorites: false,
    trackCount: 2,
    durationMs: 0,
    createdAt: 1,
    updatedAt: 1,
    autoCoverKeys: const [],
    savedQueue: const SavedQueueInfo(savedAt: 5),
  ),
  entries: const [],
);

void main() {
  test('a saved queue uid is "not found" on the playlist page', () async {
    final c = ProviderContainer(
      overrides: [
        playlistStoreProvider.overrideWithValue(
          _Store({
            'q1': _queueDetail(),
            'p1': detail(['a']),
          }),
        ),
      ],
    );
    addTearDown(c.dispose);
    final queue = c.listen(playlistDetailProvider('q1'), (_, _) {});
    final normal = c.listen(playlistDetailProvider('p1'), (_, _) {});
    addTearDown(queue.close);
    addTearDown(normal.close);
    await waitFor(
      () => queue.read().hasValue && normal.read().hasValue,
      what: 'details',
    );
    expect(queue.read().value, isNull);
    expect(normal.read().value, isNotNull);
  });
}
