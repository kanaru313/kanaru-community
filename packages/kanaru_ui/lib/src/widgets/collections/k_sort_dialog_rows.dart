import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import '../k_icon_button.dart';

/// Gap between two chosen rows.
const double sortRowGap = 6;

/// "Đã chọn" / "Chưa chọn" section header; [count] is the small number after
/// "Đã chọn".
class SortSectionHeader extends StatelessWidget {
  const SortSectionHeader({super.key, required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpace.x3,
          KSpace.x3,
          KSpace.x3,
          sortRowGap,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              title,
              style: text.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (count != null) ...[
              const KGap(KSpace.x2),
              Text(
                '$count',
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A criterion not chosen yet: icon · name · plus. The whole row adds it
/// (tap, Enter, Space); the plus is the same action drawn as a button.
class SortOffRow extends StatelessWidget {
  const SortOffRow({
    super.key,
    required this.name,
    required this.icon,
    required this.addLabel,
    required this.onAdd,
  });

  final String name;
  final IconData? icon;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: addLabel,
      excludeSemantics: true,
      onTap: onAdd,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: KShape.of(KRadius.md),
          hoverColor: scheme.onSurface.withValues(alpha: 0.08),
          focusColor: scheme.onSurface.withValues(alpha: 0.10),
          highlightColor: scheme.onSurface.withValues(alpha: 0.10),
          onTap: onAdd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: KLayout.minTarget),
            child: Padding(
              padding: const EdgeInsets.only(left: KSpace.x3),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: KIconSize.md,
                      color: scheme.onSurfaceVariant,
                    ),
                    const KGap(KSpace.x3),
                  ],
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  // Same action as the row: the button shows it and gives the
                  // press feedback, the row owns focus and semantics.
                  ExcludeFocus(
                    child: KIconButton(
                      tooltip: addLabel,
                      icon: KIcons.add,
                      size: KIconSize.sm,
                      padding: const EdgeInsets.all(KSpace.x3),
                      onPressed: onAdd,
                    ),
                  ),
                  const KGap(KSpace.x1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lift of the row being dragged: scales up and gains a shadow over
/// [KMotion.fast]; no motion when animations are off.
Widget sortRowLift(BuildContext context, Widget child) {
  final instant = MediaQuery.disableAnimationsOf(context);
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: instant ? 1 : 0, end: 1),
    duration: instant ? Duration.zero : KMotion.fast,
    curve: Curves.easeOut,
    builder: (context, t, child) => Transform.scale(
      scale: 1 + 0.02 * t,
      child: Material(
        color: const Color(0x00000000),
        elevation: 6 * t,
        shadowColor: Theme.of(context).colorScheme.shadow,
        shape: KShape.of(KRadius.md),
        child: child,
      ),
    ),
    child: child,
  );
}
