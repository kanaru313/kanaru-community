import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';

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
  });

  final Widget title;
  final Widget? subtitle;
  final List<Widget> children;

  /// False when [children] bring their own card (the permission card).
  final bool card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KSpace.x1),
          child: Semantics(
            header: true,
            child: DefaultTextStyle.merge(
              style: textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
              child: title,
            ),
          ),
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
          Material(
            color: scheme.surfaceContainerLow,
            shape: KShape.of(KRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          )
        else
          ...children,
      ],
    );
  }
}
