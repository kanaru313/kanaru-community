import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import 'setup_row_frame.dart';

/// A folder row: icon, name, path (and a count), an optional badge next to
/// the name and a remove button. Used for music folders and exclusions.
class SetupPathRow extends StatelessWidget {
  const SetupPathRow({
    super.key,
    required this.icon,
    required this.title,
    required this.path,
    this.count,
    this.badge,
    this.onRemove,
    this.removeTooltip,
  });

  final IconData icon;
  final Widget title;
  final Widget path;

  /// For example "242 songs"; shown after the path.
  final Widget? count;

  /// Small label next to the title, for example "Suggested".
  final Widget? badge;

  /// Null hides the remove button.
  final VoidCallback? onRemove;

  /// Tooltip and spoken label of the remove button.
  final String? removeTooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SetupRowFrame(
      leading: Icon(icon),
      title: Row(
        children: [
          Flexible(child: title),
          if (badge != null) ...[
            const KGap(KSpace.x2),
            DecoratedBox(
              decoration: ShapeDecoration(
                shape: KShape.of(KRadius.full),
                color: scheme.secondaryContainer,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KSpace.x2,
                  vertical: KSpace.x1 / 2,
                ),
                child: DefaultTextStyle.merge(
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                  child: badge!,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          path,
          if (count != null) ...[const Text(' · '), count!],
        ],
      ),
      trailing: onRemove == null
          ? null
          : IconButton(
              icon: const Icon(KIcons.close),
              tooltip: removeTooltip,
              onPressed: onRemove,
              constraints: const BoxConstraints.tightFor(
                width: KLayout.minTarget,
                height: KLayout.minTarget,
              ),
            ),
    );
  }
}
