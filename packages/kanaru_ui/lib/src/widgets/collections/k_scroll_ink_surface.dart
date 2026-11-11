import 'package:material_ui/material_ui.dart';

/// Gives a scrolling body its own ink layer: hover, focus and splash of a
/// card that scrolls half under a header above the body are clipped to the
/// body instead of painting over that header.
///
/// Ink is painted by the nearest [Material] ancestor, which is otherwise the
/// page's, so it is not clipped by the scroll view. This transparent Material
/// sits right around the body, inside a [ClipRect], so its box is the body's.
class KScrollInkSurface extends StatelessWidget {
  const KScrollInkSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Material(type: MaterialType.transparency, child: child),
  );
}
