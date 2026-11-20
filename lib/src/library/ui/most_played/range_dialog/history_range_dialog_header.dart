import 'package:flutter/services.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/history/history_span.dart';

/// Title of the range dialog: a small caption and, under it, a tinted block
/// with the picked days ("07/10 – 24/10/2026") in bold and, below that, how
/// many days they are or what to pick next. Days not picked yet show as dim
/// placeholders. Both lines stay on one line in every state, so the dialog
/// never changes height; the whole block is one live region.
class HistoryRangeDialogHeader extends StatelessWidget {
  const HistoryRangeDialogHeader({
    super.key,
    required this.start,
    required this.end,
  });

  final DateTime? start;
  final DateTime? end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final first = start;
    final last = end;
    final strong = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onPrimaryContainer,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final dim = strong?.copyWith(
      fontWeight: FontWeight.w500,
      color: scheme.onPrimaryContainer.withValues(alpha: 0.55),
    );
    final String span;
    final Widget title;
    if (first != null && last != null) {
      span = historySpanText(first, last);
      title = Text(
        span,
        style: strong,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      final startText = first == null
          ? l10n.historyRangeStartPlaceholder
          : _fullDay(first);
      final endText = l10n.historyRangeEndPlaceholder;
      span = '$startText – $endText';
      title = Text.rich(
        TextSpan(
          style: strong,
          children: [
            TextSpan(text: startText, style: first == null ? dim : null),
            const TextSpan(text: ' – '),
            TextSpan(text: endText, style: dim),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final line2 = _hint(l10n, first, last);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.historyRangeDialogCaption,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KSpace.x1),
        Semantics(
          container: true,
          liveRegion: true,
          excludeSemantics: true,
          label: '$span, $line2',
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: KRadius.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KSpace.x4,
                  vertical: KSpace.x3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 2),
                    Text(
                      line2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _fullDay(DateTime d) => historySpanText(d, d);

/// What to do next, or how many days are picked.
String _hint(AppLocalizations l10n, DateTime? start, DateTime? end) {
  if (start == null) return l10n.historyRangePickStart;
  if (end == null) return l10n.historyRangePickEnd;
  return l10n.historyRangeDays(rangeDays(start, end));
}

/// The month in view with arrows to the months around it; an arrow is off
/// when there is no month to go to.
class HistoryMonthBar extends StatelessWidget {
  const HistoryMonthBar({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    return Row(
      children: [
        KIconButton(
          icon: KIcons.chevronLeft,
          tooltip: loc.previousMonthTooltip,
          padding: const EdgeInsets.all(KSpace.x3),
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            loc.formatMonthYear(month),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        KIconButton(
          icon: KIcons.chevronRight,
          tooltip: loc.nextMonthTooltip,
          padding: const EdgeInsets.all(KSpace.x3),
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// Cancel and Save on the right (a second line when the text is large). [onSave] null turns Save off.
class HistoryRangeFooter extends StatelessWidget {
  const HistoryRangeFooter({super.key, required this.onSave});

  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    // Wraps instead of overflowing at a large text scale.
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: KSpace.x2,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancelButtonLabel),
        ),
        TextButton(
          onPressed: onSave,
          child: Text(AppLocalizations.of(context).historyRangeSave),
        ),
      ],
    );
  }
}

/// Runs [save] on Enter, unless a button has the focus: then Enter belongs to
/// that button (Cancel, a month arrow), which handles it further up.
KeyEventResult saveOnEnter(
  BuildContext context,
  KeyEvent event,
  VoidCallback save,
) {
  if (event is! KeyDownEvent) return KeyEventResult.ignored;
  final key = event.logicalKey;
  if (key != LogicalKeyboardKey.enter &&
      key != LogicalKeyboardKey.numpadEnter) {
    return KeyEventResult.ignored;
  }
  var onButton = KIconButton.ownsPrimaryFocus();
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
    if (e.widget is ButtonStyleButton) {
      onButton = true;
      return false;
    }
    return true;
  });
  if (onButton) return KeyEventResult.ignored;
  save();
  return KeyEventResult.handled;
}
