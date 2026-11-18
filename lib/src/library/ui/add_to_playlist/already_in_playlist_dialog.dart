import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_models.dart';
import 'add_to_playlist_model.dart';

/// Asks what to do with songs the ticked playlists already hold. Shown as a
/// centred dialog on both shells (never a second sheet over the picker).
/// Resolves to the chosen policy (first option, skip, is preselected), or null
/// on Cancel, Esc, Back or a tap outside.
///
/// [affected] are the ticked playlists that hold some of the songs
/// (non-empty).
Future<DuplicatePolicy?> showAlreadyInPlaylistDialog(
  BuildContext context, {
  required List<AffectedPlaylist> affected,
}) {
  final l10n = AppLocalizations.of(context);
  assert(affected.isNotEmpty, 'nothing to ask about');
  final held = heldTotal(affected);
  final one = affected.length == 1;
  return showSelectionPicker<DuplicatePolicy>(
    context,
    title: Text(l10n.playlistAlreadyTitle),
    header: Padding(
      padding: const EdgeInsets.fromLTRB(KSpace.x4, 0, KSpace.x4, KSpace.x2),
      child: Text(
        one
            ? l10n.plAddAlreadyInOne(held, affected.single.name)
            : '${l10n.plAddAlreadyInMany(affected.length)} '
                  '${l10n.playlistAlreadyAppliesToAll}',
        // The header does not scroll: a very long name must not push the
        // options out of the dialog.
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    options: [
      SelectionOption(
        value: DuplicatePolicy.skipExisting,
        title: Text(l10n.playlistAlreadySkip),
        subtitle: Text(l10n.playlistAlreadySkipHint(held)),
      ),
      SelectionOption(
        value: DuplicatePolicy.moveToEnd,
        title: Text(l10n.playlistAlreadyMove),
        subtitle: Text(l10n.playlistAlreadyMoveHint),
      ),
      SelectionOption(
        value: DuplicatePolicy.addAll,
        title: Text(l10n.playlistAlreadyAll),
        subtitle: Text(l10n.playlistAlreadyAllHint(held)),
      ),
    ],
    selected: DuplicatePolicy.skipExisting,
    confirmLabel: l10n.playlistConfirm,
    cancelLabel: l10n.playlistCancel,
    presentation: SelectionPickerPresentation.dialog,
  );
}
