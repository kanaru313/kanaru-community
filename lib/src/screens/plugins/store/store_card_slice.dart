import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// One row of a long list drawn as a slice of the section card: the card's
/// tonal fill with the large radius on the top of the first and the bottom of
/// the last slice. Each slice is its own list item, so a long list builds only
/// the rows that are on screen.
class CardSlice extends StatelessWidget {
  const CardSlice({
    super.key,
    required this.child,
    this.first = false,
    this.last = false,
  });

  final Widget child;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: first ? KRadius.lg.topLeft : Radius.zero,
          bottom: last ? KRadius.lg.bottomLeft : Radius.zero,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
