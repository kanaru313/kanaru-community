import 'cover_choice.dart';

/// The square cut of a [width] x [height] image (upright pixels) that starts
/// at [offset] along the long axis: 0 is the start, 1 the end, 0.5 the
/// middle. Values outside 0..1 (and NaN) are clamped. Null for a square
/// image: nothing to cut. One function for the position of the preview and
/// for what is saved, so they can never disagree.
CoverCrop? cropFor(double offset, int width, int height) {
  if (width <= 0 || height <= 0 || width == height) return null;
  final side = width < height ? width : height;
  final room = (width > height ? width : height) - side;
  final t = offset.isNaN ? 0.5 : offset.clamp(0.0, 1.0);
  final start = (t * room).round();
  return width > height
      ? CoverCrop(left: start, top: 0, side: side)
      : CoverCrop(left: 0, top: start, side: side);
}
