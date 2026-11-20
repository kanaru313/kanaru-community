import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_row_edges.dart';
import 'k_sheet_modal.dart';

/// Look of [showKSheet].
enum KSheetDialog {
  /// The app's usual sheet and dialog.
  standard,

  /// A modal dialog (420 wide, 520 from 200 % text, scale-in, scrolls when
  /// taller than the window) from 600 dp up, and a soft bottom sheet (top
  /// radius 28, 92 % high, faint `primary` glow) below.
  modal,
}

/// Modal container: bottom sheet below [KBreakpoints.compactSheet], centred
/// dialog with the same content from there up.
///
/// The sheet has rounded top corners, a grip, a scrim, closes on Back
/// (including predictive back) and on dragging down. [fixedHeight] makes it
/// [maxHeightFraction] of the screen instead of fitting its content.
/// Rows inside follow the surface: [KRowEdges.fullBleed] in the sheet,
/// [KRowEdges.inset] in the dialog (see [KRowEdgesScope]).
/// [useRootNavigator] shows it above every nested navigator (for example over
/// the shell's bottom bar and mini player).
///
/// [dialog] picks the look ([KSheetDialog.modal]: content scrolls, so it must
/// not hold an `Expanded`; [fixedHeight] then only applies to the sheet, and
/// [maxHeightFraction] is ignored: the modal look has its own sizes, 92 % high
/// for the sheet and the window minus margins for the dialog).
/// Esc closes the modal and is consumed by it. [returnFocus] gets focus after
/// the route closes, only while it is still attached to the tree.
Future<T?> showKSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool draggable = true,
  double maxHeightFraction = 0.85,
  bool fixedHeight = false,
  bool useRootNavigator = false,
  KSheetDialog dialog = KSheetDialog.standard,
  FocusNode? returnFocus,
}) {
  final result = _show<T>(
    context,
    builder: builder,
    draggable: draggable,
    maxHeightFraction: maxHeightFraction,
    fixedHeight: fixedHeight,
    useRootNavigator: useRootNavigator,
    dialog: dialog,
  );
  if (returnFocus == null) return result;
  return result.whenComplete(() {
    // After the route's own focus handling has run.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (returnFocus.context?.mounted == true) returnFocus.requestFocus();
    });
  });
}

Future<T?> _show<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required bool draggable,
  required double maxHeightFraction,
  required bool fixedHeight,
  required bool useRootNavigator,
  required KSheetDialog dialog,
}) {
  final modal = dialog == KSheetDialog.modal;
  final size = MediaQuery.sizeOf(context);
  if (size.width >= KBreakpoints.compactSheet) {
    if (modal) {
      return showKModalDialog<T>(
        context,
        builder: builder,
        useRootNavigator: useRootNavigator,
      );
    }
    return showDialog<T>(
      context: context,
      animationStyle: KMotion.routeAnimationStyle(context),
      useRootNavigator: useRootNavigator,
      builder: (context) => KRowEdgesScope(
        edges: KRowEdges.inset,
        child: Dialog(
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
      ),
    );
  }
  if (modal) {
    return showKModalSheet<T>(
      context,
      builder: builder,
      draggable: draggable,
      fixedHeight: fixedHeight,
      useRootNavigator: useRootNavigator,
    );
  }
  final maxHeight = size.height * maxHeightFraction;
  return showModalBottomSheet<T>(
    context: context,
    sheetAnimationStyle: KMotion.routeAnimationStyle(context),
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
      return KRowEdgesScope(
        edges: KRowEdges.fullBleed,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard + KSpace.x2),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: available,
              minHeight: fixedHeight ? available : 0,
            ),
            child: builder(context),
          ),
        ),
      );
    },
  );
}
