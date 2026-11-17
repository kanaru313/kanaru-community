import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../media/page_ground.dart';

/// Page of a library item (album, artist, genre): a [header] and list
/// [slivers].
///
/// Narrow (< [wideBreakpoint] px, measured on the page, not the window): the
/// header sits above the list in one scroll. Wide: a fixed left column of
/// [columnWidth] holds the header, aligned to the column bottom and scrolling
/// on its own when the window is short; the slivers scroll on the right.
///
/// It draws no background: a page tints itself by putting the layout (and its
/// header) inside a `CoverTintBackground`.
class KDetailLayout extends StatelessWidget {
  const KDetailLayout({super.key, required this.header, required this.slivers});

  final Widget header;
  final List<Widget> slivers;

  /// Page width at which the two-column layout starts.
  static const double wideBreakpoint = 840;
  static const double columnWidth = 320;

  /// Whether the [header] below this layout sits in the wide left column.
  /// False outside a [KDetailLayout].
  static bool isWide(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DetailMode>()?.wide ?? false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;
        final Widget content = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: columnWidth,
                    child: LayoutBuilder(
                      builder: (context, column) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: column.maxHeight,
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: header,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: CustomScrollView(slivers: slivers)),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: header),
                  ...slivers,
                ],
              );
        return _DetailMode(wide: wide, child: content);
      },
    );
  }
}

/// Sliver that pins [child] (a bar of fixed [height]) on the page's own
/// ground, so a bar over a scrolling list is no seam in the page.
///
/// The bar is opaque: the page ground's base colour plus its gradient, as the
/// ground paints it at the bar's place in the page (the bar paints the
/// gradient shifted by its position, so tint and bar line up at rest, while
/// the bar slides under the header and while the tint animates). A page
/// without a ground (`CoverTintBackground`) gets plain `surface`. No blur:
/// nothing is drawn through the bar, so nothing needs a backdrop filter.
class KStickyBarSliver extends StatelessWidget {
  const KStickyBarSliver({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _BarDelegate(
        height: height,
        ground: KPageGround.maybeOf(context),
        surface: Theme.of(context).colorScheme.surface,
        child: child,
      ),
    );
  }
}

class _BarDelegate extends SliverPersistentHeaderDelegate {
  _BarDelegate({
    required this.height,
    required this.ground,
    required this.surface,
    required this.child,
  });

  final double height;
  final KPageGroundPaint? ground;
  final Color surface;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(
    height: height,
    child: _GroundedBar(ground: ground, surface: surface, child: child),
  );

  @override
  bool shouldRebuild(_BarDelegate old) =>
      height != old.height ||
      child != old.child ||
      ground != old.ground ||
      surface != old.surface;
}

class _GroundedBar extends SingleChildRenderObjectWidget {
  const _GroundedBar({
    required this.ground,
    required this.surface,
    required super.child,
  });

  final KPageGroundPaint? ground;
  final Color surface;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGroundedBar(ground, surface);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGroundedBar renderObject,
  ) {
    renderObject
      ..ground = ground
      ..surface = surface;
  }
}

/// Paints the page ground under its child: [surface] without a drawn ground,
/// else the ground's base and its gradient shaded for the whole ground's rect
/// and shifted by this box's place in it. Repaints when the ground changes
/// (each frame of a tint tween) and, like any box, after every layout.
class _RenderGroundedBar extends RenderProxyBox {
  _RenderGroundedBar(this._ground, this._surface);

  KPageGroundPaint? _ground;
  Color _surface;

  set ground(KPageGroundPaint? value) {
    if (value == _ground) return;
    if (attached) _ground?.removeListener(markNeedsPaint);
    _ground = value;
    if (attached) value?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set surface(Color value) {
    if (value == _surface) return;
    _surface = value;
    markNeedsPaint();
  }

  /// The ground box this bar registered with, to repaint when it lays out.
  RenderPageGround? _groundBox;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _ground?.addListener(markNeedsPaint);
    _groundBox = RenderPageGround.nearestAbove(this)?..addBar(this);
  }

  @override
  void detach() {
    _ground?.removeListener(markNeedsPaint);
    _groundBox?.removeBar(this);
    _groundBox = null;
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final rect = offset & size;
    final canvas = context.canvas;
    final ground = _ground;
    final placement = ground != null && ground.drawn
        ? RenderPageGround.placementOf(this, ground)
        : null;
    if (ground == null || placement == null) {
      canvas.drawRect(rect, Paint()..color = _surface);
    } else {
      canvas.drawRect(rect, Paint()..color = ground.base);
      // The ground's rect in this box's coordinates, moved to the paint offset.
      final groundRect = (offset - placement.origin) & placement.size;
      canvas.drawRect(
        rect,
        Paint()..shader = ground.gradient.createShader(groundRect),
      );
    }
    super.paint(context, offset);
  }
}

class _DetailMode extends InheritedWidget {
  const _DetailMode({required this.wide, required super.child});

  final bool wide;

  @override
  bool updateShouldNotify(_DetailMode old) => old.wide != wide;
}
