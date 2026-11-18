import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../browse/library_list_scaffold.dart';

/// The heading "Playlist của bạn" under the hub (mobile).
class PlaylistsYoursHeader extends StatelessWidget {
  const PlaylistsYoursHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = libraryGutter(context);
    return SliverToBoxAdapter(
      child: Semantics(
        header: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, KSpace.x2, gutter, KSpace.x1),
          child: Text(
            AppLocalizations.of(context).playlistYours,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
