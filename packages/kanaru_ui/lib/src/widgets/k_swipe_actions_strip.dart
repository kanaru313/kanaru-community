import 'package:flutter/widgets.dart';

import '../tokens/k_motion.dart';
import '../tokens/k_space.dart';
import 'collections/k_media_card.dart';

/// The strip a capped swipe uncovers (the remove kind shows none). It is drawn
/// only in the area the row has left (width `|offset|`, on the side it moved
/// away from) and stops above the 4 dp gap a [KMediaCard] pads below itself, so
/// it matches the card. Must be a child of a [Stack].
class KSwipeStrip extends StatelessWidget {
  const KSwipeStrip({
    super.key,
    required this.offset,
    required this.icon,
    required this.iconColor,
    required this.progress,
    required this.scaled,
    required this.fill,
    required this.label,
    required this.labelStyle,
  });

  /// Signed row offset: positive uncovers the left side.
  final double offset;
  final IconData icon;
  final Color iconColor;

  /// 0..1; the icon and label fade in with it.
  final double progress;

  /// The icon is enlarged once the trigger is reached.
  final bool scaled;
  final Color fill;
  final String label;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final fromLeft = offset > 0;
    Widget content = OverflowBox(
      // Centred in the revealed area. Both minimums are loosened: the strip
      // gives this box tight constraints and OverflowBox passes unchanged
      // limits on to its child, which would stretch the Column to the full
      // height and leave its content at the top.
      alignment: Alignment.center,
      minWidth: 0,
      maxWidth: double.infinity,
      minHeight: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpace.x6),
        child: Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: scaled ? 1.3 : 1,
                duration: KMotion.fast,
                child: Icon(icon, color: iconColor),
              ),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: labelStyle,
              ),
            ],
          ),
        ),
      ),
    );
    content = ColoredBox(color: fill, child: content);
    return Positioned(
      left: fromLeft ? 0 : null,
      right: fromLeft ? null : 0,
      width: offset.abs(),
      top: 0,
      bottom: KMediaCard.gap,
      child: ExcludeSemantics(child: ClipRect(child: content)),
    );
  }
}
