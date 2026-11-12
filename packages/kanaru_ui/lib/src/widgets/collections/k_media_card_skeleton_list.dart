import 'package:material_ui/material_ui.dart';

import 'k_media_card.dart';

/// Loading look of a list of [KMediaCard] rows: skeleton cards, as many as
/// fill the height the list gets (`ceil(height / extentOf)`), not scrollable.
/// [horizontalPadding] is the side space the real list uses; [roundCover]
/// draws circles for round photos (artists).
class KMediaCardSkeletonList extends StatelessWidget {
  const KMediaCardSkeletonList({
    super.key,
    this.horizontalPadding = 0,
    this.roundCover = false,
  });

  final double horizontalPadding;
  final bool roundCover;

  @override
  Widget build(BuildContext context) {
    final extent = KMediaCard.extentOf(MediaQuery.textScalerOf(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : extent;
        return CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
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
                  childCount: (height / extent).ceil(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
