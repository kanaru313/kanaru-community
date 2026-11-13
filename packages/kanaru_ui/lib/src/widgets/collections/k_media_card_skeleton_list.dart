import 'package:material_ui/material_ui.dart';

import 'k_media_card.dart';

/// Loading look of a list of [KMediaCard] rows: skeleton cards, as many as
/// fill the height the list gets below its [header] (`ceil(height left /
/// extentOf)`, the header measured by layout), not scrollable. Needs a
/// bounded height (a list body always has one). In an unbounded parent it
/// draws [unboundedCount] rows. Hidden from semantics. [horizontalPadding] is
/// the side space the real list uses; [roundCover] draws circles for round
/// photos (artists).
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
          final bounded = constraints.hasBoundedHeight;
          Widget rows(int count) => SliverFixedExtentList(
            itemExtent: extent,
            delegate: SliverChildBuilderDelegate(
              (context, i) => KMediaCard(
                title: '',
                loading: true,
                circleLeading: roundCover,
              ),
              childCount: count,
            ),
          );
          return CustomScrollView(
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: !bounded,
            slivers: [
              if (header != null) SliverToBoxAdapter(child: header),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                // The height still free after the header sliver, measured.
                sliver: bounded
                    ? SliverLayoutBuilder(
                        builder: (context, sliver) =>
                            rows((sliver.remainingPaintExtent / extent).ceil()),
                      )
                    : rows(unboundedCount),
              ),
            ],
          );
        },
      ),
    );
  }
}
