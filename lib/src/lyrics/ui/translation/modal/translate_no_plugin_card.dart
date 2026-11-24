import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';

/// "Chưa có tiện ích dịch": shown instead of the service rows when no
/// translate plugin is installed. [onOpenStore] opens the plugin store on the
/// translation plugins.
class TranslateNoPluginCard extends StatelessWidget {
  const TranslateNoPluginCard({super.key, required this.onOpenStore});

  final VoidCallback onOpenStore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x2,
        KSpace.x1,
        KSpace.x2,
        KSpace.x2,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.surfaceContainerHighest,
          shape: KShape.of(KRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x4,
            vertical: KSpace.x6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                KIcons.extension,
                size: KIconSize.xl,
                color: scheme.onSurfaceVariant,
              ),
              const KGap(KSpace.x2),
              Text(
                l10n.lyricsTranslateNoPluginTitle,
                textAlign: TextAlign.center,
                style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const KGap(KSpace.x1),
              Text(
                l10n.lyricsTranslateNoPluginBody,
                textAlign: TextAlign.center,
                style: theme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const KGap(KSpace.x3),
              KModalButton(
                label: l10n.lyricsTranslateOpenStore,
                onPressed: onOpenStore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
