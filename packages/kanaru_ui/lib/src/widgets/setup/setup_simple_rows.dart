import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import 'setup_row_frame.dart';

/// A row that shows the current value of a choice and opens its picker when
/// tapped: leading icon, title, value text and a chevron. Pass [anchorKey] to
/// let a desktop picker open anchored under the row.
class SetupValueRow extends StatelessWidget {
  const SetupValueRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.anchorKey,
  });

  final IconData icon;
  final Widget title;
  final Widget value;
  final VoidCallback? onTap;
  final GlobalKey? anchorKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return KeyedSubtree(
      key: anchorKey,
      child: SetupRowFrame(
        leading: Icon(icon),
        title: title,
        onTap: onTap,
        sharedTrailing: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: DefaultTextStyle.merge(
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                child: value,
              ),
            ),
            const KGap(KSpace.x1),
            Icon(KIcons.chevronRight, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// The "+ Add …" row at the end of a list: primary-coloured icon and label.
class SetupAddRow extends StatelessWidget {
  const SetupAddRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Widget label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: SetupRowFrame(
        leading: IconTheme.merge(
          data: IconThemeData(color: scheme.primary),
          child: Icon(icon),
        ),
        title: label,
        onTap: onTap,
        titleStyle: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// A line of explanation inside a setup card (empty list, missing
/// permission), with the card's padding.
class SetupNote extends StatelessWidget {
  const SetupNote({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(KSpace.x4),
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: scheme.onSurfaceVariant),
        child: child,
      ),
    );
  }
}
