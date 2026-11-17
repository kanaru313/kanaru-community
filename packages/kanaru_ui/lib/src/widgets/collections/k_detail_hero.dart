import 'package:material_ui/material_ui.dart';

import '../../tokens/k_space.dart';
import '../k_detail_title.dart';
import '../k_gap.dart';
import 'k_detail_layout.dart';
import 'k_detail_line.dart';

/// Top of an album or artist page, for the [KDetailLayout.header] slot:
/// cover, the page's [title], a [line2] (link), a [line3] (plain), the
/// [actions] row and an optional [description].
///
/// Narrow: a [coverSize] cover on the left and the text column centred on
/// it; the [description] runs under the whole row. Wide (the left column):
/// the cover as wide as the column, fading into the page at its bottom edge
/// (a [circle] photo is not faded), then the same lines in the
/// same order.
///
/// The title is the page's name: when it scrolls out of sight under a
/// `PageHeader(titleInContent: true)` inside a [KDetailTitleHost], the header
/// shows it instead.
///
/// [coverBuilder] draws the cover in a square of the side it is given, so the
/// caller keeps the music types.
class KDetailHero extends StatelessWidget {
  const KDetailHero({
    super.key,
    required this.coverBuilder,
    required this.title,
    required this.actions,
    this.line2,
    this.line3,
    this.description,
    this.circle = false,
  });

  final Widget Function(BuildContext context, double side) coverBuilder;

  /// Name of the page (album, artist).
  final String title;

  /// Second line, usually the owner (artist) as a link plus a year.
  final KDetailLine? line2;

  /// Third line, one plain line (counts); null or empty leaves it out.
  final String? line3;

  /// Buttons row (play, shuffle, more).
  final Widget actions;

  /// Text under the row (narrow) or under the buttons (wide), usually a
  /// `KDetailDescription`.
  final Widget? description;

  /// Round photo: no fade, drawn inside the circle.
  final bool circle;

  static const double coverSize = 132;

  Widget _text(BuildContext context, {required bool wide}) {
    final textTheme = Theme.of(context).textTheme;
    final line3 = this.line3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        KDetailTitle(
          title,
          maxLines: wide ? 3 : 2,
          style: (wide ? textTheme.headlineSmall : textTheme.titleLarge)!
              .copyWith(fontWeight: FontWeight.w700),
        ),
        ?line2,
        // Ignored for touch: the second line's touch area overlaps it.
        if (line3 != null && line3.isNotEmpty)
          IgnorePointer(
            child: Text(
              line3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const KGap(KSpace.x2),
        actions,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = KDetailLayout.isWide(context);
    final text = _text(context, wide: wide);
    if (!wide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpace.x4,
          KSpace.x2,
          KSpace.x4,
          KSpace.x3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: coverSize,
                  child: coverBuilder(context, coverSize),
                ),
                const KGap(KSpace.x4),
                Expanded(child: text),
              ],
            ),
            if (description != null) ...[const KGap(KSpace.x3), description!],
          ],
        ),
      );
    }
    const side = KDetailLayout.columnWidth;
    Widget cover = SizedBox.square(
      dimension: side,
      child: coverBuilder(context, side),
    );
    if (!circle) {
      cover = _fade(cover, vertical: true);
    }
    return SizedBox(
      width: side,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          circle
              ? Padding(
                  padding: const EdgeInsets.all(KSpace.x4),
                  child: SizedBox.square(
                    dimension: side - KSpace.x4 * 2,
                    child: coverBuilder(context, side - KSpace.x4 * 2),
                  ),
                )
              : cover,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x4,
              0,
              KSpace.x4,
              KSpace.x4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                text,
                if (description != null) ...[
                  const KGap(KSpace.x3),
                  description!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fades the last quarter of [child] to transparent along one axis.
  static Widget _fade(Widget child, {required bool vertical}) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (rect) => LinearGradient(
      begin: Alignment.topLeft,
      end: vertical ? Alignment.bottomLeft : Alignment.topRight,
      stops: const [0.7, 1],
      colors: const [Color(0xFF000000), Color(0x00000000)],
    ).createShader(rect),
    child: child,
  );
}
