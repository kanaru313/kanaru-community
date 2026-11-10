import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';

/// The source line of Now Playing: a kind prefix and the name captured when
/// playback started (`Album · Dark Side`). Text only; it opens nothing.
String playContextText(AppLocalizations l10n, PlayContext? context) {
  if (context == null) return '';
  final kind = switch (context.kind) {
    PlayContextKind.songs => l10n.playbackSourceSongs,
    PlayContextKind.album => l10n.playbackSourceAlbum,
    PlayContextKind.artist => l10n.playbackSourceArtist,
    PlayContextKind.genre => l10n.playbackSourceGenre,
    PlayContextKind.language => l10n.playbackSourceLanguage,
    PlayContextKind.folder => l10n.playbackSourceFolder,
    PlayContextKind.favorites => l10n.playbackSourceFavorites,
    PlayContextKind.selection => l10n.playbackSourceSelection,
    PlayContextKind.queue => l10n.playbackSourceQueue,
  };
  final label = context.label;
  return label == null || label.isEmpty ? kind : '$kind · $label';
}
