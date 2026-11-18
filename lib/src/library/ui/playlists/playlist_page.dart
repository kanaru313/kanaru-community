import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_ids.dart';
import '../detail/detail_header.dart';
import '../library_locations.dart';

/// One playlist, or Favorites (uid `favorites`). Placeholder until the
/// playlist screens replace the body.
class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFavorites = uid == PlaylistUids.favorites;
    // Favorites is also a sidebar item: on desktop the header stays a root
    // header (no back); on mobile every playlist page is a child of the tab.
    final isDesktop = FormFactor.of(context) == FormFactor.desktop;
    return DetailFrame(
      title: isFavorites ? l10n.libraryNavFavorites : l10n.navPlaylists,
      fallback: LibraryLocations.playlists,
      titleInContent: false,
      showBack: !(isFavorites && isDesktop),
      child: KEmpty(
        icon: isFavorites ? KIcons.favorites : KIcons.playlists,
        message: l10n.appComingSoon,
      ),
    );
  }
}
