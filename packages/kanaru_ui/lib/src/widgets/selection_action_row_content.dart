import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_space.dart';

/// Inside of a `SelectionActionRow`: the icon, the title with its detail
/// (under it on touch shells, on the same line to the right on desktop) and
/// the `›` of a running card. [color] tints the icon and `›` on a card.
class ActionRowContent extends StatelessWidget {
  const ActionRowContent({
    super.key,
    required this.leading,
    required this.title,
    required this.detail,
    required this.desktop,
    required this.running,
    required this.color,
  });

  final Widget? leading;
  final Widget title;
  final Widget? detail;
  final bool desktop;
  final bool running;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (leading != null) ...[
          IconTheme.merge(
            data: IconThemeData(
              color: color ?? scheme.primary,
              size: desktop ? KIconSize.sm : KIconSize.md,
            ),
            child: leading!,
          ),
          SizedBox(width: desktop ? KSpace.x3 : KSpace.x4),
        ],
        Expanded(
          child: desktop
              ? Row(
                  children: [
                    Flexible(child: title),
                    if (detail != null) ...[
                      const SizedBox(width: KSpace.x3),
                      Expanded(child: detail!),
                    ],
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, ?detail],
                ),
        ),
        if (running) ...[
          const SizedBox(width: KSpace.x2),
          Icon(KIcons.chevronRight, size: KIconSize.md, color: color),
        ],
      ],
    );
  }
}
