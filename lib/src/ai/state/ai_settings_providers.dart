import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/state/settings_providers.dart';
import '../../plugins/domain/package/plugin_kind.dart';
import '../../plugins/state/plugin_page_provider.dart';
import '../data/ai_settings_store.dart';
import '../domain/settings/chat_plugin_choice.dart';
import '../domain/settings/tool_groups.dart';

final aiDefaultPermissionProvider = settingNotifierProvider(
  aiDefaultPermissionSetting,
);
final aiInstructionsProvider = settingNotifierProvider(aiInstructionsSetting);
final aiVarBypassProvider = settingNotifierProvider(aiVarBypassSetting);
final aiAutoAskProvider = settingNotifierProvider(aiAutoAskSetting);
final aiLastPluginProvider = settingNotifierProvider(aiLastPluginSetting);
final aiPromptsProvider = settingNotifierProvider(aiPromptsSetting);

// One provider per key, built once: `settingNotifierProvider` makes a new
// provider on each call.
final Map<AiToolGroup, NotifierProvider<SettingNotifier<bool>, bool>>
_toolGroupProviders = {
  for (final g in AiToolGroup.values)
    g: settingNotifierProvider(aiToolGroupSettings[g]!),
};

/// Whether the tools of [group] are on (`ai.tools.<group>`).
NotifierProvider<SettingNotifier<bool>, bool> aiToolGroupProvider(
  AiToolGroup group,
) => _toolGroupProviders[group]!;

/// The chat plugin a new conversation uses: the last one used while it is
/// still installed, else the first installed chat plugin, else null. Loading
/// or failing while the installed list does (never data(null) for "unknown").
final aiChatPluginProvider = Provider<AsyncValue<String?>>((ref) {
  final stored = ref.watch(aiLastPluginProvider);
  return ref.watch(installedByKindProvider).whenData((installed) {
    return resolveChatPlugin(
      stored: stored,
      installedIds: [
        for (final e in installed.of(PluginKind.aiChat))
          if (e.row.removedAt == null) e.row.installId,
      ],
    );
  });
});
