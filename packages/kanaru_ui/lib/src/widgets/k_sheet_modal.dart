import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_row_edges.dart';

/// Scrim of the modal dialog (desktop and tablets).
const double _dialogScrim = 0.45;

/// Scrim of the modal bottom sheet (phones).
const double _sheetScrim = 0.42;

/// Strength of the soft `primary` glow behind the top of the modal sheet.
const double _glowAlpha = 0.09;
const double _glowHeight = 96;

/// Minimum distance between the modal dialog and the window edge.
const double _dialogMargin = KSpace.x6;

/// Max height of the modal sheet, as a fraction of the window.
const double _sheetMaxHeight = 0.92;

/// Bottom padding of the modal sheet (clears the gesture bar).
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
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0xFF000000).withValues(alpha: _dialogScrim),
    transitionDuration: reduce ? Duration.zero : KMotion.dialogIn,
    transitionBuilder: (context, animation, _, child) {
      if (reduce) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, _) {
      final media = MediaQuery.of(context);
      final large = media.textScaler.scale(10) >= 20;
      return _EscCloses(
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
                  shadowColor: const Color(0xFF000000),
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
    barrierColor: const Color(0xFF000000).withValues(alpha: _sheetScrim),
    clipBehavior: Clip.antiAlias,
    shape: KShape.of(
      BorderRadius.vertical(top: KRadius.xl.topLeft),
      continuous: true,
    ),
    constraints: BoxConstraints(maxHeight: maxHeight),
    builder: (context) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      final available = (size.height - keyboard) < maxHeight
          ? size.height - keyboard
          : maxHeight;
      return _EscCloses(
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
                padding: EdgeInsets.only(bottom: keyboard + _sheetBottom),
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
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary.withValues(alpha: _glowAlpha),
              primary.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Esc closes the route and is consumed here, so a shortcut of the shell
/// above the route never sees it. Holds focus inside the route when nothing
/// else asks for it (an `autofocus` in the content wins).
class _EscCloses extends StatelessWidget {
  const _EscCloses({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
    },
    child: Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            Navigator.of(context).maybePop();
            return null;
          },
        ),
      },
      child: Focus(autofocus: true, skipTraversal: true, child: child),
    ),
  );
}
