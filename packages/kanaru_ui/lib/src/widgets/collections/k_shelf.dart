import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';

/// Titled row of fixed-width items that scrolls sideways. The title row ends
/// with a `›` that opens the full list ([onSeeAll]).
class KShelf extends StatelessWidget {
  const KShelf({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemWidth,
    required this.height,
    this.onSeeAll,
    this.seeAllLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: KSpace.x4),
  });

  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemWidth;

  /// Height of the item row (the caller includes its text scale).
  final double height;
  final VoidCallback? onSeeAll;

  /// Screen-reader text of the title row, for example "See all: Albums".
  final String? seeAllLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final header = Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: KLayout.minTarget),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (onSeeAll != null)
              Icon(KIcons.chevronRight, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onSeeAll == null)
          header
        else
          Semantics(
            button: true,
            label: seeAllLabel ?? title,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: KRadius.sm,
              onTap: onSeeAll,
              child: header,
            ),
          ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: padding,
            itemCount: itemCount,
            separatorBuilder: (_, _) => const KGap(KSpace.x3),
            itemBuilder: (context, i) =>
                SizedBox(width: itemWidth, child: itemBuilder(context, i)),
          ),
        ),
      ],
    );
  }
}
