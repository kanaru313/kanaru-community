import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../media/domain/play_context.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../browse/library_list_scaffold.dart';
import '../../menus/menu_origin.dart';
import '../../songs/song_tile.dart';
import 'playlist_shown_entries.dart';

/// The rows of a playlist: an ordinary song row for each available entry and
/// a dashed "not in library" row for each missing one.
class PlaylistRowsSliver extends StatelessWidget {
  const PlaylistRowsSliver({
    super.key,
    required this.uid,
    required this.shown,
    required this.playContext,
    required this.onRemoveMissing,
  });

  final String uid;
  final ShownEntries shown;
  final PlayContext playContext;

  /// The ✕ of a missing row.
  final void Function(PlaylistEntryView entry) onRemoveMissing;

  @override
  Widget build(BuildContext context) {
    final gutter = libraryRowGutter(context);
    final origin = MenuOrigin.playlist(uid);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x4),
      sliver: SliverFixedExtentList(
        itemExtent: KMediaCard.extentOf(MediaQuery.textScalerOf(context)),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final entry = shown.rows[i];
            // Keyed by entry: a row whose index now holds another entry
            // starts over, so a swipe never acts on the wrong one.
            if (!entry.available) {
              return SongTile(
                key: ValueKey(entry.uid),
                info: entry.info,
                index: 0,
                ids: shown.playable,
                playContext: playContext,
                origin: origin,
                unavailable: true,
                onRemove: () => onRemoveMissing(entry),
              );
            }
            return SongTile(
              key: ValueKey(entry.uid),
              info: entry.info,
              index: shown.playableIndex[i],
              ids: shown.playable,
              playContext: playContext,
              origin: origin,
              markCurrent: shown.firstOfTrack.contains(entry.uid),
            );
          },
          childCount: shown.rows.length,
          addAutomaticKeepAlives: false,
        ),
      ),
    );
  }
}
