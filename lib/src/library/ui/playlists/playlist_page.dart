import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// One playlist, or Favorites (uid `favorites`). Placeholder until the
/// playlist screens replace the body.
class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KEmptyPage(
      title: l10n.navPlaylists,
      icon: KIcons.playlists,
      message: l10n.appComingSoon,
    );
  }
}
