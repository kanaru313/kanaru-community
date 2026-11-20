import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_shape.dart';
import 'k_focus_ring.dart';
import 'k_ruler_painter.dart';

/// Horizontal drag ruler for a whole number between [min] and [max]: a tick
/// per unit, a taller one every [majorEvery], a number every [labelEvery],
/// the centre `primary` marker is the value, both edges fade out. Drag to
/// move; the value changes one step at a time through [onChanged].
///
/// A [value] outside the range sits at the nearest end and is never changed
/// by the ruler itself. Keyboard: left / right step by 1 (inside the range),
/// Enter calls [onSubmit]. Semantics: a slider with [valueLabel] as its value
/// and increase / decrease actions. 72 dp tall on touch shells, 60 on desktop.
class KRuler extends StatefulWidget {
  const KRuler({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    required this.majorEvery,
    required this.labelEvery,
    this.onSubmit,
    this.semanticLabel,
    this.valueLabel,
    this.focusNode,
    this.autofocus = false,
  }) : assert(min < max),
       assert(majorEvery > 0 && labelEvery > 0);

  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;
  final int majorEvery;
  final int labelEvery;

  /// Enter pressed on the ruler.
  final VoidCallback? onSubmit;

  /// Spoken name ("Số phút").
  final String? semanticLabel;

  /// Spoken value of a number; defaults to the number.
  final String Function(int value)? valueLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<KRuler> createState() => _KRulerState();
}

class _KRulerState extends State<KRuler> {
  bool _focused = false;

  /// Fractional position while dragging; null otherwise.
  double? _drag;

  int get _shown => widget.value.clamp(widget.min, widget.max);

  void _set(int v) {
    final next = v.clamp(widget.min, widget.max);
    if (next != widget.value) widget.onChanged(next);
  }

  void _update(DragUpdateDetails d, double tick) {
    final pos = ((_drag ?? _shown.toDouble()) - d.delta.dx / tick).clamp(
      widget.min.toDouble(),
      widget.max.toDouble(),
    );
    setState(() => _drag = pos);
    _set(pos.round());
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft) {
      _set(_shown - 1);
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _set(_shown + 1);
    } else if ((k == LogicalKeyboardKey.enter ||
            k == LogicalKeyboardKey.numpadEnter) &&
        widget.onSubmit != null) {
      widget.onSubmit!();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final height = desktop ? 60.0 : 72.0;
    final tick = widget.labelEvery <= 1 ? 28.0 : 8.0;
    final label = widget.valueLabel ?? (int v) => '$v';
    final shown = _shown;
    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      value: label(widget.value),
      increasedValue: label((shown + 1).clamp(widget.min, widget.max)),
      decreasedValue: label((shown - 1).clamp(widget.min, widget.max)),
      onIncrease: widget.value < widget.max ? () => _set(shown + 1) : null,
      onDecrease: widget.value > widget.min ? () => _set(shown - 1) : null,
      child: ExcludeSemantics(
        child: Focus(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onKeyEvent: _key,
          onFocusChange: (v) => setState(() => _focused = v),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) => _update(d, tick),
            onHorizontalDragEnd: (_) => setState(() => _drag = null),
            onHorizontalDragCancel: () => setState(() => _drag = null),
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Builder(
                      builder: (context) => ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (r) => LinearGradient(
                          colors: const [
                            Color(0x00000000),
                            Color(0xFF000000),
                            Color(0xFF000000),
                            Color(0x00000000),
                          ],
                          stops: [
                            0,
                            (56 / r.width).clamp(0.0, 0.5),
                            1 - (56 / r.width).clamp(0.0, 0.5),
                            1,
                          ],
                        ).createShader(r),
                        child: CustomPaint(
                          painter: KRulerPainter(
                            min: widget.min,
                            max: widget.max,
                            position: _drag ?? shown.toDouble(),
                            tick: tick,
                            majorEvery: widget.majorEvery,
                            labelEvery: widget.labelEvery,
                            minorColor: scheme.outlineVariant,
                            majorColor: scheme.outline,
                            labelStyle: Theme.of(context).textTheme.labelSmall!
                                .copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                            textScaler: MediaQuery.textScalerOf(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(top: height * 0.3),
                      child: KFocusRing(
                        focused: _focused,
                        radius: KRadius.full,
                        inset: 2,
                        child: Container(
                          width: 4,
                          height: height * 0.55,
                          decoration: ShapeDecoration(
                            color: scheme.primary,
                            shape: KShape.of(KRadius.full),
                          ),
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
