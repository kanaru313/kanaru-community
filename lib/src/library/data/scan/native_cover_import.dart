import '../../../media/domain/cover_colors.dart';
import '../../../rust/api/covers.dart';
import '../../domain/scan/native_failure.dart';
import 'native_cover_maker.dart';
import 'native_error_mapping.dart';

/// Result of importing one user-chosen image as a cover: a [key] (and
/// [colors], null for a near-gray image) or a [failure].
class CoverImportResult {
  const CoverImportResult.done({required String this.key, this.colors})
    : failure = null;

  const CoverImportResult.failed(NativeFailure this.failure)
    : key = null,
      colors = null;

  final String? key;
  final CoverColors? colors;

  /// Transient: I/O or a failure writing under the output folder, try again
  /// later. Permanent: the image is undecodable, unsupported or too large.
  final NativeFailure? failure;

  bool get isDone => key != null;
}

/// Turns one image file into a cover, like the song-cover pass.
abstract interface class CoverImporter {
  /// [outDir] is an absolute folder that holds `covers/` (the app data
  /// folder for custom covers). May throw when the native library is
  /// unavailable.
  Future<CoverImportResult> import({
    required String path,
    required String outDir,
  });
}

/// [CoverImporter] over `import_cover_file`.
class RustCoverImporter implements CoverImporter {
  const RustCoverImporter();

  @override
  Future<CoverImportResult> import({
    required String path,
    required String outDir,
  }) async => coverImportOf(await importCoverFile(path: path, outDir: outDir));
}

/// The scanner's view of a native import result.
CoverImportResult coverImportOf(CoverImportDto dto) {
  final error = dto.error;
  if (error != null) return CoverImportResult.failed(failureOf(error));
  final key = dto.key;
  if (key == null) {
    return const CoverImportResult.failed(
      NativeFailure(kind: 'corrupt', transient: false),
    );
  }
  return CoverImportResult.done(key: key, colors: coverColorsOfDto(dto.colors));
}
