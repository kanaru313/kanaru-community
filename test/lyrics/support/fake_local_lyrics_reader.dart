import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:kanaru/src/lyrics/data/local_lyrics_reader.dart';
import 'package:kanaru/src/lyrics/domain/embedded_lyrics.dart';

/// A [LocalLyricsReader] whose answers the test controls. A tag path with no
/// entry in [tags] answers null at once; one in [holdTags] waits for
/// [releaseTag].
class FakeLocalLyricsReader implements LocalLyricsReader {
  final tags = <String, EmbeddedLyrics?>{};
  final tagErrors = <String, Object>{};
  final lrcs = <String, String>{};
  final lrcBytes = <String, Uint8List>{};
  final lrcMtime = <String, int>{};
  final lrcErrors = <String, Object>{};
  final statErrors = <String, Object>{};
  final holdTags = <String>{};

  final tagReads = <String>[];
  final lrcReads = <String>[];
  final stats = <String>[];
  final _held = <String, Completer<void>>{};

  /// Lets the held tag read of [path] finish.
  void releaseTag(String path) => _held[path]?.complete();

  @override
  Future<EmbeddedLyrics?> readTag(String audioPath) async {
    tagReads.add(audioPath);
    if (holdTags.contains(audioPath)) {
      await (_held[audioPath] ??= Completer<void>()).future;
    }
    final error = tagErrors[audioPath];
    if (error != null) throw error;
    return tags[audioPath];
  }

  Uint8List? _bytes(String path) =>
      lrcBytes[path] ??
      (lrcs[path] == null
          ? null
          : Uint8List.fromList(utf8.encode(lrcs[path]!)));

  @override
  Future<LrcStat?> statLrc(String path) async {
    stats.add(path);
    final error = statErrors[path];
    if (error != null) throw error;
    final bytes = _bytes(path);
    if (bytes == null) return null;
    return LrcStat(
      path: path,
      mtimeMs: lrcMtime[path] ?? 1,
      size: bytes.length,
    );
  }

  @override
  Future<LrcFile?> readLrc(LrcStat stat) async {
    final path = stat.path;
    lrcReads.add(path);
    final error = lrcErrors[path];
    if (error != null) throw error;
    final bytes = _bytes(path);
    if (bytes == null) return null;
    return LrcFile(
      stat: LrcStat(
        path: path,
        mtimeMs: lrcMtime[path] ?? 1,
        size: bytes.length,
      ),
      bytes: bytes,
    );
  }
}
