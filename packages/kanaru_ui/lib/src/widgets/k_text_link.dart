import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import 'k_link_underline.dart';
import 'k_vertical_hit_extension.dart';

export 'k_vertical_hit_extension.dart';

/// How a [KTextLink] behaves when its text is wider than the space.
enum KTextLinkOverflow {
  /// One line, cut with an ellipsis (a hero line).
  ellipsis,

  /// Wraps onto as many lines as needed (a value of the song info page).
  wrap,
}

/// The one link look of the app: an underlined text in `onSurface` (not
/// `primary`), the same size and weight as the text around it.
///
/// Normal: 1 px underline 3 dp under the baseline (5 at 200 % text), at 60 %. Hover (mouse): 2 px at 100 %. Pressed: text
/// and underline at 50 % while held (instant with reduced motion). Keyboard
/// focus: a 2 px `primary` ring with 4 dp corners, only when focus came from
/// the keyboard. No visited colour. Enter / Space activate it.
///
/// The touch area is at least 48 dp tall on touch shells and 40 dp on the
/// desktop shell without making the line taller (see [KVerticalHitExtension]:
/// it works when the parent lays the link out directly, as `Column` and `Wrap`
/// do, and the neighbours leave room).
///
/// Semantics: one focusable link node; [semanticLabel] is what a screen reader
/// says ("Đi tới Tên"), [text] when null.
class KTextLink extends StatefulWidget {
  const KTextLink({
    super.key,
    required this.text,
    required this.onTap,
    this.style,
    this.semanticLabel,
    this.overflow = KTextLinkOverflow.ellipsis,
  });

  final String text;
  final VoidCallback onTap;

  /// Base text style; `bodyMedium` w500 `onSurface` when null. The underline
  /// is always added by the link.
  final TextStyle? style;
  final String? semanticLabel;
  final KTextLinkOverflow overflow;

  /// Touch height: 48 on touch shells, 40 on the desktop shell. The one rule;
  /// wrappers such as `KDetailLine` ask here.
  static double targetHeight(BuildContext context) =>
      FormFactor.of(context) == FormFactor.desktop
      ? KLayout.minTargetDesktop
      : KLayout.minTarget;

  /// Hit-only reach on each side of the text.
  static const double sideReach = 4;

  /// Corner radius of the focus ring.
  static const BorderRadius ringRadius = BorderRadius.all(Radius.circular(4));

  @override
  State<KTextLink> createState() => _KTextLinkState();
}

class _KTextLinkState extends State<KTextLink> {
  bool _pressed = false;
  bool _hovered = false;
  bool _ring = false;

  void _set({bool? pressed, bool? hovered, bool? ring}) {
    final changed =
        (pressed != null && pressed != _pressed) ||
        (hovered != null && hovered != _hovered) ||
        (ring != null && ring != _ring);
    if (!changed || !mounted) return;
    setState(() {
      _pressed = pressed ?? _pressed;
      _hovered = hovered ?? _hovered;
      _ring = ring ?? _ring;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final base =
        widget.style ??
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        );
    final line = widget.overflow == KTextLinkOverflow.ellipsis;
    return KVerticalHitExtension(
      minHeight: KTextLink.targetHeight(context),
      horizontalExtra: KTextLink.sideReach,
      child: MergeSemantics(
        child: Semantics(
          link: true,
          button: true,
          label: widget.semanticLabel ?? widget.text,
          onTap: widget.onTap,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onTap();
                  return null;
                },
              ),
            },
            onShowFocusHighlight: (v) => _set(ring: v),
            onShowHoverHighlight: (v) => _set(hovered: v),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _set(pressed: true),
              onTapUp: (_) => _set(pressed: false),
              onTapCancel: () => _set(pressed: false),
              onTap: widget.onTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ExcludeSemantics(
                    child: AnimatedOpacity(
                      opacity: _pressed ? 0.5 : 1,
                      duration: reduce ? Duration.zero : KMotion.press,
                      child: KLinkUnderline(
                        color: (base?.color ?? scheme.onSurface).withValues(
                          alpha: _hovered ? 1 : 0.6,
                        ),
                        thickness: _hovered ? 2 : 1,
                        // 3 dp under the baseline, 5 at 200 % text.
                        gap:
                            3 +
                            2 *
                                (MediaQuery.textScalerOf(context).scale(10) /
                                            10 -
                                        1)
                                    .clamp(0.0, 2.0),
                        child: Text(
                          widget.text,
                          maxLines: line ? 1 : null,
                          overflow: line
                              ? TextOverflow.ellipsis
                              : TextOverflow.clip,
                          style: base,
                        ),
                      ),
                    ),
                  ),
                  if (_ring)
                    Positioned(
                      left: -2,
                      right: -2,
                      top: -2,
                      bottom: -2,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: KTextLink.ringRadius,
                            border: Border.all(color: scheme.primary, width: 2),
                          ),
                        ),
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
