import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../online/online_labels.dart';

/// The "Đồng bộ" / "Thường" pill: synced lyrics are `tertiaryContainer`,
/// plain ones a quiet neutral.
class LyricsKindPill extends StatelessWidget {
  const LyricsKindPill({super.key, required this.synced});

  final bool synced;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: synced
            ? scheme.tertiaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: KRadius.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KSpace.x2,
          vertical: KSpace.x1,
        ),
        child: Text(
          onlineKindLabel(AppLocalizations.of(context), synced: synced),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: synced
                ? scheme.onTertiaryContainer
                : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
