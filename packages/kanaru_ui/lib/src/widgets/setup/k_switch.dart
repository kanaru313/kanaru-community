import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'k_switch_painter.dart';

/// Kanaru switch, 52 x 32: the primary fill grows from the left, the thumb
/// springs over with a stretch and shows a tick. `onChanged: null` locks it
/// (dimmed, no input). Honors reduced motion by jumping to the end state.
class KSwitch extends StatefulWidget {
  const KSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  State<KSwitch> createState() => _KSwitchState();
}

class _KSwitchState extends State<KSwitch> with SingleTickerProviderStateMixin {
  // Forward (off -> on) takes the tick's end: 200 ms delay + 220 ms draw.
  static const _on = Duration(milliseconds: 420);
  static const _off = Duration(milliseconds: 200);
  static const _fillOn = Interval(
    40 / 420,
    360 / 420,
    curve: Cubic(0.2, 0, 0, 1),
  );
  static const _thumbOn = Interval(
    0,
    380 / 420,
    curve: Cubic(0.34, 1.45, 0.64, 1),
  );
  static const _thumbOff = Cubic(0.3, 0, 0.2, 1);
  static const _tickOn = Interval(200 / 420, 1, curve: Cubic(0.65, 0, 0.35, 1));

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _on,
    reverseDuration: _off,
    value: widget.value ? 1 : 0,
  );
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onChanged != null;

  @override
  void didUpdateWidget(KSwitch old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = widget.value ? 1 : 0;
    } else if (widget.value) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged?.call(!widget.value);

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  KSwitchProgress _progress() {
    final v = _c.value;
    final off = _c.status == AnimationStatus.reverse;
    final travel = (v * 420 / 300).clamp(0.0, 1.0);
    return KSwitchProgress(
      fill: off ? Curves.easeIn.transform(v) : _fillOn.transform(v),
      thumb: off ? _thumbOff.transform(v) : _thumbOn.transform(v),
      tick: off ? ((v - 0.6) / 0.4).clamp(0.0, 1.0) : _tickOn.transform(v),
      stretch: v == 0 || v == 1 ? 0 : travel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final enabled = _enabled;
    return Semantics(
      label: widget.semanticLabel,
      toggled: widget.value,
      enabled: enabled,
      onTap: enabled ? _toggle : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            onTap: enabled ? _toggle : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.38,
              child: SizedBox(
                width: 52,
                height: 32,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    painter: KSwitchPainter(
                      progress: _progress(),
                      pressed: _pressed,
                      focused: _focused && enabled,
                      track: s.surfaceContainerHighest,
                      outline: s.outline,
                      primary: s.primary,
                      onPrimary: s.onPrimary,
                      surface: s.surface,
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
