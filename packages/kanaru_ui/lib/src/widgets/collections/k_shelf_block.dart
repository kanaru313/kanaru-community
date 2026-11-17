import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../theme/k_row_colors.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import '../k_icon_button.dart';

part 'k_shelf_block_body.dart';
part 'k_shelf_block_head.dart';

/// Rounded card around a titled, collapsible row of fixed-width items
/// (artist and group pages: Albums, Appears on, Artists).
///
/// The card fill is the song-row fill ([KRowColors.fill]). The head shows an
/// [icon], the [title] and the full [count]; the "see all" button
/// ([onSeeAll]) and a chevron sit at its end. Tapping the head calls
/// [onToggle]; the head has no hover or press fill, only the chevron reacts
/// (hover: `onSurface`, pressed: half opacity). The caller owns [collapsed]
/// so it can remember it per block kind. Collapsing shrinks the body over
/// `KMotion.normal` (instant when animations are disabled). The item row also
/// scrolls by mouse drag.
class KShelfBlock extends StatelessWidget {
  const KShelfBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.count,
    required this.collapsed,
    required this.onToggle,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemWidth,
    required this.height,
    this.onSeeAll,
    this.seeAllLabel = '',
    this.margin = EdgeInsets.zero,
  });

  final String title;
  final IconData icon;

  /// Full number of entries, even when the row shows fewer cards.
  final int count;
  final bool collapsed;
  final VoidCallback onToggle;

  /// Opens the full list; no button when null.
  final VoidCallback? onSeeAll;

  /// Tooltip and screen-reader label of the see-all button.
  final String seeAllLabel;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemWidth;

  /// Height of the item row (the caller includes its text scale).
  final double height;

  /// Space around the card.
  final EdgeInsetsGeometry margin;

  static const double _bodyBottom = KSpace.x3;
  static const EdgeInsets _bodyPadding = EdgeInsets.fromLTRB(
    KSpace.x3,
    0,
    KSpace.x3,
    _bodyBottom,
  );

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.normal;
    final body = SizedBox(
      height: height + _bodyBottom,
      child: _BodyRow(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        itemWidth: itemWidth,
        padding: _bodyPadding,
      ),
    );
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KRowColors.fill(brightness),
          borderRadius: KRadius.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Head(
              title: title,
              icon: icon,
              count: count,
              collapsed: collapsed,
              onToggle: onToggle,
              onSeeAll: onSeeAll,
              seeAllLabel: seeAllLabel,
              duration: duration,
            ),
            ClipRect(
              child: AnimatedContainer(
                key: bodyKey,
                duration: duration,
                curve: KMotion.emphasized,
                height: collapsed ? 0 : height + _bodyBottom,
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: height + _bodyBottom,
                  child: ExcludeFocus(
                    excluding: collapsed,
                    child: ExcludeSemantics(
                      excluding: collapsed,
                      child: IgnorePointer(ignoring: collapsed, child: body),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The animated body box, for layout tests.
  @visibleForTesting
  static const bodyKey = ValueKey('k-shelf-block-body');
}
