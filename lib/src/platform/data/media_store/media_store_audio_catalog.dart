import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../domain/local_audio_catalog.dart';
import '../local_files/walk_isolate.dart' show defaultWalkTimeout;
import 'media_store_channel_client.dart';
import 'media_store_like_pattern.dart';

/// `<volume>/Android/...`: app data and messenger voice notes, not music.
/// Skipped by absolute path, so the scan and the folder sheet agree.
final _volumeAppData = RegExp(r'^/storage/(?:emulated/\d+|[^/]+)/Android(?:/|$)');
final _upper = RegExp('[A-Z]');

/// ASCII-only lower-casing: SQLite's `LIKE` folds nothing else, so the Dart
/// re-check must not either.
String _fold(String s) =>
    s.replaceAllMapped(_upper, (m) => m[0]!.toLowerCase());

/// [LocalAudioCatalog] for Android, over MediaStore (paths, no SAF).
///
/// Never throws for a platform failure: a refused or failed query, or one that
/// runs past [timeout], comes back as an unreachable listing with its reason.
class MediaStoreAudioCatalog implements LocalAudioCatalog {
  MediaStoreAudioCatalog(
    this._client, {
    Future<bool> Function(String path)? rootExists,
    Future<String> Function(String path)? resolveLinks,
    this.firstRunMinDurationMs = 30000,
    this.timeout = defaultWalkTimeout,
  }) : _rootExists = rootExists ?? ((path) => Directory(path).exists()),
       _resolveLinks =
           resolveLinks ?? ((path) => Directory(path).resolveSymbolicLinks());

  static final _log = Logger('platform.media_store');

  final MediaStoreChannelClient _client;
  final Future<bool> Function(String) _rootExists;
  final Future<String> Function(String) _resolveLinks;

  /// Rows shorter than this are not counted by [audioFolders] (the first-run
  /// estimate follows the "skip short tracks" default). 0 = off.
  final int firstRunMinDurationMs;

  /// Longest a MediaStore listing may take.
  final Duration timeout;

  /// Paths already in MediaStore `_data` form (from [audioFolders] or the
  /// suggestion): [canonicalize] only normalises them.
  final Set<String> _indexRoots = {};

  @override
  FolderChoice get folderChoice => FolderChoice.mediaStoreSheet;

  static bool _excluded(String relDir, Set<String> keys) {
    for (final key in keys) {
      if (relDir == key || relDir.startsWith('$key/')) return true;
    }
    return false;
  }

  /// Relative folder of [path] below [prefix] (root plus `/`) or null when
  /// the path is outside. Case follows SQLite `LIKE` (ASCII only).
  static String? _relDir(String path, String prefix) {
    if (path.length <= prefix.length ||
        _fold(path.substring(0, prefix.length)) != _fold(prefix)) {
      return null;
    }
    final rel = path.substring(prefix.length);
    final slash = rel.lastIndexOf('/');
    return slash < 0 ? '' : rel.substring(0, slash);
  }

  static bool _inSkippedFolder(String relDir) =>
      relDir.isNotEmpty && relDir.split('/').any(isSkippedFolderName);

  @override
  Future<AudioListing> listAudio({
    required String root,
    required Set<String> excludedKeys,
    int skipShorterThanMs = 0,
  }) async {
    final cancel = _Cancel();
    try {
      if (!await _rootExists(root)) return const AudioListing.unreachable();
      return await _list(root, excludedKeys, skipShorterThanMs, cancel)
          .timeout(timeout);
    } on TimeoutException {
      cancel.cancelled = true; // a late audio reply must not start the next query
      _log.warning('MediaStore listing of $root timed out after $timeout');
      return const AudioListing.unreachable(UnreachableReason.timedOut);
    } on MediaStoreException catch (error) {
      _log.warning('MediaStore listing of $root failed: $error');
      return AudioListing.unreachable(
        error.kind == MediaStoreErrorKind.permission
            ? UnreachableReason.permission
            : UnreachableReason.failed,
      );
    }
  }

  Future<AudioListing> _list(
    String root,
    Set<String> excludedKeys,
    int skipShorterThanMs,
    _Cancel cancel,
  ) async {
    final audioRows = await _client.listAudio(
      likePattern: mediaStoreLikePattern(root),
      root: root,
    );
    if (cancel.cancelled) {
      return const AudioListing.unreachable(UnreachableReason.timedOut);
    }
    final lyricRows = await _client.listLyrics(
      likePattern: mediaStoreLikePattern(root, suffix: '.lrc'),
      root: root,
    );

    final audio = <LocalAudioFile>[];
    final lyrics = <LocalSidecarFile>[];
    var excludedOut = 0, skippedOut = audioRows.emptyPaths, shortOut = 0;
    final dropped = <String>[];
    final prefix = '$root/';
    // A root the user picked inside the app-data tree is listed as chosen.
    final rootInAppData = _volumeAppData.hasMatch(prefix);
    bool appData(String path) => !rootInAppData && _volumeAppData.hasMatch(path);

    for (var i = 0; i < audioRows.paths.length; i++) {
      final path = audioRows.paths[i];
      final dir = _relDir(path, prefix);
      if (dir == null) {
        dropped.add(path);
        continue;
      }
      if (!isAudioPath(path)) continue; // e.g. .amr or .mid rows
      if (_excluded(dir, excludedKeys)) {
        excludedOut++;
        continue;
      }
      if (_inSkippedFolder(dir) ||
          appData(path) ||
          p.basename(path).startsWith('.')) {
        skippedOut++;
        continue;
      }
      final duration = audioRows.durationsMs[i];
      if (skipShorterThanMs > 0 && duration > 0 && duration < skipShorterThanMs) {
        shortOut++;
        continue;
      }
      audio.add(
        LocalAudioFile(
          path: path,
          sizeBytes: audioRows.sizes[i],
          mtimeMs: audioRows.modifiedSec[i] * 1000,
          durationMs: duration < 0 ? null : duration,
        ),
      );
    }
    for (var i = 0; i < lyricRows.paths.length; i++) {
      final path = lyricRows.paths[i];
      final dir = _relDir(path, prefix);
      if (dir == null) {
        dropped.add(path);
        continue;
      }
      if (!isLyricsSidecarPath(path)) continue;
      if (_excluded(dir, excludedKeys) ||
          _inSkippedFolder(dir) ||
          appData(path)) {
        continue;
      }
      if (p.basename(path).startsWith('.')) continue;
      lyrics.add(
        LocalSidecarFile(
          path: path,
          sizeBytes: lyricRows.sizes[i],
          mtimeMs: lyricRows.modifiedSec[i] * 1000,
        ),
      );
    }
    if (dropped.isNotEmpty) {
      _log.info(
        '$root: ${dropped.length} MediaStore rows outside the root dropped '
        '(e.g. ${dropped.take(3).join(', ')})',
      );
    }
    if (audioRows.emptyPaths > 0) {
      _log.warning('$root: ${audioRows.emptyPaths} MediaStore rows had no path');
    }
    return AudioListing(
      audio: audio,
      lyrics: lyrics,
      excludedOut: excludedOut,
      skippedOut: skippedOut,
      shortOut: shortOut,
    );
  }

  @override
  Future<List<AudioFolderSummary>> audioFolders() async {
    final MediaStoreFolderRows rows;
    try {
      rows = await _client
          .audioFolders(
            minDurationMs: firstRunMinDurationMs,
            extensions: audioExtensions.toList(),
          )
          .timeout(timeout);
    } on TimeoutException {
      _log.warning('MediaStore folder listing timed out');
      return const [];
    } on MediaStoreException catch (error) {
      _log.warning('MediaStore folder listing failed: $error');
      return const [];
    }
    final folders = <AudioFolderSummary>[];
    for (var i = 0; i < rows.paths.length; i++) {
      final path = rows.paths[i];
      if (path.split('/').any(isSkippedFolderName) ||
          _volumeAppData.hasMatch(path)) {
        continue;
      }
      folders.add(AudioFolderSummary(path: path, audioCount: rows.counts[i]));
    }
    folders.sort((a, b) => a.path.compareTo(b.path));
    _indexRoots.addAll(folders.map((f) => f.path));
    return folders;
  }

  Future<String?> _primaryRoot() async {
    try {
      return await _client.primaryRoot();
    } on MediaStoreException catch (error) {
      _log.warning('No primary storage root: $error');
      return null;
    }
  }

  @override
  Future<String?> suggestedMusicFolder() async {
    final primary = await _primaryRoot();
    if (primary == null) return null;
    final music = '$primary/Music';
    final folders = await audioFolders();
    final has = folders.any(
      (f) => f.path == music || f.path.startsWith('$music/'),
    );
    if (!has) return null;
    _indexRoots.add(music);
    return music;
  }

  @override
  Future<String> canonicalize(String path) async {
    var normalized = _strip(p.normalize(path));
    if (_indexRoots.contains(normalized)) return normalized;
    // `/sdcard` and `/storage/self/primary` are aliases of the primary root;
    // map them first so a blocked symlink hop cannot leave an alias behind.
    final primary = await _primaryRoot();
    if (primary != null) {
      for (final alias in const ['/sdcard', '/storage/self/primary']) {
        if (normalized == alias || normalized.startsWith('$alias/')) {
          normalized = primary + normalized.substring(alias.length);
          break;
        }
      }
    }
    try {
      return _strip(await _resolveLinks(normalized));
    } on FileSystemException catch (error) {
      _log.fine('Could not resolve $normalized: $error');
      return normalized;
    }
  }

  static String _strip(String path) =>
      path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;

  @override
  Future<String?> pickFolder({String? initialDirectory}) =>
      throw UnsupportedError('Android picks folders from the MediaStore sheet');
}

/// Set when a listing timed out, so its late replies start no more queries.
class _Cancel {
  bool cancelled = false;
}
