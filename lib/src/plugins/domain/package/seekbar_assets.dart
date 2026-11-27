import 'dart:typed_data';

import 'image_header.dart';
import 'package_limits.dart';
import 'package_problem.dart';
import 'seekbar_spec.dart';
import 'zip_reader.dart';

/// The bare file name of a package path `assets/<name>`, or null when [path]
/// is not one.
String? assetNameOf(String path) {
  if (!path.startsWith('assets/')) return null;
  final name = path.substring(7);
  return assetFileName.hasMatch(name) ? name : null;
}

/// Every `assets/` path [spec] names, each once, in spec order.
Set<String> referencedAssets(SeekbarSpec spec) {
  final thumb = spec.thumb;
  return {
    ?switch (thumb) {
      SpriteThumb(:final image) => image,
      LottieThumb(:final lottie) => lottie,
      null => null,
    },
    ?spec.emitter?.image,
  };
}

/// The assets a seekbar package keeps: the files [spec] names, inflated from
/// [contents] and checked, by bare file name. A package that carries code, is
/// over its caps, or lacks or breaks a named file is refused. Files the spec
/// does not name are dropped (never inflated).
Map<String, Uint8List> readSeekbarAssets({
  required SeekbarSpec spec,
  required ZipContents contents,
  required int zipSize,
}) {
  if (contents.scripts.isNotEmpty) {
    // Seekbar plugins carry no code.
    final first = (contents.scripts.keys.toList()..sort()).first;
    throw PackageProblemError(UnsafeEntry('src/$first'));
  }
  if (zipSize > maxSeekbarPackageBytes) {
    throw const PackageProblemError(PackageTooLarge());
  }
  final assets = <String, Uint8List>{};
  for (final path in referencedAssets(spec)) {
    final name = assetNameOf(path);
    final entry = name == null ? null : contents.assetHeaders[name];
    if (name == null || entry == null) {
      throw PackageProblemError(MissingAsset(path));
    }
    assets[name] = entry.inflate(assetByteCap(name));
  }
  var unpacked = contents.manifest.length + (contents.icon?.length ?? 0);
  for (final data in assets.values) {
    unpacked += data.length;
  }
  if (unpacked > maxSeekbarUnpackedBytes) {
    throw const PackageProblemError(PackageTooLarge());
  }
  checkSeekbarAssets(spec, assets);
  return Map.unmodifiable(assets);
}

/// Checks the images [spec] names by header only (never decoded): format,
/// extension, size, and that a sprite's width divides by its frame count.
/// Throws [PackageProblemError] naming the asset.
void checkSeekbarAssets(SeekbarSpec spec, Map<String, Uint8List> assets) {
  for (final path in referencedAssets(spec)) {
    final name = assetNameOf(path);
    final data = name == null ? null : assets[name];
    if (name == null || data == null) {
      throw PackageProblemError(MissingAsset(path));
    }
    if (name.endsWith('.json')) continue;
    final header = readImageHeader(name, data);
    if (header.problem != null) {
      throw PackageProblemError(InvalidAsset(path, header.problem!));
    }
    final thumb = spec.thumb;
    if (thumb is SpriteThumb &&
        thumb.image == path &&
        header.width % thumb.frames != 0) {
      throw PackageProblemError(InvalidAsset(path, 'frames'));
    }
  }
}
