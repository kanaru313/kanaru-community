import 'package:material_ui/material_ui.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KEmptyPage(
      title: l10n.navPlaylists,
      icon: KIcons.playlists,
      message: l10n.emptyPlaylists,
    );
  }
}
