import 'dart:async';
import 'dart:io';

import '../../../media/domain/cover_colors.dart';
import '../../../rust/api/covers.dart';
import '../../domain/covers/cover_choice.dart';
import '../../domain/covers/cover_preview.dart';
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
  /// folder for custom covers). With [crop] the cover is that square of the
  /// upright original (see [CoverCrop]); null keeps the whole image. May throw
  /// when the native library is unavailable.
  Future<CoverImportResult> import({
    required String path,
    required String outDir,
    CoverCrop? crop,
  });
}

/// [CoverImporter] over `import_cover_file`.
class RustCoverImporter implements CoverImporter {
  const RustCoverImporter();

  @override
  Future<CoverImportResult> import({
    required String path,
    required String outDir,
    CoverCrop? crop,
  }) async => coverImportOf(
    await importCoverFile(
      path: path,
      outDir: outDir,
      crop: coverCropDtoOf(crop),
    ),
  );
}

const int _maxU32 = 0xFFFFFFFF;

/// The native form of [crop] (null stays null). Values the native side reads
/// as `u32` must fit it: a negative or larger one would wrap into a different,
/// valid-looking crop, so it is an [ArgumentError] here.
CoverCropDto? coverCropDtoOf(CoverCrop? crop) {
  if (crop == null) return null;
  for (final v in [crop.left, crop.top, crop.side]) {
    if (v < 0 || v > _maxU32) {
      throw ArgumentError.value(crop, 'crop', 'values must fit a u32');
    }
  }
  return CoverCropDto(left: crop.left, top: crop.top, side: crop.side);
}

/// Start of the name of every preview file `prepare_cover_preview` writes
/// (the cover temp prefix plus `preview-`). Files in the preview folder with
/// this prefix are leftovers when no dialog is open.
const String coverPreviewPrefix = '.kanaru-tmp-preview-';

/// Decodes a chosen image once, upright, for the crop dialog.
abstract interface class CoverPreviewer {
  /// Writes the preview into [outDir] (an absolute folder, created when
  /// missing) and returns it with the upright size of the original. The
  /// caller deletes the file. Permanent failures (undecodable, unsupported,
  /// too large, missing file, a native panic) throw [FormatException];
  /// transient ones (I/O, failing to write under [outDir]) and
  /// `permissionDenied` throw [FileSystemException]. May also throw when the
  /// native library is unavailable.
  Future<CoverPreview> prepare({required String path, required String outDir});
}

/// [CoverPreviewer] over `prepare_cover_preview`.
///
/// A call that takes longer than [timeout] throws [FileSystemException]: the
/// native thread stays busy until a stalled read returns, and a preview it
/// writes late is a leftover for the startup sweep.
class RustCoverPreviewer implements CoverPreviewer {
  const RustCoverPreviewer({this.timeout = const Duration(seconds: 60)});

  final Duration timeout;

  @override
  Future<CoverPreview> prepare({
    required String path,
    required String outDir,
  }) async {
    final CoverPreviewDto dto;
    try {
      dto = await prepareCoverPreview(
        path: path,
        outDir: outDir,
      ).timeout(timeout);
    } on TimeoutException {
      throw FileSystemException('cover preview timed out after $timeout', path);
    }
    return coverPreviewOf(dto, path);
  }
}

/// The preview of a native result for the image at [source], or the
/// exception that tells whether trying again can help.
CoverPreview coverPreviewOf(CoverPreviewDto dto, String source) {
  final error = dto.error;
  final previewPath = dto.previewPath;
  if (error != null) {
    final f = failureOf(error);
    if (f.transient || f.kind == 'permissionDenied') {
      throw FileSystemException('cover preview failed (${f.kind})', source);
    }
    throw FormatException('cannot use as a cover (${f.kind}): $source');
  }
  if (previewPath == null) {
    throw FormatException('cannot use as a cover (no preview): $source');
  }
  return CoverPreview(
    file: File(previewPath),
    width: dto.width,
    height: dto.height,
  );
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
