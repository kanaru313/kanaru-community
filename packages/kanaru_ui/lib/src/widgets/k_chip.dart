import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_gap.dart';

/// Tonal pill. 48 dp tall on touch shells, 40 on desktop.
class KChip extends StatelessWidget {
  const KChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  final Widget label;
  final Widget? icon;
  final bool selected;

  /// A disabled chip is dimmed and ignores taps.
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minHeight = FormFactor.of(context) == FormFactor.mobile
        ? KLayout.minTarget
        : KLayout.minTargetDesktop;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: selected
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHigh,
          shape: KShape.of(KRadius.full),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: KSpace.x4),
                child: IconTheme.merge(
                  data: IconThemeData(color: fg, size: 18),
                  child: DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: fg),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[icon!, const KGap(KSpace.x2)],
                        Flexible(child: label),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
