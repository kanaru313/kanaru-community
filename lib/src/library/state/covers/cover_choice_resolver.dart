import '../../domain/covers/cover_crop.dart';
import '../custom_cover_providers.dart';
import 'cover_dialog_options.dart';
import 'cover_dialog_state.dart';
import 'cover_temp_files.dart';

/// The [CoverChoice] for what [s] has chosen, ready for `changeCover` or a
/// draft. Needs no provider: it is safe to run after the dialog is gone.
///
/// A suggestion is cut like a picked image: its file is read once for its
/// size (`previewCover`, the preview is deleted at once) and a non-square
/// cover is cut in the middle. Failures are those of `previewCover`.
/// Throws [StateError] when the chosen row is the item's current cover or
/// nothing: there is nothing to change then.
Future<CoverChoice> resolveCoverChoice(
  CustomCoverController controller,
  CoverDialogState s,
) async {
  final id = s.selectedId;
  if (id == CoverRowIds.automatic) return const CoverChoice.automatic();
  final picked = s.chosenPicked;
  if (picked != null) {
    final size = picked.preview!;
    return CoverChoice.file(
      picked.image.file,
      crop: cropFor(s.offset, size.width, size.height),
    );
  }
  final suggestion = s.selectedSuggestion;
  if (suggestion == null) {
    throw StateError('row "$id" has nothing to change');
  }
  final preview = await controller.previewCover(suggestion.full);
  try {
    return CoverChoice.file(
      suggestion.full,
      crop: cropFor(0.5, preview.width, preview.height),
    );
  } finally {
    await deleteTempFiles([preview.file]);
  }
}
