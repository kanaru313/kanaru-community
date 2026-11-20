import 'dart:async';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/history/history_models.dart';
import '../songs/song_tile.dart';
import 'history_labels.dart';
import 'history_remove_toast.dart';
import 'history_row_menu.dart';

/// The songs a tap on a row of one day queues, in the order the day shows
/// them: each song once at its first play, the ones that cannot play left
/// out. Built once per day and shared by its rows.
class HistoryDayQueue {
  HistoryDayQueue(List<HistoryPlay> plays) {
    final seen = <int, int>{};
    final ids = <TrackId>[];
    for (final p in plays) {
      final t = p.track;
      if (!canPlayTrack(t) || seen.containsKey(t.id.value)) continue;
      seen[t.id.value] = ids.length;
      ids.add(t.id);
    }
    this.ids = ids;
    _index = seen;
  }

  late final List<TrackId> ids;
  late final Map<int, int> _index;

  /// Place of [track] in [ids]; 0 for a song that is not in it.
  int indexOf(TrackId track) => _index[track.value] ?? 0;
}

/// One play of the timeline: a [SongTile] whose third line says when the
/// play began and which time it was ("21:42 · play #6").
///
/// A tap plays the day from this song. Only the newest play of the playing
/// song is [current] (the others would all light up). A play whose file is
/// gone is dimmed, says "can't play" and answers a tap with a toast. The
/// Delete key removes the play. The ⋮ menu is the song's menu plus "History of
/// this song" and "Remove from history"; a missing play's menu holds only
/// those two.
class HistoryRow extends StatelessWidget {
  const HistoryRow({
    super.key,
    required this.play,
    required this.queue,
    required this.markCurrent,
  });

  final HistoryPlay play;
  final HistoryDayQueue queue;

  /// True for the newest play of its song in the shown list.
  final bool markCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final missing = !canPlayTrack(play.track);
    return SongTile(
      info: play.track,
      index: queue.indexOf(play.track.id),
      ids: queue.ids,
      playContext: PlayContext(
        PlayContextKind.history,
        label: l10n.historyTitle,
      ),
      markCurrent: markCurrent,
      unavailable: missing,
      detailLine: historyRowLine(l10n, play, missing: missing),
      menuExtras: missing ? const [] : historyRowMenuItems(l10n, play),
      onMenu: missing ? missingPlayMenu(context, play) : null,
      onDelete: () => unawaited(removeHistoryPlay(context, play)),
      onUnavailableTap: () => showAppSnackBar(context, l10n.historyMissingTap),
    );
  }
}
