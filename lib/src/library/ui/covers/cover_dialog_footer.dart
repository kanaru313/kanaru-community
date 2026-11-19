import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/custom_cover_providers.dart';

/// Fixed footer: what the change applies to, [Huỷ] and [Lưu] / [Chọn]. The
/// confirm button is off until the choice differs from the opening one (and
/// while an image is read), and shows a progress ring while saving. At large
/// text the scope sits above the buttons.
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
    final scheme = Theme.of(context).colorScheme;
    final label = formMode ? l10n.coverChoose : l10n.coverSave;
    final scope = formMode
        ? l10n.coverScopeForm
        : switch (kind) {
            CustomCoverKind.album => l10n.coverScopeAlbum,
            CustomCoverKind.artist => l10n.coverScopeArtist,
            CustomCoverKind.playlist => l10n.coverScopePlaylist,
          };
    final scopeText = Text(
      scope,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: scheme.onSurfaceVariant),
    );
    final buttons = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: KSpace.x2,
      runSpacing: KSpace.x1,
      children: [
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
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpace.x4,
          KSpace.x2,
          KSpace.x4,
          KSpace.x2,
        ),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [scopeText, const KGap(KSpace.x1), buttons],
              )
            : Row(
                children: [
                  Expanded(child: scopeText),
                  const KGap(KSpace.x2),
                  Flexible(child: buttons),
                ],
              ),
      ),
    );
  }
}
