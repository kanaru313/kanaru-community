import 'dart:io';
import 'dart:typed_data';

import '../../rust/api/error.dart';
import '../../rust/api/lyrics.dart';
import '../domain/embedded_lyrics.dart';
import '../domain/lyrics.dart';
import 'lrc_file_read.dart';
import 'local_lyrics_reader.dart';

/// The bridge call that reads the tag lyrics of a file.
typedef ReadTagFn = Future<EmbeddedLyricsDto?> Function(String path);

/// [LocalLyricsReader] on the real thing: tags through the Rust bridge (own
/// thread per call, 10 s deadline, at most two stuck threads), `.lrc` through
/// `dart:io` with a 5 s deadline. A native `Timeout` is transient; every other
/// native error is permanent (no tag lyrics).
class NativeLocalLyricsReader implements LocalLyricsReader {
  NativeLocalLyricsReader({ReadTagFn? readTagFn})
    : _readTag = readTagFn ?? ((path) => readEmbeddedLyrics(path: path));

  final ReadTagFn _readTag;
  final _stats = PathFlights<FileStat>();
  final _reads = PathFlights<Uint8List>();

  @override
  Future<EmbeddedLyrics?> readTag(String audioPath) async {
    final EmbeddedLyricsDto? dto;
    try {
      dto = await _readTag(audioPath);
    } on NativeError catch (e) {
      throw LyricsReadFailure(
        kind: e.kind.name,
        transient: e.transient || e.kind == NativeErrorKind.timeout,
      );
    }
    if (dto == null) return null;
    return EmbeddedLyrics(
      text: dto.text,
      synced: [
        for (final line in dto.synced)
          LyricLine(Duration(milliseconds: line.timeMs), line.text),
      ],
    );
  }

  @override
  Future<LrcStat?> statLrc(String path) =>
      statLrcFile(path, statFn: (p) => _stats.join(p, () => FileStat.stat(p)));

  @override
  Future<LrcFile?> readLrc(LrcStat stat) => readLrcFile(
    stat,
    // Joined by the identity of the stat, so an edited file is not served
    // the bytes of a read that started before the edit.
    readBytes: (p, max) =>
        _reads.join(lrcReadKey(stat), () => readFileBytes(p, max)),
  );
}
