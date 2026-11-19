import 'dart:io';

/// An upright, at most 1024 px preview of a chosen image, and the upright
/// size of the original, the space a `CoverCrop` is given in. The file lives
/// under the folder it was prepared in; whoever prepared it deletes it.
class CoverPreview {
  const CoverPreview({
    required this.file,
    required this.width,
    required this.height,
  });

  final File file;

  /// Upright size of the original image, not of [file].
  final int width;
  final int height;
}
