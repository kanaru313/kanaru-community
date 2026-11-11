import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';

/// The lyrics card of the mobile page while lyrics do not exist yet: dimmed,
/// "Coming soon", not tappable.
class LyricsCardPlaceholder extends StatelessWidget {
  const LyricsCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.5,
      child: Semantics(
        enabled: false,
        label: '${l10n.playbackLyricsCard} · ${l10n.appComingSoon}',
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: KRadius.lg,
            ),
            child: Padding(
              padding: const EdgeInsets.all(KSpace.x4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.playbackLyricsCard,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    l10n.appComingSoon,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
