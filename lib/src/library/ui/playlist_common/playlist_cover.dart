import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../media/domain/cover_files.dart';
import '../../domain/playlists/playlist_ids.dart';
import '../../state/custom_cover_providers.dart';
import '../browse/item_covers.dart';
import 'auto_cover_art.dart';

/// Side, in decoded pixels, of the `thumb` cover files.
const _thumbPx = 256;

/// The file size to decode for a tile of [side] logical pixels: `full` when
/// the decoded side exceeds the thumb, else the thumb.
CoverSize playlistCoverFileSize(double side, double devicePixelRatio) =>
    side * devicePixelRatio > _thumbPx ? CoverSize.full : CoverSize.thumb;

/// Cover of a playlist (decorative: the name next to it names the item).
///
/// A playlist shows the cover the user chose, else its automatic cover: a
/// mosaic of 2 to 4 song covers, the single cover of 1, or a placeholder for
/// none. Favorites has no custom cover: it always shows its automatic one. With
/// [automaticOnly] a custom cover is ignored (the Edit preview of a staged
/// "automatic cover").
///
/// Small tiles read the thumb files and big ones (a header) the full files;
/// see [playlistCoverFileSize].
class PlaylistCover extends StatelessWidget {
  const PlaylistCover({
    super.key,
    required this.uid,
    required this.autoCoverKeys,
    required this.dimension,
    this.radius,
    this.automaticOnly = false,
  });

  final String uid;

  /// 0 to 4 cover keys of the automatic cover.
  final List<String> autoCoverKeys;
  final double dimension;
  final BorderRadius? radius;
  final bool automaticOnly;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final radius = this.radius ?? KRadius.sm;
    final keys = autoCoverKeys.take(4).toList();
    // Longest side of the tile a cover is drawn in.
    final autoSide = keys.length == 4 ? dimension / 2 : dimension;
    final automatic = _automatic(
      context,
      keys,
      playlistCoverFileSize(autoSide, dpr),
      radius,
    );
    return ExcludeSemantics(
      child: automaticOnly || uid == PlaylistUids.favorites
          ? automatic
          : ItemCover(
              item: (kind: CustomCoverKind.playlist, itemKey: uid),
              seed: uid,
              automaticCoverKey: keys.firstOrNull,
              dimension: dimension,
              radius: radius,
              thumb: playlistCoverFileSize(dimension, dpr) == CoverSize.thumb,
              automatic: automatic,
            ),
    );
  }

  Widget _automatic(
    BuildContext context,
    List<String> keys,
    CoverSize size,
    BorderRadius radius,
  ) {
    if (keys.isEmpty) {
      final scheme = Theme.of(context).colorScheme;
      return _IconTile(
        icon: KIcons.playlists,
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        dimension: dimension,
        radius: radius,
      );
    }
    return autoCoverArt(
      keys: keys,
      seed: uid,
      size: size,
      dimension: dimension,
      radius: radius,
    );
  }
}

/// Icon on a flat tile: the cover of a playlist with no song cover.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.dimension,
    required this.radius,
  });

  /// Icon side as a share of the tile side.
  static const double iconShare = 0.42;

  final IconData icon;
  final Color background;
  final Color foreground;
  final double dimension;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: dimension,
    child: DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: radius),
      child: Center(
        child: Icon(icon, size: dimension * iconShare, color: foreground),
      ),
    ),
  );
}
