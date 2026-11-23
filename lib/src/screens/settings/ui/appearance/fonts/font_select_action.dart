import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../l10n/gen/app_localizations.dart';
import '../../../../../fonts/domain/app_font.dart';
import '../../../../../fonts/state/font_selector.dart';
import 'font_labels.dart';

/// Makes [font] the app font and tells the user how it went: "Font changed",
/// or an error when it cannot be loaded (the old font stays). A newer tap
/// while this one loads wins and this one stays silent.
Future<void> selectFont(
  BuildContext context,
  WidgetRef ref,
  AppFont font,
) async {
  // Taken before the await: the page may be gone when the font is loaded.
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final result = await ref.read(fontSelectorProvider).select(font);
  switch (result) {
    case FontSelectResult.applied:
      showAppSnackBarOn(messenger, l10n.fontsChanged);
    case FontSelectResult.failed:
      showAppSnackBarOn(messenger, l10n.fontsUseFailed(fontLabel(l10n, font)));
    case FontSelectResult.superseded:
      break;
  }
}
