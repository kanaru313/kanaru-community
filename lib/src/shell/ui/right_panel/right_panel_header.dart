import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Head of the right panel: name, the content's own menu (chat only) and ✕.
class RightPanelHeader extends StatelessWidget {
  const RightPanelHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.menu,
  });

  final String title;
  final Widget? menu;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: KLayout.minTarget + KSpace.x2,
      child: Padding(
        padding: const EdgeInsets.only(left: KSpace.x4, right: KSpace.x2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ?menu,
            IconButton(
              icon: const Icon(KIcons.close),
              tooltip: AppLocalizations.of(context).playbackPanelClose,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
