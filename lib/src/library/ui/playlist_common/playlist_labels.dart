import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_models.dart';
import '../saved_queues/saved_queue_labels.dart';

/// Name a playlist is shown under: Favorites has a localized name (its stored
/// name is not shown), a saved queue the date it was saved (never "Today": a
/// file or a picker outlives the day), every other playlist its own.
String playlistDisplayName(AppLocalizations l10n, PlaylistSummary summary) {
  final queue = summary.savedQueue;
  if (queue != null) return savedQueueExportName(l10n, queue.savedAt);
  return summary.isFavorites ? l10n.playlistFavoritesName : summary.name;
}
