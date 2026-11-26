import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import 'k_modal_esc_scope.dart';
import 'k_row_edges.dart';
import 'k_sheet.dart';

/// Scrim behind a side sheet.
const double _sideSheetScrim = 0.32;

/// Modal sheet docked to the trailing edge of the window, [width] wide
/// (clamped to the window), full height, left corners rounded.
///
/// Shown above every nested navigator by default ([useRootNavigator]), so it
/// also covers the sidebar, top bar and player bar. Slides in over
/// [KMotion.normal]; with reduced motion it just appears. A tap on the scrim
/// and Esc / Back close it, Tab stays inside it, and [returnFocus] gets focus
/// after it closes (only while still attached to the tree).
Future<T?> showKSideSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required double width,
  bool useRootNavigator = true,
  FocusNode? returnFocus,
}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  final scheme = Theme.of(context).colorScheme;
  final slide = CurveTween(curve: KMotion.emphasized);
  final result = showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: scheme.scrim.withValues(alpha: _sideSheetScrim),
    transitionDuration: reduce ? Duration.zero : KMotion.normal,
    transitionBuilder: (context, animation, _, child) {
      if (reduce) return child;
      final rtl = Directionality.of(context) == TextDirection.rtl;
      return SlideTransition(
        position: animation.drive(
          Tween(begin: Offset(rtl ? -1 : 1, 0), end: Offset.zero).chain(slide),
        ),
        child: child,
      );
    },
    pageBuilder: (context, _, _) => KModalEscScope(
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            elevation: 6,
            shadowColor: Theme.of(context).colorScheme.shadow,
            shape: KShape.of(
              BorderRadiusDirectional.horizontal(start: KRadius.md.topLeft)
                  .resolve(Directionality.of(context)),
              continuous: true,
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              child: KRowEdgesScope(
                edges: KRowEdges.inset,
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (returnFocus == null) return result;
  return result.whenComplete(() {
    // After the route's own focus handling has run.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (returnFocus.context?.mounted == true) returnFocus.requestFocus();
    });
  });
}

/// Width of the side sheet [showKAdaptiveSheet] opens on the desktop shell.
const double _adaptiveSideWidth = 400;

/// Max height of the bottom sheet [showKAdaptiveSheet] opens on the mobile
/// shell.
const double _adaptiveSheetHeight = 0.82;

/// Options sheet that fits the shell: a bottom sheet with a grip (82 % high at
/// most, swipe down closes) on the mobile shell, a 400 wide side sheet on the
/// desktop shell. Both are modal, sit above the whole window and return focus
/// to [returnFocus]. The shell is chosen here, never by the caller.
Future<T?> showKAdaptiveSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  FocusNode? returnFocus,
}) {
  if (FormFactor.of(context) == FormFactor.desktop) {
    return showKSideSheet<T>(
      context,
      builder: builder,
      width: _adaptiveSideWidth,
      returnFocus: returnFocus,
    );
  }
  return showKSheet<T>(
    context,
    builder: builder,
    maxHeightFraction: _adaptiveSheetHeight,
    useRootNavigator: true,
    alwaysBottom: true,
    returnFocus: returnFocus,
  );
}
