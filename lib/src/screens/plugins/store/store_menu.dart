import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart'
    show ScaffoldMessenger, ScaffoldMessengerState;

import '../../../../l10n/gen/app_localizations.dart';
import '../../../platform/state/file_manager_provider.dart';
import '../../../plugins/state/plugin_logs_provider.dart';
import '../plugin_paths.dart';
import 'store_actions.dart';

/// Opens the ⋮ menu of the store: the two install flows, the repositories,
/// refresh, and the plugin logs: on desktop "Mở thư mục nhật ký", on the phone
/// the share entry, dimmed "Sắp có" until the share sheet exists.
Future<void> showStoreMenu(
  BuildContext context, {
  required StoreActions actions,
  required int repoCount,
  required VoidCallback onRefreshAll,
  required bool viaKeyboard,
}) {
  final l10n = AppLocalizations.of(context);
  final desktop = FormFactor.of(context) == FormFactor.desktop;
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
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
            onTap: desktop
                ? () => unawaited(_openLogFolder(container, messenger, l10n))
                : null,
            soonLabel: desktop ? null : l10n.appComingSoon,
          ),
        ],
      ],
    ),
  );
}

/// Shows the folder of the plugin logs in the file manager; says so when it
/// cannot.
Future<void> _openLogFolder(
  ProviderContainer container,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
) async {
  final folder = container.read(pluginLogFolderProvider);
  final result = await container.read(fileManagerProvider).reveal(folder.path);
  if (!result.isOk) showAppSnackBarOn(messenger, l10n.pluginsLogsOpenFailed);
}
