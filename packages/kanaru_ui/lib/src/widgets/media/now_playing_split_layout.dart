import 'package:material_ui/material_ui.dart';

import 'now_playing_split_geometry.dart';

/// What the track column needs to lay itself out in the split body.
class SplitMetrics {
  const SplitMetrics({
    required this.columnWidth,
    required this.innerWidth,
    required this.coverSide,
    required this.blockHeight,
  });

  /// Whole column, padding included.
  final double columnWidth;

  /// Column minus its horizontal padding.
  final double innerWidth;
  final double coverSide;

  /// Height of the fixed block: the cover plus everything reserved below it.
  final double blockHeight;
}

/// The split body of the desktop Now Playing: the track column on the left
/// (42 % of the body, 300..600) and the side pane filling the rest. The cover
/// size comes from the body's height and a fixed reserve for the text, the
/// seek slot and the transport row, so nothing moves when a title wraps. The
/// numbers are the old app's.
class NowPlayingSplitLayout extends StatelessWidget {
  const NowPlayingSplitLayout({
    super.key,
    required this.columnBuilder,
    required this.pane,
    required this.titleStyle,
    required this.lineStyle,
    required this.seekHeight,
  });

  /// Builds the track column for the given [SplitMetrics].
  final Widget Function(BuildContext context, SplitMetrics metrics)
  columnBuilder;
  final Widget pane;

  /// Style of the title (the reserve counts two lines of it) and of the
  /// artist and album lines.
  final TextStyle? titleStyle;
  final TextStyle? lineStyle;

  /// Height of the seek slot.
  final double seekHeight;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final columnWidth = splitColumnWidth(box.maxWidth);
        final inner = columnWidth - splitColumnPadding.horizontal;
        final reserve = splitReserve(
          scaler,
          titleStyle: titleStyle,
          lineStyle: lineStyle,
          seekHeight: seekHeight,
        );
        final side = splitCoverSide(
          innerWidth: inner,
          bodyHeight: box.maxHeight,
          reserve: reserve,
        );
        return Row(
          children: [
            SizedBox(
              width: columnWidth,
              child: columnBuilder(
                context,
                SplitMetrics(
                  columnWidth: columnWidth,
                  innerWidth: inner,
                  coverSide: side,
                  blockHeight: side + reserve,
                ),
              ),
            ),
            Expanded(child: pane),
          ],
        );
      },
    );
  }
}
