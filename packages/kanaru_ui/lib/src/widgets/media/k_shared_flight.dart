import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';

/// One piece that flies between two rects (a cover, a title block, a button).
class KFlightLayer {
  const KFlightLayer({
    required this.from,
    required this.to,
    required this.builder,
  });

  /// Where the piece starts, in the flight's own coordinates. Null when the
  /// source is gone (a mini player that left, a rotation): the piece then
  /// fades in at [to] instead of flying.
  final Rect? from;

  /// Where the piece ends.
  final Rect to;

  /// Builds the piece for the current [rect] and progress `t` (0 = at
  /// [from], 1 = at [to]), so sizes and text styles can follow.
  final Widget Function(BuildContext context, Rect rect, double t) builder;
}

/// Shared-element flight: every layer moves from its [KFlightLayer.from] rect
/// to its [KFlightLayer.to] rect as [progress] goes 0 to 1 (and back). The
/// caller drives [progress] (an animation or any listenable value): a timed animation, or a drag.
///
/// Layers fade instead of fly when their source rect is missing or the
/// platform asks for reduced motion. Each layer repaints on its own.
class KSharedFlight extends StatelessWidget {
  const KSharedFlight({
    super.key,
    required this.progress,
    required this.layers,
  });

  final ValueListenable<double> progress;
  final List<KFlightLayer> layers;

  /// The rect of [layer] at progress [t]; its `to` rect when it has no source
  /// or [fade] is set.
  static Rect rectAt(KFlightLayer layer, double t, {bool fade = false}) {
    final from = layer.from;
    if (from == null || fade) return layer.to;
    return Rect.lerp(from, layer.to, t.clamp(0.0, 1.0))!;
  }

  /// Opacity of [layer] at progress [t]: 1 while it flies, `t` while it fades.
  static double opacityAt(KFlightLayer layer, double t, {bool fade = false}) =>
      layer.from == null || fade ? t.clamp(0.0, 1.0) : 1;

  @override
  Widget build(BuildContext context) {
    final fade = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final layer in layers)
              Positioned.fromRect(
                rect: rectAt(layer, t, fade: fade),
                child: RepaintBoundary(
                  child: Opacity(
                    opacity: opacityAt(layer, t, fade: fade),
                    child: layer.builder(
                      context,
                      rectAt(layer, t, fade: fade),
                      t,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
