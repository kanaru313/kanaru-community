import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import 'page_ground.dart';
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
/// Provides a [KPageGround] to its descendants: the colours it paints this
/// frame, so a layer that floats over the page (a pinned bar) can continue
/// the same picture instead of covering it with a flat colour.
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

class _CoverTintBackgroundState extends State<CoverTintBackground>
    with SingleTickerProviderStateMixin {
  /// The palette on screen: set by a palette, cleared by a settled null, kept
  /// while loading.
  List<Color>? _shown;

  /// False until the first sync that draws, so [fadeIn] starts from nothing.
  bool _started = false;
  Brightness? _brightness;
  Color _base = const Color(0x00000000);

  /// The tween between two stop lists, owned here (not by a builder) so the
  /// current colours can be published to widgets below as a listenable.
  late final AnimationController _controller;
  List<Color> _from = const [];
  List<Color> _to = const [];
  KPageGroundPaint? _paint;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1)
      ..addListener(_publish);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CoverTintBackground old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    _paint?.dispose();
    super.dispose();
  }

  double get _strength => widget.strength.clamp(0.0, 1.0);

  /// The stops between [_from] and [_to] at the controller's position.
  List<Color> _current() => _StopsTween(
    begin: _Stops(_from),
    end: _Stops(_to),
  ).transform(Curves.easeInOut.transform(_controller.value)).colors;

  void _publish() {
    final paint = _paint;
    if (paint == null || !_started) return;
    paint.update(
      base: _base,
      stops: _current(),
      strength: _strength,
      drawn: true,
    );
  }

  /// Takes the palette, theme and strength of the widget: starts a tween when
  /// the stops changed, publishes the result to [_paint].
  void _sync() {
    final palette = widget.palette;
    if (palette != null) {
      _shown = palette;
    } else if (!widget.loading) {
      _shown = null;
    }
    final scheme = Theme.of(context).colorScheme;
    _base = widget.base ?? scheme.surface;
    final shown = _shown;
    // Nothing drawn before the first palette of a fading-in ground.
    if (!_started && widget.fadeIn && shown == null) {
      final none = List.filled(maxGradientStops, const Color(0x00000000));
      final paint = _paint;
      if (paint == null) {
        _paint = KPageGroundPaint(
          base: _base,
          stops: none,
          strength: _strength,
          drawn: false,
        );
      } else {
        paint.update(
          base: _base,
          stops: none,
          strength: _strength,
          drawn: false,
        );
      }
      return;
    }
    final stops = shown == null
        ? List.filled(maxGradientStops, const Color(0x00000000))
        : _padded(
            readableGradientStops(
              shown,
              base: _base,
              onSurface: scheme.onSurface,
              onSurfaceVariant: scheme.onSurfaceVariant,
              brightness: scheme.brightness,
            ),
          );
    if (!_started) {
      _started = true;
      _brightness = scheme.brightness;
      _to = stops;
      _from = widget.fadeIn
          ? List.filled(maxGradientStops, stops.first.withValues(alpha: 0))
          : stops;
      _paint ??= KPageGroundPaint(
        base: _base,
        stops: stops,
        strength: _strength,
        drawn: true,
      );
      _animate(MediaQuery.disableAnimationsOf(context));
    } else if (scheme.brightness != _brightness) {
      // The surface jumps at once on a light/dark switch; a fade from the
      // other brightness's stops could briefly break the text contrast, so a
      // new brightness starts at its own stops.
      _brightness = scheme.brightness;
      _from = _to = stops;
      _controller.value = 1;
    } else if (!listEquals(stops, _to)) {
      _from = _current();
      _to = stops;
      _animate(MediaQuery.disableAnimationsOf(context));
    }
    _publish();
  }

  void _animate(bool instant) {
    if (listEquals(_from, _to)) {
      _controller.value = 1;
      return;
    }
    _controller.duration = instant ? Duration.zero : coverTintTransition;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final paint = _paint!;
    return KPageGround(
      paint: paint,
      child: PageGroundBox(
        paint: paint,
        // The Stack stays when nothing is drawn yet so the child keeps its
        // state when the layer appears.
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: !_started
                  ? const SizedBox.shrink()
                  : RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: paint,
                        // Two layers: a BoxDecoration ignores its color once it
                        // has a gradient, and the gradient is translucent.
                        builder: (context, _) => ColoredBox(
                          color: paint.base,
                          child: DecoratedBox(
                            decoration: BoxDecoration(gradient: paint.gradient),
                          ),
                        ),
                      ),
                    ),
            ),
            widget.child,
          ],
        ),
      ),
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
