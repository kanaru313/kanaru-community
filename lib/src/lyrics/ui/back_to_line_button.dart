import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';

/// The tonal pill "Về dòng đang hát" shown while the user has taken the
/// scroll: it fades and slides in at the bottom centre and is gone from the
/// tree when hidden.
class BackToLineButton extends StatelessWidget {
  const BackToLineButton({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.normal;
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: KMotion.emphasized,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: visible
          ? FilledButton.tonalIcon(
              key: const ValueKey('back-to-line'),
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, KSpace.x8),
              ),
              icon: const Icon(KIcons.arrowUp, size: KIconSize.xs),
              label: Text(AppLocalizations.of(context).lyricsBackToLine),
            )
          : const SizedBox.shrink(key: ValueKey('no-back-to-line')),
    );
  }
}
