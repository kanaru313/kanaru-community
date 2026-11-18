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
/// [coverBuilder] draws the cover in a square of the side it is given, with
/// the corner radius this layout wants (round when narrow, square in the wide
/// column), so the caller keeps the music types and never asks which layout
/// it is in.
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
    this.framedCover = false,
  }) : assert(!(circle && framedCover), 'a round photo has no framed cover');

  final Widget Function(BuildContext context, double side, BorderRadius radius)
  coverBuilder;

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

  /// Playlist look of the wide column: the cover washed out as a backdrop
  /// (35 % opacity, no blur, fading at its foot and right edge) with the
  /// cover again as a framed card centred on it, and a two-line name. The
  /// cover is built once, at the card's inner side, and the backdrop scales
  /// that same widget, so one image decode serves both. That widget is placed in
  /// two spots of the tree, so what [coverBuilder] returns must not carry a
  /// `GlobalKey`. Ignored when narrow.
  final bool framedCover;

  static const double coverSize = 132;

  /// Framed card over the backdrop: outer side, border, outer and inner radii.
  static const double frameSize = 240;
  static const double frameBorder = 4;
  static const double frameRadius = 16;
  static const double frameInnerSize = frameSize - 2 * frameBorder;
  static const double frameInnerRadius = frameRadius - frameBorder;

  /// Opacity of the framed backdrop.
  static const double backdropOpacity = 0.35;
  static const double _frameShadowAlpha = 0.3;
  static const double _frameShadowBlur = 24;
  static const double _frameShadowDrop = 8;

  /// Corner radius of the narrow cover; the wide cover is square.
  static const BorderRadius narrowCoverRadius = BorderRadius.all(
    Radius.circular(14),
  );

  Widget _text(BuildContext context, {required bool wide, int wideLines = 3}) {
    final textTheme = Theme.of(context).textTheme;
    final line3 = this.line3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        KDetailTitle(
          title,
          maxLines: wide ? wideLines : 2,
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
    final framed = framedCover && wide;
    final text = _text(context, wide: wide, wideLines: framed ? 2 : 3);
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
                  child: coverBuilder(context, coverSize, narrowCoverRadius),
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
    if (framed) return _framed(context, text);
    Widget cover = SizedBox.square(
      dimension: side,
      child: coverBuilder(context, side, BorderRadius.zero),
    );
    if (!circle) {
      cover = _fadeBottom(cover);
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
                    child: coverBuilder(
                      context,
                      side - KSpace.x4 * 2,
                      BorderRadius.zero,
                    ),
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

  Widget _framed(BuildContext context, Widget text) {
    const side = KDetailLayout.columnWidth;
    final scheme = Theme.of(context).colorScheme;
    // Built once: the card and the backdrop show the same widget.
    final cover = coverBuilder(context, frameInnerSize, BorderRadius.zero);
    return SizedBox(
      width: side,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: side,
                child: Opacity(
                  opacity: backdropOpacity,
                  child: _fadeBottom(
                    _fadeRight(
                      FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox.square(
                          dimension: frameInnerSize,
                          child: cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(frameRadius),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: _frameShadowAlpha),
                      blurRadius: _frameShadowBlur,
                      offset: const Offset(0, _frameShadowDrop),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(frameBorder),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(frameInnerRadius),
                    child: SizedBox.square(
                      dimension: frameInnerSize,
                      child: cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x4,
              KSpace.x2,
              KSpace.x4,
              KSpace.x6,
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

  /// Fades the last 5 % of [child] at the right edge down to half.
  static Widget _fadeRight(Widget child) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (rect) => const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: [0.95, 1],
      colors: [Color(0xFF000000), Color(0x80000000)],
    ).createShader(rect),
    child: child,
  );

  /// Fades the last 30 % of [child] to transparent, top to bottom.
  static Widget _fadeBottom(Widget child) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (rect) => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0.7, 1],
      colors: [Color(0xFF000000), Color(0x00000000)],
    ).createShader(rect),
    child: child,
  );
}
