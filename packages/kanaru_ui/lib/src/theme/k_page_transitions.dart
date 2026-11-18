import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';

/// Wraps a platform page transition and drops it (the page just appears) when
/// animations are off at the OS level (`disableAnimations`). With [instant]
/// (the app's own motion setting) the route durations are zero as well, so a
/// pushed or popped page completes at once. Flutter's page routes read the
/// duration from the theme, not from `disableAnimations`.
class KPageTransitionsBuilder extends PageTransitionsBuilder {
  const KPageTransitionsBuilder(this.inner, {this.instant = false});

  final PageTransitionsBuilder inner;

  /// No transition and zero duration, whatever the media query says.
  final bool instant;

  // Value equality: the theme is rebuilt often, and a ThemeData that compares
  // unequal makes MaterialApp animate a theme change (a running animation).
  @override
  bool operator ==(Object other) =>
      other is KPageTransitionsBuilder &&
      other.inner == inner &&
      other.instant == instant;

  @override
  int get hashCode => Object.hash(inner, instant);

  @override
  Duration get transitionDuration =>
      instant ? Duration.zero : inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      instant ? Duration.zero : inner.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      instant ? null : inner.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (instant || MediaQuery.disableAnimationsOf(context)) return child;
    return inner.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// The platform defaults, each wrapped by [KPageTransitionsBuilder]; with
/// [instant] none of them animate and all durations are zero.
PageTransitionsTheme kanaruPageTransitionsTheme({required bool instant}) =>
    PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: KPageTransitionsBuilder(
          const PredictiveBackPageTransitionsBuilder(),
          instant: instant,
        ),
        TargetPlatform.iOS: KPageTransitionsBuilder(
          const CupertinoPageTransitionsBuilder(),
          instant: instant,
        ),
        TargetPlatform.macOS: KPageTransitionsBuilder(
          const CupertinoPageTransitionsBuilder(),
          instant: instant,
        ),
        TargetPlatform.windows: KPageTransitionsBuilder(
          const ZoomPageTransitionsBuilder(),
          instant: instant,
        ),
        TargetPlatform.linux: KPageTransitionsBuilder(
          const ZoomPageTransitionsBuilder(),
          instant: instant,
        ),
      },
    );
