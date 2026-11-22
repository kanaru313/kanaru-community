import 'package:intl/intl.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../domain/history/history_days.dart';
import '../../domain/playlists/playlist_models.dart';
import '../browse/library_labels.dart';
import '../history/history_labels.dart';

/// Name of a saved queue: the time it was saved, `Today · 21:17`,
/// `Yesterday · …`, the weekday up to six days back, then `dd/MM` (the same
/// year) or `dd/MM/yyyy`. [today] is the local day the screen is on; days are
/// compared on the calendar, so a 23 or 25 hour day still counts as one.
String savedQueueName(AppLocalizations l10n, int savedAt, DateTime today) {
  final day = localDay(DateTime.fromMillisecondsSinceEpoch(savedAt));
  final label = switch (dayLabelKind(day, today)) {
    DayLabelKind.date => DateFormat(
      day.year == today.year ? 'dd/MM' : 'dd/MM/yyyy',
    ).format(day),
    _ => historyDayLabel(l10n, day, today),
  };
  return l10n.savedQueueName(label, historyClock(l10n, savedAt));
}

/// The name an exported file starts from: it never says "Today", the file
/// outlives the day (`Queue 21/11/2026 21:17`).
String savedQueueExportName(AppLocalizations l10n, int savedAt) =>
    l10n.savedQueueExportName(
      DateFormat('dd/MM/yyyy HH:mm')
          .format(DateTime.fromMillisecondsSinceEpoch(savedAt)),
    );

/// `24 songs · 1 h 41 min`, plus `· 2 songs gone` when [missing] is above 0.
String savedQueueStatsLine(
  AppLocalizations l10n,
  PlaylistSummary summary, {
  int missing = 0,
}) => [
  l10n.librarySongCount(summary.trackCount),
  formatTotalDuration(l10n, summary.durationMs),
  if (missing > 0) l10n.savedQueueMissing(missing),
].join(' · ');

/// Where the queue was playing from, as `From album X`. Null when it is not
/// known: a queue built by "play next" / "add to queue", a kind this build
/// does not know, or a source without the name it needs.
String? savedQueueSourceLine(AppLocalizations l10n, SavedQueueInfo info) {
  final kind = _kindOf(info);
  final name = info.contextLabel?.trim();
  final named = name != null && name.isNotEmpty ? name : null;
  return switch (kind) {
    null || PlayContextKind.queue => null,
    PlayContextKind.album =>
      named == null ? null : l10n.savedQueueFromAlbum(named),
    PlayContextKind.artist =>
      named == null ? null : l10n.savedQueueFromArtist(named),
    PlayContextKind.genre =>
      named == null ? null : l10n.savedQueueFromGenre(named),
    PlayContextKind.language =>
      named == null ? null : l10n.savedQueueFromLanguage(named),
    PlayContextKind.folder =>
      named == null ? null : l10n.savedQueueFromFolder(named),
    PlayContextKind.playlist =>
      named == null ? null : l10n.savedQueueFromPlaylist(named),
    PlayContextKind.favorites => l10n.savedQueueFromFavorites,
    PlayContextKind.songs => l10n.savedQueueFromSongs,
    PlayContextKind.selection => l10n.savedQueueFromSelection,
    PlayContextKind.history => l10n.savedQueueFromList(
      named ?? l10n.libraryNavHistory,
    ),
    PlayContextKind.mostPlayed => l10n.savedQueueFromList(
      named ?? l10n.libraryNavMostPlayed,
    ),
  };
}

PlayContextKind? _kindOf(SavedQueueInfo info) {
  final name = info.contextKind;
  return name == null ? null : PlayContextKind.values.asNameMap()[name];
}

/// The context a saved queue plays under: the source it was saved from, else
/// a plain queue.
PlayContext savedQueuePlayContext(SavedQueueInfo info) {
  final kind = _kindOf(info);
  if (kind == null) return const PlayContext(PlayContextKind.queue);
  return PlayContext(kind, ref: info.contextRef, label: info.contextLabel);
}

/// The songs a saved queue can play now, in played order: a missing or hidden
/// one is left out, and so is anything that is not on disk.
List<TrackId> savedQueuePlayableIds(PlaylistDetail detail) => [
  for (final e in detail.entries)
    if (e.info.status == TrackAvailability.present) e.info.id,
];
