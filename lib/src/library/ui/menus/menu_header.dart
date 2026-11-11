import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../media/domain/cover_files.dart';
import '../../../playback/ui/track_cover.dart';
import '../browse/item_covers.dart';
import 'menu_model.dart';

/// The top of a menu: picture, name and a line under it. The picture is 56
/// on the mobile shell and 64 on desktop.
class MenuHeaderView extends StatelessWidget {
  const MenuHeaderView({super.key, required this.header});

  final MenuHeader header;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final side = FormFactor.of(context) == FormFactor.mobile ? 56.0 : 64.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KSpace.x1),
      child: Row(
        children: [
          _image(context, side),
          const KGap(KSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  header.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (header.subtitle != null && header.subtitle!.isNotEmpty)
                  Text(
                    header.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _image(BuildContext context, double side) {
    final radius = BorderRadius.circular(12);
    switch (header.image) {
      case MenuImage.track:
        return ExcludeSemantics(
          child: TrackCover(
            coverKey: header.coverKey,
            seed: header.seed,
            size: CoverSize.thumb,
            dimension: side,
            radius: radius,
          ),
        );
      case MenuImage.album:
        return AlbumCover(
          itemKey: header.itemKey,
          coverKey: header.coverKey,
          dimension: side,
          radius: radius,
        );
      case MenuImage.artist:
        return ArtistCover(
          itemKey: header.itemKey,
          name: header.title,
          coverKey: header.coverKey,
          dimension: side,
        );
      case MenuImage.tile:
        final colors = KCoverPlaceholderColors.of(
          header.seed,
          Theme.of(context).brightness,
        );
        return _IconTile(
          side: side,
          fill: colors.fill,
          ink: colors.ink,
          icon: header.tileIcon ?? KIcons.songs,
        );
      case MenuImage.folder:
        final scheme = Theme.of(context).colorScheme;
        return _IconTile(
          side: side,
          fill: scheme.secondaryContainer,
          ink: scheme.onSecondaryContainer,
          icon: KIcons.folders,
        );
    }
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.side,
    required this.fill,
    required this.ink,
    required this.icon,
  });

  final double side;
  final Color fill;
  final Color ink;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox.square(
        dimension: side,
        child: Icon(icon, color: ink, size: side * 0.5),
      ),
    ),
  );
}
