import 'package:material_ui/material_ui.dart';

import '../../../media/domain/cover_files.dart';
import '../../../playback/ui/track_cover.dart';

/// Cover of an album (decorative: the title next to it names the item), in every place the app draws one (tile, grid card,
/// page header). The one place that decides which picture an album shows:
/// today the cover of its tracks, else a placeholder coloured from [itemKey]
/// (the encoded `AlbumKey`). A cover the user chose for the album is resolved
/// here, ahead of [coverKey], once that source exists.
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
    child: TrackCover(
      coverKey: coverKey,
      seed: itemKey,
      size: CoverSize.thumb,
      dimension: dimension,
      radius: radius,
    ),
  );
}

/// Round photo of an artist, resolved like [AlbumCover]: today the cover of
/// the artist's newest album that has one, else a letter placeholder seeded by
/// [name]. [itemKey] is the encoded `ArtistKey`, the key a user-chosen photo
/// is stored under.
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
    child: TrackCover(
      coverKey: coverKey,
      seed: name,
      size: CoverSize.thumb,
      dimension: dimension,
      circle: true,
    ),
  );
}
