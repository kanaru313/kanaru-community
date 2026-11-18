import '../../../../l10n/gen/app_localizations.dart';
import 'add_to_playlist_model.dart';

/// The toast after adding, from the numbers of [s].
///
/// The suffix strings carry their own leading `, `, so parts are joined by
/// plain concatenation; a second sentence (playlists deleted meanwhile) is
/// joined with `. `.
String addToPlaylistMessage(AppLocalizations l10n, AddSummary s) {
  // Nothing was written anywhere (every target gone, nothing created).
  if (s.failed) return l10n.playlistAddFailed;

  final one = s.playlists == 1;
  final name = s.singleName ?? '';
  final b = StringBuffer();
  if (s.nothingNew) {
    b.write(
      one
          ? l10n.plAddNothingNewOne(name)
          : l10n.plAddNothingNewMany(s.playlists),
    );
  } else if (one) {
    b.write(l10n.plAddAddedToOne(s.singleAdded, name));
    if (s.singleSkipped > 0) b.write(l10n.plAddSkippedSuffix(s.singleSkipped));
    if (s.moved > 0) b.write(l10n.plAddMovedSuffix(s.moved));
  } else {
    b.write(
      l10n.playlistAddedSummary(s.songs, s.playlists, s.created, s.skipped),
    );
    if (s.moved > 0) b.write(l10n.plAddMovedSuffix(s.moved));
  }
  if (s.dropped > 0) b.write(l10n.plAddDroppedSuffix(s.dropped));
  if (s.gone > 0) b.write('. ${l10n.playlistAddedGone(s.gone)}');
  return b.toString();
}
