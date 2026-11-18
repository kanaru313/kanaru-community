import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/custom_cover_providers.dart';

/// Lets the user pick a cover for the item [itemKey] of [kind]. Placeholder
/// until the cover dialog replaces the body: shows the coming-soon notice.
Future<void> pickCustomCover(
  BuildContext context,
  CustomCoverKind kind,
  String itemKey,
) async {
  showAppSnackBar(context, AppLocalizations.of(context).appComingSoon);
}
