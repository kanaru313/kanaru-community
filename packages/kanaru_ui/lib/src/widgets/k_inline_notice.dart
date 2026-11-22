import 'package:material_ui/material_ui.dart';

import '../tokens/k_icon_size.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';

/// Colour intent of a [KInlineNotice]. [normal] and [error] only change the
/// icon colour; [errorFilled] and [primaryFilled] tint the whole strip
/// (`errorContainer` / `primaryContainer`) for a page-level banner.
enum KInlineNoticeTone { normal, error, errorFilled, primaryFilled }

/// Strip inside a page: icon, optional bold title, message that wraps, and an
/// optional text action. No close button: the caller removes it when the
/// state it describes changes, and animates that itself.
class KInlineNotice extends StatelessWidget {
  const KInlineNotice({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.tone = KInlineNoticeTone.normal,
    this.actionLabel,
    this.onAction,
    this.actionSemanticsLabel,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction are set together',
       );

  final IconData icon;
  final String message;
  final String? title;
  final KInlineNoticeTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Longer label for screen readers; defaults to [actionLabel].
  final String? actionSemanticsLabel;

  /// From this text scale the action moves under the text.
  static const double _stackScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme.bodyMedium;
    final hasAction = actionLabel != null;
    final stacked =
        hasAction &&
        MediaQuery.textScalerOf(context).scale(14) / 14 >= _stackScale;

    final filled =
        tone == KInlineNoticeTone.errorFilled ||
        tone == KInlineNoticeTone.primaryFilled;
    final background = switch (tone) {
      KInlineNoticeTone.errorFilled => scheme.errorContainer,
      KInlineNoticeTone.primaryFilled => scheme.primaryContainer,
      _ => scheme.surfaceContainerHigh,
    };
    final foreground = switch (tone) {
      KInlineNoticeTone.errorFilled => scheme.onErrorContainer,
      KInlineNoticeTone.primaryFilled => scheme.onPrimaryContainer,
      _ => scheme.onSurface,
    };
    final iconColor = filled
        ? foreground
        : tone == KInlineNoticeTone.error
        ? scheme.error
        : scheme.primary;

    final iconWidget = Padding(
      padding: const EdgeInsets.only(top: KSpace.x2),
      child: Icon(icon, size: KIconSize.md, color: iconColor),
    );
    final text = Padding(
      padding: const EdgeInsets.symmetric(vertical: KSpace.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: textTheme?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(message, style: textTheme?.copyWith(color: foreground)),
        ],
      ),
    );
    final action = hasAction
        ? Semantics(
            container: true,
            button: true,
            enabled: true,
            onTap: onAction,
            label: actionSemanticsLabel ?? actionLabel,
            excludeSemantics: true,
            child: TextButton(
              onPressed: onAction,
              style: filled
                  ? TextButton.styleFrom(foregroundColor: foreground)
                  : null,
              child: Text(actionLabel!),
            ),
          )
        : null;

    final Widget content;
    if (stacked) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconWidget,
              const SizedBox(width: KSpace.x3),
              Expanded(child: text),
            ],
          ),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      );
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          const SizedBox(width: KSpace.x3),
          Expanded(child: text),
          if (action != null) ...[const SizedBox(width: KSpace.x3), action],
        ],
      );
    }

    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: KRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KSpace.x9 + KSpace.x1),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              KSpace.x4,
              KSpace.x1,
              hasAction ? KSpace.x2 : KSpace.x4,
              KSpace.x1,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
