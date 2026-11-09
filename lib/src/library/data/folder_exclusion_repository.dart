import 'dart:async';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../database/database.dart';
import '../domain/music_folder.dart';
import '../domain/scan_status.dart';

/// Folders hidden from the library, per [MusicFolder].
abstract interface class FolderExclusions {
  /// Excludes [folderKey] of [folder] and hides its tracks now (no question
  /// asked: the UI shows a toast with undo).
  Future<void> exclude(
    MusicFolder folder,
    String folderKey, {
    required String displayPath,
  });

  /// Undo: removes the exclusion; the rows come back after the next scan
  /// (one is requested).
  Future<void> include(MusicFolder folder, String folderKey);

  Stream<List<({String folderKey, String displayPath})>> watch(
    MusicFolder folder,
  );
}

class FolderExclusionRepository implements FolderExclusions {
  FolderExclusionRepository(this._db, this._scan, {int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final LibraryScanCommands _scan;
  final int Function() _now;

  @override
  Future<void> exclude(
    MusicFolder folder,
    String folderKey, {
    required String displayPath,
  }) async {
    await applyFolderExclusion(
      _db,
      sourceId: folder.sourceId,
      folderKey: folderKey,
      displayPath: displayPath,
      now: _now(),
    );
  }

  @override
  Future<void> include(MusicFolder folder, String folderKey) async {
    await removeFolderExclusion(
      _db,
      sourceId: folder.sourceId,
      folderKey: folderKey,
      now: _now(),
    );
    // The exclusion is already undone; a scan that is slow to accept or fails
    // must not hold up or fail the undo. Scan failures show in scan status.
    unawaited(
      _scan.rescan().catchError(
        (Object e, StackTrace st) =>
            Logger('library.exclusion')
                .warning('rescan after include failed', e, st),
      ),
    );
  }

  @override
  Stream<List<({String folderKey, String displayPath})>> watch(
    MusicFolder folder,
  ) => _db
      .customSelect(
        'SELECT folder_key, display_path FROM excluded_folders '
        'WHERE source_id = ? AND deleted_at IS NULL ORDER BY folder_key',
        variables: [Variable.withInt(folder.sourceId)],
        readsFrom: {_db.excludedFolders},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            (
              folderKey: r.read<String>('folder_key'),
              displayPath: r.read<String>('display_path'),
            ),
        ],
      );
}
