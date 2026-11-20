import 'package:material_ui/material_ui.dart';

import '../tokens/k_icon_size.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';

/// Colour intent of a [KInlineNotice]: only the icon changes.
enum KInlineNoticeTone { normal, error }

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

    final iconWidget = Padding(
      padding: const EdgeInsets.only(top: KSpace.x2),
      child: Icon(
        icon,
        size: KIconSize.md,
        color: tone == KInlineNoticeTone.error ? scheme.error : scheme.primary,
      ),
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
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(message, style: textTheme?.copyWith(color: scheme.onSurface)),
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
            child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
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
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: KRadius.md,
        ),
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
