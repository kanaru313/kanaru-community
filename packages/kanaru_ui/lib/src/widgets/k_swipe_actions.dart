import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:material_ui/material_ui.dart';

import '../tokens/k_motion.dart';
import 'k_swipe_actions_gesture.dart';
import 'k_swipe_actions_strip.dart';
import 'k_swipe_geometry.dart';

export 'k_swipe_actions_gesture.dart' show KSwipeAction, kSwipeDevices;

/// A row that moves sideways under the finger and shows what a release does.
///
/// [KSwipeActions.capped]: each side may carry a [KSwipeAction]; travel is
/// capped (rubber band past the trigger), letting go past the trigger runs
/// the action once and the row springs back. Speed is ignored. A side without
/// an action does not move but still takes the drag, so a surrounding tab
/// swipe does not start.
///
/// [KSwipeActions.remove]: both directions; letting go after covering 70 % of
/// the width slides the row out and awaits `onRemove`; false or a throw
/// brings the row back. A fling alone removes nothing. Its drag reveals no
/// strip and no icon.
/// `onRemove` starts at release, at the same time as the slide-out, so a
/// caller that drops the row synchronously cuts the slide short and should
/// wait for the slide first if the animation matters.
///
/// The side is locked when the drag starts and the offset never crosses zero,
/// so the strip never flips side. [enabled] false keeps the same tree (the
/// child never remounts) and drops callbacks and semantics actions.
class KSwipeActions extends StatefulWidget {
  const KSwipeActions.capped({
    super.key,
    required this.child,
    this.start,
    this.end,
    this.enabled = true,
  }) : removeLabel = null,
       onRemove = null;

  const KSwipeActions.remove({
    super.key,
    required this.child,
    required String label,
    required Future<bool> Function() this.onRemove,
    this.enabled = true,
  }) : removeLabel = label,
       start = null,
       end = null;

  final Widget child;

  /// Swipe right (strip on the left).
  final KSwipeAction? start;

  /// Swipe left (strip on the right).
  final KSwipeAction? end;
  final String? removeLabel;
  final Future<bool> Function()? onRemove;
  final bool enabled;

  @override
  State<KSwipeActions> createState() => _KSwipeActionsState();
}

class _KSwipeActionsState extends State<KSwipeActions>
    with SingleTickerProviderStateMixin {
  // Unbounded: the signed sideways offset in dp.
  late final AnimationController _dx = AnimationController.unbounded(
    vsync: this,
  );
  double _width = 1;

  /// -1, 0 (not locked yet) or 1: the side of this drag.
  double _side = 0;

  /// Finger travel on [_side], from the pointer-down point, never negative.
  double _travel = 0;
  bool _leaving = false;
  bool _past = false;

  bool get _isRemove => widget.onRemove != null;
  KSwipeAction? get _action => _side > 0 ? widget.start : widget.end;
  KSwipeGeometry get _geo => KSwipeGeometry(width: _width, isRemove: _isRemove);
  bool get _reached =>
      _geo.reached(_travel, hasAction: _isRemove || _action != null);

  @override
  void didUpdateWidget(KSwipeActions old) {
    super.didUpdateWidget(old);
    if (old.enabled && !widget.enabled && !_leaving && _dx.value != 0) {
      _springBack();
    }
  }

  @override
  void dispose() {
    _dx.dispose();
    super.dispose();
  }

  void _springBack() {
    _past = false;
    KSpring.animateTo(context, _dx, 0, KSpring.gentle);
  }

  void _onStart(DragStartDetails _) {
    if (_leaving) return;
    _dx.stop();
    _width = context.size?.width ?? 1;
    _side = _dx.value.sign;
    _travel = _geo.travelFor(
      _dx.value.abs(),
      hasAction: _isRemove || _action != null,
    );
    _past = _reached;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_leaving) return;
    if (_side == 0 && d.delta.dx != 0) _side = d.delta.dx.sign;
    if (_side == 0) return;
    _travel = math.max(0, _travel + d.delta.dx * _side);
    _dx.value =
        _side *
        _geo.offsetFor(_travel, hasAction: _isRemove || _action != null);
    final reached = _reached;
    if (reached && !_past && _mobile) HapticFeedback.selectionClick();
    _past = reached;
  }

  void _onEnd(DragEndDetails _) {
    if (_leaving) return;
    if (!_reached) return _springBack();
    if (_isRemove) {
      unawaited(_slideOut());
    } else {
      // Back first: a trigger that throws must not leave the row out.
      final action = _action;
      _springBack();
      action?.onTrigger();
    }
  }

  void _onCancel() {
    if (!_leaving) _springBack();
  }

  /// Starts the removal and slides the row out at the same time. The removal
  /// runs once even if the row is remounted meanwhile (its state is gone but
  /// the callback was already called). The row stays out when it was removed
  /// (the list drops it); otherwise it comes back.
  Future<void> _slideOut() async {
    _leaving = true;
    final removal = _remove();
    unawaited(
      _dx.animateTo(
        (_side == 0 ? 1 : _side) * _width,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : KMotion.fast,
        curve: Curves.easeOut,
      ),
    );
    final removed = await removal;
    if (!removed && mounted) {
      _leaving = false;
      _springBack();
    }
  }

  Future<bool> _remove() async {
    try {
      return await widget.onRemove!();
    } on Object catch (error, stack) {
      // A failed removal is reported like any framework error; the row comes
      // back and takes drags again.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'swipe actions',
        ),
      );
      return false;
    }
  }

  void _removeFromSemantics() {
    if (_leaving) return;
    _width = context.size?.width ?? 1;
    _side = 1;
    unawaited(_slideOut());
  }

  static bool get _mobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Map<CustomSemanticsAction, VoidCallback>? _semanticsActions() {
    if (!widget.enabled) return null;
    if (_isRemove) {
      return {
        CustomSemanticsAction(label: widget.removeLabel!): _removeFromSemantics,
      };
    }
    return {
      for (final a in [widget.start, widget.end])
        if (a != null) CustomSemanticsAction(label: a.label): a.onTrigger,
    };
  }

  void _configure(KSwipeDragRecognizer r) {
    final on = widget.enabled;
    r
      ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context)
      ..dragStartBehavior = DragStartBehavior.down
      ..supportedDevices = kSwipeDevices
      ..onStart = on ? _onStart : null
      ..onUpdate = on ? _onUpdate : null
      ..onEnd = on ? _onEnd : null
      ..onCancel = on ? _onCancel : null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      customSemanticsActions: _semanticsActions(),
      child: RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          KSwipeDragRecognizer:
              GestureRecognizerFactoryWithHandlers<KSwipeDragRecognizer>(
                KSwipeDragRecognizer.new,
                _configure,
              ),
        },
        child: AnimatedBuilder(
          animation: _dx,
          child: widget.child,
          builder: (context, child) {
            final dx = _dx.value;
            final side = dx.sign;
            // Painted after the row: it only covers the area the row left.
            return Stack(
              children: [
                Transform.translate(offset: Offset(dx, 0), child: child),
                // The remove kind reveals nothing: it must be dragged to 70 %
                // and an icon halfway would read as already removed.
                if (dx != 0 && !_isRemove)
                  _strip(scheme, Theme.of(context), dx, side),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _strip(ColorScheme scheme, ThemeData theme, double dx, double side) {
    final action = side > 0 ? widget.start : widget.end;
    if (action == null) return const SizedBox.shrink();
    return KSwipeStrip(
      offset: dx,
      icon: action.icon,
      iconColor: scheme.onSurfaceVariant,
      fill: scheme.surfaceContainerHighest,
      label: action.label,
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      progress: dx.abs() / _geo.trigger,
      scaled: _past,
    );
  }
}
