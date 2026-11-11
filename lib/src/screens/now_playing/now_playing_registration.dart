import 'dart:math' as math;

import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_registry.dart';
import '../../extension/state/registry_entries.dart';
import '../../platform/state/media_controls_provider.dart';
import '../../playback/state/playback_flush.dart';
import 'now_playing_path.dart';
import 'ui/now_playing_page.dart';

final _log = Logger('now_playing.registration');

/// How long the media session may take to start before the app goes on
/// without it.
const mediaSessionStartTimeout = Duration(seconds: 3);

/// Registers the playback module's seams: the exit hook that pauses, the
/// flush hook that saves the session, the Android media session start and
/// the dimmed "Queue" nav item (saved queues, not built yet).
void registerNowPlaying(ExtensionRegistry registry) {
  registry
    ..addRoute(
      GoRoute(
        path: nowPlayingPath,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const NowPlayingPage(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: nowPlayingTransition,
        ),
      ),
    )
    ..addBeforeExitHook(pausePlaybackOnExitHook)
    ..addFlushHook(playbackFlushHook)
    ..addStartupHook(mediaSessionStartHook())
    ..addNavItem(
      NavItem(
        id: 'queue',
        path: '/queue',
        icon: KIcons.queue,
        selectedIcon: KIcons.queue,
        label: (c) => AppLocalizations.of(c).playbackNavQueue,
        order: 230,
        mobileTab: false,
        // Saved queues; not built yet. The live queue is the right panel
        // (desktop) and the sheet from the mini player (mobile).
        comingSoon: true,
      ),
    );
}

/// Startup hook for the media session. It must run once per process (the
/// Android audio service wants its init at launch), but a failure or a hang
/// never stops the app from starting. [start] and [timeout] are for tests.
StartupHook mediaSessionStartHook({
  Future<void> Function()? start,
  Duration timeout = mediaSessionStartTimeout,
}) {
  final init = start ?? initAndroidMediaSession;
  return (StartupContext _) async {
    try {
      await init().timeout(timeout);
    } on Object catch (e, st) {
      _log.warning('media session did not start: $e', e, st);
    }
  };
}

/// Slide up with the `bouncy` spring, stopped at the top edge (an overshoot
/// would uncover a strip of the page below); slide down on an ease-in curve
/// (replaying the spring backwards would first jump up). A fade under reduced
/// motion.
Widget nowPlayingTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return FadeTransition(opacity: animation, child: child);
  }
  return SlideTransition(
    position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: animation,
        curve: _bouncyCurve,
        reverseCurve: Curves.easeInCubic,
      ),
    ),
    child: child,
  );
}

final Curve _bouncyCurve = SpringCurve(KSpring.bouncy, maxValue: 1);

/// A [Curve] that follows a spring from 0 to 1. The route animation runs for
/// a fixed time, so the spring is played over its own settle time. [maxValue]
/// caps the overshoot.
class SpringCurve extends Curve {
  SpringCurve(SpringDescription spring, {this.maxValue = double.infinity})
    : _sim = SpringSimulation(spring, 0, 1, 0) {
    var t = 0.0;
    while (!_sim.isDone(t) && t < 3) {
      t += 1 / 120;
    }
    _settle = t;
  }

  final SpringSimulation _sim;
  final double maxValue;
  late final double _settle;

  @override
  double transformInternal(double t) => math.min(maxValue, _sim.x(t * _settle));
}
