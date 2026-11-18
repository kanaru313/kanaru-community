import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_ids.dart';

/// One playlist, or Favorites (uid `favorites`). Placeholder until the
/// playlist screens replace the body.
class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFavorites = uid == PlaylistUids.favorites;
    return KEmptyPage(
      title: isFavorites ? l10n.libraryNavFavorites : l10n.navPlaylists,
      icon: isFavorites ? KIcons.favorites : KIcons.playlists,
      message: l10n.appComingSoon,
    );
  }
}
