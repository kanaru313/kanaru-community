import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../media/domain/cover_files.dart';
import '../../../media/domain/track_info.dart';
import '../../../media/domain/track_lines.dart';
import '../../../playback/ui/track_cover.dart';

/// Side of the cover in the header of the queue row menu.
const double queueRowMenuCoverSide = 56;

/// The top of the queue row menu: the song's row (cover, title, artist,
/// `album • year`), with the text of a media card. No `›`: the queue menu
/// has no song info.
class QueueRowMenuHeader extends StatelessWidget {
  const QueueRowMenuHeader({super.key, required this.info});

  final TrackInfo info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final soft = KMediaCardMetrics.lineStyle(text)
        ?.copyWith(color: scheme.onSurfaceVariant);
    final album = trackAlbumLine(info);
    return Row(
      children: [
        ExcludeSemantics(
          child: TrackCover(
            coverKey: info.coverKey,
            seed: info.coverSeed,
            size: CoverSize.thumb,
            dimension: queueRowMenuCoverSide,
            radius: BorderRadius.circular(10),
          ),
        ),
        const KGap(KSpace.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KMediaCardMetrics.titleStyle(text)
                    ?.copyWith(color: scheme.onSurface),
              ),
              Text(
                trackArtistLine(info),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: soft,
              ),
              if (album.isNotEmpty)
                Text(
                  album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: soft,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
