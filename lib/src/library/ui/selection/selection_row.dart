import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/track_info.dart';
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
      line2: songArtistLine(info),
      line3: songAlbumLine(info),
      leading: ExcludeSemantics(
        child: TrackCover(
          coverKey: info.coverKey,
          seed: info.albumKey?.encode() ?? info.title,
          size: CoverSize.thumb,
          dimension: KMediaCard.coverSize,
          radius: BorderRadius.circular(10),
        ),
      ),
      top: duration == null ? null : Text(formatClock(duration)),
      bottom: SongFavoriteButton(info: info),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Tooltip(
              message: AppLocalizations.of(context).libraryPanelReorder,
              child: const Padding(
                padding: EdgeInsets.all(KSpace.x2),
                child: Icon(KIcons.dragHandle),
              ),
            ),
          ),
          LibraryMoreButton(
            onPressed: ({required viaKeyboard}) =>
                openSongMenu(context, info, viaKeyboard: viaKeyboard),
          ),
        ],
      ),
    );
  }
}
