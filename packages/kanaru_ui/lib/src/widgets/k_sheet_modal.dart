import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_modal_esc_scope.dart';
import 'k_row_edges.dart';

/// Scrim of the modal dialog (desktop and tablets).
const double _dialogScrim = 0.45;

/// Scrim of the modal bottom sheet (phones).
const double _sheetScrim = 0.42;

/// Strength of the soft `primary` glow behind the top of the modal sheet.
/// The glow is an ellipse centred on the top edge: its horizontal radius is
/// 0.84 of the sheet width and its vertical radius 0.63 of [_glowHeight],
/// fading to nothing, so no edge shows.
const double _glowAlpha = 0.09;
const double _glowHeight = 260;
const double _glowReachX = 1.2 * 0.7;
const double _glowReachY = 0.9 * 0.7;

/// Minimum distance between the modal dialog and the window edge.
const double _dialogMargin = KSpace.x6;

/// Max height of the modal sheet, as a fraction of the window.
const double _sheetMaxHeight = 0.92;

/// Gap under the content of the modal sheet, on top of the system bottom
/// inset (gesture bar / navigation bar).
const double _sheetBottom = KSpace.x6;

/// Dialog look of `showKSheet(dialog: KSheetDialog.modal)`: centred, scales
/// in over [KMotion.dialogIn] (instantly with reduced motion), scrolls when
/// taller than the window, keeps [_dialogMargin] from every edge.
Future<T?> showKModalDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required bool useRootNavigator,
}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  final scheme = Theme.of(context).colorScheme;
  final fade = CurveTween(curve: KMotion.dialogCurve);
  final grow = Tween<double>(begin: 0.96, end: 1).chain(fade);
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: scheme.scrim.withValues(alpha: _dialogScrim),
    transitionDuration: reduce ? Duration.zero : KMotion.dialogIn,
    transitionBuilder: (context, animation, _, child) {
      if (reduce) return child;
      return FadeTransition(
        opacity: animation.drive(fade),
        child: ScaleTransition(scale: animation.drive(grow), child: child),
      );
    },
    pageBuilder: (context, _, _) {
      final media = MediaQuery.of(context);
      final large = media.textScaler.scale(10) >= 20;
      return KModalEscScope(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _dialogMargin,
              _dialogMargin,
              _dialogMargin,
              _dialogMargin + media.viewInsets.bottom,
            ),
            child: Center(
              child: SizedBox(
                // The window clamps it when narrower than the dialog.
                width: large ? KLayout.dialogModalLarge : KLayout.dialogModal,
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  elevation: 6,
                  shadowColor: Theme.of(context).colorScheme.shadow,
                  shape: KShape.of(KRadius.lg, continuous: true),
                  clipBehavior: Clip.antiAlias,
                  child: KRowEdgesScope(
                    edges: KRowEdges.inset,
                    child: SingleChildScrollView(child: builder(context)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Sheet look of `showKSheet(dialog: KSheetDialog.modal)` on phones.
Future<T?> showKModalSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required bool draggable,
  required bool fixedHeight,
  required bool useRootNavigator,
}) {
  final size = MediaQuery.sizeOf(context);
  final maxHeight = size.height * _sheetMaxHeight;
  return showModalBottomSheet<T>(
    context: context,
    sheetAnimationStyle: KMotion.routeAnimationStyle(context),
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    enableDrag: draggable,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    barrierColor: Theme.of(context).colorScheme.scrim
        .withValues(alpha: _sheetScrim),
    clipBehavior: Clip.antiAlias,
    shape: KShape.of(
      BorderRadius.vertical(top: KRadius.xl.topLeft),
      continuous: true,
    ),
    constraints: BoxConstraints(maxHeight: maxHeight),
    builder: (context) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      // The route's safe area leaves the bottom alone: clear the system bar
      // here (it is 0 while the keyboard covers it).
      final systemBottom = MediaQuery.paddingOf(context).bottom;
      final available = (size.height - keyboard) < maxHeight
          ? size.height - keyboard
          : maxHeight;
      return KModalEscScope(
        child: KRowEdgesScope(
          edges: KRowEdges.fullBleed,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _glowHeight,
                child: _TopGlow(),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: keyboard + systemBottom + _sheetBottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: available,
                    minHeight: fixedHeight ? available : 0,
                  ),
                  child: SingleChildScrollView(child: builder(context)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Decoration only: a faint `primary` halo at the top of the sheet.
class _TopGlow extends StatelessWidget {
  const _TopGlow();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return IgnorePointer(child: CustomPaint(painter: _GlowPainter(primary)));
  }
}

/// Radial gradient drawn in a unit-ellipse space (scaled from the top centre),
/// clamped to transparent past its reach: no visible boundary anywhere.
class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rx = size.width * _glowReachX;
    final ry = size.height * _glowReachY;
    final shader = ui.Gradient.radial(Offset.zero, 1, [
      color.withValues(alpha: _glowAlpha),
      color.withValues(alpha: 0),
    ]);
    canvas
      ..save()
      ..translate(size.width / 2, 0)
      ..scale(rx, ry)
      ..drawRect(
        Rect.fromLTRB(
          -size.width / 2 / rx,
          0,
          size.width / 2 / rx,
          size.height / ry,
        ),
        Paint()..shader = shader,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.color != color;
}
