import 'package:material_ui/material_ui.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';

class OnlinePage extends StatelessWidget {
  const OnlinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KEmptyPage(
      title: l10n.navOnline,
      icon: KIcons.online,
      message: l10n.emptyOnline,
    );
  }
}
