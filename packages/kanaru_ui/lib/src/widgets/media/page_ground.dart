import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// The one gradient a page ground paints: diagonal from the top left to the
/// bottom right of the ground, [stops] spread evenly, their alpha multiplied
/// by [strength] (0-1). The ground's own layer and every layer that continues
/// it (a pinned bar) build it here, so the geometry has no second copy.
LinearGradient pageGroundGradient(List<Color> stops, double strength) =>
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [for (final c in stops) c.withValues(alpha: c.a * strength)],
    );

/// What a `CoverTintBackground` is painting right now, readable by widgets
/// below it that must continue the same picture (see [KPageGround]).
///
/// Owned and updated by the ground; listeners are told on every change of the
/// colours (each frame of a tween), of the strength and of the base.
class KPageGroundPaint extends ChangeNotifier {
  KPageGroundPaint({
    required Color base,
    required List<Color> stops,
    required double strength,
    required bool drawn,
  }) {
    _base = base;
    _stops = stops;
    _strength = strength;
    _drawn = drawn;
  }

  late Color _base;
  late List<Color> _stops;
  late double _strength;
  late bool _drawn;

  /// The colour under the gradient.
  Color get base => _base;

  /// Whether the ground draws anything yet. False before the first palette
  /// of a fading-in ground: what is behind it shows, so a continuation falls
  /// back to the surface.
  bool get drawn => _drawn;

  /// The gradient as painted this frame.
  LinearGradient get gradient => pageGroundGradient(_stops, _strength);

  /// Called by the ground only.
  void update({
    required Color base,
    required List<Color> stops,
    required double strength,
    required bool drawn,
  }) {
    if (base == _base &&
        strength == _strength &&
        drawn == _drawn &&
        listEquals(stops, _stops)) {
      return;
    }
    _base = base;
    _stops = stops;
    _strength = strength;
    _drawn = drawn;
    notifyListeners();
  }
}

/// Exposes the [KPageGroundPaint] of the nearest `CoverTintBackground` above.
class KPageGround extends InheritedWidget {
  const KPageGround({super.key, required this.paint, required super.child});

  final KPageGroundPaint paint;

  /// The nearest ground, registering [context] to rebuild when the ground
  /// above it is replaced; null when there is none. The colours themselves
  /// are a listenable: they never rebuild a dependent.
  static KPageGroundPaint? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KPageGround>()?.paint;

  @override
  bool updateShouldNotify(KPageGround old) => old.paint != paint;
}

/// The box of a page ground: lets a layer deep in the page find where it sits
/// inside the ground.
class PageGroundBox extends SingleChildRenderObjectWidget {
  const PageGroundBox({super.key, required this.paint, super.child});

  final KPageGroundPaint paint;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderPageGround(paint);

  @override
  void updateRenderObject(BuildContext context, RenderPageGround renderObject) {
    renderObject.paint_ = paint;
  }
}

class RenderPageGround extends RenderProxyBox {
  RenderPageGround(this.paint_);

  /// The paint this box belongs to (named apart from [RenderObject.paint]).
  KPageGroundPaint paint_;

  /// Bars that continue this ground and must repaint when it lays out.
  final Set<RenderObject> _bars = {};

  void addBar(RenderObject bar) => _bars.add(bar);

  void removeBar(RenderObject bar) => _bars.remove(bar);

  @override
  void performLayout() {
    super.performLayout();
    // A resize of the ground can move a viewport inside it without relaying
    // the viewport out (a page centred at a maximum width): its bar would
    // keep a gradient shifted for the old place. Paint only; the paint
    // notifier is not used because its listeners rebuild widgets.
    for (final bar in _bars) {
      bar.markNeedsPaint();
    }
  }

  /// The nearest ground above [descendant], or null.
  static RenderPageGround? nearestAbove(RenderObject descendant) {
    RenderObject? node = descendant.parent;
    while (node != null && node is! RenderPageGround) {
      node = node.parent;
    }
    return node is RenderPageGround ? node : null;
  }

  /// Where [descendant]'s top left is inside the ground of [expected] above
  /// it, and the ground's size. Null when the nearest ground above is not that
  /// one (an overlay entry, a replaced ground) or is not laid out.
  ///
  /// Read while painting, when every offset on the way up is final. It is
  /// fresh whenever the descendant repaints, which the caller guarantees on
  /// its own layout, on this ground's layout ([addBar]) and on the paint's
  /// notifications. A viewport that moves inside the ground with none of
  /// those (a `Transform` or an animated alignment above it) is not seen.
  static ({Offset origin, Size size})? placementOf(
    RenderBox descendant,
    KPageGroundPaint expected,
  ) {
    final node = nearestAbove(descendant);
    if (node == null || node.paint_ != expected || !node.hasSize) return null;
    final origin = MatrixUtils.transformPoint(
      descendant.getTransformTo(node),
      Offset.zero,
    );
    return (origin: origin, size: node.size);
  }
}
