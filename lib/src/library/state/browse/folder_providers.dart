import 'dart:async';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../data/browse/folder_rows_query.dart';
import '../../data/browse/throttled_query.dart';
import '../../domain/browse/folder_tree.dart';
import '../../domain/music_folder.dart';
import '../music_folders_providers.dart';
import 'song_list_providers.dart';

/// Above this many files the tree is built on another isolate (decided on the
/// row count, no extra pass).
const folderIsolateThreshold = 5000;

/// Runs [computation] away from the UI isolate; tests replace it to see
/// whether the isolate path was taken.
typedef IsolateRunner = Future<R> Function<R>(
  FutureOr<R> Function() computation,
);

final folderIsolateThresholdProvider = Provider<int>(
  (ref) => folderIsolateThreshold,
);

final folderIsolateRunnerProvider = Provider<IsolateRunner>(
  (ref) =>
      <R>(FutureOr<R> Function() computation) => Isolate.run(computation),
);

/// [buildFolderTrees], on another isolate from [threshold] rows up.
Future<List<FolderRoot>> buildFolderTreesOffIsolate(
  List<MusicFolder> roots,
  List<FolderRow> rows, {
  required int threshold,
  required IsolateRunner run,
}) {
  if (rows.length < threshold) {
    return Future.value(buildFolderTrees(roots, rows));
  }
  return run(() => buildFolderTrees(roots, rows));
}

/// The music folders by value: a rewrite of `sources` or `source_mounts`
/// that leaves the folders as they were (a scan cursor, a timestamp) must not
/// rebuild the tree stream.
class _Roots {
  const _Roots(this.value);
  final AsyncValue<List<MusicFolder>> value;

  @override
  bool operator ==(Object other) {
    if (other is! _Roots) return false;
    final a = value, b = other.value;
    if (a.hasValue && b.hasValue) {
      return sameElements(a.requireValue, b.requireValue);
    }
    if (a.hasError && b.hasError) return identical(a.error, b.error);
    return !a.hasValue && !a.hasError && !b.hasValue && !b.hasError;
  }

  @override
  int get hashCode => value.hasValue ? value.requireValue.length : 0;
}

/// The folder tree of every music folder, live. Reloads at most once per
/// folder refresh interval while a scan writes, and only while somebody
/// watches (the provider is released with its last listener).
final folderTreesProvider = StreamProvider.autoDispose<List<FolderRoot>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final threshold = ref.watch(folderIsolateThresholdProvider);
  final run = ref.watch(folderIsolateRunnerProvider);
  final interval = ref.watch(folderRefreshIntervalProvider);
  return ref
      .watch(musicFoldersProvider.select(_Roots.new))
      .value
      .when(
        data: (roots) => throttledQuery(db, {db.tracks}, () async {
          final rows = await folderRows(db, [
            for (final r in roots) r.sourceId,
          ]);
          return buildFolderTreesOffIsolate(
            roots,
            rows,
            threshold: threshold,
            run: run,
          );
        }, interval: interval),
        loading: () => const Stream.empty(),
        error: (e, s) => Stream.error(e, s),
      );
});
