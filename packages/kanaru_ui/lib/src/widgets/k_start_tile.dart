import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_focus_ring.dart';

/// A start button: a title with a detail line under it ("45 phút" / "đến
/// 23:40"). Tapping it does the thing at once. Not a choice: no check mark,
/// no selected state. Lay tiles out in a [KStartTileGrid].
///
/// [opensMore] marks the tile that opens a further screen ("Tuỳ chỉnh…"): it
/// is drawn outlined, and its [icon] shows on touch shells only. Hover 8 %,
/// press 10 % (touch shells also scale to 97 %), keyboard focus draws the
/// 2 dp `primary` ring inside. [onPressed] null = disabled. Enter / Space
/// activate it; arrow keys move between tiles inside a [KStartArea].
class KStartTile extends StatefulWidget {
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
  final Widget? icon;
  final bool opensMore;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<KStartTile> createState() => _KStartTileState();
}

class _KStartTileState extends State<KStartTile> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _activate() => widget.onPressed?.call();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final radius = desktop ? KRadius.sm : KRadius.lg;
    final animate = !MediaQuery.disableAnimationsOf(context);
    final titleStyle = widget.opensMore
        ? (desktop ? text.titleSmall : text.titleMedium)
        : (desktop ? text.titleMedium : text.titleLarge);
    final overlay = !_enabled
        ? 0.0
        : _pressed
        ? 0.10
        : (_hovered ? 0.08 : 0.0);
    final fill = widget.opensMore
        ? null
        : (desktop
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerHigh);
    final showIcon = widget.opensMore && widget.icon != null && !desktop;
    return Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      onTap: _enabled ? _activate : null,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: _enabled ? 1 : 0.38,
          child: AnimatedScale(
            scale: _pressed && animate && !desktop ? 0.97 : 1,
            duration: animate ? KMotion.fast : Duration.zero,
            child: FocusableActionDetector(
              enabled: _enabled,
              autofocus: widget.autofocus,
              focusNode: widget.focusNode,
              mouseCursor: _enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    _activate();
                    return null;
                  },
                ),
              },
              onShowFocusHighlight: (v) => setState(() => _focused = v),
              onShowHoverHighlight: (v) => setState(() => _hovered = v),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _enabled
                    ? (_) => setState(() => _pressed = true)
                    : null,
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                onTap: _enabled ? _activate : null,
                child: KFocusRing(
                  focused: _focused,
                  radius: radius,
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
                      shape: widget.opensMore
                          ? RoundedRectangleBorder(
                              borderRadius: radius,
                              side: BorderSide(color: scheme.outlineVariant),
                            )
                          : KShape.of(radius),
                    ),
                    foregroundDecoration: widget.opensMore && overlay > 0
                        ? ShapeDecoration(
                            shape: KShape.of(radius),
                            color: scheme.onSurface.withValues(alpha: overlay),
                          )
                        : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: widget.opensMore
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showIcon) ...[
                              IconTheme.merge(
                                data: IconThemeData(color: scheme.primary),
                                child: widget.icon!,
                              ),
                              const SizedBox(width: KSpace.x2),
                            ],
                            Flexible(
                              child: Text(
                                widget.title,
                                style: titleStyle?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.detail != null)
                          Text(
                            widget.detail!,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
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
