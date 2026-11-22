import 'dart:async';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_screen.dart';

/// Opens the lyrics screen over the page [context] belongs to (on the root
/// navigator, so it also covers the page's own chrome) and returns its route,
/// which the caller keeps to close it later with [closeLyricsScreen].
LyricsScreenRoute showLyricsScreen(BuildContext context) {
  final route = LyricsScreenRoute(
    reduceMotion: MediaQuery.disableAnimationsOf(context),
  );
  unawaited(Navigator.of(context, rootNavigator: true).push(route));
  return route;
}

/// Closes [route] if it is still on its navigator. Every way out goes through
/// here (the user, "no track", Now Playing leaving for the desktop panel), so
/// a close never pops some other route: a route that is not the top one, or
/// that Now Playing removes while it leaves ([animated] false), is removed by
/// itself instead of popped. Closing twice does nothing.
void closeLyricsScreen(LyricsScreenRoute route, {bool animated = true}) {
  final navigator = route.navigator;
  if (navigator == null || !route.isActive || route.isClosing) return;
  if (animated && route.isCurrent) {
    navigator.pop();
  } else {
    navigator.removeRoute(route);
  }
}

/// A full-screen opaque route that slides up over Now Playing.
class LyricsScreenRoute extends ModalRoute<void> {
  LyricsScreenRoute({required this.reduceMotion});

  /// The platform asked for no animation: the screen appears and leaves at
  /// once.
  final bool reduceMotion;

  bool _closing = false;

  /// True once the route started to pop (it may still be sliding out).
  bool get isClosing => _closing;

  @override
  bool didPop(void result) {
    _closing = true;
    return super.didPop(result);
  }

  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : KMotion.pageIn;

  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? Duration.zero : KMotion.pageOut;

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
  ) => LyricsScreen(route: this);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).chain(CurveTween(curve: KMotion.emphasized)).animate(animation),
    child: child,
  );
}
