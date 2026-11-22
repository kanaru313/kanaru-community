import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../plugin_paths.dart';
import 'store_actions.dart';

/// Opens the ⋮ menu of the store: the two install flows, the repositories,
/// refresh, and the plugin log entry (not built yet, dimmed).
Future<void> showStoreMenu(
  BuildContext context, {
  required StoreActions actions,
  required int repoCount,
  required VoidCallback onRefreshAll,
  required bool viaKeyboard,
}) {
  final l10n = AppLocalizations.of(context);
  final desktop = FormFactor.of(context) == FormFactor.desktop;
  return showKLayeredMenu(
    context,
    viaKeyboard: viaKeyboard,
    root: KMenuPage(
      groups: [
        [
          KMenuRow(
            title: l10n.pluginsMenuInstallFile,
            icon: KIcons.installFile,
            onTap: actions.onInstallFromFile == null
                ? null
                : () => actions.onInstallFromFile!(context),
            enabled: actions.onInstallFromFile != null,
          ),
          KMenuRow(
            title: l10n.pluginsMenuInstallLink,
            icon: KIcons.installLink,
            onTap: actions.onInstallFromLink == null
                ? null
                : () => actions.onInstallFromLink!(context),
            enabled: actions.onInstallFromLink != null,
          ),
        ],
        [
          KMenuRow(
            title: l10n.pluginsMenuRepositories(repoCount),
            icon: KIcons.repository,
            onTap: () => context.push(PluginPaths.repositories),
          ),
          KMenuRow(
            title: l10n.pluginsMenuRefreshAll,
            icon: KIcons.refresh,
            onTap: onRefreshAll,
            enabled: repoCount > 0,
          ),
        ],
        [
          KMenuRow(
            title: desktop
                ? l10n.pluginsMenuLogsDesktop
                : l10n.pluginsMenuLogsMobile,
            icon: KIcons.pluginLogs,
            soonLabel: l10n.appComingSoon,
          ),
        ],
      ],
    ),
  );
}
