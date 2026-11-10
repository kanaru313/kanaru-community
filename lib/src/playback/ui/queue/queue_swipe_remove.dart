import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../spring_to_rest.dart';

/// Pointers that may drag a row away. A trackpad two-finger pan scrolls the
/// list on desktop, so it is left out.
const Set<PointerDeviceKind> queueSwipeDevices = {
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
};

/// Share of the row width a drag must pass to remove the row.
const double queueSwipeThreshold = 0.4;

/// Drag a row sideways (either way) to remove it: the row follows the finger
/// and fades, a red `delete` icon shows on the side it left (no red fill) and
/// grows past the threshold. Letting go past it slides the row out and calls
/// [onRemove]; the row stays hidden until the list drops it. [onRemove]
/// answering false (nothing was removed) brings the row back.
///
/// Not a `Dismissible`: that one wants the row gone in the same frame, but a
/// removal here is persisted first.
class QueueSwipeRemove extends StatefulWidget {
  const QueueSwipeRemove({
    super.key,
    required this.child,
    required this.onRemove,
    this.enabled = true,
  });

  final Widget child;
  final Future<bool> Function() onRemove;
  final bool enabled;

  @override
  State<QueueSwipeRemove> createState() => _QueueSwipeRemoveState();
}

class _QueueSwipeRemoveState extends State<QueueSwipeRemove>
    with SingleTickerProviderStateMixin {
  // Unbounded: holds the sideways offset in dp.
  late final AnimationController _dx = AnimationController.unbounded(
    vsync: this,
  );
  bool _leaving = false;

  /// Width of the row, read from its render box when a drag starts (the size
  /// cannot be read while building).
  double _width = 1;

  @override
  void dispose() {
    _dx.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) {
    if (_leaving) return;
    _dx.value = (_dx.value + d.delta.dx).clamp(-_width, _width);
  }

  Future<void> _end(DragEndDetails d) async {
    if (_leaving) return;
    if (_dx.value.abs() < _width * queueSwipeThreshold) {
      await animateSpringTo(context, _dx, 0, KSpring.snappy);
      return;
    }
    _leaving = true;
    final side = _dx.value.sign;
    await _dx.animateTo(
      side * _width,
      duration: KMotion.fast,
      curve: Curves.easeOut,
    );
    var removed = false;
    try {
      removed = await widget.onRemove();
    } on Object catch (error, stack) {
      // A failed removal (the database chain) is reported like any other
      // framework error; the row below comes back and takes drags again.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'queue swipe remove',
        ),
      );
    }
    // Nothing removed (declined or failed): the row comes back. A removed row
    // is gone with its state.
    if (!removed && mounted) {
      _leaving = false;
      await animateSpringTo(context, _dx, 0, KSpring.snappy);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      dragStartBehavior: DragStartBehavior.down,
      supportedDevices: queueSwipeDevices,
      onHorizontalDragStart: (_) => _width = context.size?.width ?? 1,
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: _end,
      onHorizontalDragCancel: () {
        if (!_leaving) animateSpringTo(context, _dx, 0, KSpring.snappy);
      },
      child: AnimatedBuilder(
        animation: _dx,
        builder: (context, child) {
          final p = (_dx.value.abs() / _width).clamp(0.0, 1.0);
          final past = p >= queueSwipeThreshold;
          return Stack(
            children: [
              if (_dx.value != 0)
                Positioned.fill(
                  child: Align(
                    alignment: _dx.value > 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KSpace.x6,
                      ),
                      child: AnimatedScale(
                        scale: past ? 1.3 : 1,
                        duration: KMotion.fast,
                        child: Icon(KIcons.delete, color: scheme.error),
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(_dx.value, 0),
                child: Opacity(opacity: 1 - 0.7 * p, child: child),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}
