import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/ui/library_locations.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/track_info.dart';

/// Artist names of [info] in tag order (the single [TrackInfo.artist] when the
/// track has no split list).
List<String> trackArtistNames(TrackInfo info) => [
  if (info.artists.isNotEmpty)
    ...info.artists
  else if (info.artist != null && info.artist!.trim().isNotEmpty)
    info.artist!,
];

bool canGoToAlbum(TrackInfo? info) => info?.albumKey != null;

bool canGoToArtist(TrackInfo? info) =>
    info != null && trackArtistNames(info).isNotEmpty;

/// Opens the track's album page. [beforeNavigate] runs first: the host closes
/// what covers the page (a sheet).
void goToAlbum(
  BuildContext context,
  TrackInfo info, {
  VoidCallback? beforeNavigate,
}) {
  final key = info.albumKey;
  if (key == null) return;
  final router = GoRouter.of(context);
  beforeNavigate?.call();
  router.go(LibraryLocations.album(key));
}

/// Opens the artist page; with several artists asks which one first.
Future<void> goToArtist(
  BuildContext context,
  TrackInfo info, {
  VoidCallback? beforeNavigate,
}) async {
  final names = trackArtistNames(info);
  if (names.isEmpty) return;
  final router = GoRouter.of(context);
  var name = names.first;
  if (names.length > 1) {
    final l10n = AppLocalizations.of(context);
    final chosen = await showSelectionPicker<String>(
      context,
      title: Text(l10n.playbackPickArtist),
      selected: null,
      options: [
        for (final n in names) SelectionOption(value: n, title: Text(n)),
      ],
    );
    if (chosen == null) return;
    name = chosen;
  }
  beforeNavigate?.call();
  router.go(LibraryLocations.artist(ArtistKey(groupKey(name))));
}
