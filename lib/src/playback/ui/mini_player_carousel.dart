import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/queue_neighbours.dart';
import '../state/playback_providers.dart';
import '../state/queue_view_provider.dart';
import 'flight_source.dart';
import 'mini_carousel_math.dart';
import 'mini_carousel_view.dart';
import 'mini_player_body.dart';
import 'spring_to_rest.dart';

final _log = Logger('MiniPlayerCarousel');

/// Cover and text of the mini player that follow the finger sideways, with
/// the previous and next entries peeking in. Only this area moves.
///
/// The card's one arbiter drives it through a [GlobalKey]: [dragStart],
/// [dragUpdate], [dragEnd], [dragCancel]. A release that is a real swipe runs
/// the Next / Previous button command at once; where there is a neighbour it
/// slides in, where there is none the area snaps back and the command reports
/// the end of the queue or restarts the entry.
class MiniPlayerCarousel extends ConsumerStatefulWidget {
  const MiniPlayerCarousel({
    super.key,
    required this.cardHeight,
    required this.radius,
    required this.flight,
  });

  final double cardHeight;

  /// Corner radius of the card the area is clipped to.
  final BorderRadius radius;

  /// Only the current entry's body hosts the flight pieces.
  final FlightSource? flight;

  @override
  ConsumerState<MiniPlayerCarousel> createState() => MiniPlayerCarouselState();
}

class MiniPlayerCarouselState extends ConsumerState<MiniPlayerCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
  );
  double _width = 0;
  double _base = 0; // offset when the drag locked (a spring may still run)
  bool _dragging = false; // from [dragStart] to the end of the drag
  MiniCarouselPin? _pin;
  // The release went on: the neighbour slides in; [_slid] once it is there.
  bool _committed = false;
  bool _slid = false;
  Timer? _giveUp;

  @override
  void dispose() {
    _giveUp?.cancel();
    _x.dispose();
    super.dispose();
  }

  /// The drag locked to horizontal. False when not taken (queue sheet up,
  /// slide running, nothing current).
  bool dragStart() {
    if (_dragging || _committed || widget.flight?.hidden.value == true) {
      return false;
    }
    final now = ref.read(nowPlayingProvider).value;
    final view = ref.read(queueViewProvider).value;
    final trackId = now?.trackId;
    final entryId = now?.entryId;
    if (trackId == null || entryId == null || view == null) return false;
    _giveUp?.cancel();
    _x.stop();
    _width = context.size?.width ?? 0;
    _base = _x.value;
    _dragging = true;
    setState(() => _pin = MiniCarouselPin.of(entryId, trackId, view));
    return true;
  }

  void dragUpdate(double dx) {
    if (!_dragging) return;
    final d = _base + dx;
    final towards = d < 0 ? _pin!.neighbours.next : _pin!.neighbours.previous;
    _x.value = towards is NoNeighbour ? miniRubberBand(d) : d;
  }

  void dragEnd(double dx, double vx) {
    if (!_dragging) return;
    _dragging = false;
    final pin = _pin!;
    final next = dx < 0;
    final neighbour = next ? _pin!.neighbours.next : _pin!.neighbours.previous;
    final changed = ref.read(nowPlayingProvider).value?.entryId != pin.entryId;
    // Entry changed under the finger, or not a real swipe: spring back.
    if (changed || !miniCarouselCommits(dx, vx, _width)) {
      _back();
      return;
    }
    if (neighbour is NoNeighbour) {
      _back();
      _run(next);
      return;
    }
    _committed = true;
    _slid = false;
    _run(next);
    animateSpringTo(
      context,
      _x,
      (next ? -1 : 1) * (_width + miniCarouselGap),
      KSpring.gentle,
      velocity: vx * 1000,
    ).then((_) {
      if (!mounted) return;
      _slid = true;
      _giveUp = Timer(KMotion.slow * 2.5, _abandon);
      _settleIfDone();
    });
  }

  void dragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _back();
  }

  /// Springs to rest and drops the pinned entries.
  void _back() {
    animateSpringTo(context, _x, 0, KSpring.gentle).then((_) {
      if (mounted && !_dragging && !_committed) setState(() => _pin = null);
    });
  }

  /// The entry did not change after a committed slide: come back.
  void _abandon() {
    if (!mounted || !_committed) return;
    _committed = false;
    _back();
  }

  /// A slide ends once the neighbour is in and the entry changed.
  void _settleIfDone() {
    final pin = _pin;
    if (!_committed || !_slid || pin == null) return;
    final entryId = ref.read(nowPlayingProvider).value?.entryId;
    if (entryId == pin.entryId) return;
    _giveUp?.cancel();
    _committed = false;
    _slid = false;
    _x.value = 0;
    setState(() => _pin = null);
  }

  void _run(bool next) {
    final controller = ref.read(playerControllerProvider);
    (next ? controller.next() : controller.previous()).catchError((
      Object e,
      StackTrace s,
    ) {
      _log.warning('mini player command failed', e, s);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(nowPlayingProvider.select((n) => n.value?.entryId), (_, _) {
      _settleIfDone();
    });
    // Keeps the queue provider live for a drag; no rebuild.
    ref.listen(queueViewProvider, (_, _) {});
    final nowTrack = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    final pin = _pin;
    final current = pin?.current ?? nowTrack;
    if (current == null) return const SizedBox.shrink();
    return MiniCarouselStrip(
      x: _x,
      radius: widget.radius,
      step: _width + miniCarouselGap,
      current: MiniPlayerBody(
        key: const ValueKey('current'),
        trackId: current,
        flight: widget.flight,
        cardHeight: widget.cardHeight,
      ),
      previous: miniCarouselSlot(pin?.neighbours.previous, widget.cardHeight),
      next: miniCarouselSlot(pin?.neighbours.next, widget.cardHeight),
    );
  }
}
