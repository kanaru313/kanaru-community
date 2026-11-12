import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import 'readable_gradient_stops.dart';

/// How long the tint takes to move to new colours or to fade in and out.
const coverTintTransition = Duration(milliseconds: 300);

/// Full-bleed background tinted by a gradient of a cover's colours: up to four
/// readable stops (see [readableGradientStops]), diagonal from the top left to
/// the bottom right, translucent over [base] (default: the theme surface), so
/// text on it keeps its contrast. Never drives the app theme.
///
/// Colour changes tween over [coverTintTransition] (nothing with reduced
/// motion). Losing the colours fades only the alpha, so the hue does not slide
/// through grey. The child sits outside the tween and is not rebuilt by it.
///
/// - [palette]: the cover's colours; null = none.
/// - [loading]: the colours are not known yet. A null [palette] while loading
///   keeps the palette on screen (no flash to "no tint"), then tweens to the
///   new one; only a settled null ([loading] false) fades out and clears it.
///   Chosen over making callers carry the palette: the widget already holds
///   it.
/// - [fadeIn]: until a palette has ever been given nothing is drawn (not even
///   [base]); the first palette fades in. Later behaviour is as without it.
/// - [strength] (0-1): multiplies the stops' alpha. Applied on every frame
///   without touching the colour tween, so it can be animated by the caller.
class CoverTintBackground extends StatefulWidget {
  const CoverTintBackground({
    super.key,
    required this.palette,
    required this.child,
    this.loading = false,
    this.strength = 1,
    this.fadeIn = false,
    this.base,
  });

  final List<Color>? palette;
  final bool loading;
  final double strength;
  final bool fadeIn;
  final Color? base;
  final Widget child;

  @override
  State<CoverTintBackground> createState() => _CoverTintBackgroundState();
}

class _CoverTintBackgroundState extends State<CoverTintBackground> {
  /// The palette on screen: set by a palette, cleared by a settled null, kept
  /// while loading.
  List<Color>? _shown;

  /// True until the first build that draws, so [fadeIn] starts from nothing.
  bool _firstDraw = true;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    if (palette != null) {
      _shown = palette;
    } else if (!widget.loading) {
      _shown = null;
    }
    final scheme = Theme.of(context).colorScheme;
    final base = widget.base ?? scheme.surface;

    final shown = _shown;
    // Nothing drawn before the first palette; the Stack stays so the child
    // keeps its state when the layer appears.
    if (widget.fadeIn && _firstDraw && shown == null) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: const SizedBox.shrink()),
          widget.child,
        ],
      );
    }
    final stops = shown == null
        ? List.filled(maxGradientStops, const Color(0x00000000))
        : _padded(
            readableGradientStops(
              shown,
              base: base,
              onSurface: scheme.onSurface,
              onSurfaceVariant: scheme.onSurfaceVariant,
              brightness: scheme.brightness,
            ),
          );
    final from = _firstDraw && widget.fadeIn
        ? _Stops(
            List.filled(maxGradientStops, stops.first.withValues(alpha: 0)),
          )
        : null;
    _firstDraw = false;
    final strength = widget.strength.clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: TweenAnimationBuilder<_Stops>(
              // The surface jumps at once on a light/dark switch; a fade from
              // the other brightness's stops could briefly break the text
              // contrast, so a new brightness starts at its own stops.
              key: ValueKey(scheme.brightness),
              tween: _StopsTween(begin: from, end: _Stops(stops)),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : coverTintTransition,
              curve: Curves.easeInOut,
              // Two layers: a BoxDecoration ignores its color once it has a
              // gradient, and the gradient is translucent.
              builder: (context, value, _) => ColoredBox(
                color: base,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        for (final c in value.colors)
                          c.withValues(alpha: c.a * strength),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// [stops] padded to [maxGradientStops] by repeating the last one, so two
/// gradients always tween stop by stop.
List<Color> _padded(List<Color> stops) => [
  for (var i = 0; i < maxGradientStops; i++)
    stops[math.min(i, stops.length - 1)],
];

/// A fixed-length list of gradient stops, comparable for the tween.
@immutable
class _Stops {
  const _Stops(this.colors);

  final List<Color> colors;

  @override
  bool operator ==(Object other) =>
      other is _Stops && listEquals(other.colors, colors);

  @override
  int get hashCode => Object.hashAll(colors);
}

class _StopsTween extends Tween<_Stops> {
  _StopsTween({super.begin, super.end});

  @override
  _Stops lerp(double t) {
    final from = begin ?? end!, to = end!;
    return _Stops([
      for (var i = 0; i < maxGradientStops; i++)
        Color.lerp(
          _towards(from.colors[i], to.colors[i]),
          _towards(to.colors[i], from.colors[i]),
          t,
        )!,
    ]);
  }
}

/// A fully transparent [stop] takes [other]'s hue, so fading between a cover
/// and no colours changes only the opacity, never through a dark tint.
Color _towards(Color stop, Color other) =>
    stop.a == 0 ? other.withValues(alpha: 0) : stop;
