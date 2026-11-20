import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_press_surface.dart';

/// How loud a [KModalButton] is.
enum KModalEmphasis {
  /// Filled `primary`: the one main action ("Bắt đầu", "Tiếp tục đếm").
  primary,

  /// Tonal `secondaryContainer` ("Đổi…").
  tonal,

  /// Outlined, neutral ("Tạm dừng đếm").
  secondary,

  /// Text only ("Huỷ").
  text,

  /// `error` text on an `error` 40 % outline ("Tắt hẹn giờ").
  destructive,
}

/// Footer / control button of a modal (sheet or dialog): a 48 dp stadium on
/// touch shells, 40 on desktop; the running screen's − / + and pause buttons
/// are the same size.
///
/// One widget whatever the emphasis, so a pause <-> resume swap only changes
/// [emphasis], [label] and [icon]: the element, its [focusNode] and the
/// keyboard focus stay. [onPressed] null = disabled.
class KModalButton extends StatelessWidget {
  const KModalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.emphasis = KModalEmphasis.primary,
    this.icon,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final KModalEmphasis emphasis;
  final IconData? icon;
  final FocusNode? focusNode;
  final bool autofocus;

  /// What a screen reader says when it differs from [label] ("Thêm 5 phút"
  /// for "+5 phút"). Defaults to [label].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final enabled = onPressed != null;
    const radius = KRadius.full;
    final minHeight = desktop ? 40.0 : KLayout.minTarget;
    final dim = scheme.onSurface.withValues(alpha: 0.38);
    final (Color? fill, Color fg, Color? line) = switch (emphasis) {
      KModalEmphasis.primary => (scheme.primary, scheme.onPrimary, null),
      KModalEmphasis.tonal => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        null,
      ),
      KModalEmphasis.secondary => (null, scheme.primary, scheme.outline),
      KModalEmphasis.text => (null, scheme.primary, null),
      KModalEmphasis.destructive => (
        null,
        scheme.error,
        scheme.error.withValues(alpha: 0.4),
      ),
    };
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    final style = text.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    return KPressSurface(
      onPressed: onPressed,
      radius: radius,
      semanticLabel: semanticLabel ?? label,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, overlay, _) => AnimatedContainer(
        duration: duration,
        constraints: BoxConstraints(minHeight: minHeight),
        padding: EdgeInsets.symmetric(
          horizontal: emphasis == KModalEmphasis.text
              ? (desktop ? KSpace.x3 : KSpace.x5)
              : (desktop ? KSpace.x5 : KSpace.x4),
          vertical: KSpace.x2,
        ),
        decoration: ShapeDecoration(
          color: enabled
              ? Color.alphaBlend(
                  fg.withValues(alpha: overlay),
                  fill ?? const Color(0x00000000),
                )
              : (fill == null
                    ? null
                    : scheme.onSurface.withValues(alpha: 0.12)),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: line == null
                ? BorderSide.none
                : BorderSide(
                    color: enabled
                        ? line
                        : scheme.onSurface.withValues(alpha: 0.12),
                  ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: KIconSize.md, color: enabled ? fg : dim),
              const SizedBox(width: KSpace.x2),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: style?.copyWith(color: enabled ? fg : dim),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
