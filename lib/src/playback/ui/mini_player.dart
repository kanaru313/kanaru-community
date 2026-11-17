import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/playback_providers.dart';
import '../state/player_controller.dart';
import 'flight_source.dart';
import 'mini_card_drag.dart';
import 'mini_card_layer.dart';
import 'mini_player_carousel.dart';
import 'mini_player_vertical.dart';
import 'play_pause_button.dart';
import 'transport_buttons.dart';

final _log = Logger('MiniPlayer');

const miniRadius = BorderRadius.all(Radius.circular(14));

/// Mobile mini player: 72 dp card above the bottom bar, shown only while a
/// track is current.
///
/// - Tap, Enter or Space: [onOpen]. A swipe up of more than 30 dp: [onOpen].
/// - Every drag on the card is decided by [MiniCardDragRecognizer]; a drag
///   that starts in the seek band is always a seek.
/// - Long press (500 ms without moving 10 dp): haptic, then [onOpenQueue].
///   The release after a long press does not count as a tap.
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({
    super.key,
    required this.onOpen,
    required this.onOpenQueue,
    this.flight,
  });

  static const double height = 72;
  static const double margin = 8;
  static const double swipeDistance = 30;

  final VoidCallback onOpen;
  final VoidCallback onOpenQueue;

  /// Where the queue sheet flies from and back to; its pieces are hidden
  /// while the sheet is up.
  final FlightSource? flight;

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  final _carousel = GlobalKey<MiniPlayerCarouselState>();
  final _vertical = GlobalKey<MiniPlayerVerticalState>();

  void _onLock(MiniDragLock lock) {
    if (lock == MiniDragLock.x) {
      _carousel.currentState?.dragStart();
    } else {
      _vertical.currentState?.lock(lock);
    }
  }

  void _onDragUpdate(MiniDragLock lock, Offset total) {
    if (lock == MiniDragLock.x) {
      _carousel.currentState?.dragUpdate(total.dx);
    } else {
      _vertical.currentState?.update(lock, total.dy);
    }
  }

  void _onDragEnd(MiniDragLock lock, Offset total, Offset velocity) {
    if (lock == MiniDragLock.x) {
      _carousel.currentState?.dragEnd(total.dx, velocity.dx);
    } else {
      _vertical.currentState?.end(lock, total.dy, velocity.dy);
    }
  }

  void _onDragCancel(MiniDragLock lock) {
    if (lock == MiniDragLock.x) {
      _carousel.currentState?.dragCancel();
    } else {
      _vertical.currentState?.cancel(lock);
    }
  }

  /// A semantics action runs a player command; a failure is logged, not lost.
  void _command(Future<void> Function(PlayerController) run) {
    run(ref.read(playerControllerProvider))
        .catchError((Object e, StackTrace s) {
          _log.warning('mini player command failed', e, s);
        });
  }

  Widget _piece(FlightPiece piece, Widget child) => widget.flight == null
      ? child
      : FlightPieceHost(source: widget.flight!, piece: piece, child: child);

  @override
  Widget build(BuildContext context) {
    final trackId = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    if (trackId == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // The queue flight starts from this look (text sizes, cover corners).
    widget.flight?.look = FlightLook(
      title: KMediaCardMetrics.titleStyle(text),
      artist: KMediaCardMetrics.lineStyle(text),
      coverRadius: KMediaCard.coverRadius,
    );
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(MiniPlayer.margin),
      child: Semantics(
        container: true,
        label: l10n.playbackPlayer,
        // The long press and the swipes are not reachable by assistive tech:
        // expose their outcomes as actions.
        customSemanticsActions: {
          CustomSemanticsAction(label: l10n.playbackOpenNowPlaying):
              widget.onOpen,
          CustomSemanticsAction(label: l10n.playbackNavQueue):
              widget.onOpenQueue,
          CustomSemanticsAction(label: l10n.playbackNext): () =>
              _command((c) => c.next()),
          CustomSemanticsAction(label: l10n.playbackPrevious): () =>
              _command((c) => c.previous()),
          CustomSemanticsAction(label: l10n.playbackStopAndClear): () =>
              _vertical.currentState?.stopPlayback(animate: false),
        },
        child: MiniPlayerVertical(
          key: _vertical,
          onOpen: widget.onOpen,
          travel: MiniPlayer.height + MiniPlayer.margin,
          child: Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: miniRadius,
            child: SizedBox(
              height: MiniPlayer.height,
              child: Stack(
                children: [
                  // The whole card takes the tap and the long press. Play and
                  // Next sit above it and take their own touches first, so
                  // holding either never reaches this layer.
                  Positioned.fill(
                    child: MiniCardLayer(
                      cardHeight: MiniPlayer.height,
                      radius: miniRadius,
                      onTap: widget.onOpen,
                      onLongPress: widget.onOpenQueue,
                      onLock: _onLock,
                      onUpdate: _onDragUpdate,
                      onEnd: _onDragEnd,
                      onCancel: _onDragCancel,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: IgnorePointer(
                          child: MiniPlayerCarousel(
                            key: _carousel,
                            cardHeight: MiniPlayer.height,
                            flight: widget.flight,
                          ),
                        ),
                      ),
                      _piece(
                        FlightPiece.play,
                        const PlayPauseButton(iconSize: KIconSize.lg),
                      ),
                      _piece(
                        FlightPiece.next,
                        const NextButton(iconSize: KIconSize.md),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
