/// A square cut out of a cover image, in pixels of the **upright** original
/// (after its EXIF turn): the picture a preview shows and the size a preview
/// reports.
class CoverCrop {
  const CoverCrop({required this.left, required this.top, required this.side});

  final int left;
  final int top;
  final int side;

  @override
  bool operator ==(Object other) =>
      other is CoverCrop &&
      other.left == left &&
      other.top == top &&
      other.side == side;

  @override
  int get hashCode => Object.hash(left, top, side);

  @override
  String toString() => 'CoverCrop($left, $top, $side)';
}
