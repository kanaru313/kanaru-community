import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_motion.dart';
import 'k_ruler_marker.dart';
import 'k_ruler_painter.dart';
import 'k_ruler_physics.dart';

String _plainNumber(int v) => '$v';

/// Width of one unit: wide when every unit is numbered, narrow otherwise.
double _unitWidth(int labelEvery) => labelEvery <= 1 ? 28.0 : 8.0;

/// Horizontal ruler on a real scroll view (momentum, snaps to a tick) for a
/// whole number between [min] and [max]: a tick per unit, a taller one every [majorEvery], a number every [labelEvery],
/// the centre `primary` marker is the value, both edges fade out. Drag or
/// fling to move; [onChanged] fires once each time the centred tick changes.
/// A value changed from outside animates to its tick (a jump with reduced
/// motion) without echoing [onChanged]; touch shells tick a haptic per step.
///
/// A [value] outside the range sits at the nearest end and is never changed
/// by the ruler itself. Keyboard: left / right step by 1 inside the range;
/// from an outside value the key that points inward steps from the end (240
/// with max 180: left gives 179) and the key that points further out changes
/// nothing (it never lowers a value on "increase"); Enter calls [onSubmit].
/// One unit is 28 dp wide when every unit carries a number ([labelEvery] 1),
/// 8 dp otherwise. Semantics: a slider with [valueLabel] as its value
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
    this.tickLabel,
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

  /// Text drawn at a labelled tick ("1:15", "2 giờ"); defaults to the number.
  /// Short: it sits in the width of [labelEvery] units.
  final String Function(int value)? tickLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<KRuler> createState() => _KRulerState();
}

class _KRulerState extends State<KRuler> {
  late final ScrollController _scroll;
  bool _focused = false;

  /// The centred value last seen (reported or set from outside).
  late int _idx;

  /// True while this widget moves the scroll itself: no echo, no haptic.
  bool _own = false;

  double get _tick => _unitWidth(widget.labelEvery);
  int get _shown => widget.value.clamp(widget.min, widget.max);
  double _offsetOf(int v) => (v - widget.min) * _tick;

  @override
  void initState() {
    super.initState();
    _idx = _shown;
    _scroll = ScrollController(initialScrollOffset: _offsetOf(_idx))
      ..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_own || !_scroll.hasClients) return;
    final v = (widget.min + (_scroll.offset / _tick).round()).clamp(
      widget.min,
      widget.max,
    );
    if (v == _idx) return;
    _idx = v;
    if (FormFactor.of(context) != FormFactor.desktop) {
      HapticFeedback.selectionClick();
    }
    widget.onChanged(v);
  }

  @override
  void didUpdateWidget(KRuler old) {
    super.didUpdateWidget(old);
    if (!_scroll.hasClients) return;
    final moving = _scroll.position.isScrollingNotifier.value;
    if (_shown == _idx || moving) return;
    _idx = _shown;
    final target = _offsetOf(_idx);
    if (MediaQuery.disableAnimationsOf(context)) {
      _own = true;
      _scroll.jumpTo(target);
      _own = false;
      return;
    }
    _own = true;
    _scroll
        .animateTo(target, duration: KMotion.normal, curve: KMotion.dialogCurve)
        .whenComplete(() => _own = false);
  }

  void _set(int v) {
    final next = v.clamp(widget.min, widget.max);
    if (next != widget.value) widget.onChanged(next);
  }

  /// One step; the direction that points further out of the range from an
  /// end or outside value is a no-op (the key is still consumed).
  void _step(int delta) {
    final v = widget.value;
    if ((delta > 0 && v >= widget.max) || (delta < 0 && v <= widget.min)) {
      return;
    }
    _set(_shown + delta);
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft) {
      _step(-1);
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _step(1);
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
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final height = desktop ? 60.0 : 72.0;
    final tick = _tick;
    final label = widget.valueLabel ?? (int v) => '$v';
    final shown = _shown;
    final span = (widget.max - widget.min) * tick;
    return Semantics(
      slider: true,
      focusable: true,
      focused: _focused,
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
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListenableBuilder(
                    listenable: _scroll,
                    builder: (context, _) => KRulerFace(
                      min: widget.min,
                      max: widget.max,
                      position: _scroll.hasClients
                          ? widget.min + _scroll.offset / tick
                          : _idx.toDouble(),
                      unitWidth: tick,
                      majorEvery: widget.majorEvery,
                      labelEvery: widget.labelEvery,
                      tickLabel: widget.tickLabel ?? _plainNumber,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: KRulerScrollLayer(
                    controller: _scroll,
                    tick: tick,
                    span: span,
                  ),
                ),
                IgnorePointer(
                  child: KRulerMarker(focused: _focused, height: height),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
