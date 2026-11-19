import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/covers/cover_draft.dart';
import '../../state/covers/cover_texts.dart';
import '../../state/custom_cover_providers.dart';
import 'cover_dialog.dart';

/// Opens the "Ảnh bìa" dialog for the item [itemKey] of [kind] in save mode:
/// Lưu changes the cover everywhere and shows an undo snack bar.
Future<void> pickCustomCover(
  BuildContext context,
  CustomCoverKind kind,
  String itemKey,
) async {
  await _open(context, kind, itemKey, formMode: false, draft: null);
}

/// Opens the dialog in form mode (Sửa playlist): Chọn returns the
/// [CoverDraft] and writes nothing; null when cancelled or unchanged. The
/// caller owns the draft's temp files from then on. Pass the earlier [draft]
/// to reopen on it.
Future<CoverDraft?> pickCoverForForm(
  BuildContext context,
  CustomCoverKind kind,
  String itemKey, {
  CoverDraft? draft,
}) => _open(context, kind, itemKey, formMode: true, draft: draft);

Future<CoverDraft?> _open(
  BuildContext context,
  CustomCoverKind kind,
  String itemKey, {
  required bool formMode,
  required CoverDraft? draft,
}) {
  // Taken now: the dialog and its save job outlive this context.
  final messenger = ScaffoldMessenger.of(context);
  final texts = CoverTexts.of(AppLocalizations.of(context));
  Widget dialog({required bool fixedHeight}) => CoverDialog(
    kind: kind,
    itemKey: itemKey,
    messenger: messenger,
    texts: texts,
    fixedHeight: fixedHeight,
    formMode: formMode,
    draft: draft,
  );
  if (FormFactor.of(context) == FormFactor.mobile) {
    return showKSheet<CoverDraft?>(
      context,
      fixedHeight: true,
      maxHeightFraction: 0.94,
      useRootNavigator: true,
      builder: (_) => dialog(fixedHeight: true),
    );
  }
  return showKDialog<CoverDraft?>(
    context,
    maxWidth: KLayout.dialogWide,
    // Height: at most 760 and, through the Dialog's own inset, the window's
    // height less 48 (reading the window here is only allowed in kanaru_ui).
    builder: (context) => Dialog(
      // No side inset: the 620 dp width is the dialog's own (the desktop
      // shell is at least 1200 dp wide).
      insetPadding: const EdgeInsets.symmetric(vertical: KSpace.x6),
      shape: KShape.of(KRadius.xl, continuous: true),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          // Fixed width: the content has no natural width of its own.
          minWidth: KLayout.dialogWide,
          maxWidth: KLayout.dialogWide,
          maxHeight: 760,
        ),
        child: dialog(fixedHeight: false),
      ),
    ),
  );
}
