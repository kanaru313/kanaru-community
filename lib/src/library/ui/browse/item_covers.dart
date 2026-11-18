import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../media/domain/cover_files.dart';
import '../../../playback/ui/track_cover.dart';
import '../../state/custom_cover_providers.dart';
import '../../state/shown_cover_provider.dart';

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
    child: ItemCover(
      item: (kind: CustomCoverKind.album, itemKey: itemKey),
      seed: itemKey,
      automaticCoverKey: coverKey,
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
    child: ItemCover(
      item: (kind: CustomCoverKind.artist, itemKey: itemKey),
      seed: name,
      automaticCoverKey: coverKey,
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

/// Shows the picture [shownCoverProvider] picks for [item]: the user's, else
/// [automatic].
///
/// A list holds thousands of these, so the provider selects from one index
/// stream per kind; only an item with a custom cover opens its file streams.
/// While the answer is unknown the cover skeleton is drawn (never the source
/// cover first). The file goes through [KCover], which decodes at display
/// size. A file that exists but cannot be decoded falls back to [automatic] at
/// paint time (the provider only knows whether the file exists).
class ItemCover extends ConsumerWidget {
  const ItemCover({
    super.key,
    required this.item,
    required this.seed,
    required this.automaticCoverKey,
    required this.dimension,
    required this.automatic,
    this.radius,
    this.circle = false,
    this.thumb = false,
  });

  /// Draw the 256 px `thumb` file of a custom cover instead of the `full`
  /// one: for small tiles, so a list does not decode 1024 px files (the
  /// thumb path comes from the shown key, no second lookup).
  final bool thumb;

  final CustomCoverItem item;
  final String seed;
  final String? automaticCoverKey;
  final double dimension;
  final BorderRadius? radius;
  final bool circle;
  final Widget automatic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ref.watch(
      shownCoverProvider((item: item, automaticCoverKey: automaticCoverKey)),
    );
    return switch (shown) {
      ShownCoverLoading() => KCover.loading(
        size: dimension,
        radius: radius,
        circle: circle,
      ),
      ShownAutomaticCover() => automatic,
      ShownCustomCover(:final coverKey, :final file) => _custom(
        file,
        thumb ? _thumbOf(coverKey, file) : null,
      ),
    };
  }

  /// The picture of a custom cover [full] file. With a [small] file (the
  /// `thumb` of the same key) the tile decodes that only; a missing thumb
  /// falls back to the full file, a missing full file to [automatic].
  Widget _custom(File full, File? small) {
    final fullCover = KCover(
      image: FileImage(full),
      size: dimension,
      placeholderSeed: seed,
      radius: radius,
      circle: circle,
      errorFallback: automatic,
    );
    if (small == null) return fullCover;
    return KCover(
      image: FileImage(small),
      size: dimension,
      placeholderSeed: seed,
      radius: radius,
      circle: circle,
      errorFallback: fullCover,
    );
  }
}

/// The `thumb` file next to a custom cover's [full] file, derived from the
/// shown cover's own key (the store's layout, `coverRelativePath`), so it
/// always belongs to the picture shown: a cover change never pairs the new
/// key with the old thumb. Null when [full] is not in that layout.
File? _thumbOf(String coverKey, File full) {
  final suffix = coverRelativePath(coverKey, CoverSize.full);
  if (!full.path.endsWith(suffix)) return null;
  final root = full.path.substring(0, full.path.length - suffix.length);
  return File('$root${coverRelativePath(coverKey, CoverSize.thumb)}');
}
