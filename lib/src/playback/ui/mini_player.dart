import 'dart:async';

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/cover_files.dart';
import '../../media/domain/track_id.dart';
import '../state/playback_position_provider.dart';
import '../state/playback_providers.dart';
import '../state/track_info_providers.dart';
import 'flight_source.dart';
import 'play_pause_button.dart';
import 'track_cover.dart';
import 'transport_buttons.dart';

const miniRadius = BorderRadius.all(Radius.circular(14));

/// Mobile mini player: 64 dp card above the bottom bar, shown only while a
/// track is current.
///
/// - Tap, Enter or Space: [onOpen]. A swipe up of more than 30 dp: [onOpen].
/// - Long press (500 ms without moving 10 dp): haptic, then [onOpenQueue].
///   The release after a long press does not count as a tap.
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({
    super.key,
    required this.onOpen,
    required this.onOpenQueue,
    this.flight,
  });

  static const double height = 64;
  static const double margin = 8;
  static const double swipeDistance = 30;
  static const double longPressSlop = 10;
  static const Duration longPressDelay = Duration(milliseconds: 500);

  final VoidCallback onOpen;
  final VoidCallback onOpenQueue;

  /// Where the queue sheet flies from and back to; its pieces are hidden
  /// while the sheet is up.
  final FlightSource? flight;

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  Timer? _longPress;
  Offset? _downAt;
  bool _longPressed = false;
  double _swipeUp = 0;

  void _cancelLongPress() {
    _longPress?.cancel();
    _longPress = null;
  }

  void _onDown(PointerDownEvent e) {
    _downAt = e.position;
    _longPressed = false;
    _swipeUp = 0;
    _cancelLongPress();
    _longPress = Timer(MiniPlayer.longPressDelay, () {
      _longPress = null;
      _longPressed = true;
      HapticFeedback.selectionClick();
      widget.onOpenQueue();
    });
  }

  void _onMove(PointerMoveEvent e) {
    final start = _downAt;
    if (start != null &&
        (e.position - start).distance > MiniPlayer.longPressSlop) {
      _cancelLongPress();
    }
  }

  void _onTap() {
    if (_longPressed) return;
    widget.onOpen();
  }

  @override
  void dispose() {
    _cancelLongPress();
    super.dispose();
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
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: (d) => _swipeUp -= d.delta.dy,
          onVerticalDragEnd: (_) {
            if (_swipeUp > MiniPlayer.swipeDistance && !_longPressed) {
              widget.onOpen();
            }
          },
          child: Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: miniRadius,
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: MiniPlayer.height,
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Only the body (cover and titles) takes the tap and the
                      // long press; holding Play or Next does not open the queue.
                      Expanded(
                        child: Listener(
                          onPointerDown: _onDown,
                          onPointerMove: _onMove,
                          onPointerUp: (_) => _cancelLongPress(),
                          onPointerCancel: (_) => _cancelLongPress(),
                          child: KPressable(
                            radius: miniRadius,
                            onTap: _onTap,
                            child: _Body(
                              trackId: trackId,
                              flight: widget.flight,
                            ),
                          ),
                        ),
                      ),
                      _piece(FlightPiece.play, const PlayPauseButton()),
                      _piece(FlightPiece.next, const NextButton()),
                    ],
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: RepaintBoundary(child: _Progress()),
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

class _Body extends ConsumerWidget {
  const _Body({required this.trackId, required this.flight});

  final TrackId trackId;
  final FlightSource? flight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(trackInfoProvider(trackId)).value;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget wrap(FlightPiece piece, Widget child) => flight == null
        ? child
        : FlightPieceHost(source: flight!, piece: piece, child: child);
    return Padding(
      padding: const EdgeInsets.only(left: KSpace.x2),
      child: Row(
        spacing: KSpace.x3,
        children: [
          wrap(
            FlightPiece.cover,
            TrackCover(
              coverKey: info?.coverKey,
              seed: info?.albumKey?.toString() ?? info?.title ?? '',
              size: CoverSize.thumb,
              dimension: 48,
              radius: KRadius.xs,
            ),
          ),
          Expanded(
            child: wrap(
              FlightPiece.text,
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info?.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (info?.artist != null)
                    Text(
                      info!.artist!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 2 dp line. Only this widget rebuilds on a position tick.
class _Progress extends ConsumerWidget {
  const _Progress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(playbackPositionProvider).value;
    final total = pos?.duration?.inMilliseconds ?? 0;
    return KProgressLine(
      value: total > 0 ? pos!.position.inMilliseconds / total : 0,
    );
  }
}
