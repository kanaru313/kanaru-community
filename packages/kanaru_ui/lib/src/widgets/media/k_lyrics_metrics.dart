import 'package:material_ui/material_ui.dart';

/// Where lyrics are drawn; each surface has its own size rule.
enum KLyricsSurface {
  /// The mobile full lyrics screen.
  screen,

  /// The desktop "Lyrics" tab of the Now Playing side pane.
  tab,

  /// The mobile Now Playing card (three lines).
  card,
}

/// Sizes of one lyrics area, before the user's font scale (the caller
/// multiplies [lineSize] by it). Width rules live here so `lib/src/` never
/// reads a width to size lyrics.
class KLyricsMetrics {
  const KLyricsMetrics({
    required this.lineSize,
    required this.sidePadding,
    required this.viewportHeight,
  });

  /// Font size of a synced line, in dp.
  final double lineSize;

  /// Space between the area's edge and the text.
  final double sidePadding;

  /// Height of the area: the synced view sizes its anchor padding from it and
  /// puts the current line back after a resize.
  final double viewportHeight;

  /// Plain (unsynchronized) lyrics are this fraction of [lineSize].
  static const double plainScale = 0.7;

  /// Mobile screen: from this width on, the tablet sizes apply.
  static const double tabletWidth = 600;

  /// Desktop tab: below this pane width the narrow sizes apply.
  static const double narrowPaneWidth = 900;

  /// Share of the pane width used as side padding when the cover column is
  /// hidden.
  static const double hiddenColumnPaddingShare = 0.12;

  /// Card: synced line size and plain line size.
  static const double cardLineSize = 18;
  static const double cardPlainLineSize = 15;

  /// The metrics of a [surface] [width] x [height] dp big. [coverColumnShown]
  /// matters on the desktop tab only.
  static KLyricsMetrics resolve({
    required KLyricsSurface surface,
    required double width,
    required double height,
    bool coverColumnShown = true,
  }) {
    final (size, padding) = switch (surface) {
      KLyricsSurface.screen =>
        width >= tabletWidth ? (34.0, 56.0) : (25.0, 24.0),
      KLyricsSurface.tab when width < narrowPaneWidth => (22.0, 24.0),
      KLyricsSurface.tab when coverColumnShown => (28.0, 40.0),
      KLyricsSurface.tab => (36.0, width * hiddenColumnPaddingShare),
      KLyricsSurface.card => (cardLineSize, 0.0),
    };
    return KLyricsMetrics(
      lineSize: size,
      sidePadding: padding,
      viewportHeight: height,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KLyricsMetrics &&
      other.lineSize == lineSize &&
      other.sidePadding == sidePadding &&
      other.viewportHeight == viewportHeight;

  @override
  int get hashCode => Object.hash(lineSize, sidePadding, viewportHeight);
}

/// Measures its box and hands [builder] the [KLyricsMetrics] for [surface].
/// The one place that turns the available width into lyrics sizes.
class KLyricsMetricsBuilder extends StatelessWidget {
  const KLyricsMetricsBuilder({
    super.key,
    required this.surface,
    this.coverColumnShown = true,
    required this.builder,
  });

  final KLyricsSurface surface;
  final bool coverColumnShown;
  final Widget Function(BuildContext context, KLyricsMetrics metrics) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => builder(
      context,
      KLyricsMetrics.resolve(
        surface: surface,
        width: box.maxWidth,
        // Unbounded (inside a scroll view): no anchor room can be computed.
        height: box.hasBoundedHeight ? box.maxHeight : 0,
        coverColumnShown: coverColumnShown,
      ),
    ),
  );
}
