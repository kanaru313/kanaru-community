import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// "Ảnh bìa" and the item's name. No close button and no help icon: the
/// dialog closes with Cancel, Esc, Back, the scrim or a drag down.
class CoverDialogHead extends StatelessWidget {
  const CoverDialogHead({
    super.key,
    required this.itemName,
    required this.onPick,
  });

  final String itemName;

  /// Opens the image chooser; null while the dialog is saving.
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    return Padding(
      // Desktop: 24 above the title. Mobile: the sheet's grip already sits
      // above. 4 below on both.
      padding: EdgeInsets.fromLTRB(
        KSpace.x6,
        mobile ? 0 : KSpace.x6,
        KSpace.x6,
        KSpace.x1,
      ),
      child: Row(
        // The button is centred on the title block (title + item name).
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Loose flex 2 : 3 instead of Expanded: at large text neither the
          // title nor the button is squeezed to nothing (the label
          // ellipsizes, the title wraps), and the button stays on the right.
          Flexible(flex: 2, child: _titles(context, theme)),
          const KGap(KSpace.x3),
          Flexible(
            flex: 3,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: KSpace.x6),
              ),
              onPressed: onPick,
              icon: const Icon(KIcons.imageAdd, size: KIconSize.sm),
              label: Text(
                mobile ? l10n.coverPickMobile : l10n.coverPickDesktop,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titles(BuildContext context, ThemeData theme) {
    return Column(
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
    );
  }
}
