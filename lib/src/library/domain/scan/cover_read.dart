import '../../../media/domain/cover_colors.dart';
import 'native_failure.dart';

enum CoverStatus { found, noCover, failed }

/// The cover result of one track (pure mirror of the Rust DTO).
class CoverRead {
  const CoverRead({
    required this.trackId,
    required this.status,
    this.key,
    this.made = false,
    this.thumbRel,
    this.fullRel,
    this.colors,
    this.error,
    this.cacheFailure = false,
  });

  final int trackId;
  final CoverStatus status;

  /// Cover key (`<2 hex>/<32 hex>`) of a found cover.
  final String? key;

  /// The files were written by this call (colours come with them).
  final bool made;

  /// Paths Rust wrote, relative to the cache folder.
  final String? thumbRel, fullRel;

  /// Null when the files already existed, and for a near-gray cover.
  final CoverColors? colors;
  final NativeFailure? error;

  /// The failure is about writing under the cache folder (the batch stopped).
  final bool cacheFailure;
}

/// The colours of one cached cover.
class CoverColorsRead {
  const CoverColorsRead({required this.key, this.colors, this.error});

  final String key;

  /// Null for a near-gray cover (no colours by design) and on [error].
  final CoverColors? colors;
  final NativeFailure? error;
}
