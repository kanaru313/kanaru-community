import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../../database/database.dart';
import '../../../foundation/result.dart';
import '../../../media/domain/track_id.dart';
import '../../../platform/domain/document_picker.dart';
import '../../../storage/domain/m3u/m3u_relative_path.dart';
import '../../../storage/domain/m3u/m3u_write.dart';
import 'm3u_export_entries.dart';
import 'm3u_results.dart';

final _log = Logger('library.m3u');

/// Writes a playlist to [target] as an extended M3U file.
class M3uExportService {
  M3uExportService(this._db, this._picker, this._canonicalize);

  final AppDatabase _db;
  final DocumentPicker _picker;
  final Future<String> Function(String) _canonicalize;

  /// [relative] writes paths relative to the target's folder (needs
  /// `target.localPath`). Rows with no file of their own (remote, CUE) and
  /// lines the writer cannot express are counted in `skipped`. On any failure, typed or thrown,
  /// the created [target] is given up.
  Future<Result<M3uExportResult, M3uExportError>> exportPlaylist(
    String playlistUid,
    SaveTarget target, {
    required bool relative,
  }) =>
      _guarded(target, () => loadM3uExportEntries(_db, playlistUid), relative);

  /// Writes the songs [trackIds], in that order, to [target]: the same file
  /// as a playlist's, for a list that is not one (Most played, History).
  /// Rows with no file of their own are counted in `skipped` as in
  /// [exportPlaylist].
  Future<Result<M3uExportResult, M3uExportError>> exportTracks(
    List<TrackId> trackIds,
    SaveTarget target, {
    required bool relative,
  }) => _guarded(
    target,
    () =>
        loadM3uExportEntriesByTracks(_db, [for (final t in trackIds) t.value]),
    relative,
  );

  Future<Result<M3uExportResult, M3uExportError>> _guarded(
    SaveTarget target,
    Future<List<M3uExportEntry>?> Function() load,
    bool relative,
  ) async {
    try {
      return await _export(load, target, relative);
    } on Object {
      // Unexpected failure: give the created target up, then let it surface.
      await _discardQuietly(target);
      rethrow;
    }
  }

  Future<Result<M3uExportResult, M3uExportError>> _export(
    Future<List<M3uExportEntry>?> Function() load,
    SaveTarget target,
    bool relative,
  ) async {
    final entries = await load();
    if (entries == null) return _fail(target, M3uExportError.playlistGone);
    String? dir;
    if (relative) {
      final local = target.localPath;
      if (local == null) return _fail(target, M3uExportError.folderUnknown);
      dir = await _canonicalize(p.posix.dirname(local));
    }
    final items = <M3uWriteItem>[];
    final noFile = <int>{}, writtenIds = <int>{}, badIds = <int>{};
    for (final e in entries) {
      final path = e.absolutePath;
      if (path == null) {
        noFile.add(e.trackId);
        continue;
      }
      final item = M3uWriteItem(
        path: dir == null ? path : relativeM3uPath(dir, path),
        title: e.title,
        artist: e.artist,
        durationMs: e.durationMs,
      );
      items.add(item);
      // The writer's verdict depends on the item alone, so test it per song.
      if (writtenIds.contains(e.trackId) || badIds.contains(e.trackId)) {
        continue;
      }
      (writeM3u([item]).skipped == 0 ? writtenIds : badIds).add(e.trackId);
    }
    final written = writeM3u(items);
    final wrote = await _picker.write(
      target,
      Uint8List.fromList(utf8.encode(written.text)),
    );
    if (wrote is Err) return _fail(target, M3uExportError.writeFailed);
    return Ok(
      M3uExportResult(
        written: writtenIds.length,
        skipped: noFile.length + badIds.length,
      ),
    );
  }

  Future<Result<M3uExportResult, M3uExportError>> _fail(
    SaveTarget target,
    M3uExportError error,
  ) async {
    await _discardQuietly(target);
    return Err(error);
  }

  Future<void> _discardQuietly(SaveTarget target) async {
    try {
      await _picker.discard(target);
    } on Object catch (e, st) {
      _log.warning('discarding the export target failed', e, st);
    }
  }
}
