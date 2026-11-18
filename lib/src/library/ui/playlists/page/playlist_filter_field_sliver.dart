import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import 'playlist_filter_state.dart';

/// The open filter field of a playlist page, under the list bar. [alive] says
/// whether the page still stands when the debounced text arrives.
class PlaylistFilterFieldSliver extends StatelessWidget {
  const PlaylistFilterFieldSliver({
    super.key,
    required this.filter,
    required this.gutter,
    required this.alive,
  });

  final PlaylistFilterState filter;
  final double gutter;
  final bool Function() alive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x2),
        child: KFilterField(
          controller: filter.controller,
          hint: l10n.libraryFilterSongsHint,
          closeTooltip: l10n.libraryFilterClose,
          onChanged: (text) => filter.typed(text, alive),
          onClose: filter.close,
        ),
      ),
    );
  }
}
