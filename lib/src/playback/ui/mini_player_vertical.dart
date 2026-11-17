import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/playback_providers.dart';
import 'mini_card_drag.dart';
import 'spring_to_rest.dart';

final _log = Logger('MiniPlayerVertical');

/// How far the card follows a swipe up before it stops.
const double miniSwipeUpTravel = 30;

/// A swipe down past this (dp), or a fling faster than [miniDropFling]
/// (px per ms), drops the card and stops playback.
const double miniDropDistance = 48;
const double miniDropFling = 0.5;

/// The card is fully faded after following the finger this far down.
const double miniFadeDistance = 120;

/// Moves the whole mini player card up and down with a vertical drag.
///
/// - Down: the card follows the finger and fades. Past [miniDropDistance] or
///   a fling it drops out (`KSpring.snappy`), then the queue and the saved
///   session are cleared and "Playback stopped" is announced to screen
///   readers. No question, no undo, no snack bar. Short of it, it springs
///   back.
/// - Up: the card follows up to [miniSwipeUpTravel]; a release past it opens
///   Now Playing ([onOpen]); either way the card springs back.
///
/// The drag comes from the card's one arbiter: the owner forwards it through
/// a [GlobalKey]. Playback stops through [stopPlayback], also for the
/// "Stop playback" semantics action.
class MiniPlayerVertical extends ConsumerStatefulWidget {
  const MiniPlayerVertical({
    super.key,
    required this.child,
    required this.onOpen,
    required this.travel,
  });

  final Widget child;
  final VoidCallback onOpen;

  /// How far down the card must fall to be out of sight.
  final double travel;

  @override
  ConsumerState<MiniPlayerVertical> createState() => MiniPlayerVerticalState();
}

class MiniPlayerVerticalState extends ConsumerState<MiniPlayerVertical>
    with SingleTickerProviderStateMixin {
  late final AnimationController _y = AnimationController.unbounded(
    vsync: this,
  );
  bool _dropping = false;

  /// What is left to do once the card is out of sight: clear the queue and
  /// announce it. Taken from here by the animation, or by [dispose] when the
  /// card leaves the tree first, so the stop is never lost.
  Future<void> Function()? _pendingStop;

  @override
  void dispose() {
    _y.dispose();
    final stop = _pendingStop;
    _pendingStop = null;
    if (stop != null) unawaited(stop());
    super.dispose();
  }

  void lock(MiniDragLock lock) {
    if (!_dropping && lock != MiniDragLock.x) _y.stop();
  }

  void update(MiniDragLock lock, double dy) {
    if (_dropping) return;
    switch (lock) {
      case MiniDragLock.up:
        _y.value = math.max(dy, -miniSwipeUpTravel);
      case MiniDragLock.down:
        _y.value = math.max(0, dy);
      case MiniDragLock.x:
        break;
    }
  }

  void end(MiniDragLock lock, double dy, double vy) {
    if (_dropping) return;
    switch (lock) {
      case MiniDragLock.up:
        if (dy < -miniSwipeUpTravel) widget.onOpen();
        _back();
      case MiniDragLock.down:
        if (dy > miniDropDistance || vy > miniDropFling) {
          unawaited(stopPlayback());
        } else {
          _back();
        }
      case MiniDragLock.x:
        break;
    }
  }

  void cancel(MiniDragLock lock) {
    if (!_dropping && lock != MiniDragLock.x) _back();
  }

  void _back() {
    animateSpringTo(context, _y, 0, KSpring.snappy);
  }

  /// Stops playback and clears the queue and the saved session. With
  /// [animate] the card drops out of sight first (a semantics action does not
  /// need that). The controller and the announcement are taken before any
  /// await, so the stop still happens if the card is gone by then.
  Future<void> stopPlayback({bool animate = true}) async {
    if (_dropping) return;
    final controller = ref.read(playerControllerProvider);
    final message = AppLocalizations.of(context).playbackStoppedAnnouncement;
    final view = View.of(context);
    final direction = Directionality.of(context);
    setState(() => _dropping = true);
    _pendingStop = () async {
      try {
        await controller.clearQueue();
      } on Object catch (e, s) {
        _log.warning('could not stop playback', e, s);
        if (mounted) {
          setState(() => _dropping = false);
          _back();
        }
        return;
      }
      try {
        await SemanticsService.sendAnnouncement(view, message, direction);
      } on Object catch (e, s) {
        _log.fine('could not announce the stop', e, s);
      }
    };
    if (animate) {
      await animateSpringTo(context, _y, widget.travel, KSpring.snappy);
      // Never reached when the card left the tree: dispose ran the stop.
      if (!mounted) return;
    }
    final stop = _pendingStop;
    _pendingStop = null;
    if (stop != null) await stop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _y,
      child: IgnorePointer(ignoring: _dropping, child: widget.child),
      builder: (context, child) {
        final y = _y.value;
        final fade = _dropping
            ? 1 - y / widget.travel
            : 1 - y / miniFadeDistance;
        return Transform.translate(
          offset: Offset(0, y),
          child: Opacity(
            opacity: y > 0 ? fade.clamp(0.0, 1.0) : 1,
            child: child,
          ),
        );
      },
    );
  }
}
