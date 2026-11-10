import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../../database/database.dart';
import '../../media/domain/cover_colors.dart' as media;
import '../../media/domain/cover_files.dart';
import '../../media/domain/library_keys.dart';
import '../domain/custom_cover_controller.dart';
import 'scan/native_cover_import.dart';

final _log = Logger('kanaru.library.custom_cover');

/// Folder under the data dir (not the cache dir: the OS may clear that). It
/// holds the `covers/{thumb,full}/<key>.jpg` layout the Rust import writes.
const String customCoversDirName = 'custom_covers';

/// True when [key] is a well-formed custom cover key (`ab/<32 hex>`, the same
/// form as a song cover key).
bool isCustomCoverKey(String key) => isCoverKey(key);

/// Makes covers from user-chosen images (through the Rust import, so they get
/// the same thumb/full JPEGs and colours as song covers) under
/// `<dataDir>/custom_covers/covers/` and keeps the `custom_covers` rows in
/// step. Import (Rust call and row write) and GC run one after the other in
/// one serial queue, so the GC never sees a file whose row is not written yet.
/// The folder is created by the first import.
class CustomCoverStore implements CustomCoverController {
  CustomCoverStore(
    this._db,
    Directory dataDir, {
    this._importer = const RustCoverImporter(),
    this.gcMinAge = const Duration(hours: 1),
    this.importTimeout = const Duration(seconds: 60),
    this._clock = DateTime.now,
  }) : _dir = Directory('${dataDir.path}/$customCoversDirName');

  final AppDatabase _db;
  final Directory _dir;
  final CoverImporter _importer;
  final DateTime Function() _clock;

  /// The GC leaves files younger than this alone: an import of a second
  /// process on the same data folder may have written them and not yet its
  /// row (nothing locks the data folder to one instance).
  final Duration gcMinAge;

  /// Longest wait for the native import. The Rust thread stays busy until a
  /// stalled read returns; its late files get no row and the GC removes them.
  final Duration importTimeout;
  Future<void> _tail = Future.value();

  /// The folder passed to the importer as `outDir`.
  Directory get directory => _dir;

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _tail.then((_) => op());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// The stored image of [coverKey] in [size], or null when the key is
  /// malformed or the file is gone.
  Future<File?> fileFor(
    String coverKey, {
    CoverSize size = CoverSize.full,
  }) async {
    if (!isCustomCoverKey(coverKey)) return null;
    final file = File('${_dir.path}/${coverRelativePath(coverKey, size)}');
    // An empty file is a write that did not survive a crash.
    return await file.exists() && await file.length() > 0 ? file : null;
  }

  void _checkItem(CustomCoverKind kind, String itemKey) {
    final valid = switch (kind) {
      CustomCoverKind.playlist =>
        itemKey.isNotEmpty && itemKey != favoritesPlaylistUid,
      CustomCoverKind.album => AlbumKey.decode(itemKey) != null,
      CustomCoverKind.artist => ArtistKey.decode(itemKey) != null,
    };
    if (!valid) {
      throw ArgumentError.value(
        itemKey,
        'itemKey',
        'not valid for ${kind.name}',
      );
    }
  }

  @override
  Future<void> importCover(
    CustomCoverKind kind,
    String itemKey,
    File source,
  ) async {
    _checkItem(kind, itemKey);
    await _serial(() async {
      final pending = _importer.import(path: source.path, outDir: _dir.path);
      final CoverImportResult result;
      try {
        result = await pending.timeout(importTimeout);
      } on TimeoutException {
        // A late success has no row: drop its files once it returns (in the
        // queue, so no other import is cut short); else the GC gets them.
        unawaited(
          pending.then<void>((late) {
            final k = late.key;
            if (k != null) return _serial(() => _deleteIfUnreferenced(k));
          }, onError: (Object _) {}),
        );
        throw FileSystemException(
          'cover import timed out after $importTimeout',
          source.path,
        );
      }
      final key = result.key;
      if (key == null || !isCustomCoverKey(key)) {
        throw _failureOf(result, source);
      }
      try {
        final colors = result.colors;
        if (colors != null && colors.palette.isNotEmpty) {
          await upsertCoverColors(
            _db,
            coverKey: key,
            seed: colors.seed,
            colors: colors.palette,
            version: media.coverColorsVersion,
            now: _clock().millisecondsSinceEpoch,
          );
        }
        final previous = await setCustomCover(_db, kind.name, itemKey, key);
        if (previous != null && previous != key) {
          await _deleteIfUnreferenced(previous);
        }
      } catch (_) {
        await _deleteIfUnreferenced(key);
        rethrow;
      }
    });
  }

  /// Permanent failures (undecodable, unsupported, too large, missing file,
  /// a native panic) are a [FormatException]; transient ones (I/O, failing to
  /// write under the data folder) and `permissionDenied` are a
  /// [FileSystemException].
  Exception _failureOf(CoverImportResult r, File source) {
    final f = r.failure;
    final what = f == null ? 'no key' : f.kind;
    if (f != null && (f.transient || f.kind == 'permissionDenied')) {
      return FileSystemException('cover import failed ($what)', source.path);
    }
    return FormatException('cannot use as a cover ($what): ${source.path}');
  }

  @override
  Future<void> removeCover(CustomCoverKind kind, String itemKey) =>
      _serial(() async {
        final previous = await clearCustomCover(_db, kind.name, itemKey);
        if (previous != null) await _deleteIfUnreferenced(previous);
      });

  @override
  Future<int> collectUnreferencedFiles() => _serial(() async {
    final keep = await referencedCustomCoverKeys(_db);
    final cutoff = _clock().subtract(gcMinAge);
    var deleted = 0;
    for (final size in CoverSize.values) {
      final sizeDir = Directory('${_dir.path}/covers/${size.name}');
      if (!await sizeDir.exists()) continue;
      await for (final shard in sizeDir.list(followLinks: false)) {
        if (shard is! Directory) continue;
        final shardName = shard.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .last;
        await for (final file in shard.list(followLinks: false)) {
          if (file is! File) continue;
          final name = file.uri.pathSegments.last;
          final bool stale;
          if (name.startsWith(coverTempPrefix)) {
            stale = !(await file.lastModified()).isAfter(cutoff);
          } else if (name.endsWith('.jpg')) {
            final key = '$shardName/${name.substring(0, name.length - 4)}';
            // Age window too: inside this process an import and this GC share
            // one queue, but a second process on the same folder may have
            // written the file and not yet its row.
            stale =
                isCustomCoverKey(key) &&
                !keep.contains(key) &&
                !(await file.lastModified()).isAfter(cutoff);
          } else {
            stale = false; // unknown files are not ours
          }
          if (stale && await _tryDelete(file)) deleted++;
        }
      }
    }
    return deleted;
  });

  Future<void> _deleteIfUnreferenced(String coverKey) async {
    if (!isCustomCoverKey(coverKey)) return;
    if (await isCustomCoverKeyReferenced(_db, coverKey)) return;
    for (final size in CoverSize.values) {
      final file = File('${_dir.path}/${coverRelativePath(coverKey, size)}');
      if (await file.exists()) await _tryDelete(file);
    }
  }

  Future<bool> _tryDelete(File file) async {
    try {
      await file.delete();
      return true;
    } on FileSystemException catch (e) {
      _log.warning('could not delete ${file.path}: $e');
      return false;
    }
  }
}
