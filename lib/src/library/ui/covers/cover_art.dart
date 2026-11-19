import 'dart:io';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/ui/track_cover.dart';
import '../../state/covers/cover_dialog_options.dart';
import '../../state/custom_cover_providers.dart';
import '../playlist_common/playlist_cover.dart';

/// Corner radius of the 48 dp row thumbs of the cover dialog.
const BorderRadius coverThumbRadius = KMediaCard.coverRadius;

/// Corner radius of the square preview frame (like the app's covers).
const BorderRadius coverFrameRadius = BorderRadius.all(Radius.circular(14));

/// The automatic cover of the item, drawn at [dimension]: the song cover of an
/// album or artist (letter-less placeholder when none), the 1 to 4 cover
/// mosaic of a playlist. Never reads the custom cover.
class AutomaticCoverArt extends StatelessWidget {
  const AutomaticCoverArt({
    super.key,
    required this.kind,
    required this.itemKey,
    required this.options,
    required this.dimension,
    required this.radius,
  });

  final CustomCoverKind kind;
  final String itemKey;
  final CoverDialogOptions options;
  final double dimension;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    if (kind == CustomCoverKind.playlist) {
      return PlaylistCover(
        uid: itemKey,
        autoCoverKeys: options.automaticCoverKeys,
        dimension: dimension,
        radius: radius,
        automaticOnly: true,
      );
    }
    final artist = kind == CustomCoverKind.artist;
    return TrackCover(
      coverKey: options.automaticCoverKeys.firstOrNull,
      seed: artist && options.itemName.isNotEmpty ? options.itemName : itemKey,
      size: playlistCoverFileSize(
        dimension,
        MediaQuery.devicePixelRatioOf(context),
      ),
      dimension: dimension,
      radius: radius,
      circle: artist,
    );
  }
}

/// An image file (preview or thumb) at [dimension], decoded at display size.
class FileCoverArt extends StatelessWidget {
  const FileCoverArt({
    super.key,
    required this.file,
    required this.seed,
    required this.dimension,
    required this.radius,
    this.circle = false,
  });

  final File file;
  final String seed;
  final double dimension;
  final BorderRadius radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => KCover(
    image: FileImage(file),
    size: dimension,
    placeholderSeed: seed,
    radius: radius,
    circle: circle,
  );
}
