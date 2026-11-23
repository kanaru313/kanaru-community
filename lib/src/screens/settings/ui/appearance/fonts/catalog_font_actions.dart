import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../l10n/gen/app_localizations.dart';
import '../../../../../fonts/domain/font_catalog.dart';
import '../../../../../fonts/state/font_downloads.dart';
import '../../../../../fonts/state/installed_catalog_fonts.dart';

/// Downloads [font] and tells the user how it went. The download goes on when
/// the page is closed, so the snack bar goes through a messenger taken before
/// the await. The font is not applied.
Future<void> downloadCatalogFont(
  BuildContext context,
  WidgetRef ref,
  CatalogFont font,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final result = await ref.read(fontDownloadsProvider.notifier).download(font);
  switch (result) {
    case FontDownloadResult.done:
      showAppSnackBarOn(messenger, l10n.fontsDownloaded);
    case FontDownloadResult.failed:
      showAppSnackBarOn(messenger, l10n.fontsDownloadFailed(font.label));
    case FontDownloadResult.ignored:
      break;
  }
}

/// Deletes the downloaded [font] at once (it can be downloaded again).
void deleteCatalogFont(BuildContext context, WidgetRef ref, CatalogFont font) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    ref.read(installedCatalogFontsProvider.notifier).delete(font.id);
  } on StateError {
    return; // in use or downloading: the row offers no delete anyway
  }
  showAppSnackBarOn(messenger, l10n.fontsDeleted);
}
