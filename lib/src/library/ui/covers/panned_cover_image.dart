import 'dart:io';

import 'package:material_ui/material_ui.dart';

/// A cover preview of [width] x [height] upright pixels shown square-cut the
/// way a cover is saved: cover-fit and slid to [offset] (0..1) along its long
/// axis, the same cut `cropFor` gives. One widget for the dialog frame and the
/// Edit form, so what they show is what gets stored.
class PannedCoverImage extends StatelessWidget {
  const PannedCoverImage({
    super.key,
    required this.file,
    required this.width,
    required this.height,
    required this.offset,
    required this.dimension,
    required this.errorBuilder,
  });

  final File file;
  final int width;
  final int height;
  final double offset;

  /// Side of the square shown.
  final double dimension;

  /// Shown when the file cannot be read.
  final ImageErrorWidgetBuilder errorBuilder;

  @override
  Widget build(BuildContext context) {
    final px = (dimension * MediaQuery.devicePixelRatioOf(context)).ceil();
    final t = offset * 2 - 1;
    final landscape = width > height;
    return Image.file(
      file,
      width: dimension,
      height: dimension,
      fit: BoxFit.cover,
      alignment: landscape ? Alignment(t, 0) : Alignment(0, t),
      // Decode the short side at frame size; the long side follows.
      cacheWidth: landscape ? null : px,
      cacheHeight: landscape ? px : null,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );
  }
}
