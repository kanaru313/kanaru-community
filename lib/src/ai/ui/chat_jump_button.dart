import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';

/// The round "Xuống cuối" button: shows while the reader is more than a screen
/// above the newest message. 40 dp on the desktop shell, 48 dp on the phone.
class ChatJumpButton extends StatelessWidget {
  const ChatJumpButton({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final instant = MediaQuery.disableAnimationsOf(context);
    final size = FormFactor.of(context) == FormFactor.desktop ? 40.0 : 48.0;
    final tooltip = AppLocalizations.of(context).aiChatJumpToEnd;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: instant ? Duration.zero : KMotion.fast,
        child: Semantics(
          button: true,
          label: tooltip,
          excludeSemantics: true,
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: SizedBox.square(
                  dimension: size,
                  child: Icon(
                    KIcons.arrowDown,
                    size: KIconSize.md,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
