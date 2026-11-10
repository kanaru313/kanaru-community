import '../../../rust/api/tags.dart';
import '../../domain/scan/tag_read.dart';
import 'native_error_mapping.dart';

/// Reads the tags of many files. The Rust call runs on its background pool.
abstract interface class TagReader {
  /// One result per path (matched by [TagRead.path]). May throw when the
  /// native library is unavailable.
  Future<List<TagRead>> read(List<String> paths);
}

/// [TagReader] over `read_tags_batch`; the only user of the generated API.
class RustTagReader implements TagReader {
  const RustTagReader();

  @override
  Future<List<TagRead>> read(List<String> paths) async {
    final dtos = await readTagsBatch(paths: paths);
    return [for (final dto in dtos) _map(dto)];
  }

  static TagRead _map(TagReadDto dto) {
    final e = dto.error;
    final f = dto.fields;
    return TagRead(
      path: dto.path,
      error: e == null ? null : failureOf(e),
      fields: f == null
          ? null
          : TagFields(
              title: f.title,
              artists: f.artists,
              album: f.album,
              albumArtists: f.albumArtists,
              genres: f.genres,
              composer: f.composer,
              year: f.year,
              trackNo: f.trackNo,
              trackTotal: f.trackTotal,
              discNo: f.discNo,
              discTotal: f.discTotal,
              titleSort: f.titleSort,
              artistSort: f.artistSort,
              albumSort: f.albumSort,
              languageTag: f.languageTag,
              detectedLanguage: f.detectedLanguage,
              comment: f.comment,
              durationMs: f.durationMs,
              bitrate: f.bitrate,
              sampleRate: f.sampleRate,
              bitDepth: f.bitDepth,
              channels: f.channels,
              codec: f.codec,
            ),
    );
  }
}
