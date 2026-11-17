import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'mini_player_body.dart';
import 'playback_time_label.dart';

/// Gap between the bubble and the card, and between the bubble and the card's
/// side edges.
const double miniSeekBubbleGap = 8;

/// "0:00 / 4:12" above the card at the finger, 8 dp from the card edges. It
/// lives in the overlay, so no clip of the card cuts it.
class MiniSeekBubble extends StatelessWidget {
  const MiniSeekBubble({
    super.key,
    required this.link,
    required this.state,
    required this.duration,
    required this.cardHeight,
    required this.bandHeight,
  });

  final LayerLink link;
  final KSeekState state;
  final Duration duration;
  final double cardHeight;

  /// Height of the seek band the bubble floats above.
  final double bandHeight;

  static const double _padV = 4;
  static const double _lineHeight = 16;

  @override
  Widget build(BuildContext context) {
    if (!state.dragging) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: MiniPlayerBody.maxTextScale(cardHeight));
    final at = Duration(
      milliseconds: (duration.inMilliseconds * state.progress).round(),
    );
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: scheme.onInverseSurface,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: _lineHeight / 12,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // The overlay gives its child tight constraints: Align frees the follower
    // to take the size of the bubble box.
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topLeft,
        followerAnchor: Alignment.bottomLeft,
        offset: Offset(0, -(cardHeight - bandHeight) - miniSeekBubbleGap),
        child: SizedBox(
          width: state.width,
          height: scaler.scale(_lineHeight) + 2 * _padV,
          child: CustomSingleChildLayout(
            delegate: _BubbleLayout(state.progress * state.width),
            child: Semantics(
              // The slider already speaks the position.
              excludeSemantics: true,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: scheme.inverseSurface,
                  shape: const StadiumBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: _padV,
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${formatClock(at)} '),
                        TextSpan(
                          text: '/ ${formatClock(duration)}',
                          style: TextStyle(
                            color: scheme.onInverseSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    style: style,
                    textScaler: scaler,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centres the bubble on [x], keeping 8 dp from both edges.
class _BubbleLayout extends SingleChildLayoutDelegate {
  const _BubbleLayout(this.x);

  final double x;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const edge = miniSeekBubbleGap;
    final max = size.width - childSize.width - edge;
    final left = (x - childSize.width / 2).clamp(edge, max < edge ? edge : max);
    return Offset(left, 0);
  }

  @override
  bool shouldRelayout(_BubbleLayout old) => old.x != x;
}
