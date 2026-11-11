import 'package:material_ui/material_ui.dart';

/// A scroll controller whose first layout keeps the starting offset inside
/// the content: a short queue that "starts at row 40" simply starts at the
/// top, with no frame drawn past the end.
class QueueScrollController extends ScrollController {
  QueueScrollController({super.initialScrollOffset});

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _QueueScrollPosition(
    physics: physics,
    context: context,
    initialPixels: initialScrollOffset,
    oldPosition: oldPosition,
  );
}

class _QueueScrollPosition extends ScrollPositionWithSingleContext {
  _QueueScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.oldPosition,
  });

  bool _clamped = false;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    if (!_clamped && hasPixels) {
      _clamped = true;
      final inside = pixels.clamp(minScrollExtent, maxScrollExtent);
      if (inside != pixels) {
        correctPixels(inside);
        // The viewport laid out with the old offset: ask for another pass.
        return false;
      }
    }
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }
}
