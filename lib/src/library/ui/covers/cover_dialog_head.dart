import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// "Ảnh bìa" and the item's name. No close button and no help icon: the
/// dialog closes with Cancel, Esc, Back, the scrim or a drag down.
class CoverDialogHead extends StatelessWidget {
  const CoverDialogHead({super.key, required this.itemName});

  final String itemName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x6,
        KSpace.x4,
        KSpace.x6,
        KSpace.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              AppLocalizations.of(context).coverDialogTitle,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          if (itemName.isNotEmpty)
            Text(
              itemName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
