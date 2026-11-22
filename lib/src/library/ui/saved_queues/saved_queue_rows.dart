import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_info.dart';
import '../../domain/playlists/playlist_models.dart';
import '../browse/library_list_scaffold.dart';
import '../playlists/page/playlist_page_states.dart' show PlaylistStateSliver;
import '../selection/selection_inset.dart';
import '../songs/song_tile.dart';
import 'saved_queue_labels.dart';

/// The songs part of a saved queue's page, as slivers: the bar
/// `N songs, in played order` (no sort, filter or edit mode: the order is the
/// order they were played in) and the rows. A queue with no entry left shows
/// its empty line in their place.
///
/// A row is a [SongTile]. A song that is not there any more is dimmed, says
/// "not in library", answers a tap with a toast and has no ✕: nothing is
/// edited in a saved queue. A tap on a song that can play starts the playable
/// songs of the queue from that one, under the source the queue was saved
/// from.
List<Widget> savedQueueSlivers(BuildContext context, PlaylistDetail detail) {
  final l10n = AppLocalizations.of(context);
  final info = detail.summary.savedQueue;
  if (detail.entries.isEmpty || info == null) {
    return [
      PlaylistStateSliver(
        child: KEmpty(icon: KIcons.queue, message: l10n.savedQueueNoSongs),
      ),
    ];
  }
  final ids = savedQueuePlayableIds(detail);
  final playContext = savedQueuePlayContext(info);
  // Place of each playable row among the playable ones (the play queue); a
  // song listed twice marks only its first row as the playing one.
  final placeOf = <int>[];
  final firstRow = <int>{};
  final seen = <int>{};
  var place = 0;
  for (var i = 0; i < detail.entries.length; i++) {
    final e = detail.entries[i];
    final playable = e.info.status == TrackAvailability.present;
    placeOf.add(playable ? place++ : 0);
    if (seen.add(e.info.id.value)) firstRow.add(i);
  }
  final gutter = libraryRowGutter(context);
  return [
    KStickyBarSliver(
      height: MediaQuery.textScalerOf(context).scale(KListSortFilterBar.height),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: libraryBarGutter(context)),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l10n.savedQueueBar(detail.summary.trackCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    ),
    SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x4),
      sliver: SliverFixedExtentList(
        itemExtent: KMediaCard.extentOf(MediaQuery.textScalerOf(context)),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final entry = detail.entries[i];
            final playable = entry.info.status == TrackAvailability.present;
            return SongTile(
              // Keyed by entry: a row whose place now holds another entry
              // starts over, so a swipe never acts on the wrong one.
              key: ValueKey(entry.uid),
              info: entry.info,
              index: placeOf[i],
              ids: ids,
              playContext: playContext,
              markCurrent: firstRow.contains(i),
              unavailable: !playable,
              onUnavailableTap: () =>
                  showAppSnackBar(context, l10n.historyMissingTap),
            );
          },
          childCount: detail.entries.length,
          addAutomaticKeepAlives: false,
        ),
      ),
    ),
    const SelectionInsetSliver(),
  ];
}
