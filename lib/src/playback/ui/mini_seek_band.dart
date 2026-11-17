import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/playback_position_provider.dart';
import '../state/playback_providers.dart';
import 'mini_seek_bubble.dart';
import 'playback_time_label.dart';

/// Seek strip along the bottom edge of the mini player card, inside it.
///
/// Drag only: a tap falls to the card (opens Now Playing). The line grows
/// upward from the card edge (2 rest, 4 hover or keyboard focus, 6 drag); a
/// round thumb shows while hovering, dragging or focused, and a time bubble
/// floats above the card while dragging. Only this widget rebuilds on a
/// position tick.
class MiniSeekBand extends ConsumerStatefulWidget {
  const MiniSeekBand({
    super.key,
    required this.cardHeight,
    required this.radius,
  });

  /// Height of the hit area, inside the card.
  static const double height = 16;
  static const double thumbSize = 12;
  static const double lineRest = 2;
  static const double lineActive = 4;
  static const double lineDragging = 6;
  static const Duration keyStep = Duration(seconds: 5);

  /// Height of the card the band sits in (the bubble floats above it).
  final double cardHeight;

  /// Corner radius of the card; the line is clipped to its bottom corners.
  final BorderRadius radius;

  @override
  ConsumerState<MiniSeekBand> createState() => _MiniSeekBandState();
}

class _MiniSeekBandState extends ConsumerState<MiniSeekBand> {
  final _link = LayerLink();
  final _bubble = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pos = ref.watch(playbackPositionProvider).value;
    final position = pos?.position ?? Duration.zero;
    final duration = pos?.duration;
    return RepaintBoundary(
      child: KSeekGestureArea(
        track: pos?.entryId,
        position: position,
        duration: duration,
        height: MiniSeekBand.height,
        keyStep: MiniSeekBand.keyStep,
        seekOnTap: false,
        anyDirection: true,
        semanticLabel: l10n.playbackSeek,
        semanticValue: duration == null
            ? null
            : l10n.playbackPositionValue(
                formatClock(position),
                formatClock(duration),
              ),
        onSeekStart: _bubble.show,
        onSeekEnd: _bubble.hide,
        onSeek: (to) => ref.read(playerControllerProvider).seek(to),
        builder: (context, state) => CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _bubble,
            overlayChildBuilder: (_) => MiniSeekBubble(
              link: _link,
              state: state,
              duration: duration ?? Duration.zero,
              cardHeight: widget.cardHeight,
              bandHeight: MiniSeekBand.height,
            ),
            child: _Strip(state: state, radius: widget.radius),
          ),
        ),
      ),
    );
  }
}

/// The line (clipped to the card's corners) and the thumb (never clipped:
/// it centres on the line and so hangs up to 5 dp below the card edge).
class _Strip extends StatelessWidget {
  const _Strip({required this.state, required this.radius});

  final KSeekState state;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced ? Duration.zero : KMotion.fast;
    final line = !state.seekable
        ? MiniSeekBand.lineRest
        : state.dragging
        ? MiniSeekBand.lineDragging
        : state.active
        ? MiniSeekBand.lineActive
        : MiniSeekBand.lineRest;
    final showThumb = state.seekable && state.active;
    final ring =
        state.focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    const half = MiniSeekBand.thumbSize / 2;
    final left = (state.progress * state.width - half).clamp(
      0.0,
      (state.width - MiniSeekBand.thumbSize).clamp(0.0, double.infinity),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(end: line),
      duration: duration,
      curve: KMotion.emphasized,
      builder: (context, lineHeight, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(bottom: radius.bottomLeft),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  height: lineHeight,
                  color: scheme.primary.withValues(alpha: 0.24),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: state.seekable ? state.progress : 0,
                    heightFactor: 1,
                    child: ColoredBox(color: scheme.primary),
                  ),
                ),
              ),
            ),
          ),
          if (state.seekable)
            Positioned(
              left: left,
              bottom: lineHeight / 2 - half,
              width: MiniSeekBand.thumbSize,
              height: MiniSeekBand.thumbSize,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: AnimatedOpacity(
                    opacity: showThumb ? 1 : 0,
                    duration: duration,
                    child: AnimatedScale(
                      scale: showThumb ? 1 : 0.5,
                      duration: duration,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                          boxShadow: ring
                              ? [
                                  BoxShadow(
                                    color: scheme.primary,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: scheme.surfaceContainerHigh,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
