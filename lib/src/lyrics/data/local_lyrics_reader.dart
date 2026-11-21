import 'dart:typed_data';

import '../domain/embedded_lyrics.dart';

/// A lyrics source that could not be read. [transient] = a later attempt may
/// succeed (timeout, I/O error): the result is shown but not cached.
/// Permanent = the source has nothing for us (permission denied, corrupt
/// tag). [kind] is a short name safe to log: never a path or lyrics text.
class LyricsReadFailure implements Exception {
  const LyricsReadFailure({required this.kind, required this.transient});

  final String kind;
  final bool transient;

  @override
  String toString() =>
      'LyricsReadFailure($kind${transient ? ', transient' : ''})';
}

/// The stat of a `.lrc` file: its cache identity.
class LrcStat {
  const LrcStat({
    required this.path,
    required this.mtimeMs,
    required this.size,
  });

  final String path;
  final int mtimeMs;
  final int size;

  @override
  bool operator ==(Object other) =>
      other is LrcStat &&
      other.path == path &&
      other.mtimeMs == mtimeMs &&
      other.size == size;

  @override
  int get hashCode => Object.hash(path, mtimeMs, size);
}

/// A `.lrc` file read: its [stat] and raw [bytes] (decoded later, off the UI
/// isolate when large).
class LrcFile {
  const LrcFile({required this.stat, required this.bytes});

  final LrcStat stat;
  final Uint8List bytes;
}

/// Reads the two local lyrics sources. No scheduling here: the loader decides
/// what runs when. Failures are [LyricsReadFailure]s.
abstract interface class LocalLyricsReader {
  /// Lyrics stored in the tags of the audio file at [audioPath]; null when it
  /// has none.
  Future<EmbeddedLyrics?> readTag(String audioPath);

  /// The stat of the `.lrc` at [path]; null when there is no regular file of
  /// a readable size.
  Future<LrcStat?> statLrc(String path);

  /// The `.lrc` of [stat] (from [statLrc]; no second stat); null when it is
  /// unreadable for good or grew past the cap.
  Future<LrcFile?> readLrc(LrcStat stat);
}

/// The default reader: reads nothing, so tests that open Now Playing never
/// touch the file system or the native library. The app overrides it with
/// `NativeLocalLyricsReader`.
class NoLocalLyricsReader implements LocalLyricsReader {
  const NoLocalLyricsReader();

  @override
  Future<EmbeddedLyrics?> readTag(String audioPath) async => null;

  @override
  Future<LrcStat?> statLrc(String path) async => null;

  @override
  Future<LrcFile?> readLrc(LrcStat stat) async => null;
}
