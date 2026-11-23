import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../settings/ui/soon_row.dart';

/// "Kết nối": one dimmed row for the request limits "Sắp có" (the runtime uses
/// fixed limits for now).
class ConnectionBlock extends StatelessWidget {
  const ConnectionBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SetupSection(
      title: Text(l10n.pluginsPageConnection),
      children: [
        SoonRow(icon: KIcons.bolt, title: Text(l10n.pluginsPageConnectionRow)),
      ],
    );
  }
}
