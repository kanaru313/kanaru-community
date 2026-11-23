import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/online/lyrics_source.dart';

String _names(List<LyricsSource> sources) =>
    sources.map((s) => s.name).join(', ');

/// "Chưa thấy lời ưng ý?": the end of the list, offering the sources that are
/// off. They are asked only when the user taps [Tìm]; settings do not change.
class PickerMoreCard extends StatelessWidget {
  const PickerMoreCard({
    super.key,
    required this.pending,
    required this.onSearch,
  });

  final List<LyricsSource> pending;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x2,
        KSpace.x2,
        KSpace.x2,
        KSpace.x1,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.surfaceContainerHighest,
          shape: KShape.of(KRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x4,
            vertical: KSpace.x3,
          ),
          child: Row(
            spacing: KSpace.x3,
            children: [
              Icon(KIcons.online, color: scheme.primary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.lyricsPickerMoreTitle,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.lyricsPickerMoreBody(
                        pending.length,
                        _names(pending),
                      ),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              KModalButton(
                label: l10n.lyricsPickerMoreAction,
                emphasis: KModalEmphasis.tonal,
                onPressed: onSearch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nothing to list: no source is on, or the ones that are on found nothing.
/// With sources that are off it offers to ask them, only on this tap.
class PickerEmpty extends StatelessWidget {
  const PickerEmpty({
    super.key,
    required this.enabledCount,
    required this.pending,
    required this.onSearchOff,
  });

  final int enabledCount;
  final List<LyricsSource> pending;

  /// Null when asking the sources that are off makes no sense (a filter
  /// shows one source only).
  final VoidCallback? onSearchOff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final headline = enabledCount == 0
        ? l10n.lyricsPickerEmptyNone
        : l10n.lyricsPickerEmptyNotFound(enabledCount);
    final canAsk = pending.isNotEmpty && onSearchOff != null;
    // On the mockup's tinted card (`surfaceContainerHighest`, radius 20); the
    // card fills the pane because `KEmpty` needs a bounded height to scroll
    // at large text.
    return Padding(
      padding: const EdgeInsets.all(KSpace.x2),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: KShape.of(KRadius.lg),
        ),
        child: KEmpty(
          icon: KIcons.search,
          title: canAsk ? headline : null,
          message: canAsk
              ? l10n.lyricsPickerEmptyOff(pending.length, _names(pending))
              : headline,
          action: canAsk
              ? KModalButton(
                  label: l10n.lyricsPickerEmptyAction(pending.length),
                  onPressed: onSearchOff,
                )
              : null,
        ),
      ),
    );
  }
}
