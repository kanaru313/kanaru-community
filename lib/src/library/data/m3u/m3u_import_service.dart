import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../../foundation/result.dart';
import '../../../platform/domain/document_picker.dart';
import '../../../storage/data/m3u/m3u_line_resolver.dart';
import '../../../storage/data/m3u/m3u_reader.dart';
import '../../../storage/domain/m3u/m3u_parse.dart';
import '../../../storage/domain/m3u/m3u_text.dart';
import '../../domain/playlists/playlist_import.dart';
import '../../domain/playlists/playlist_store.dart';
import '../../domain/scan_status.dart';
import '../scan/scan_folders.dart';
import 'm3u_index_check.dart';
import 'm3u_results.dart';
import 'm3u_scan_rules.dart';
import 'm3u_track_matcher.dart';

final _log = Logger('library.m3u');

/// Reads an M3U document, maps its lines to the library and creates the
/// playlist. Typed failures come back as [Err]; unexpected errors (database,
/// parse isolate, a second `ArgumentError`) propagate and nothing is written.
class M3uImportService {
  M3uImportService(
    this._db,
    this._store,
    this._picker,
    this._canonicalize,
    this._scans,
    this._short, {
    this.parseFile = parseM3u,
    required this.androidStorage,
    this.indexCheck,
  });

  final AppDatabase _db;
  final PlaylistStore _store;
  final DocumentPicker _picker;
  final Future<String> Function(String) _canonicalize;
  final LibraryScanCommands _scans;
  final ShortTrackRule _short;

  /// A top-level function: it runs on a worker isolate.
  final M3uParse Function(Uint8List) parseFile;

  /// Android shared storage: case-insensitive, `<volume>/Android` is app data.
  final bool androidStorage;

  /// Android: which files the scanner's index cannot see. Null on Linux,
  /// where the scan walks the file system the resolver already stat'ed.
  final M3uIndexCheck? indexCheck;

  Future<Result<M3uImportResult, M3uImportError>> importDocument(
    PickedDocument doc, {
    required String fallbackName,
    void Function(M3uImportProgress p)? onProgress,
  }) async {
    void report(int done, int? total) => onProgress?.call(
      M3uImportProgress(fileName: doc.name, done: done, total: total),
    );
    report(0, null);
    final read = await readM3u(_picker, doc, parseFile: parseFile);
    if (read is M3uReadFailed) {
      return Err(switch (read.error) {
        DocumentError.tooLarge => M3uImportError.tooLarge,
        DocumentError.notAFile => M3uImportError.notAFile,
        _ => M3uImportError.unreadable,
      });
    }
    read as M3uReadOk;
    final folders = await liveScanFolders(_db);
    final resolved = await resolveM3uLines(
      read.parse.entries,
      baseDir: read.baseDir,
      liveRoots: [for (final f in folders) f.root],
      canonicalize: _canonicalize,
      onProgress: report,
    );
    // One listing per import: a retried match reuses the verdicts.
    final asked = <String>{};
    final verdicts = <String, M3uIndexVerdict>{};
    final inner = androidStorage ? indexCheck : null;
    final M3uIndexCheck? check = inner == null
        ? null
        : (paths) async {
            final fresh = [
              for (final p in paths)
                if (!asked.contains(p)) p,
            ];
            if (fresh.isNotEmpty) {
              asked.addAll(fresh);
              verdicts.addAll(await inner(fresh));
            }
            return {for (final p in paths) p: ?verdicts[p]};
          };
    Future<M3uMatch> match([bool fresh = false]) => matchM3uLines(
      _db,
      resolved,
      folders: fresh ? null : folders,
      short: _short,
      androidStorage: androidStorage,
      indexCheck: check,
      truncated: read.parse.truncated,
    );

    var found = await match();
    ImportedPlaylist? created;
    final name = _nameOf(read.fileName, fallbackName);
    if (found.entries.isNotEmpty) {
      try {
        created = await _create(name, found);
      } on ArgumentError {
        // Only a source removed since the match is retried, once.
        if (await _allSourcesLive(found)) rethrow;
        found = await match(true);
        if (found.entries.isNotEmpty) created = await _create(name, found);
      }
    }
    if (created == null) return Err(_refusal(found));
    if (created.missingCreated > 0) _rescanQuietly();
    return Ok(
      M3uImportResult(
        playlistUid: created.uid,
        name: name,
        fileName: read.fileName,
        added: created.entryCount,
        totalLines: found.totalLines,
        songsAdded: _distinctSongs(found.entries),
        // Distinct songs: a repeated line counts once.
        notInLibrary:
            _distinctSongs(found.entries.whereType<ImportedMissing>()) +
            found.notPresent,
        outsideFolders: found.outsideFolders,
        notScanned: found.notScanned,
        notIndexed: found.notIndexed,
        problems: found.problems,
        truncated: found.truncated,
      ),
    );
  }

  /// Songs by identity: the track id, or (source, locator) of a placeholder.
  static int _distinctSongs(Iterable<ImportedEntry> entries) => {
    for (final e in entries)
      switch (e) {
        ImportedTrack() => 't${e.id.value}',
        ImportedMissing() => 'm${e.sourceId}\u0000${e.locator}',
      },
  }.length;

  Future<ImportedPlaylist> _create(String name, M3uMatch m) =>
      _store.createImportedPlaylist(name: name, entries: m.entries);

  Future<bool> _allSourcesLive(M3uMatch m) async {
    final used = {
      for (final e in m.entries)
        if (e is ImportedMissing) e.sourceId,
    };
    if (used.isEmpty) return true;
    final live = {for (final f in await liveScanFolders(_db)) f.sourceId};
    return live.containsAll(used);
  }

  void _rescanQuietly() {
    // Failures show in the scan status; they never fail the import.
    unawaited(
      Future<void>.sync(_scans.rescan).catchError(
        (Object e, StackTrace st) =>
            _log.warning('rescan after M3U import failed', e, st),
      ),
    );
  }

  static String _nameOf(String fileName, String fallback) {
    final name = m3uPlaylistName(fileName);
    return name.isEmpty ? fallback : name;
  }

  /// Nothing was written. A line is usable when it names an existing local
  /// file: when such files were found only outside the music folders (and
  /// none inside), the user is told to add that folder; URL, typo and
  /// no-base lines do not hide that hint.
  static M3uImportError _refusal(M3uMatch m) {
    if (m.notIndexed > 0) return M3uImportError.notIndexed;
    return m.outsideFolders > 0 && m.notScanned == 0
        ? M3uImportError.allOutsideFolders
        : M3uImportError.nothingFound;
  }
}
