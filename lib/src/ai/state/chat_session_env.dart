import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../plugins/data/store/plugin_row_types.dart';
import '../../plugins/domain/package/plugin_kind.dart';
import '../../plugins/state/plugin_run_provider.dart';
import '../../plugins/state/plugin_store_providers.dart';
import '../domain/conversation/ai_conversation.dart';
import '../domain/loop/loop_ports.dart';
import '../domain/output/chat_readiness.dart';
import '../domain/settings/chat_plugin_choice.dart';
import '../domain/settings/tool_groups.dart';
import '../domain/tools/ai_tool_registry.dart';
import '../domain/tools/tool_env.dart';
import 'ai_settings_providers.dart';
import 'chat_providers.dart';
import 'tool_env_provider.dart';

/// The tool ports with the session's own values (the localized play-context
/// label). Built from the live app state at each call.
ToolEnv sessionToolEnv(Ref ref) => ref
    .read(toolEnvFactoryProvider)(ref)
    .copyWith(playContextLabel: ref.read(aiPlayContextLabelProvider));

/// [LoopEnvironment] on the app state. Every getter reads the providers when
/// it is called, so a provider that rebuilt meanwhile (a settings change, a
/// plugin update) is seen and no stale value is kept.
class SessionEnvironment implements LoopEnvironment {
  SessionEnvironment(this._ref);

  final Ref _ref;

  @override
  AiToolRegistry get registry => _ref.read(aiToolRegistryProvider);

  @override
  ToolEnv get toolEnv => sessionToolEnv(_ref);

  @override
  Future<LoopSettings> settings() async {
    final enabled = {
      for (final g in AiToolGroup.values) g: _ref.read(aiToolGroupProvider(g)),
    };
    return LoopSettings(
      groupEnabled: (g) => enabled[g] ?? false,
      instructions: _ref.read(aiInstructionsProvider),
    );
  }

  /// The plugin of [conversation], or null when it is not installed, not
  /// the generation the chat was bound to, broken, or no model is chosen.
  /// The model is the chat's own, else the plugin settings' `model`.
  @override
  Future<LoopPlugin?> plugin(AiConversation conversation) async {
    final installId = conversation.installId;
    if (installId == null) return null;
    final rows = _ref.read(pluginRowsProvider);
    final row = await rows.liveById(installId);
    if (row == null || row.installedAt != conversation.installGeneration) {
      return null;
    }
    final spec = rows.manifestOf(row)?.chat;
    if (spec == null) return null;
    final config = await _ref
        .read(pluginConfigStoreProvider)
        .configForRun(installId);
    final configured = config['model'];
    final model = conversation.model?.trim().isNotEmpty == true
        ? conversation.model!
        : (configured is String && configured.trim().isNotEmpty
              ? configured
              : null);
    if (model == null) return null;
    return LoopPlugin(
      installId: installId,
      installGeneration: row.installedAt,
      version: row.version,
      model: model,
      capabilities: spec.capabilitiesOf(model),
      pausedUntil: _ref.read(pluginPausesProvider).until(installId),
    );
  }
}

/// Whether [conversation] can send through its plugin now, read from the
/// stored plugin row and settings (the send path; screens use
/// `chatReadinessProvider`).
Future<ChatReadiness> readChatReadiness(
  Ref ref,
  AiConversation conversation,
) async {
  final installId = conversation.installId;
  if (installId == null) return const ChatPluginRemoved();
  final rows = ref.read(pluginRowsProvider);
  final row = await rows.liveById(installId);
  final manifest = row == null ? null : rows.manifestOf(row);
  final stored = manifest == null
      ? const <String, Object?>{}
      : await ref.read(pluginConfigStoreProvider).configForRun(installId);
  return chatReadiness(
    manifest: manifest,
    storedConfig: stored,
    conversationModel: conversation.model,
    reinstalled:
        row != null && row.installedAt != conversation.installGeneration,
  );
}

/// The installed chat plugins, install order.
Future<List<PluginRow>> installedChatRows(Ref ref) async {
  final rows = await ref.read(installedPluginsProvider.future);
  return [
    for (final r in rows)
      if (r.pluginKind == PluginKind.aiChat) r,
  ];
}

/// The plugin a new chat uses: the last one used while installed, else the
/// first installed; null when none is installed.
Future<PluginRow?> defaultChatRow(Ref ref) async {
  final rows = await installedChatRows(ref);
  final id = resolveChatPlugin(
    stored: ref.read(aiLastPluginProvider),
    installedIds: [for (final r in rows) r.installId],
  );
  return rows.where((r) => r.installId == id).firstOrNull;
}

/// The `model` value of a plugin's own settings, null when it has none.
Future<String?> pluginDefaultModel(Ref ref, String installId) async {
  final config = await ref
      .read(pluginConfigStoreProvider)
      .configForRun(installId);
  final model = config['model'];
  return model is String && model.trim().isNotEmpty ? model : null;
}
