import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// The ⋮ button of a tile, card or page: opens the item's menu. [onPressed]
/// is told whether the button was activated with the keyboard, so the menu can
/// focus its first row.
class LibraryMoreButton extends StatelessWidget {
  const LibraryMoreButton({
    super.key,
    required this.onPressed,
    this.large = false,
  });

  final void Function({required bool viaKeyboard}) onPressed;

  /// For a page's hero row: a larger icon and box.
  final bool large;

  @override
  Widget build(BuildContext context) => KMoreButton(
    tooltip: AppLocalizations.of(context).libraryMenuMore,
    onPressed: onPressed,
    large: large,
  );
}
