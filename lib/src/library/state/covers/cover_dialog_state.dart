import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/domain/image_file_picker.dart';
import '../../domain/covers/cover_choice.dart';
import '../../domain/covers/cover_crop.dart';
import 'cover_dialog_options.dart';
import 'cover_draft.dart';

/// A failure the dialog shows once as a snack bar (a pick or a read that
/// failed). Every instance is a new event, even for the same [cause].
class CoverDialogError {
  CoverDialogError(this.cause);

  /// What went wrong; map it with `CoverTexts.errorFor`.
  final Object cause;
}

/// The choice the dialog opened with, to tell whether the user changed it.
typedef CoverOpening = ({String rowId, PickedImage? image, double offset});

const Object _keep = Object();

/// State of one open cover dialog.
class CoverDialogState {
  const CoverDialogState({
    required this.options,
    this.selectedId,
    this.picked,
    this.offset = 0.5,
    this.saving = false,
    this.error,
    this.opening,
  });

  /// Loading, failed, or what the rows show.
  final AsyncValue<CoverDialogOptions> options;

  /// The chosen row (`CoverRowIds`); null until [options] is loaded.
  final String? selectedId;

  /// The image picked from the device (its row), reading or ready.
  final CoverPicked? picked;

  /// Pan position along the long axis of the picked image, 0..1.
  final double offset;

  /// A save (or the making of a draft) is running: the dialog is locked.
  final bool saving;

  /// The latest failure to show; null when none (or already shown).
  final CoverDialogError? error;

  final CoverOpening? opening;

  /// A picked image is being read.
  bool get reading => picked?.reading ?? false;

  /// The suggestion row that is chosen, if one is.
  CoverSuggestion? get selectedSuggestion {
    final id = selectedId;
    for (final s in options.value?.suggestions ?? const <CoverSuggestion>[]) {
      if (s.rowId == id) return s;
    }
    return null;
  }

  /// The picked image's row is chosen and its preview is ready.
  CoverPicked? get chosenPicked =>
      selectedId == CoverRowIds.picked && !reading ? picked : null;

  /// The square cut the chosen picked image gets; null when none is chosen or
  /// the image is square (nothing to pan).
  CoverCrop? get crop {
    final preview = chosenPicked?.preview;
    return preview == null
        ? null
        : cropFor(offset, preview.width, preview.height);
  }

  /// The chosen image can be panned.
  bool get panPossible => crop != null;

  /// The choice differs from the one the dialog opened with, and nothing is
  /// running: the Save / Choose button is enabled.
  bool get changed {
    final open = opening;
    if (open == null || selectedId == null || reading || saving) return false;
    if (selectedId != open.rowId) return true;
    if (selectedId != CoverRowIds.picked) return false;
    return picked?.image != open.image || offset != open.offset;
  }

  CoverDialogState copyWith({
    AsyncValue<CoverDialogOptions>? options,
    Object? selectedId = _keep,
    Object? picked = _keep,
    double? offset,
    bool? saving,
    Object? error = _keep,
    CoverOpening? opening,
  }) => CoverDialogState(
    options: options ?? this.options,
    selectedId: identical(selectedId, _keep)
        ? this.selectedId
        : selectedId as String?,
    picked: identical(picked, _keep) ? this.picked : picked as CoverPicked?,
    offset: offset ?? this.offset,
    saving: saving ?? this.saving,
    error: identical(error, _keep) ? this.error : error as CoverDialogError?,
    opening: opening ?? this.opening,
  );
}
