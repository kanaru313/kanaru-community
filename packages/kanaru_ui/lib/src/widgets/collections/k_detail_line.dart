import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../tokens/k_layout.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';

/// Second line of a detail hero: [text] (a link when [onTap] is set) and an
/// optional plain [trailing] after ` · ` (an album's year).
///
/// Each part is one line with its own ellipsis, so a long name is cut before
/// the year. The link is a keyboard stop, underlined, with a touch area at
/// least 48 dp tall that overlaps the lines around it without making the row
/// taller.
///
/// [trailing] is meant to be short (a year). Not usable inside
/// `IntrinsicHeight` / `IntrinsicWidth`: it uses a `LayoutBuilder`.
class KDetailLine extends StatelessWidget {
  const KDetailLine({super.key, required this.text, this.onTap, this.trailing});

  final String text;

  /// Makes [text] a link.
  final VoidCallback? onTap;

  /// Plain text after the link, e.g. the year.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(fontWeight: FontWeight.w500, color: scheme.onSurface);
    final tap = onTap;
    final line = LayoutBuilder(
      builder: (context, c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: tap == null
                ? Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  )
                : _KDetailLink(text: text, style: style, onTap: tap),
          ),
          if (trailing != null)
            // Keeps its natural width (a year is never cut); only text wider
            // than the whole line is ellipsized.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: c.hasBoundedWidth ? c.maxWidth : double.infinity,
              ),
              child: Text(
                ' · $trailing',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
        ],
      ),
    );
    return tap == null ? line : KVerticalHitExtension(child: line);
  }
}

class _KDetailLink extends StatefulWidget {
  const _KDetailLink({
    required this.text,
    required this.style,
    required this.onTap,
  });

  final String text;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  State<_KDetailLink> createState() => _KDetailLinkState();
}

class _KDetailLinkState extends State<_KDetailLink> {
  bool _pressed = false;
  bool _ring = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final primary = Theme.of(context).colorScheme.primary;
    return MergeSemantics(
      child: Semantics(
        link: true,
        button: true,
        label: widget.text,
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
          onShowFocusHighlight: (v) {
            if (_ring != v) setState(() => _ring = v);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ExcludeSemantics(
                  child: AnimatedOpacity(
                    opacity: _pressed ? 0.5 : 1,
                    duration: reduce ? Duration.zero : KMotion.press,
                    child: Text(
                      widget.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.style?.copyWith(
                        decoration: TextDecoration.underline,
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
                          borderRadius: KRadius.sm,
                          border: Border.all(color: primary, width: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets taps in the space around [child] reach it, up to a total touch
/// height of [KLayout.minTarget], without changing its size: the touch area
/// overlaps the neighbours, the row stays as tall as its content. Only the
/// child's own width takes part.
///
/// The extra reach is split above and below, or all above when
/// [upwardOnly]: for a last child, whose parents end where it ends and
/// reject touches below.
class KVerticalHitExtension extends SingleChildRenderObjectWidget {
  const KVerticalHitExtension({
    super.key,
    this.upwardOnly = false,
    super.child,
  });

  final bool upwardOnly;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderVerticalHitExtension(upwardOnly);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderVerticalHitExtension).upwardOnly = upwardOnly;
  }
}

class _RenderVerticalHitExtension extends RenderProxyBox {
  _RenderVerticalHitExtension(this.upwardOnly);

  bool upwardOnly;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    final extra = math.max(0.0, KLayout.minTarget - size.height);
    final above = upwardOnly ? extra : extra / 2;
    final below = upwardOnly ? 0.0 : extra / 2;
    if (position.dx < 0 ||
        position.dx >= size.width ||
        position.dy < -above ||
        position.dy >= size.height + below) {
      return false;
    }
    // A tap in the extra strip is a tap on the child's nearest edge.
    final y = position.dy.clamp(0.0, math.max(0.0, size.height - 0.01));
    if (!c.hitTest(result, position: Offset(position.dx, y.toDouble()))) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}
