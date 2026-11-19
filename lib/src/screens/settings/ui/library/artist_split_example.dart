import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../library/domain/scan/artist_split.dart';
import '../../../../library/domain/scan/read_rules.dart';

/// The line the example splits (artist names, so not translated).
const String artistSplitExample = 'Đen feat. Chi Pu / MIN';

/// Card "Example": [artistSplitExample] split by the rules as they are now,
/// then a note on why the defaults leave `,` and `&` out.
class ArtistSplitExampleCard extends StatelessWidget {
  const ArtistSplitExampleCard({super.key, required this.rules});

  final LibraryReadRules rules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final names = splitArtists(const [
      artistSplitExample,
    ], rules: rules.artistSplit);
    return Material(
      color: scheme.surfaceContainerLow,
      shape: KShape.of(KRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(KSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsArtistSplitExample,
              style: textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const KGap(KSpace.x2),
            Text.rich(
              TextSpan(
                style: textTheme.bodyLarge,
                children: [
                  for (final part in rules.artistSplit.segments(
                    artistSplitExample,
                  ))
                    if (part.separator)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: _SeparatorMark(part.text),
                      )
                    else
                      TextSpan(text: part.text),
                ],
              ),
            ),
            const KGap(KSpace.x2),
            Wrap(
              spacing: KSpace.x2,
              runSpacing: KSpace.x2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  KIcons.arrowForward,
                  size: KIconSize.xs,
                  color: scheme.onSurfaceVariant,
                ),
                for (final name in names) _NamePill(name),
              ],
            ),
            const KGap(KSpace.x3),
            Text(
              l10n.settingsArtistSplitExampleNote,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A separator the rules would split at, highlighted in the example line.
class _SeparatorMark extends StatelessWidget {
  const _SeparatorMark(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(KSpace.x1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// One resulting artist name: a small static pill (not a choice).
class _NamePill extends StatelessWidget {
  const _NamePill(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      shape: KShape.of(KRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KSpace.x3,
          vertical: KSpace.x1,
        ),
        child: Text(
          name,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
