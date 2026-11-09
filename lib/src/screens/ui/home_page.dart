import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KEmptyPage(
      title: l10n.navHome,
      icon: KIcons.home,
      message: l10n.emptyHome,
      headerActions: [
        // Desktop has Settings in the sidebar; mobile reaches it from here.
        if (FormFactor.of(context) == FormFactor.mobile)
          IconButton(
            icon: const Icon(KIcons.settings),
            tooltip: l10n.navSettings,
            onPressed: () => context.push('/settings'),
          ),
      ],
    );
  }
}
