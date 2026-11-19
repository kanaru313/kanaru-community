import 'dart:io';

import '../../../platform/domain/image_file_picker.dart';
import '../../domain/covers/cover_choice.dart';
import '../../domain/covers/cover_preview.dart';
import 'cover_temp_files.dart';

/// An image picked from the device: the file the picker gave and, once read,
/// its upright preview. While [preview] is null the preview is being made.
class CoverPicked {
  const CoverPicked(this.image, [this.preview]);

  final PickedImage image;
  final CoverPreview? preview;

  bool get reading => preview == null;

  /// Files the app made for this pick and must delete: the picker's copy (not
  /// the user's own file) and the preview.
  List<File> get ownedFiles => [
    if (image.temporary) image.file,
    ?preview?.file,
  ];
}

/// What the cover dialog returns in form mode (Sửa playlist): the choice and
/// what the form needs to show it, with no write done. The holder owns the
/// temp files of [picked]: it calls [discard] when the draft is replaced or
/// dropped, and keeps them until the form is saved.
class CoverDraft {
  const CoverDraft({
    required this.choice,
    required this.rowId,
    this.displayFile,
    this.picked,
    this.offset = 0.5,
  });

  /// What to save; null when the user went back to the cover the item has
  /// stored, so the holder drops its pending draft.
  final CoverChoice? choice;

  /// Row of the dialog this draft was made from (`CoverRowIds`), so the
  /// dialog can open on it again.
  final String rowId;

  /// Image that stands for the choice in the form (the preview file of a
  /// picked image, the album cover file of a suggestion); null for the
  /// automatic cover.
  final File? displayFile;

  /// The picked image, when the choice is one; its files are the holder's.
  final CoverPicked? picked;

  /// Pan position the crop was made at.
  final double offset;

  bool get isAutomatic => choice is AutomaticCover;

  /// The user went back to the stored cover: nothing is pending.
  bool get keepsStored => choice == null;

  /// Deletes the temp files this draft owns.
  Future<void> discard() => deleteTempFiles(picked?.ownedFiles ?? const []);

  /// [discard] for a draft that [next] replaces: keeps the files when [next]
  /// is made from the same picked image (the dialog reopened on this draft
  /// and only moved the pan).
  Future<void> discardUnlessSharedWith(CoverDraft next) =>
      next.picked?.image.file.path == picked?.image.file.path && picked != null
      ? Future.value()
      : discard();
}
