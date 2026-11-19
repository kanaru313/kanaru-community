import 'dart:math' as math;

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

const double _previewHeight = 40;
const int _waveBars = 44;
const double _playedFraction = 0.38;

/// A small drawing of the waveform seek bar for its preview card.
class WaveformSeekPreview extends StatelessWidget {
  const WaveformSeekPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final played = (_waveBars * _playedFraction).round();
    return ExcludeSemantics(
      child: SizedBox(
        height: _previewHeight,
        child: Row(
          children: [
            for (var i = 0; i < _waveBars; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor: _barHeight(i),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: i < played
                            ? scheme.primary
                            : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: KRadius.full,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A fixed, varied height in 0.2 .. 1 so the drawing never changes.
  static double _barHeight(int i) =>
      0.2 + 0.8 * (math.sin(i * 1.7) * math.cos(i * 0.45)).abs();
}

/// A small drawing of the flat seek bar for its preview card.
class FlatSeekPreview extends StatelessWidget {
  const FlatSeekPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const played = 38, left = 62; // flex of the two sides of the thumb
    Widget track(Color color) => DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: KRadius.full),
      child: const SizedBox(height: 4),
    );
    return ExcludeSemantics(
      child: SizedBox(
        height: _previewHeight,
        child: Row(
          children: [
            Expanded(flex: played, child: track(scheme.primary)),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 12),
            ),
            Expanded(
              flex: left,
              child: track(scheme.onSurfaceVariant.withValues(alpha: 0.3)),
            ),
          ],
        ),
      ),
    );
  }
}
