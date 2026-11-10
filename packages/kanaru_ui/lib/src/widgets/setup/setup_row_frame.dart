import 'package:material_ui/material_ui.dart';

import '../../layout/form_factor.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';

/// Layout shared by the rows inside a setup card: leading widget, title with
/// optional subtitle, trailing widget. 56 dp tall on mobile, 48 on desktop,
/// no background of its own (the card shows through) and no divider.
class SetupRowFrame extends StatelessWidget {
  const SetupRowFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleStyle,
    this.sharedTrailing = false,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Defaults to `bodyLarge`.
  final TextStyle? titleStyle;

  /// The trailing widget is wide and may shrink (a value text): it takes two
  /// fifths of the free width, right aligned, instead of its natural width.
  final bool sharedTrailing;

  /// Minimum row height for the current form factor.
  static double minHeight(BuildContext context) =>
      FormFactor.of(context) == FormFactor.mobile
      ? KLayout.minTarget + KSpace.x2
      : KLayout.minTarget;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight(context)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KSpace.x4,
          vertical: KSpace.x2,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: scheme.onSurfaceVariant),
                child: leading!,
              ),
              const KGap(KSpace.x4),
            ],
            Expanded(
              flex: sharedTrailing ? 3 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: titleStyle ?? textTheme.bodyLarge,
                    child: title,
                  ),
                  if (subtitle != null)
                    DefaultTextStyle.merge(
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      child: subtitle!,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const KGap(KSpace.x3),
              if (sharedTrailing)
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing!,
                  ),
                )
              else
                trailing!,
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
