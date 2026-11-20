import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_press_surface.dart';

/// Where a button [KPill] sits: the default is 40 high, the desktop player
/// bar's is 36.
enum KPillPlacement { standard, playerBar }

const double _kMaxLabel = 56;

/// Stadium with an icon and a short label (the sleep timer's "Dừng lúc 23:40"
/// and its running indicator).
///
/// Without [onPressed] it is an info pill: not focusable, 36 high on touch
/// shells and 32 on desktop. With [onPressed] it is a button: [focusNode] is
/// kept across label changes, hover 8 %, press 10 %, keyboard focus ring 2.
///
/// The label of a button pill (the ticking indicator) is capped at 56 dp
/// (scaled with the text) so it stays small; an info pill shows its whole
/// label on one line (two from 200 % text) and gets an ellipsis only when its
/// parent is narrower.
///
/// [widestLabel] is the widest string the label will ever show; the label box
/// never gets narrower than it, so a ticking label does not relayout its
/// neighbours. [held] draws the icon in `onSurfaceVariant` (a paused state).
/// [semanticLabel] is spoken instead of the label (minute precision comes
/// from the caller).
class KPill extends StatelessWidget {
  const KPill({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.focusNode,
    this.tooltip,
    this.semanticLabel,
    this.widestLabel,
    this.held = false,
    this.placement = KPillPlacement.standard,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final String? tooltip;
  final String? semanticLabel;
  final String? widestLabel;
  final bool held;
  final KPillPlacement placement;

  bool get _isButton => onPressed != null;

  double _height(bool desktop) {
    if (!_isButton) return desktop ? 32 : 36;
    return placement == KPillPlacement.playerBar ? 36 : 40;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final iconSize = _isButton ? KIconSize.md : KIconSize.sm;
    final style = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final maxLabel = _isButton
        ? MediaQuery.textScalerOf(context).scale(_kMaxLabel)
        : double.infinity;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;

    // Same 200 % rule as the tile grid: an info pill may wrap to two lines.
    final large = MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.99;
    Widget text(String s) => Text(
      s,
      maxLines: _isButton || !large ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    Widget face(double overlay) => AnimatedContainer(
      duration: duration,
      curve: KMotion.emphasized,
      constraints: BoxConstraints(minHeight: _height(desktop)),
      padding: const EdgeInsetsDirectional.only(
        start: KSpace.x1 + 2,
        end: KSpace.x2 + 6,
      ),
      decoration: ShapeDecoration(
        color: Color.alphaBlend(
          scheme.onSurface.withValues(alpha: overlay),
          scheme.surfaceContainerHighest,
        ),
        shape: KShape.of(KRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: held ? scheme.onSurfaceVariant : scheme.primary,
          ),
          const SizedBox(width: KSpace.x2),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabel),
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  if (widestLabel != null)
                    Opacity(opacity: 0, child: text(widestLabel!)),
                  text(label),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!_isButton) {
      return Semantics(
        container: true,
        label: semanticLabel ?? label,
        child: ExcludeSemantics(child: face(0)),
      );
    }

    return KPressSurface(
      onPressed: onPressed,
      radius: KRadius.full,
      semanticLabel: semanticLabel ?? tooltip ?? label,
      focusNode: focusNode,
      builder: (context, overlay, _) => tooltip == null
          ? face(overlay)
          : Tooltip(
              message: tooltip,
              excludeFromSemantics: true,
              child: face(overlay),
            ),
    );
  }
}
