import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_lines.dart';
import '../../domain/history/history_models.dart';
import '../../domain/history/top_queue.dart';
import '../browse/library_list_scaffold.dart' show libraryRowGutter;
import '../history/history_locations.dart';
import '../menus/menu_model.dart';
import '../menus/open_menu.dart';
import '../songs/song_tile.dart';

/// The ranked songs as a list of rows. [entries] are in rank order; a tap on
/// a row queues the playable ones from that row on.
Widget mostPlayedRows(BuildContext context, List<TopEntry> entries) {
  final l10n = AppLocalizations.of(context);
  final queue = TopQueue(entries);
  final playContext = PlayContext(
    PlayContextKind.mostPlayed,
    label: l10n.libraryNavMostPlayed,
  );
  final gutter = libraryRowGutter(context);
  return SliverPadding(
    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x4),
    sliver: SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return KeyedSubtree(
          // Keyed by song: a row whose place now holds another song starts
          // over, so a swipe never acts on the wrong one.
          key: ValueKey(entry.track.id.value),
          child: MostPlayedRow(
            entry: entry,
            queue: queue,
            playContext: playContext,
          ),
        );
      },
    ),
  );
}

/// One ranked song: a [SongTile] with its rank on the cover and `10 lượt ·
/// album • năm` as third line. A song whose file is gone keeps its rank, is
/// dimmed, says "không phát được", answers a tap with a toast and has only
/// the song's history in its menu. The ⋮ menu is the song's menu plus "Lịch
/// sử bài này"; there is nothing to delete here.
class MostPlayedRow extends StatelessWidget {
  const MostPlayedRow({
    super.key,
    required this.entry,
    required this.queue,
    required this.playContext,
  });

  final TopEntry entry;
  final TopQueue queue;

  /// Where a tap starts the playback from (the list's source).
  final PlayContext playContext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final track = entry.track;
    final missing = !canPlayTrack(track);
    final plays = l10n.historyMostPlayedPlays(entry.count);
    final history = _historyRow(l10n, track.id.value);
    return SongTile(
      info: track,
      index: queue.indexOf(track.id),
      ids: queue.ids,
      playContext: playContext,
      rank: entry.rank,
      unavailable: missing,
      detailLine: missing
          ? l10n.historyMostPlayedRowMissing(plays)
          : _detailLine(plays, trackAlbumLine(track)),
      menuExtras: missing ? const [] : [history],
      onMenu: missing ? _missingMenu(context, history) : null,
      onUnavailableTap: () => showAppSnackBar(context, l10n.historyMissingTap),
    );
  }

  /// `10 lượt · album • năm`; the play count alone when the song has no album.
  static String _detailLine(String plays, String album) =>
      album.isEmpty ? plays : '$plays · $album';

  /// "Lịch sử bài này": the song's own plays, from the Most played page.
  static MenuItemSpec _historyRow(AppLocalizations l10n, int trackId) =>
      MenuItemSpec(
        // The id of the "go to" rows: no dedicated id exists for this one.
        MenuItemId.link,
        icon: KIcons.history,
        title: l10n.historyMenuTrackHistory,
        action: MenuAction.go(HistoryLocations.mostPlayedTrack(trackId)),
      );

  /// The menu of a song whose file is gone: its head and the history row.
  Future<void> Function({required bool viaKeyboard}) _missingMenu(
    BuildContext context,
    MenuItemSpec history,
  ) =>
      ({required viaKeyboard}) => openMenu(context, (container, env) async {
        final info = entry.track;
        return MenuSpec(
          header: MenuHeader(
            image: MenuImage.track,
            title: info.title,
            subtitle: [
              trackArtistLine(info),
              env.l10n.historyMenuMissing,
            ].where((s) => s.isNotEmpty).join(' · '),
            seed: info.coverSeed,
          ),
          groups: [
            [history],
          ],
        );
      }, viaKeyboard: viaKeyboard);
}
