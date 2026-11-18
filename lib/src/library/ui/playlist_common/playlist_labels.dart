import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_models.dart';

/// Name a playlist is shown under: Favorites has a localized name (its stored
/// name is not shown), every other playlist its own.
String playlistDisplayName(AppLocalizations l10n, PlaylistSummary summary) =>
    summary.isFavorites ? l10n.playlistFavoritesName : summary.name;
