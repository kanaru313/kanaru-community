import 'dart:io';

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

/// What the user picked for an item's cover.
sealed class CoverChoice {
  const CoverChoice();

  /// Back to the automatic cover (no custom cover row).
  const factory CoverChoice.automatic() = AutomaticCover;

  /// An image file, whole or cut to [crop] (a square of the upright original).
  const factory CoverChoice.file(File image, {CoverCrop? crop}) = FileCover;
}

class AutomaticCover extends CoverChoice {
  const AutomaticCover();
}

class FileCover extends CoverChoice {
  const FileCover(this.image, {this.crop});

  final File image;
  final CoverCrop? crop;
}

/// The outcome of one cover change, kept until [release] so the change can be
/// taken back. While it is unreleased the files of [previousKey] stay on disk,
/// whatever else deletes covers.
abstract interface class CoverChange {
  /// Cover key the item had before the change (null: the automatic cover).
  String? get previousKey;

  /// Cover key the item has after the change (null: the automatic cover).
  String? get currentKey;

  /// Puts [previousKey] back. Returns false, changing nothing, when the item
  /// no longer holds [currentKey] (another change landed), when the item is
  /// gone (a deleted playlist), when the change was already undone or
  /// released, or when the database refuses. Releases the change either way.
  Future<bool> undo();

  /// Lets go of [previousKey]: its files are deleted when nothing references
  /// them. Safe to call again.
  Future<void> release();
}
