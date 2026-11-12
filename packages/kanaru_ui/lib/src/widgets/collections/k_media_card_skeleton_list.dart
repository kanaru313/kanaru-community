import 'package:material_ui/material_ui.dart';

import 'k_media_card.dart';

/// Loading look of a list of [KMediaCard] rows: skeleton cards, as many as
/// fill the height the list gets (`ceil(height / extentOf)`), not scrollable.
/// Needs a bounded height (a list body always has one). In an unbounded
/// parent it draws [unboundedCount] rows. Hidden from semantics.
/// [horizontalPadding] is the side space the real list uses; [roundCover]
/// draws circles for round photos (artists).
class KMediaCardSkeletonList extends StatelessWidget {
  const KMediaCardSkeletonList({
    super.key,
    this.horizontalPadding = 0,
    this.roundCover = false,
    this.header,
  });

  final double horizontalPadding;
  final bool roundCover;

  /// Content the real list draws above its rows (a note), so the rows sit at
  /// the same y while loading and loaded. It brings its own padding.
  final Widget? header;

  /// Rows drawn when the parent gives no height limit.
  static const int unboundedCount = 8;

  @override
  Widget build(BuildContext context) {
    final extent = KMediaCard.extentOf(MediaQuery.textScalerOf(context));
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.hasBoundedHeight
              ? (constraints.maxHeight / extent).ceil()
              : unboundedCount;
          return CustomScrollView(
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: !constraints.hasBoundedHeight,
            slivers: [
              if (header != null) SliverToBoxAdapter(child: header),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverFixedExtentList(
                  itemExtent: extent,
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => KMediaCard(
                      title: '',
                      loading: true,
                      circleLeading: roundCover,
                    ),
                    childCount: count,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
