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
    this.closeTooltip,
  });

  /// The name: a text, or the chat's title that can be renamed in place.
  final Widget title;
  final Widget? menu;
  final VoidCallback onClose;

  /// Tooltip of ✕; the generic "Đóng khung" when null.
  final String? closeTooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: KLayout.minTarget + KSpace.x2,
      child: Padding(
        padding: const EdgeInsets.only(left: KSpace.x4, right: KSpace.x2),
        child: Row(
          children: [
            Expanded(child: title),
            ?menu,
            KIconButton(
              icon: KIcons.close,
              tooltip:
                  closeTooltip ??
                  AppLocalizations.of(context).playbackPanelClose,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// A plain name for a right panel header (the queue's).
class RightPanelTitle extends StatelessWidget {
  const RightPanelTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.titleMedium,
  );
}
