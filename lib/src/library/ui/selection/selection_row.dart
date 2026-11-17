import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/track_info.dart';
import '../../../media/domain/track_lines.dart';
import '../../../playback/ui/playback_time_label.dart' show formatClock;
import '../../../playback/ui/track_cover.dart';
import '../menus/more_button.dart';
import '../menus/open_menu.dart';
import '../songs/song_tile.dart';

/// One selected song in the expanded panel: cover, three lines, duration and
/// ♥, a drag handle that changes the play order, and the song's menu (which
/// has "Deselect"). [index] is the row's place, for the drag handle.
class SelectedSongRow extends StatelessWidget {
  const SelectedSongRow({super.key, required this.info, required this.index});

  final TrackInfo info;
  final int index;

  @override
  Widget build(BuildContext context) {
    final duration = info.durationMs;
    return KMediaCard(
      // The panel is a surface of its own: no row fill.
      filled: false,
      title: info.title,
      line2: trackArtistLine(info),
      line3: trackAlbumLine(info),
      leading: ExcludeSemantics(
        child: TrackCover(
          coverKey: info.coverKey,
          seed: info.coverSeed,
          size: CoverSize.thumb,
          dimension: KMediaCard.coverSize,
          radius: KMediaCard.coverRadius,
        ),
      ),
      top: duration == null
          ? null
          : Text(formatClock(Duration(milliseconds: duration))),
      bottom: SongFavoriteButton(trackId: info.id),
      // Same box as the row's icon buttons, like the queue's handle.
      accessory: KDragHandle(
        index: index,
        dimension: KIconSize.sm + 2 * KSpace.x2,
        iconSize: KIconSize.sm,
        tooltip: AppLocalizations.of(context).libraryPanelReorder,
      ),
      trailing: LibraryMoreButton(
        onPressed: ({required viaKeyboard}) =>
            openSongMenu(context, info, viaKeyboard: viaKeyboard),
      ),
    );
  }
}
