import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/playback_providers.dart';
import 'flight_source.dart';
import 'mini_card_drag.dart';
import 'mini_card_layer.dart';
import 'mini_player_body.dart';
import 'play_pause_button.dart';
import 'transport_buttons.dart';

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
  void _onDragEnd(MiniDragLock lock, Offset total, Offset velocity) {
    if (lock == MiniDragLock.up && total.dy < -MiniPlayer.swipeDistance) {
      widget.onOpen();
    }
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
        // The long press and the swipe are not reachable by assistive tech:
        // expose both outcomes as actions.
        customSemanticsActions: {
          CustomSemanticsAction(label: l10n.playbackOpenNowPlaying):
              widget.onOpen,
          CustomSemanticsAction(label: l10n.playbackNavQueue):
              widget.onOpenQueue,
        },
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
                    onEnd: _onDragEnd,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: IgnorePointer(
                        child: MiniPlayerBody(
                          trackId: trackId,
                          flight: widget.flight,
                          cardHeight: MiniPlayer.height,
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
    );
  }
}
