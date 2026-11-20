import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_space.dart';

/// One navigation area for start buttons: arrow keys move focus to the nearest
/// enabled start button in that direction (tiles of a [KStartTileGrid] and
/// `SelectionRow(action: true)` rows alike, disabled ones skipped); Tab keeps
/// walking in reading order. Arrows never leave the area, so a footer button
/// below is reached with Tab only.
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

class _Move extends Intent {
  const _Move(this.direction);
  final TraversalDirection direction;
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
    final candidates = _root.traversalDescendants.toList();
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
    best?.requestFocus();
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
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return _AreaMarker(
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Focus(
          focusNode: _root,
          child: Shortcuts(
            shortcuts: {
              const SingleActivator(LogicalKeyboardKey.arrowUp): const _Move(
                TraversalDirection.up,
              ),
              const SingleActivator(LogicalKeyboardKey.arrowDown): const _Move(
                TraversalDirection.down,
              ),
              const SingleActivator(LogicalKeyboardKey.arrowLeft): _Move(
                rtl ? TraversalDirection.right : TraversalDirection.left,
              ),
              const SingleActivator(LogicalKeyboardKey.arrowRight): _Move(
                rtl ? TraversalDirection.left : TraversalDirection.right,
              ),
            },
            child: Actions(
              actions: {
                _Move: CallbackAction<_Move>(
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
      ),
    );
  }
}

/// Grid of [KStartTile]s: 2 columns on touch shells, 3 on desktop; 1 / 2 from
/// 200 % text. Tiles of a row share one height.
class KStartTileGrid extends StatelessWidget {
  const KStartTileGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final large = MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.99;
    final columns = (desktop ? 3 : 2) - (large ? 1 : 0);
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
