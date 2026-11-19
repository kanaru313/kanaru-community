import 'dart:io';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A cover preview of [width] x [height] upright pixels shown square-cut the
/// way a cover is saved: cover-fit and slid to [offset] (0..1) along its long
/// axis, the same cut `cropFor` gives. One widget for the dialog frame and the
/// Edit form, so what they show is what gets stored.
///
/// Without a size ([width] / [height] null: a thumb that is already square, or
/// a file of unknown shape) the picture is cover-fitted and centred, decoded
/// to fit the frame like a `KCover`.
///
/// Changing [file] keeps the old picture on screen until the new one has its
/// first frame, and only the very first picture fades in (over whatever sits
/// behind), so a switch never dips through a blank frame.
class PannedCoverImage extends StatelessWidget {
  const PannedCoverImage({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.offset = 0.5,
    required this.dimension,
    required this.errorBuilder,
  });

  final File file;
  final int? width;
  final int? height;
  final double offset;

  /// Side of the square shown.
  final double dimension;

  /// Shown when the file cannot be read.
  final ImageErrorWidgetBuilder errorBuilder;

  @override
  Widget build(BuildContext context) {
    final px = (dimension * MediaQuery.devicePixelRatioOf(context)).ceil();
    final w = width;
    final h = height;
    final known = w != null && h != null;
    final landscape = known && w > h;
    final t = offset * 2 - 1;
    return Image(
      image: known
          // Decode the short side at frame size; the long side follows.
          ? ResizeImage(
              FileImage(file),
              width: landscape ? null : px,
              height: landscape ? px : null,
            )
          : ResizeImage(
              FileImage(file),
              width: px,
              height: px,
              policy: ResizeImagePolicy.fit,
            ),
      width: dimension,
      height: dimension,
      fit: BoxFit.cover,
      alignment: !known
          ? Alignment.center
          : landscape
          ? Alignment(t, 0)
          : Alignment(0, t),
      // A new file keeps showing the old picture until it has decoded.
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
      // Always the same stateful wrapper (a cached first picture counts as
      // shown), so a later switch to an uncached file never starts from 0.
      frameBuilder: (context, child, frame, sync) =>
          _FirstFrameFade(shown: sync || frame != null, child: child),
    );
  }
}

/// Fades the picture in once, from transparent so what sits behind shows
/// through; after its first frame it stays opaque. An image provider change
/// resets the frame to null, which must not dim the picture kept by
/// `gaplessPlayback`.
class _FirstFrameFade extends StatefulWidget {
  const _FirstFrameFade({required this.shown, required this.child});

  final bool shown;
  final Widget child;

  @override
  State<_FirstFrameFade> createState() => _FirstFrameFadeState();
}

class _FirstFrameFadeState extends State<_FirstFrameFade> {
  bool _everShown = false;

  @override
  Widget build(BuildContext context) {
    _everShown = _everShown || widget.shown;
    return AnimatedOpacity(
      opacity: _everShown ? 1 : 0,
      duration: KMotion.fast,
      child: widget.child,
    );
  }
}
