import 'dart:async';

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
///   a fling the queue and the saved session are cleared at once (like the
///   carousel runs Next at release) while the card drops out of sight
///   (`KSpring.snappy`, visual only), and "Playback stopped" is announced to
///   screen readers. No question, no undo, no snack bar. Short of it, it
///   springs back. When a new entry arrives after the drop the card is back
///   in place and takes touches again.
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

  /// Entry that was current when the drop started.
  int? _droppedEntry;

  @override
  void dispose() {
    _y.dispose();
    super.dispose();
  }

  void lock(MiniDragLock lock) {
    if (!_dropping && lock != MiniDragLock.x) _y.stop();
  }

  void update(MiniDragLock lock, double dy) {
    if (_dropping) return;
    switch (lock) {
      case MiniDragLock.up:
        _y.value = dy.clamp(-miniSwipeUpTravel, 0.0);
      case MiniDragLock.down:
        _y.value = dy.clamp(0.0, double.infinity);
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

  /// Stops playback and clears the queue and the saved session at once. With
  /// [animate] the card also drops out of sight (a semantics action does not
  /// need that); the drop is only visual. The controller and the announcement
  /// are taken before any await, so the stop does not depend on the card
  /// staying in the tree.
  Future<void> stopPlayback({bool animate = true}) async {
    if (_dropping) return;
    final controller = ref.read(playerControllerProvider);
    final message = AppLocalizations.of(context).playbackStoppedAnnouncement;
    final view = View.of(context);
    final direction = Directionality.of(context);
    _droppedEntry = ref.read(nowPlayingProvider).value?.entryId;
    setState(() => _dropping = true);
    if (animate) {
      unawaited(animateSpringTo(context, _y, widget.travel, KSpring.snappy));
    }
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
  }

  /// A new entry after the drop (a song picked while the card was falling):
  /// the card is back in place and takes touches.
  void _onEntry(int? entryId) {
    if (!_dropping || entryId == null || entryId == _droppedEntry) return;
    _y.stop();
    _y.value = 0;
    setState(() => _dropping = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      nowPlayingProvider.select((n) => n.value?.entryId),
      (_, entryId) => _onEntry(entryId),
    );
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
