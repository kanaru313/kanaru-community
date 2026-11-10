import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../media/domain/cover_files.dart';
import '../../../playback/ui/track_cover.dart';
import '../../state/browse/custom_cover_index_providers.dart';
import '../../state/custom_cover_providers.dart';

/// Cover of an album (decorative: the title next to it names the item), in every place the app draws one (tile, grid card,
/// page header). The one place that decides which picture an album shows:
/// the cover the user chose, else the cover of its tracks ([coverKey]), else a
/// placeholder coloured from [itemKey] (the encoded `AlbumKey`).
class AlbumCover extends StatelessWidget {
  const AlbumCover({
    super.key,
    required this.itemKey,
    required this.coverKey,
    required this.dimension,
    this.radius,
  });

  final String itemKey;
  final String? coverKey;
  final double dimension;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: _ItemCover(
      item: (kind: CustomCoverKind.album, itemKey: itemKey),
      seed: itemKey,
      dimension: dimension,
      radius: radius,
      automatic: TrackCover(
        coverKey: coverKey,
        seed: itemKey,
        size: CoverSize.thumb,
        dimension: dimension,
        radius: radius,
      ),
    ),
  );
}

/// Round photo of an artist, resolved like [AlbumCover]: the photo the user
/// chose, else the cover of the artist's newest album that has one, else a
/// letter placeholder seeded by [name]. [itemKey] is the encoded `ArtistKey`,
/// the key a user-chosen photo is stored under.
class ArtistCover extends StatelessWidget {
  const ArtistCover({
    super.key,
    required this.itemKey,
    required this.name,
    required this.coverKey,
    required this.dimension,
  });

  final String itemKey;
  final String name;
  final String? coverKey;
  final double dimension;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: _ItemCover(
      item: (kind: CustomCoverKind.artist, itemKey: itemKey),
      seed: name,
      dimension: dimension,
      circle: true,
      automatic: TrackCover(
        coverKey: coverKey,
        seed: name,
        size: CoverSize.thumb,
        dimension: dimension,
        circle: true,
      ),
    ),
  );
}

/// Shows the user's picture of [item] when it has one, else [automatic].
///
/// A list holds thousands of these, so the check is the per-kind index (one
/// stream, `select`ed to this item's answer). Only an item that has a custom
/// cover opens the per-item file stream. The file goes through [KCover], which
/// decodes at display size. While the file resolves, when it is gone and when
/// it cannot be decoded, [automatic] is on screen.
class _ItemCover extends ConsumerWidget {
  const _ItemCover({
    required this.item,
    required this.seed,
    required this.dimension,
    required this.automatic,
    this.radius,
    this.circle = false,
  });

  final CustomCoverItem item;
  final String seed;
  final double dimension;
  final BorderRadius? radius;
  final bool circle;
  final Widget automatic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(hasCustomCoverProvider(item))) return automatic;
    final File? file = ref.watch(customCoverFileProvider(item)).value;
    if (file == null) return automatic;
    return KCover(
      image: FileImage(file),
      size: dimension,
      placeholderSeed: seed,
      radius: radius,
      circle: circle,
      // A file that exists but cannot be decoded shows the source cover.
      errorFallback: automatic,
    );
  }
}
