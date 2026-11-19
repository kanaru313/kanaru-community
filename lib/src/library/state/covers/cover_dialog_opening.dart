import 'cover_dialog_options.dart';
import 'cover_dialog_state.dart';
import 'cover_draft.dart';

/// Chooses the opening row once the options of [s] are known: the [draft]'s
/// row when it still exists, else the item's custom cover, else automatic.
/// The row chosen becomes the state the dialog measures `changed` against.
CoverDialogState openCoverDialog(CoverDialogState s, CoverDraft? draft) {
  final options = s.options.requireValue;
  final draftRow = draft?.rowId;
  final exists =
      draftRow == CoverRowIds.automatic ||
      (draftRow == CoverRowIds.picked && s.picked != null) ||
      options.suggestions.any((x) => x.rowId == draftRow);
  final row = exists
      ? draftRow!
      : (options.current != null ? CoverRowIds.current : CoverRowIds.automatic);
  return s.copyWith(
    selectedId: row,
    opening: (
      rowId: row,
      image: row == CoverRowIds.picked ? s.picked?.image : null,
      offset: s.offset,
    ),
  );
}
