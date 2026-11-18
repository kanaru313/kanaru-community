import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../../database/database.dart';
import '../../../foundation/result.dart';
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
  }) async {
    try {
      return await _export(playlistUid, target, relative);
    } on Object {
      // Unexpected failure: give the created target up, then let it surface.
      await _discardQuietly(target);
      rethrow;
    }
  }

  Future<Result<M3uExportResult, M3uExportError>> _export(
    String playlistUid,
    SaveTarget target,
    bool relative,
  ) async {
    final entries = await loadM3uExportEntries(_db, playlistUid);
    if (entries == null) return _fail(target, M3uExportError.playlistGone);
    String? dir;
    if (relative) {
      final local = target.localPath;
      if (local == null) return _fail(target, M3uExportError.folderUnknown);
      dir = await _canonicalize(p.posix.dirname(local));
    }
    final items = <M3uWriteItem>[];
    var noFile = 0;
    for (final e in entries) {
      final path = e.absolutePath;
      if (path == null) {
        noFile++;
        continue;
      }
      items.add(
        M3uWriteItem(
          path: dir == null ? path : relativeM3uPath(dir, path),
          title: e.title,
          artist: e.artist,
          durationMs: e.durationMs,
        ),
      );
    }
    final written = writeM3u(items);
    final wrote = await _picker.write(
      target,
      Uint8List.fromList(utf8.encode(written.text)),
    );
    if (wrote is Err) return _fail(target, M3uExportError.writeFailed);
    return Ok(
      M3uExportResult(
        written: items.length - written.skipped,
        skipped: noFile + written.skipped,
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
