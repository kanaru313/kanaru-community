import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/track_info.dart';
import '../../../media/domain/track_lines.dart';
import '../../../playback/ui/track_cover.dart';
import '../browse/library_labels.dart';
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
      title: info.title,
      line2: trackArtistLine(info),
      line3: trackAlbumLine(info),
      leading: ExcludeSemantics(
        child: TrackCover(
          coverKey: info.coverKey,
          seed: info.albumKey?.encode() ?? info.title,
          size: CoverSize.thumb,
          dimension: KMediaCard.coverSize,
          radius: KMediaCard.coverRadius,
        ),
      ),
      top: duration == null ? null : Text(formatClock(duration)),
      bottom: SongFavoriteButton(trackId: info.id),
      // The queue's handle: 40 dp on desktop, 48 dp on mobile.
      accessory: KDragHandle(
        index: index,
        tooltip: AppLocalizations.of(context).libraryPanelReorder,
      ),
      trailing: LibraryMoreButton(
        onPressed: ({required viaKeyboard}) =>
            openSongMenu(context, info, viaKeyboard: viaKeyboard),
      ),
    );
  }
}
