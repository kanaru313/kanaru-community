import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

import '../../database/database.dart';
import '../../media/domain/library_keys.dart';
import '../domain/custom_cover_controller.dart';

final _log = Logger('kanaru.library.custom_cover');

/// Largest image accepted (bytes). Images are stored as chosen (not resized),
/// so the cap keeps the data folder small.
const int maxCustomCoverBytes = 8 * 1024 * 1024;

/// Folder under the data dir (not the cache dir: the OS may clear that).
const String customCoversDirName = 'custom_covers';

const String _tmpPrefix = '.tmp-';
final RegExp _keyPattern = RegExp(r'^[0-9a-f]{64}$');
const List<String> _extensions = ['jpg', 'png', 'webp', 'gif', 'bmp'];

/// True when [key] is a well-formed custom cover key (SHA-256, lower-case hex).
bool isCustomCoverKey(String key) => _keyPattern.hasMatch(key);

/// Image extension from the first bytes, or null when not a supported image.
String? sniffImageExtension(List<int> head) {
  bool starts(List<int> sig, [int at = 0]) {
    if (head.length < at + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (head[at + i] != sig[i]) return false;
    }
    return true;
  }

  if (starts([0xFF, 0xD8, 0xFF])) return 'jpg';
  if (starts([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return 'png';
  if (starts([0x52, 0x49, 0x46, 0x46]) && starts([0x57, 0x45, 0x42, 0x50], 8)) {
    return 'webp';
  }
  if (starts([0x47, 0x49, 0x46, 0x38])) return 'gif';
  if (starts([0x42, 0x4D])) return 'bmp';
  return null;
}

/// Copies user-chosen cover images into `<dataDir>/custom_covers/<key>.<ext>`
/// and keeps the `custom_covers` rows in step. Operations of one store run one
/// after the other; other processes are covered by the GC age limit. The
/// folder is created on first import.
class CustomCoverStore implements CustomCoverController {
  CustomCoverStore(
    this._db,
    Directory dataDir, {
    this.maxBytes = maxCustomCoverBytes,
    this.gcMinAge = const Duration(hours: 1),
    this.readTimeout = const Duration(seconds: 10),
  }) : _dir = Directory('${dataDir.path}/$customCoversDirName');

  final AppDatabase _db;
  final Directory _dir;

  /// Largest accepted image.
  final int maxBytes;

  /// The GC leaves younger files alone (an in-flight import, a second
  /// process).
  final Duration gcMinAge;

  /// Longest wait for the next chunk of the source.
  final Duration readTimeout;
  Future<void> _tail = Future.value();
  int _tmpCounter = 0;

  /// The folder holding the images.
  Directory get directory => _dir;

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _tail.then((_) => op());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// The stored file of [coverKey], or null when the key is malformed or the
  /// file is gone.
  Future<File?> fileFor(String coverKey) async {
    if (!isCustomCoverKey(coverKey)) return null;
    for (final ext in _extensions) {
      final file = File('${_dir.path}/$coverKey.$ext');
      if (await file.exists()) return file;
    }
    return null;
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
      final key = await _copyAndHash(source);
      try {
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

  @override
  Future<void> removeCover(CustomCoverKind kind, String itemKey) =>
      _serial(() async {
        final previous = await clearCustomCover(_db, kind.name, itemKey);
        if (previous != null) await _deleteIfUnreferenced(previous);
      });

  @override
  Future<int> collectUnreferencedFiles() => _serial(() async {
    if (!await _dir.exists()) return 0;
    final keep = await referencedCustomCoverKeys(_db);
    final cutoff = DateTime.now().subtract(gcMinAge);
    var deleted = 0;
    await for (final entity in _dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final key = name.split('.').first;
      final stale =
          name.startsWith(_tmpPrefix) ||
          (isCustomCoverKey(key) && !keep.contains(key));
      if (!stale) continue;
      if ((await entity.lastModified()).isAfter(cutoff)) continue;
      if (await _tryDelete(entity)) deleted++;
    }
    return deleted;
  });

  /// Copies [source] to a temp file (fsync), names it after the SHA-256 of its
  /// bytes and renames it over the target, so a damaged earlier copy is
  /// repaired. Returns the key.
  Future<String> _copyAndHash(File source) async {
    // Async, so a stalled network or FUSE path cannot freeze the UI isolate.
    if (await FileSystemEntity.type(source.path) != FileSystemEntityType.file) {
      throw FormatException('not a regular file: ${source.path}');
    }
    await _dir.create(recursive: true);
    final tmp = File('${_dir.path}/$_tmpPrefix${pid}_${_tmpCounter++}');
    final digest = _DigestSink();
    final hasher = sha256.startChunkedConversion(digest);
    final out = await tmp.open(mode: FileMode.write);
    String? ext;
    var size = 0;
    try {
      await for (final chunk in source.openRead().timeout(readTimeout)) {
        ext ??= sniffImageExtension(chunk);
        if (ext == null) {
          throw FormatException('not a supported image: ${source.path}');
        }
        size += chunk.length;
        if (size > maxBytes) {
          throw FormatException('image is larger than $maxBytes bytes');
        }
        hasher.add(chunk);
        await out.writeFrom(chunk);
      }
      if (ext == null) throw const FormatException('empty file');
      hasher.close();
      await out.flush(); // fsync before the rename makes it visible
      await out.close();
    } catch (_) {
      await out.close().catchError((Object _) {});
      await _tryDelete(tmp);
      rethrow;
    }
    final key = digest.value.toString();
    await tmp.rename('${_dir.path}/$key.$ext');
    return key;
  }

  Future<void> _deleteIfUnreferenced(String coverKey) async {
    if (!isCustomCoverKey(coverKey)) return;
    if (await isCustomCoverKeyReferenced(_db, coverKey)) return;
    for (final ext in _extensions) {
      final file = File('${_dir.path}/$coverKey.$ext');
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

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
