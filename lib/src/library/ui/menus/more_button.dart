import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// The ⋮ button of a tile, card or page: opens the item's menu.
class LibraryMoreButton extends StatelessWidget {
  const LibraryMoreButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context).libraryMenuMore,
    onPressed: onPressed,
    icon: const Icon(KIcons.moreVert),
  );
}
