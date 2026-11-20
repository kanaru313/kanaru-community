import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_press_surface.dart';
import 'k_start_arrows.dart';

/// A start button: a title with a detail line under it ("45 phút" / "đến
/// 23:40"). Tapping it does the thing at once. Not a choice: no check mark,
/// no selected state. Lay tiles out in a [KStartTileGrid].
///
/// [opensMore] marks the tile that opens a further screen ("Tuỳ chỉnh…"): it
/// is drawn outlined, and its [icon] (drawn by the tile, in `primary`) shows
/// on touch shells only. Hover 8 %,
/// press 10 % (touch shells also scale to 97 %), keyboard focus draws the
/// 2 dp `primary` ring inside. [onPressed] null = disabled. Enter / Space
/// activate it; arrow keys move between tiles inside a [KStartArea].
class KStartTile extends StatelessWidget {
  const KStartTile({
    super.key,
    required this.title,
    required this.semanticLabel,
    required this.onPressed,
    this.detail,
    this.icon,
    this.opensMore = false,
    this.autofocus = false,
    this.focusNode,
  });

  final String title;
  final String? detail;

  /// Spoken name, with the detail in words ("Bắt đầu 15 phút, dừng lúc 23:40").
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Leading icon of an [opensMore] tile; dropped on desktop.
  final IconData? icon;
  final bool opensMore;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final radius = desktop ? KRadius.sm : KRadius.lg;
    final animate = !MediaQuery.disableAnimationsOf(context);
    final enabled = onPressed != null;
    final titleStyle = opensMore
        ? (desktop ? text.titleSmall : text.titleMedium)
        : (desktop ? text.titleMedium : text.titleLarge);
    final fill = opensMore
        ? null
        : (desktop
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerHigh);
    final showIcon = opensMore && icon != null && !desktop;
    return KStartMarker(
      child: KPressSurface(
        onPressed: onPressed,
        radius: radius,
        semanticLabel: semanticLabel,
        shortcuts: kStartArrowShortcuts(Directionality.of(context)),
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (context, overlay, pressed) => Opacity(
          opacity: enabled ? 1 : 0.38,
          child: AnimatedScale(
            scale: pressed && animate && !desktop ? 0.97 : 1,
            duration: animate ? KMotion.fast : Duration.zero,
            child: Container(
              constraints: BoxConstraints(minHeight: desktop ? 56 : 80),
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? KSpace.x3 : KSpace.x4,
                vertical: desktop ? KSpace.x2 : KSpace.x3,
              ),
              decoration: ShapeDecoration(
                color: fill == null
                    ? null
                    : Color.alphaBlend(
                        scheme.onSurface.withValues(alpha: overlay),
                        fill,
                      ),
                shape: opensMore
                    ? RoundedRectangleBorder(
                        borderRadius: radius,
                        side: BorderSide(color: scheme.outlineVariant),
                      )
                    : KShape.of(radius),
              ),
              foregroundDecoration: opensMore && overlay > 0
                  ? ShapeDecoration(
                      shape: KShape.of(radius),
                      color: scheme.onSurface.withValues(alpha: overlay),
                    )
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: opensMore
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showIcon) ...[
                        Icon(icon, size: KIconSize.md, color: scheme.primary),
                        const SizedBox(width: KSpace.x2),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          style: titleStyle?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
