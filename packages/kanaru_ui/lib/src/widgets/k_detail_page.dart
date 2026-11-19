import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../theme/k_page_transitions.dart';
import '../tokens/k_motion.dart';

/// Page of a detail or sub-page route (library detail, Settings sub-pages).
///
/// Mobile slides in from the right on one smooth curve (the platform default
/// eases fast-to-slow and leaves the page below as a trailing image). Desktop
/// replaces the content area, where a slide feels heavy, so it fades in
/// quickly and out a little later. With animations off (the OS setting or the
/// app's motion setting, which installs an instant page transitions theme)
/// the durations are zero and nothing animates. The state is read when the
/// page pushes and when it pops, so toggling motion while a page is open
/// takes effect on its Back.
///
/// Use with go_router: `pageBuilder: (_, s) => KDetailPage(key: s.pageKey,
/// child: ...)`.
class KDetailPage extends Page<void> {
  const KDetailPage({required LocalKey super.key, required this.child});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _KDetailRoute(this);
}

class _KDetailRoute extends PageRoute<void> {
  _KDetailRoute(KDetailPage page) : super(settings: page);

  KDetailPage get _page => settings as KDetailPage;

  /// Animations off right now, read from the navigator's context (above the
  /// route, so it follows the live media query and theme).
  bool get _instant {
    final context = navigator?.context;
    if (context == null) return false;
    final theme = Theme.of(context);
    final builder = theme.pageTransitionsTheme.builders[theme.platform];
    return MediaQuery.disableAnimationsOf(context) ||
        (builder is KPageTransitionsBuilder && builder.instant);
  }

  @override
  Duration get transitionDuration => _instant ? Duration.zero : KMotion.pageIn;

  @override
  Duration get reverseTransitionDuration =>
      _instant ? Duration.zero : KMotion.pageOut;

  /// The controller reads the durations once at install: bring them up to
  /// date before each push and pop.
  void _syncDurations() {
    controller
      ?..duration = transitionDuration
      ..reverseDuration = reverseTransitionDuration;
  }

  @override
  TickerFuture didPush() {
    _syncDurations();
    return super.didPush();
  }

  @override
  bool didPop(void result) {
    _syncDurations();
    return super.didPop(result);
  }

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: _page.child,
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_instant) return child;
    if (FormFactor.of(context) == FormFactor.desktop) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.55, curve: Curves.easeOut),
          reverseCurve: const Interval(0.5, 1, curve: Curves.easeIn),
        ),
        child: child,
      );
    }
    return SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      ),
      child: child,
    );
  }
}
