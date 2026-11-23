import 'package:material_ui/material_ui.dart';

import '../../tokens/k_layout.dart';
import '../../tokens/k_motion.dart';
import 'k_overlay_page_shell.dart';

/// Opens [builder] as one route on the root navigator that is a full-screen
/// page below `KBreakpoints.compactSheet` (600) and a centred box from there
/// up, and changes between the two live when the window is resized or
/// rotated while it is open (the body keeps its state).
///
/// Page: `surface`, bar `[←] title · actions`, no barrier, covers the
/// navigation. Box: [maxWidth] wide (620 by default) and at most 85 % of the
/// height (window height - 48 under 760), 28 corners, `surfaceContainerHigh`,
/// a 45 % barrier (tap closes), a fixed header (the [boxHeader] or the title,
/// then [actions] and a ✕) with a hairline under it.
///
/// Back, Esc, ← / ✕ and a tap on the barrier close exactly this layer, so
/// layers can stack (menu > info > lyrics). The route is a real modal route:
/// it traps focus and hides the layers below from screen readers.
/// [viaKeyboard] focuses the first button of the header.
///
/// [title] is the page bar title, the default box header and the route's
/// semantics label. [builder] draws the body below the header; it gives its
/// own scrolling. Read the current kind with [KOverlayPageScope].
Future<T?> showKOverlayPage<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  List<Widget> actions = const [],
  WidgetBuilder? boxHeader,
  double maxWidth = KLayout.dialogWide,
  String? closeTooltip,
  String? backTooltip,
  bool viaKeyboard = false,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final l10n = MaterialLocalizations.of(context);
  final reduce = MediaQuery.disableAnimationsOf(context);
  return navigator.push<T>(
    RawDialogRoute<T>(
      // The route draws no barrier: the shell paints its own, only in box
      // mode, and the kind can change while the route is open.
      barrierColor: null,
      barrierDismissible: false,
      barrierLabel: title,
      // No route animation when the platform asks for reduced motion
      // (`RawDialogRoute` does not read `disableAnimations` itself).
      transitionDuration: reduce ? Duration.zero : KMotion.dialogIn,
      pageBuilder: (routeContext, _, _) => themes.wrap(
        KOverlayPageShell(
          title: title,
          builder: builder,
          actions: actions,
          boxHeader: boxHeader,
          maxWidth: maxWidth,
          closeTooltip: closeTooltip ?? l10n.closeButtonTooltip,
          backTooltip: backTooltip ?? l10n.backButtonTooltip,
          viaKeyboard: viaKeyboard,
        ),
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation.drive(CurveTween(curve: KMotion.dialogCurve)),
        child: child,
      ),
    ),
  );
}
