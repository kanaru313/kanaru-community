import 'package:material_ui/material_ui.dart';

import '../../tokens/k_space.dart';
import '../k_detail_title.dart';
import '../k_gap.dart';

/// Name block at the head of a "see all" grid: the [title] (the page's name,
/// up to two lines) and an optional one-line [caption] under it. No cover, no
/// buttons.
class KGridHeading extends StatelessWidget {
  const KGridHeading({super.key, required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        KDetailTitle(
          title,
          maxLines: 2,
          style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700),
        ),
        if (caption != null) ...[
          const KGap(KSpace.x1),
          Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
