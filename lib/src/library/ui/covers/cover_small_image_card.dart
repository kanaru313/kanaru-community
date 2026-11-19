import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Short side, in pixels, under which a picked image is called small.
const int smallCoverSide = 500;

/// Warning under the preview: the picked image is small and may look blurry.
/// A live region, so a screen reader announces it when the image is picked.
class CoverSmallImageCard extends StatelessWidget {
  const CoverSmallImageCard({
    super.key,
    required this.width,
    required this.height,
  });

  final int width;
  final int height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: scheme.onTertiaryContainer);
    return Padding(
      // 4 above (after the preview's 8), 16 at the sides, 8 below.
      padding: const EdgeInsets.fromLTRB(
        KSpace.x4,
        KSpace.x1,
        KSpace.x4,
        KSpace.x2,
      ),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: KRadius.md,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KSpace.x4,
              vertical: KSpace.x3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  KIcons.warning,
                  size: KIconSize.sm,
                  color: scheme.onTertiaryContainer,
                ),
                const KGap(KSpace.x3),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).coverSmallImage(width, height),
                    style: style,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
