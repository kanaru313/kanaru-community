import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/output/chat_readiness.dart';
import '../../state/chat_providers.dart';
import '../../state/chat_session.dart';
import '../../state/chat_view/composer_view.dart';
import '../chat_host.dart';
import '../chat_links.dart';
import 'chat_plugin_icon.dart';

/// The state line under a plugin in the picker, from its readiness.
String pluginStatusText(AppLocalizations l10n, ChatPluginInfo plugin) =>
    switch (plugin.readiness) {
      ChatReady() =>
        plugin.spec.keyField == null
            ? l10n.aiChatPluginReady
            : l10n.aiChatPluginHasKey,
      ChatNeedsKey() => l10n.aiChatPluginNeedsKey,
      ChatNeedsModel() => l10n.aiChatPluginNeedsModel,
      ChatNeedsConfig() => l10n.aiChatPluginNeedsConfig,
      ChatPluginRemoved() || ChatPluginReinstalled() => '',
    };

/// Picks the AI plugin of the open chat (icon rows), applied from the next
/// message. The footer opens the plugin store.
Future<void> showPluginPicker(
  BuildContext context,
  WidgetRef ref, {
  GlobalKey? anchor,
}) async {
  final l10n = AppLocalizations.of(context);
  final plugins = ref.read(chatPluginsProvider).value ?? const [];
  final current = ref.read(composerViewProvider).plugin?.installId;
  final session = ref.read(chatSessionProvider.notifier);
  final host = ref.read(chatHostProvider);
  final chosen = await showSelectionPicker<String>(
    context,
    anchor: anchor,
    selected: current,
    header: Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x4,
        KSpace.x2,
        KSpace.x4,
        KSpace.x2,
      ),
      child: Text(l10n.aiChatPluginPickerCaption),
    ),
    options: [
      for (final p in plugins)
        SelectionOption<String>(
          value: p.installId,
          title: Text(p.name),
          subtitle: Text(pluginStatusText(l10n, p)),
          leading: ChatPluginIcon(installId: p.installId),
        ),
    ],
    footerAction: SelectionPickerAction(
      label: l10n.aiChatPluginPickerAdd,
      onPressed: (_) async {
        host.openSettings(aiPluginStoreLocation);
        return const SelectionActionResult.close();
      },
    ),
  );
  if (chosen != null && chosen != current) await session.switchPlugin(chosen);
}
