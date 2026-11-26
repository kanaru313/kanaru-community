import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_icon_button.dart';
import 'k_inline_notice_action.dart';
import 'k_inline_notice_layout.dart';

/// Colour intent of a [KInlineNotice]. [normal] and [error] only change the
/// icon colour; [errorFilled] and [primaryFilled] tint the whole strip
/// (`errorContainer` / `primaryContainer`) for a page-level banner.
/// [warning] is a tertiary strip that blocks something (an alert for screen
/// readers); [quiet] has no background and is a gentle note that blocks
/// nothing. Both use the compact 13 / 18 text and always put their buttons
/// under the text.
enum KInlineNoticeTone {
  normal,
  error,
  errorFilled,
  primaryFilled,
  warning,
  quiet,
}

/// Strip inside a page: icon, optional bold title, message that wraps, up to
/// two text actions and an optional × ([onDismiss]).
///
/// With one action and no ×, the strip of a plain tone keeps its action at the
/// right of the text (under it from 150 % text scale). With a second action,
/// a × or a [KInlineNoticeTone.warning] / [KInlineNoticeTone.quiet] tone, the
/// buttons sit in a row under the text (the first is the main one, they wrap
/// when narrow) and the × is at the top right. The caller removes the strip
/// when the state it describes changes, and animates that itself.
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
    this.actionBusy = false,
    this.actionBusyLabel,
    this.prominentAction = false,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.onDismiss,
    this.dismissLabel,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction are set together',
       ),
       assert(
         (secondaryActionLabel == null) == (onSecondaryAction == null),
         'secondaryActionLabel and onSecondaryAction are set together',
       ),
       assert(
         secondaryActionLabel == null || actionLabel != null,
         'a second action needs a first one',
       ),
       assert(
         (onDismiss == null) == (dismissLabel == null),
         'onDismiss needs dismissLabel (tooltip and screen-reader label)',
       );

  final IconData icon;
  final String message;
  final String? title;
  final KInlineNoticeTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Longer label for screen readers; defaults to [actionLabel].
  final String? actionSemanticsLabel;

  /// The action is running: its label becomes a small spinner and it cannot
  /// be pressed again. [actionBusyLabel] is what a screen reader says then.
  final bool actionBusy;
  final String? actionBusyLabel;

  /// The action is the main thing to do here: a filled button instead of a
  /// text button.
  final bool prominentAction;

  /// Second, always plain, action next to the first (under the text).
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  /// Shows a × at the top right; the caller removes the strip.
  final VoidCallback? onDismiss;

  /// Tooltip and screen-reader label of the ×; required with [onDismiss].
  final String? dismissLabel;

  /// From this text scale the action moves under the text.
  static const double _stackScale = 1.5;

  bool get _compact =>
      tone == KInlineNoticeTone.warning || tone == KInlineNoticeTone.quiet;

  bool get _filled =>
      tone == KInlineNoticeTone.errorFilled ||
      tone == KInlineNoticeTone.primaryFilled ||
      tone == KInlineNoticeTone.warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme;
    final textTheme = switch (tone) {
      KInlineNoticeTone.warning || KInlineNoticeTone.quiet => base.bodySmall,
      _ => base.bodyMedium,
    };
    final hasAction = actionLabel != null;
    final underText =
        _compact || secondaryActionLabel != null || onDismiss != null;
    final stacked =
        hasAction &&
        !underText &&
        MediaQuery.textScalerOf(context).scale(14) / 14 >= _stackScale;

    final filled = _filled;
    final background = switch (tone) {
      KInlineNoticeTone.errorFilled => scheme.errorContainer,
      KInlineNoticeTone.primaryFilled => scheme.primaryContainer,
      KInlineNoticeTone.warning => scheme.tertiaryContainer,
      KInlineNoticeTone.quiet => null,
      _ => scheme.surfaceContainerHigh,
    };
    final foreground = switch (tone) {
      KInlineNoticeTone.errorFilled => scheme.onErrorContainer,
      KInlineNoticeTone.primaryFilled => scheme.onPrimaryContainer,
      KInlineNoticeTone.warning => scheme.onTertiaryContainer,
      KInlineNoticeTone.quiet => scheme.onSurfaceVariant,
      _ => scheme.onSurface,
    };
    final iconColor = filled || tone == KInlineNoticeTone.quiet
        ? foreground
        : tone == KInlineNoticeTone.error
        ? scheme.error
        : scheme.primary;
    final iconSize = _compact
        ? (tone == KInlineNoticeTone.quiet ? KIconSize.xs : 18.0)
        : KIconSize.md;

    final iconWidget = Padding(
      padding: EdgeInsets.only(top: _compact ? KSpace.x1 : KSpace.x2),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
    final text = Padding(
      padding: EdgeInsets.symmetric(vertical: _compact ? 0 : KSpace.x3),
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
          if (message.isNotEmpty)
            Text(message, style: textTheme?.copyWith(color: foreground)),
        ],
      ),
    );
    final action = hasAction
        ? KInlineNoticeAction(
            label: actionLabel!,
            onTap: onAction,
            foreground: foreground,
            filled: filled,
            primary: true,
            prominent: prominentAction,
            busy: actionBusy,
            busyLabel: actionBusyLabel,
            semanticsLabel: actionSemanticsLabel,
          )
        : null;
    final second = secondaryActionLabel == null
        ? null
        : KInlineNoticeAction(
            label: secondaryActionLabel!,
            onTap: onSecondaryAction,
            foreground: foreground,
            filled: filled,
            primary: false,
          );
    final dismiss = onDismiss == null
        ? null
        : KIconButton(
            icon: KIcons.close,
            size: KIconSize.xs,
            tooltip: dismissLabel!,
            color: foreground,
            padding: const EdgeInsets.all(KSpace.x2),
            onPressed: onDismiss,
          );
    final content = KInlineNoticeLayout(
      icon: iconWidget,
      text: text,
      action: action,
      second: second,
      dismiss: dismiss,
      underText: underText,
      stacked: stacked,
      compact: _compact,
    );

    final EdgeInsets padding = _compact
        ? (tone == KInlineNoticeTone.quiet
              ? const EdgeInsets.symmetric(
                  horizontal: KSpace.x2,
                  vertical: KSpace.x1,
                )
              : const EdgeInsets.all(KSpace.x3))
        : EdgeInsets.fromLTRB(
            KSpace.x4,
            KSpace.x1,
            hasAction || onDismiss != null ? KSpace.x2 : KSpace.x4,
            KSpace.x1,
          );
    return Semantics(
      container: true,
      // A quiet note is read in order but never interrupts.
      liveRegion: tone != KInlineNoticeTone.quiet,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: KRadius.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: _compact ? 0 : KSpace.x9 + KSpace.x1,
          ),
          child: Padding(padding: padding, child: content),
        ),
      ),
    );
  }
}
