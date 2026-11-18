import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_models.dart';

/// Opens the "add to playlist" picker for [request]. Placeholder until the
/// picker replaces the body: shows the coming-soon notice.
Future<void> showAddToPlaylist(
  BuildContext context,
  AddToPlaylistRequest request,
) async {
  showAppSnackBar(context, AppLocalizations.of(context).appComingSoon);
}
