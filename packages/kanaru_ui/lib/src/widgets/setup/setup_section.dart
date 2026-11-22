import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import '../k_help_icon.dart';
import 'setup_section_pulse.dart';

/// A group of a setup page: a heading, an optional caption and a rounded
/// tonal card holding [children] (rows). Rows are separated by space and
/// their own height, never by lines.
class SetupSection extends StatelessWidget {
  const SetupSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.card = true,
    this.hint,
    this.hintTooltip,
    this.hintTitle,
    this.action,
  }) : assert(
         hint == null || hintTooltip != null,
         'a hint needs the accessible name of its icon',
       );

  final Widget title;
  final Widget? subtitle;
  final List<Widget> children;

  /// A note about the whole section, shown behind an ⓘ after the title and
  /// read as the section's description. Only Settings sections use it.
  final String? hint;

  /// Accessible name of the ⓘ button; required with [hint].
  final String? hintTooltip;

  /// Heading of the sheet / panel a long [hint] opens in.
  final String? hintTitle;

  /// A text button beside the title (for example "Cập nhật tất cả"). From
  /// 1.5x text scale it moves under the title.
  final Widget? action;

  /// From this text scale [action] drops under the title.
  static const double _stackScale = 1.5;

  /// False when [children] bring their own card (the permission card).
  final bool card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stacked =
        action != null &&
        MediaQuery.textScalerOf(context).scale(14) / 14 >= _stackScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KSpace.x1),
          child: _heading(context, stacked),
        ),
        if (subtitle != null) ...[
          const KGap(KSpace.x1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpace.x1),
            child: DefaultTextStyle.merge(
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              child: subtitle!,
            ),
          ),
        ],
        const KGap(KSpace.x2),
        if (card)
          _pulsing(
            context,
            Material(
              color: scheme.surfaceContainerLow,
              shape: KShape.of(KRadius.lg),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          )
        else
          ...children,
      ],
    );
  }

  /// Wraps the card in the pulse border when a [SetupSectionPulse] is above.
  Widget _pulsing(BuildContext context, Widget cardWidget) {
    final animation = SetupSectionPulse.maybeOf(context);
    if (animation == null) return cardWidget;
    return SetupCardPulse(
      animation: animation,
      radius: KRadius.lg,
      child: cardWidget,
    );
  }

  Widget _heading(BuildContext context, bool stacked) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            header: true,
            hint: hint,
            child: DefaultTextStyle.merge(
              style: textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
              child: title,
            ),
          ),
        ),
        if (hint != null)
          KHelpIcon(message: hint!, tooltip: hintTooltip!, title: hintTitle),
      ],
    );
    if (action == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: titleRow,
      );
    }
    if (!stacked) {
      return Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: titleRow,
            ),
          ),
          action!,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRow,
        Align(alignment: AlignmentDirectional.centerEnd, child: action),
      ],
    );
  }
}
