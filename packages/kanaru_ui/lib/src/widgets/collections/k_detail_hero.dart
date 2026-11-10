import 'package:material_ui/material_ui.dart';

import '../../tokens/k_space.dart';
import '../k_gap.dart';
import 'k_detail_layout.dart';

/// Top of an album or artist page, for the [KDetailLayout.header] slot.
///
/// Narrow: a [coverSize] cover on the left and, aligned to its bottom, the
/// [body] lines and the [actions] on the right. Wide (the left column): the
/// cover as wide as the column, fading into the page at its bottom and right
/// edges (a [circle] photo is not faded), then [body] and [actions] below.
///
/// [coverBuilder] draws the cover in a square of the side it is given, so the
/// caller keeps the music types.
class KDetailHero extends StatelessWidget {
  const KDetailHero({
    super.key,
    required this.coverBuilder,
    required this.body,
    required this.actions,
    this.circle = false,
  });

  final Widget Function(BuildContext context, double side) coverBuilder;

  /// Lines next to or under the cover (artist link, year, counts).
  final List<Widget> body;

  /// Buttons row (play, shuffle, more).
  final Widget actions;

  /// Round photo: no fade, drawn inside the circle.
  final bool circle;

  static const double coverSize = 132;

  @override
  Widget build(BuildContext context) {
    final wide = KDetailLayout.isWide(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [...body, if (body.isNotEmpty) const KGap(KSpace.x3), actions],
    );
    if (!wide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpace.x4,
          KSpace.x2,
          KSpace.x4,
          KSpace.x3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox.square(
              dimension: coverSize,
              child: coverBuilder(context, coverSize),
            ),
            const KGap(KSpace.x4),
            Expanded(child: text),
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
      cover = _fade(_fade(cover, vertical: true), vertical: false);
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
            child: text,
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
