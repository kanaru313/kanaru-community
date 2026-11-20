import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_space.dart';
import 'k_start_arrows.dart';

/// One navigation area for start buttons: with focus on a start button, arrow
/// keys move it to the nearest enabled start button in that direction (tiles
/// of a [KStartTileGrid] and `SelectionRow.action` rows alike, disabled ones
/// skipped); Tab keeps walking in reading order. Arrows never leave the area
/// from a start button, so a footer button below is reached with Tab only.
/// Arrow keys on any other focusable inside the area (a text field, a ruler)
/// are not touched. Put only start buttons in an area.
///
/// A [KStartTileGrid] outside any area wraps itself in one; put tiles and rows
/// that should share arrow navigation under a single [KStartArea].
class KStartArea extends StatefulWidget {
  const KStartArea({super.key, required this.child});

  final Widget child;

  /// True when [context] sits below a [KStartArea].
  static bool contains(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AreaMarker>() != null;

  @override
  State<KStartArea> createState() => _KStartAreaState();
}

class _AreaMarker extends InheritedWidget {
  const _AreaMarker({required super.child});

  @override
  bool updateShouldNotify(_AreaMarker old) => false;
}

class _KStartAreaState extends State<KStartArea> {
  final _root = FocusNode(
    debugLabel: 'KStartArea',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _root.dispose();
    super.dispose();
  }

  void _move(TraversalDirection direction) {
    final current = FocusManager.instance.primaryFocus;
    if (current == null) return;
    // Only start buttons are sources and targets.
    final candidates = [
      for (final node in _root.traversalDescendants)
        if (node.context != null && KStartMarker.isIn(node.context!)) node,
    ];
    if (!candidates.contains(current)) return;
    final from = current.rect;
    FocusNode? best;
    var bestScore = double.infinity;
    for (final node in candidates) {
      if (node == current) continue;
      final score = _score(from, node.rect, direction);
      if (score != null && score < bestScore) {
        best = node;
        bestScore = score;
      }
    }
    // Same call as Tab traversal: also scrolls the target into view.
    if (best != null) {
      FocusTraversalPolicy.defaultTraversalRequestFocusCallback(best);
    }
  }

  /// Lower is nearer; null when [to] does not lie in [direction] of [from].
  /// Along-axis gap plus twice the cross-axis centre offset, so a tile right
  /// below beats one diagonal.
  static double? _score(Rect from, Rect to, TraversalDirection direction) {
    const slack = 1.0;
    final horizontal =
        direction == TraversalDirection.left ||
        direction == TraversalDirection.right;
    final double gap;
    switch (direction) {
      case TraversalDirection.down:
        gap = to.top - from.bottom;
      case TraversalDirection.up:
        gap = from.top - to.bottom;
      case TraversalDirection.right:
        gap = to.left - from.right;
      case TraversalDirection.left:
        gap = from.left - to.right;
    }
    if (gap < -slack) return null;
    final cross = horizontal
        ? (to.center.dy - from.center.dy).abs()
        : (to.center.dx - from.center.dx).abs();
    // Left / right stay on the same row: a candidate must overlap vertically.
    if (horizontal && (to.bottom <= from.top || to.top >= from.bottom)) {
      return null;
    }
    return gap.clamp(0, double.infinity) + 2 * cross;
  }

  @override
  Widget build(BuildContext context) {
    return _AreaMarker(
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Focus(
          focusNode: _root,
          child: Actions(
            actions: {
              KStartMoveIntent: CallbackAction<KStartMoveIntent>(
                onInvoke: (intent) {
                  _move(intent.direction);
                  return null;
                },
              ),
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Column rules of [KStartTileGrid], all in one place. Touch shells: 3
/// columns, 2 when the grid is narrower than [_narrowWidth] (a third of it
/// cannot hold "15 phút" at the tile title size), 1 from 200 % text. Desktop:
/// 3 columns, 2 from 200 % text.
const int _touchColumns = 3;
const int _touchColumnsNarrow = 2;
const int _touchColumnsLarge = 1;
const int _desktopColumns = 3;
const int _desktopColumnsLarge = 2;
const double _narrowWidth = 360;
const double _largeTextScale = 1.99;

/// Grid of [KStartTile]s: columns follow the rules above. Tiles of a row
/// share one height.
class KStartTileGrid extends StatelessWidget {
  const KStartTileGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _grid(
        context,
        _columnsFor(
          desktop: FormFactor.of(context) == FormFactor.desktop,
          large:
              MediaQuery.textScalerOf(context).scale(14) / 14 >=
              _largeTextScale,
          width: constraints.maxWidth,
        ),
      ),
    );
  }

  static int _columnsFor({
    required bool desktop,
    required bool large,
    required double width,
  }) {
    if (desktop) return large ? _desktopColumnsLarge : _desktopColumns;
    if (large) return _touchColumnsLarge;
    return width < _narrowWidth ? _touchColumnsNarrow : _touchColumns;
  }

  Widget _grid(BuildContext context, int columns) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: KSpace.x2));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: KSpace.x2),
                Expanded(
                  child: i + c < children.length
                      ? children[i + c]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    final grid = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
    return KStartArea.contains(context) ? grid : KStartArea(child: grid);
  }
}
