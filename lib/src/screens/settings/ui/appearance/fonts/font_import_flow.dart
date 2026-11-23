import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../l10n/gen/app_localizations.dart';
import '../../../../../foundation/result.dart';
import '../../../../../fonts/domain/app_font.dart';
import '../../../../../fonts/domain/custom_font.dart';
import '../../../../../fonts/domain/font_label.dart';
import '../../../../../fonts/state/custom_fonts.dart';
import '../../../../../platform/domain/document_picker.dart';
import '../../../../../platform/state/document_picker_provider.dart';

final _log = Logger('font_import_flow');

/// "Import font": the consent dialog, then the system file dialog, then the
/// import. Tells the user how it went; the font is not applied. Everything
/// the flow needs after an await is taken before it, because the page may be
/// gone by then.
Future<void> importCustomFont(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final picker = ref.read(documentPickerProvider);
  final fonts = ref.read(customFontsProvider.notifier);
  final filter = customFontDocumentFilter(
    label: l10n.fontsImportFileTypes,
    withMimeTypes: defaultTargetPlatform == TargetPlatform.android,
  );

  final agreed = await confirmAction(
    context,
    title: l10n.fontsImportTitle,
    message: l10n.fontsImportBody,
    confirmLabel: l10n.fontsImportPick,
  );
  if (!agreed) return;

  final PickedDocument? doc;
  try {
    doc = await picker.openDocument(filter);
  } on DocumentPickerException catch (e) {
    _log.warning('Font picker failed', e);
    showAppSnackBarOn(messenger, l10n.fontsImportInvalid);
    return;
  }
  if (doc == null) return;
  if (!filter.matchesName(doc.name)) {
    showAppSnackBarOn(messenger, l10n.fontsImportInvalid);
    return;
  }

  final read = await picker.read(doc, maxBytes: maxCustomFontBytes);
  final Uint8List bytes;
  switch (read) {
    case Ok(:final value):
      bytes = value;
    case Err(:final error):
      showAppSnackBarOn(
        messenger,
        error == DocumentError.tooLarge
            ? l10n.fontsImportTooLarge
            : l10n.fontsImportInvalid,
      );
      return;
  }

  try {
    final font = await fonts.importFromBytes(doc.name, bytes);
    showAppSnackBarOn(messenger, l10n.fontsImported(font.label));
  } on CustomFontException catch (e) {
    _log.info('Import of "${doc.name}" refused: $e');
    showAppSnackBarOn(
      messenger,
      e.error == CustomFontError.tooLarge
          ? l10n.fontsImportTooLarge
          : l10n.fontsImportInvalid,
    );
  }
}

/// Asks, then deletes the imported [font]. The row of the font in use has no
/// delete button, and the notifier refuses it as well.
Future<void> deleteCustomFont(
  BuildContext context,
  WidgetRef ref,
  CustomFont font,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final fonts = ref.read(customFontsProvider.notifier);
  final confirmed = await confirmAction(
    context,
    title: l10n.fontsRemoveTitle(font.label),
    message: l10n.fontsRemoveBody,
    confirmLabel: l10n.fontsRemoveConfirm,
    destructive: true,
  );
  if (!confirmed) return;
  try {
    await fonts.delete(font.id);
  } on StateError catch (e) {
    _log.warning('Delete of "${font.id}" refused: $e');
    return;
  } on FontDeleteException catch (e) {
    _log.warning('Delete of "${font.id}" failed: $e');
    return;
  }
  showAppSnackBarOn(messenger, l10n.fontsRemoved);
}
