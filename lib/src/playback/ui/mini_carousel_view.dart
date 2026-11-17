import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../media/domain/cover_files.dart';
import '../domain/queue_neighbours.dart';
import 'mini_player_body.dart';
import 'track_cover.dart';

/// What peeks in for [n] (null: no drag pinned the entries): nothing where there is no neighbour (the area only
/// stretches there), a bare cover where the entry is not known yet.
Widget? miniCarouselSlot(Neighbour? n, double cardHeight) => switch (n) {
  KnownNeighbour(:final item) => MiniPlayerBody(
    trackId: item.trackId,
    flight: null,
    cardHeight: cardHeight,
  ),
  UnknownNeighbour() => const _EmptySlot(),
  NoNeighbour() || null => null,
};

/// The sliding stack of the carousel: [current] at [x], [previous] one [step]
/// to the right of it and [next] one [step] to the left, clipped to the left
/// corners of the card's [radius].
class MiniCarouselStrip extends StatelessWidget {
  const MiniCarouselStrip({
    super.key,
    required this.x,
    required this.radius,
    required this.step,
    required this.current,
    this.previous,
    this.next,
  });

  final Animation<double> x;
  final BorderRadius radius;
  final double step;
  final Widget current;
  final Widget? previous;
  final Widget? next;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(left: radius.topLeft),
      child: AnimatedBuilder(
        animation: x,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            if (previous != null)
              Transform.translate(
                key: const ValueKey('previous'),
                offset: Offset(x.value - step, 0),
                child: previous,
              ),
            Transform.translate(
              key: const ValueKey('currentSlot'),
              offset: Offset(x.value, 0),
              child: current,
            ),
            if (next != null)
              Transform.translate(
                key: const ValueKey('next'),
                offset: Offset(x.value + step, 0),
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
