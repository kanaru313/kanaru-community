import 'package:flutter/services.dart';

/// Why a MediaStore call failed.
enum MediaStoreErrorKind {
  /// The media permission is missing.
  permission,

  /// The query failed.
  io,

  /// The native side is not there (tests, other platform).
  unavailable,
}

class MediaStoreException implements Exception {
  const MediaStoreException(this.kind, [this.message]);

  final MediaStoreErrorKind kind;
  final String? message;

  @override
  String toString() => 'MediaStoreException(${kind.name}, $message)';
}

/// Audio rows as parallel lists; [durationsMs] is -1 when unknown.
class MediaStoreAudioRows {
  const MediaStoreAudioRows({
    required this.paths,
    required this.sizes,
    required this.modifiedSec,
    required this.durationsMs,
    this.emptyPaths = 0,
  });

  final List<String> paths;
  final List<int> sizes, modifiedSec, durationsMs;

  /// Rows whose `_data` was empty (an OEM build that blanks it).
  final int emptyPaths;
}

class MediaStoreLyricsRows {
  const MediaStoreLyricsRows({
    required this.paths,
    required this.sizes,
    required this.modifiedSec,
  });

  final List<String> paths;
  final List<int> sizes, modifiedSec;
}

class MediaStoreFolderRows {
  const MediaStoreFolderRows({required this.paths, required this.counts});

  final List<String> paths;
  final List<int> counts;
}

/// Typed client of the `kanaru/media_store` channel.
class MediaStoreChannelClient {
  MediaStoreChannelClient({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'kanaru/media_store';

  final MethodChannel _channel;
  int? _sdkInt;
  String? _primaryRoot;

  /// Android SDK level; cached after the first answer.
  Future<int> sdkInt() async {
    final cached = _sdkInt;
    if (cached != null) return cached;
    final value = await _call<int>('sdkInt');
    if (value == null) {
      throw const MediaStoreException(MediaStoreErrorKind.io, 'no sdkInt');
    }
    return _sdkInt = value;
  }

  /// Shared storage root of the current user (`/storage/emulated/<N>`);
  /// cached after the first answer.
  Future<String> primaryRoot() async {
    final cached = _primaryRoot;
    if (cached != null) return cached;
    final value = await _call<String>('primaryRoot');
    if (value == null || value.isEmpty) {
      throw const MediaStoreException(MediaStoreErrorKind.io, 'no primaryRoot');
    }
    return _primaryRoot = value;
  }

  Future<MediaStoreAudioRows> listAudio({
    required String likePattern,
    required String root,
  }) async {
    final m = await _map('listAudio', {'likePattern': likePattern, 'root': root});
    final paths = _strings(m, 'paths');
    final sizes = _ints(m, 'sizes');
    final modifiedSec = _ints(m, 'modifiedSec');
    final durationsMs = _ints(m, 'durationsMs');
    _sameLength('listAudio', paths.length, [sizes, modifiedSec, durationsMs]);
    return MediaStoreAudioRows(
      paths: paths,
      sizes: sizes,
      modifiedSec: modifiedSec,
      durationsMs: durationsMs,
      emptyPaths: (m['emptyPaths'] as int?) ?? 0,
    );
  }

  Future<MediaStoreLyricsRows> listLyrics({
    required String likePattern,
    required String root,
  }) async {
    final m = await _map('listLyrics', {'likePattern': likePattern, 'root': root});
    final paths = _strings(m, 'paths');
    final sizes = _ints(m, 'sizes');
    final modifiedSec = _ints(m, 'modifiedSec');
    _sameLength('listLyrics', paths.length, [sizes, modifiedSec]);
    return MediaStoreLyricsRows(
      paths: paths,
      sizes: sizes,
      modifiedSec: modifiedSec,
    );
  }

  /// [extensions] is the allow list of audio extensions (lower case).
  Future<MediaStoreFolderRows> audioFolders({
    required int minDurationMs,
    required List<String> extensions,
  }) async {
    final m = await _map('audioFolders', {
      'minDurationMs': minDurationMs,
      'extensions': extensions,
    });
    return MediaStoreFolderRows(
      paths: _strings(m, 'paths'),
      counts: _ints(m, 'counts'),
    );
  }

  Future<Map<Object?, Object?>> _map(String method, Object? args) async {
    final reply = await _call<Map<Object?, Object?>>(method, args);
    if (reply == null) {
      throw MediaStoreException(MediaStoreErrorKind.io, '$method: empty reply');
    }
    return reply;
  }

  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.code == 'permission'
            ? MediaStoreErrorKind.permission
            : MediaStoreErrorKind.io,
        e.message,
      );
    } on MissingPluginException catch (e) {
      throw MediaStoreException(MediaStoreErrorKind.unavailable, e.message);
    }
  }

  /// The parallel lists of a reply must have one entry per path; a mismatch
  /// is an io failure here, not a `RangeError` later.
  static void _sameLength(String method, int length, List<List<Object?>> others) {
    if (others.any((l) => l.length != length)) {
      throw MediaStoreException(
        MediaStoreErrorKind.io,
        '$method: reply lists differ in length',
      );
    }
  }

  static List<String> _strings(Map<Object?, Object?> m, String key) {
    final v = m[key];
    if (v is! List) throw MediaStoreException(MediaStoreErrorKind.io, 'bad $key');
    try {
      return List<String>.from(v); // eager: a bad element fails here
    } on TypeError {
      throw MediaStoreException(MediaStoreErrorKind.io, 'bad $key');
    }
  }

  static List<int> _ints(Map<Object?, Object?> m, String key) {
    final v = m[key];
    if (v is! List) throw MediaStoreException(MediaStoreErrorKind.io, 'bad $key');
    try {
      return List<int>.from(v);
    } on TypeError {
      throw MediaStoreException(MediaStoreErrorKind.io, 'bad $key');
    }
  }
}
