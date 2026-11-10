import '../../../media/domain/cover_colors.dart';
import '../../../rust/api/covers.dart';
import '../../domain/scan/cover_read.dart';
import 'native_error_mapping.dart';

/// Start of the detail Rust gives to a failure writing under the cache
/// folder (`kanaru_bridge/src/api/covers.rs` `cache_error`).
const String coverCacheErrorPrefix = 'cover cache';

/// Makes covers and reads their colours. The Rust calls run on its
/// background pool.
abstract interface class CoverMaker {
  /// One result per item (matched by track id). May throw when the native
  /// library is unavailable.
  Future<List<CoverRead>> extract({
    required String cacheDir,
    required List<({int trackId, String path})> items,
    required bool sidecars,
  });

  /// Colours of already cached covers.
  Future<List<CoverColorsRead>> colorsFor({
    required String cacheDir,
    required List<String> keys,
  });
}

/// [CoverMaker] over `extract_covers_batch`; the only user of the generated
/// covers API.
class RustCoverMaker implements CoverMaker {
  const RustCoverMaker();

  @override
  Future<List<CoverRead>> extract({
    required String cacheDir,
    required List<({int trackId, String path})> items,
    required bool sidecars,
  }) async {
    final dtos = await extractCoversBatch(
      cacheDir: cacheDir,
      items: [
        for (final i in items)
          CoverRequestDto(trackId: i.trackId, path: i.path),
      ],
      sidecars: sidecars,
    );
    return [
      for (final d in dtos)
        CoverRead(
          trackId: d.trackId,
          status: switch (d.status) {
            CoverStatusDto.found => CoverStatus.found,
            CoverStatusDto.noCover => CoverStatus.noCover,
            CoverStatusDto.failed => CoverStatus.failed,
          },
          key: d.key,
          made: d.made,
          thumbRel: d.thumbRel,
          fullRel: d.fullRel,
          colors: coverColorsOfDto(d.colors),
          error: d.error == null ? null : failureOf(d.error!),
          cacheFailure:
              d.error?.detail.startsWith(coverCacheErrorPrefix) ?? false,
        ),
    ];
  }

  @override
  Future<List<CoverColorsRead>> colorsFor({
    required String cacheDir,
    required List<String> keys,
  }) async {
    final dtos = await coverColorsFor(cacheDir: cacheDir, keys: keys);
    return [
      for (final d in dtos)
        CoverColorsRead(
          key: d.key,
          colors: coverColorsOfDto(d.colors),
          error: d.error == null ? null : failureOf(d.error!),
        ),
    ];
  }
}

// The generated `Int64List` is a `List<BigInt>` to the analyzer (the web
// variant) and a `List<int>` at run time on the native targets, hence the
// `Object` loop.
CoverColors? coverColorsOfDto(CoverColorsDto? c) => c == null
    ? null
    : CoverColors(
        seed: c.seed,
        palette: [
          for (final Object v in c.palette) v is BigInt ? v.toInt() : v as int,
        ],
      );
