import 'dart:math' as math;

import '../../media/domain/track_id.dart';
import '../domain/playback_views.dart';
import '../domain/queue_neighbours.dart';

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

/// True when a release at [dx] (px, the raw finger distance) with horizontal
/// velocity [vx] (px per ms) is a real swipe: far enough, or a fast fling the
/// same way. It goes on to the neighbour, or runs the end-of-queue command
/// where there is none.
bool miniCarouselCommits(double dx, double vx, double width) =>
    dx.abs() > width * miniCarouselThreshold ||
    (vx.sign == dx.sign && vx.abs() > miniCarouselFling);

/// The three entries shown while a drag or a slide runs.
class MiniCarouselPin {
  const MiniCarouselPin({
    required this.entryId,
    required this.current,
    required this.neighbours,
  });

  /// Pins [entryId] / [trackId] with the neighbours in [view].
  factory MiniCarouselPin.of(int entryId, TrackId trackId, QueueView view) =>
      MiniCarouselPin(
        entryId: entryId,
        current: trackId,
        neighbours: neighboursOf(view.items, view.current, view.repeat),
      );

  /// Entry that was current when the drag locked.
  final int entryId;
  final TrackId current;
  final QueueNeighbours neighbours;
}
