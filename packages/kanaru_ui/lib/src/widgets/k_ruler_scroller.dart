import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens/k_motion.dart';
import 'k_ruler_marker.dart';
import 'k_ruler_painter.dart';
import 'k_ruler_physics.dart';

/// The scrolling part of `KRuler`: controller, painted face, marker and the
/// sync between the scroll offset and the value.
///
/// `KRuler` keys it on min / max / tick, so a change of range or unit builds
/// a fresh controller and physics, parked on the current value.
///
/// Sync rule: while the user drags or the ruler flings from a gesture, the
/// finger wins (an outside value is ignored); each centred tick is reported
/// once. Whenever the ruler is idle the outside value wins: an outside value
/// that differs from the settled tick is animated to (a jump with reduced
/// motion), and a newer outside value retargets a running animation. Nothing
/// an outside change causes is echoed through [onChanged].
class KRulerScroller extends StatefulWidget {
  const KRulerScroller({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.tick,
    required this.majorEvery,
    required this.labelEvery,
    required this.tickLabel,
    required this.focused,
    required this.height,
    required this.onChanged,
  });

  final int min;
  final int max;
  final int value;
  final double tick;
  final int majorEvery;
  final int labelEvery;
  final String Function(int value) tickLabel;
  final bool focused;
  final double height;
  final ValueChanged<int> onChanged;

  @override
  State<KRulerScroller> createState() => _KRulerScrollerState();
}

class _KRulerScrollerState extends State<KRulerScroller> {
  late final ScrollController _scroll;

  /// The centred value last seen (reported or set from outside).
  late int _idx;

  /// True while this widget moves the scroll itself: no echo, no haptic.
  bool _own = false;
  int _run = 0;

  /// The last pointer that went down was a finger: ticks vibrate.
  bool _touch = false;

  int get _shown => widget.value.clamp(widget.min, widget.max);
  double _offsetOf(int v) => (v - widget.min) * widget.tick;

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
    final v = (widget.min + (_scroll.offset / widget.tick).round()).clamp(
      widget.min,
      widget.max,
    );
    if (v == _idx) return;
    _idx = v;
    if (_touch) HapticFeedback.selectionClick();
    widget.onChanged(v);
  }

  @override
  void didUpdateWidget(KRulerScroller old) {
    super.didUpdateWidget(old);
    if (!_scroll.hasClients || _shown == _idx) return;
    final scrolling = _scroll.position.isScrollingNotifier.value;
    if (scrolling && !_own) return; // the finger wins; re-synced at rest
    _syncToValue();
  }

  /// Moves the ruler to the outside value; the newest call wins.
  void _syncToValue() {
    _idx = _shown;
    final target = _offsetOf(_idx);
    final run = ++_run;
    _own = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
      _own = false;
      return;
    }
    _scroll
        .animateTo(target, duration: KMotion.normal, curve: KMotion.dialogCurve)
        .whenComplete(() {
          if (run == _run) _own = false;
        });
  }

  bool _onNote(ScrollNotification n) {
    final byUser =
        (n is ScrollStartNotification && n.dragDetails != null) ||
        (n is ScrollUpdateNotification && n.dragDetails != null);
    if (byUser) {
      _own = false; // a finger took over from our animation
      _run++;
    } else if (n is ScrollEndNotification && !_own && _shown != _idx) {
      _syncToValue(); // at rest the outside value wins
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tick = widget.tick;
    final span = (widget.max - widget.min) * tick;
    return NotificationListener<ScrollNotification>(
      onNotification: _onNote,
      child: Listener(
        onPointerDown: (e) => _touch = e.kind == PointerDeviceKind.touch,
        child: RepaintBoundary(
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
                    tickLabel: widget.tickLabel,
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
                child: KRulerMarker(
                  focused: widget.focused,
                  height: widget.height,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
