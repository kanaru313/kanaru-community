import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';

/// Modal container: bottom sheet below [KBreakpoints.compactSheet], centred
/// dialog with the same content from there up.
///
/// The sheet has rounded top corners, a grip, a scrim, closes on Back
/// (including predictive back) and on dragging down. [fixedHeight] makes it
/// [maxHeightFraction] of the screen instead of fitting its content.
/// [useRootNavigator] shows it above every nested navigator (for example over
/// the shell's bottom bar and mini player).
Future<T?> showKSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool draggable = true,
  double maxHeightFraction = 0.85,
  bool fixedHeight = false,
  bool useRootNavigator = false,
}) {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= KBreakpoints.compactSheet) {
    return showDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (context) => Dialog(
        shape: KShape.of(KRadius.xl, continuous: true),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: KLayout.sheet,
            maxHeight: size.height * maxHeightFraction,
            minHeight: fixedHeight ? size.height * maxHeightFraction : 0,
          ),
          child: builder(context),
        ),
      ),
    );
  }
  final maxHeight = size.height * maxHeightFraction;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    enableDrag: draggable,
    shape: KShape.of(
      BorderRadius.vertical(top: KRadius.xl.topLeft),
      continuous: true,
    ),
    constraints: BoxConstraints(maxHeight: maxHeight),
    builder: (context) {
      // The keyboard shrinks the room the content may use.
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      final available = math.min(maxHeight, size.height - keyboard);
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard + KSpace.x2),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: available,
            minHeight: fixedHeight ? available : 0,
          ),
          child: builder(context),
        ),
      );
    },
  );
}
