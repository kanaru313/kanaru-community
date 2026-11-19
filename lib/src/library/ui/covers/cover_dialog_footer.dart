import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/custom_cover_providers.dart';

/// Fixed footer on the shared `PickerFooter`: what the change applies to,
/// [Huỷ] and [Lưu] / [Chọn]. The confirm button is off until the choice
/// differs from the opening one (and while an image is read), and shows a
/// progress ring while saving.
class CoverDialogFooter extends StatelessWidget {
  const CoverDialogFooter({
    super.key,
    required this.kind,
    required this.formMode,
    required this.enabled,
    required this.saving,
    required this.onCancel,
    required this.onConfirm,
  });

  final CustomCoverKind kind;
  final bool formMode;
  final bool enabled;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = formMode ? l10n.coverChoose : l10n.coverSave;
    final scope = formMode
        ? l10n.coverScopeForm
        : switch (kind) {
            CustomCoverKind.album => l10n.coverScopeAlbum,
            CustomCoverKind.artist => l10n.coverScopeArtist,
            CustomCoverKind.playlist => l10n.coverScopePlaylist,
          };
    // The shared picker footer: scope note left, buttons right, one row.
    return PickerFooter(
      note: Text(scope),
      buttons: [
        TextButton(onPressed: onCancel, child: Text(l10n.coverCancel)),
        FilledButton(
          onPressed: enabled ? onConfirm : null,
          child: saving
              ? Semantics(
                  label: label,
                  child: const SizedBox.square(
                    dimension: KIconSize.sm,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Text(label),
        ),
      ],
    );
  }
}
