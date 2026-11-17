import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../media/domain/cover_files.dart';
import '../../media/domain/track_id.dart';
import '../domain/queue_neighbours.dart';
import '../state/playback_providers.dart';
import '../state/queue_view_provider.dart';
import 'flight_source.dart';
import 'mini_player_body.dart';
import 'spring_to_rest.dart';
import 'track_cover.dart';

final _log = Logger('MiniPlayerCarousel');

/// Space between the current entry and a neighbour that peeks in.
const double miniCarouselGap = 12;

/// A drag past this share of the width changes track.
const double miniCarouselThreshold = 1 / 3;

/// A fling faster than this (px per ms) changes track at any distance.
const double miniCarouselFling = 0.5;

/// Furthest a drag pulls the cover where there is no neighbour.
const double miniCarouselResist = 40;

/// Drag distance [d] towards a missing neighbour: a rubber band that tends to
/// [miniCarouselResist].
double miniRubberBand(double d) =>
    d.sign * miniCarouselResist * (1 - math.exp(-d.abs() / 120));

/// True when a release at [dx] (px) with horizontal velocity [vx] (px per ms)
/// goes on to the neighbour: far enough, or a fast fling the same way.
bool miniCarouselCommits(double dx, double vx, double width) =>
    dx.abs() > width * miniCarouselThreshold ||
    (vx.sign == dx.sign && vx.abs() > miniCarouselFling);

/// The three entries shown while a drag or a slide runs.
class _Pin {
  const _Pin({
    required this.entryId,
    required this.current,
    required this.neighbours,
  });

  /// Entry that was current when the drag locked.
  final int entryId;
  final TrackId current;
  final QueueNeighbours neighbours;
}

/// Cover and text of the mini player that follow the finger sideways, with
/// the previous and next entries peeking in: left = next, right = previous.
/// Only this area moves; Play, Next and the seek band stay put.
///
/// The drag comes from the card's one arbiter: the owner calls [dragStart],
/// [dragUpdate], [dragEnd] and [dragCancel] through a [GlobalKey]. A release
/// that goes on runs the same command as the Next / Previous button at once
/// and slides the neighbour in; towards a missing neighbour the area snaps
/// back and the command reports the end of the queue or restarts the entry.
class MiniPlayerCarousel extends ConsumerStatefulWidget {
  const MiniPlayerCarousel({
    super.key,
    required this.cardHeight,
    required this.flight,
  });

  final double cardHeight;

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

  /// Offset when the drag locked (a spring back may still have been running).
  double _base = 0;

  /// True from [dragStart] to the end of the drag.
  bool _dragging = false;
  _Pin? _pin;

  /// The release went on: the neighbour slides in; [_slid] once it is there.
  bool _committed = false;
  bool _slid = false;
  Timer? _giveUp;

  @override
  void dispose() {
    _giveUp?.cancel();
    _x.dispose();
    super.dispose();
  }

  QueueNeighbours get _neighbours => _pin?.neighbours ?? QueueNeighbours.none;

  /// The drag locked to horizontal. False when it is not taken (the queue
  /// sheet is up, a slide is still running, nothing is current).
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
    // The area's own width: how far a neighbour sits and a swipe must go.
    _width = context.size?.width ?? 0;
    _base = _x.value;
    _dragging = true;
    setState(
      () => _pin = _Pin(
        entryId: entryId,
        current: trackId,
        neighbours: neighboursOf(view.items, view.current, view.repeat),
      ),
    );
    return true;
  }

  void dragUpdate(double dx) {
    if (!_dragging) return;
    final d = _base + dx;
    final towards = d < 0 ? _neighbours.next : _neighbours.previous;
    _x.value = towards is NoNeighbour ? miniRubberBand(d) : d;
  }

  void dragEnd(double dx, double vx) {
    if (!_dragging) return;
    _dragging = false;
    final pin = _pin!;
    final next = dx < 0;
    final neighbour = next ? _neighbours.next : _neighbours.previous;
    final controller = ref.read(playerControllerProvider);
    final changed = ref.read(nowPlayingProvider).value?.entryId != pin.entryId;
    if (neighbour is NoNeighbour) {
      // No neighbour: bounce, and let the command say why.
      _back();
      _run(next ? controller.next() : controller.previous());
      return;
    }
    if (changed || !miniCarouselCommits(dx, vx, _width)) {
      _back();
      return;
    }
    // Goes on: the same command as the button, at once; the slide follows.
    _committed = true;
    _slid = false;
    _run(next ? controller.next() : controller.previous());
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

  /// A committed slide ends once the neighbour is in and the entry changed.
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

  void _run(Future<void> command) {
    command.catchError((Object e, StackTrace s) {
      _log.warning('mini player command failed', e, s);
    });
  }

  /// What peeks in: nothing where there is no neighbour (the area only
  /// stretches there), a bare cover where the entry is not known yet.
  Widget? _slot(Neighbour n) => switch (n) {
    KnownNeighbour(:final item) => MiniPlayerBody(
      trackId: item.trackId,
      flight: null,
      cardHeight: widget.cardHeight,
    ),
    UnknownNeighbour() => const _EmptySlot(),
    NoNeighbour() => null,
  };

  @override
  Widget build(BuildContext context) {
    ref.listen(nowPlayingProvider.select((n) => n.value?.entryId), (_, _) {
      _settleIfDone();
    });
    // Keeps the queue provider live so a drag can read it without waiting;
    // no rebuild: the queue is read only when a drag locks.
    ref.listen(queueViewProvider, (_, _) {});
    final nowTrack = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    final pin = _pin;
    final current = pin?.current ?? nowTrack;
    if (current == null) return const SizedBox.shrink();
    final body = MiniPlayerBody(
      key: const ValueKey('current'),
      trackId: current,
      flight: widget.flight,
      cardHeight: widget.cardHeight,
    );
    final previous = pin == null ? null : _slot(pin.neighbours.previous);
    final next = pin == null ? null : _slot(pin.neighbours.next);
    final step = _width + miniCarouselGap;
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
      child: AnimatedBuilder(
        animation: _x,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            if (previous != null)
              Transform.translate(
                key: const ValueKey('previous'),
                offset: Offset(_x.value - step, 0),
                child: previous,
              ),
            Transform.translate(
              key: const ValueKey('currentSlot'),
              offset: Offset(_x.value, 0),
              child: body,
            ),
            if (next != null)
              Transform.translate(
                key: const ValueKey('next'),
                offset: Offset(_x.value + step, 0),
                child: next,
              ),
          ],
        ),
      ),
    );
  }
}

/// A neighbour whose entry is not known yet (the first entry of a new
/// shuffled pass): the placeholder cover, no text.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: KSpace.x2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TrackCover(
          coverKey: null,
          seed: '',
          size: CoverSize.thumb,
          dimension: KMediaCard.coverSize,
          radius: KMediaCard.coverRadius,
        ),
      ),
    );
  }
}
