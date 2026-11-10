import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Share of the cover width a drag must pass to change track.
const double coverSwipeThreshold = 0.25;

/// A faster fling than this (40 dp in 250 ms) changes track at any distance.
const double coverSwipeFlingVelocity = 160;

/// How far the cover may be pulled where there is no track to go to.
const double coverSwipeResist = 0.3;

/// Swipe the cover sideways to change track: left = next, right = previous.
/// The cover follows the finger; past 25 % of its width, or on a fast fling,
/// it slides out and the new one slides in when [entryId] changes. Short of
/// that it springs back. At the first or last entry it moves at most 30 % and
/// springs back (the buttons raise the "first/last track" notice). Vertical
/// drags are not taken: the page scrolls.
class CoverSwiper extends StatefulWidget {
  const CoverSwiper({
    super.key,
    required this.entryId,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  /// The current queue entry; a change after a swipe brings the new cover in.
  final int? entryId;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// The cover box. Its width decides how far a swipe has to go.
  final Widget child;

  @override
  State<CoverSwiper> createState() => _CoverSwiperState();
}

class _CoverSwiperState extends State<CoverSwiper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
  );
  double _side = 1;
  double _gap = 0;

  /// +1 when the cover left to the right (previous), -1 to the left (next).
  double _leftTo = 0;
  Timer? _giveUp;

  @override
  void dispose() {
    _giveUp?.cancel();
    _x.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CoverSwiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entryId != widget.entryId && _leftTo != 0) {
      // The new track is here: its cover enters from the opposite side.
      _giveUp?.cancel();
      final from = -_leftTo * (_side + _gap);
      _leftTo = 0;
      _x.value = from;
      KSpring.animateTo(context, _x, 0, KSpring.gentle);
    }
  }

  void _start(DragStartDetails _) {
    final width = context.size?.width ?? 1;
    _side = NowPlayingCoverBox.sideFor(width);
    _gap = KSpace.x6;
    _x.stop();
  }

  void _update(DragUpdateDetails d) {
    if (_leftTo != 0) return;
    var v = _x.value + d.delta.dx;
    if (v < 0 && !widget.hasNext) v = v.clamp(-coverSwipeResist * _side, 0);
    if (v > 0 && !widget.hasPrevious) v = v.clamp(0, coverSwipeResist * _side);
    _x.value = v;
  }

  Future<void> _end(DragEndDetails d) async {
    if (_leftTo != 0) return;
    final velocity = d.velocity.pixelsPerSecond.dx;
    final fast = velocity.abs() > coverSwipeFlingVelocity;
    final far = _x.value.abs() >= coverSwipeThreshold * _side;
    final sign = fast ? velocity.sign : _x.value.sign;
    final allowed = sign < 0 ? widget.hasNext : widget.hasPrevious;
    final commit = (fast || far) && sign != 0 && allowed;
    if (!commit) {
      await KSpring.animateTo(context, _x, 0, KSpring.snappy);
      return;
    }
    _leftTo = sign;
    sign < 0 ? widget.onNext() : widget.onPrevious();
    await _x.animateTo(
      sign * (_side + _gap),
      duration: KMotion.fast,
      curve: Curves.easeOut,
    );
    // No new track after a while (the change failed): come back.
    _giveUp = Timer(KMotion.slow * 2, () {
      if (!mounted || _leftTo == 0) return;
      _leftTo = 0;
      KSpring.animateTo(context, _x, 0, KSpring.snappy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragStart: _start,
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: _end,
      child: AnimatedBuilder(
        animation: _x,
        builder: (context, child) =>
            Transform.translate(offset: Offset(_x.value, 0), child: child),
        child: widget.child,
      ),
    );
  }
}
