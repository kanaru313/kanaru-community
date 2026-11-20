import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_gap.dart';

/// Tonal pill. 48 dp tall on touch shells, 40 on desktop; [dense] makes it
/// 40 r12 on touch shells and 32 on desktop (a chip row that must fit).
class KChip extends StatelessWidget {
  const KChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.dense = false,
  }) : trailing = null,
       _interactive = true;

  /// A pill that is a value, not a choice: no button, no selected state, no
  /// ink. [trailing] (a remove button) sits at the end with less padding.
  /// Use it for chips that only show something, or hold their own action.
  const KChip.static({super.key, required this.label, this.trailing})
    : icon = null,
      selected = false,
      enabled = true,
      onTap = null,
      dense = false,
      _interactive = false;

  final Widget label;
  final Widget? icon;
  final bool selected;

  /// A disabled chip is dimmed and ignores taps.
  final bool enabled;
  final VoidCallback? onTap;

  /// Compact height (see the class doc) with 12 dp corners on touch shells.
  final bool dense;

  /// Widget after the label of a [KChip.static] (its own action).
  final Widget? trailing;
  final bool _interactive;

  static const double _denseDesktopHeight = 32;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final touch = FormFactor.of(context) == FormFactor.mobile;
    final minHeight = dense
        ? (touch ? KLayout.minTargetDesktop : _denseDesktopHeight)
        : (touch ? KLayout.minTarget : KLayout.minTargetDesktop);
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: KSpace.x4,
          end: trailing == null ? KSpace.x4 : KSpace.x2,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: KIconSize.xs),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const KGap(KSpace.x2)],
                Flexible(child: label),
                if (trailing != null) ...[const KGap(KSpace.x2), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
    final pill = Material(
      color: selected ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
      shape: KShape.of(dense && touch ? KRadius.sm : KRadius.full),
      clipBehavior: Clip.antiAlias,
      child: _interactive
          ? InkWell(onTap: enabled ? onTap : null, child: content)
          : content,
    );
    if (!_interactive) return pill;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: Opacity(opacity: enabled ? 1 : 0.5, child: pill),
    );
  }
}
