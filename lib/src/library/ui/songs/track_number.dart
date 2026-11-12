import 'package:material_ui/material_ui.dart';

/// Text style of a track number, shared by drawing ([TrackNumber]) and
/// measuring ([trackNumberWidth]) so the two cannot drift. Tabular figures
/// make every digit the same width, so 1 … 12 line up when right-aligned.
TextStyle? trackNumberStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleSmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      // `Text` adds bold itself under the system bold-text setting; a
      // `TextPainter` does not, so the style carries it for both.
      fontWeight: MediaQuery.boldTextOf(context) ? FontWeight.bold : null,
    );

/// Width of the prefix slot for a list whose numbers have [digits] digits:
/// that many zeros in the number style at the current text scale. Computed
/// once per list, not per row.
///
/// Lists pass the digits of their length: a track number above the list
/// length (a filtered album, track 12 of 3 rows) is wider than the slot and
/// the card's prefix `FittedBox` scales it down instead of overflowing.
double trackNumberWidth(BuildContext context, int digits) {
  final painter = TextPainter(
    text: TextSpan(
      text: '0' * (digits < 1 ? 1 : digits),
      style: trackNumberStyle(context),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width.ceilToDouble();
}

/// Number of decimal digits of a list of [length] rows (at least 1).
int digitsOfLength(int length) => length < 10 ? 1 : '$length'.length;

/// Track number before the cover (album pages), empty when the file has no
/// track number. Right-aligned in at least [width] on one line; the card's
/// prefix `FittedBox` scales it down only when a longer number or the text
/// size makes it wider, so it never wraps or overflows.
class TrackNumber extends StatelessWidget {
  const TrackNumber({super.key, required this.number, required this.width});

  final int? number;
  final double width;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minWidth: width),
    child: Text(
      number == null ? '' : '$number',
      textAlign: TextAlign.right,
      maxLines: 1,
      softWrap: false,
      // The card sets its soft colour (the tint-aware one) on IconTheme, not
      // on the text style; this reads it from there. Depends on KMediaCard
      // keeping that IconTheme around its content.
      style: trackNumberStyle(context)
          ?.copyWith(color: IconTheme.of(context).color),
    ),
  );
}
