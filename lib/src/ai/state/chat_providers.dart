import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../../library/data/browse/song_ids_query.dart';
import '../../library/domain/browse/list_sort.dart';
import '../../library/domain/browse/sort_order.dart';
import '../../library/state/playlists/playlist_providers.dart';
import '../../library/state/track_search_provider.dart';

import '../../plugins/data/store/plugin_config_values.dart';
import '../../plugins/domain/config/config_field.dart';
import '../../plugins/domain/package/chat_spec.dart';
import '../../plugins/domain/package/plugin_kind.dart';
import '../../plugins/state/plugin_page_provider.dart';
import '../../plugins/state/plugin_store_providers.dart';
import '../data/chat_turn_runner.dart' show ChatStreamStatus;
import '../data/chip_scope_adapter.dart';
import '../domain/output/chat_readiness.dart';
import '../domain/tools/ai_tool_registry.dart';
import '../domain/tools/read_tools.dart';
import '../domain/tools/write_tools.dart';
import '../domain/variables/chip_resolver.dart';

/// The tools the assistant knows: the read tools and the write tools.
final aiToolRegistryProvider = Provider<AiToolRegistry>(
  (ref) => AiToolRegistry([readToolProvider, writeToolProvider]),
);

/// The text the player shows as the source of a queue the assistant started
/// ("AI assistant", localized). The chat screen sets it from its
/// localizations; until then the English default of `ToolEnv` applies.
class AiPlayContextLabel extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String label) => state = label;
}

final aiPlayContextLabelProvider =
    NotifierProvider<AiPlayContextLabel, String?>(AiPlayContextLabel.new);

/// What the running chat script says it is doing; null while it says nothing.
class ChatStreamStatusNotifier extends Notifier<ChatStreamStatus?> {
  @override
  ChatStreamStatus? build() => null;

  void set(ChatStreamStatus status) => state = status;

  void clear() => state = null;
}

final chatStreamStatusProvider =
    NotifierProvider<ChatStreamStatusNotifier, ChatStreamStatus?>(
      ChatStreamStatusNotifier.new,
    );

/// One model the user can pick for a chat: the plugin's `model` options and
/// the choices the user added, with what the model can do.
class ChatModelOption {
  const ChatModelOption({
    required this.id,
    required this.title,
    required this.capabilities,
    this.subtitle,
    this.isCustom = false,
  });

  final String id;
  final String title;
  final String? subtitle;
  final ChatCapabilities capabilities;

  /// Added by the user (not one of the plugin's own options).
  final bool isCustom;
}

/// An installed `ai-chat` plugin as the chat screens use it.
class ChatPluginInfo {
  const ChatPluginInfo({
    required this.installId,
    required this.installGeneration,
    required this.name,
    required this.version,
    required this.spec,
    required this.models,
    required this.defaultModel,
    required this.readiness,
  });

  final String installId;

  /// `installed_at` of the plugin row: a reinstall has another one.
  final int installGeneration;
  final String name;
  final int version;
  final ChatSpec spec;

  /// Model list: the `model` select's options plus the user's choices.
  final List<ChatModelOption> models;

  /// The `model` value of the plugin's own settings (seeds a new chat).
  final String? defaultModel;

  /// Readiness with the plugin's own model (a chat's model may differ).
  final ChatReadiness readiness;

  ChatModelOption? modelById(String id) {
    for (final m in models) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// The model options of [manifestConfig]'s `model` field.
List<ChatModelOption> chatModelOptions(
  List<ConfigField> manifestConfig,
  ChatSpec spec,
  PluginConfigData data,
) {
  final field = manifestConfig.where((f) => f.key == 'model').firstOrNull;
  if (field is! SelectField) return const [];
  final choices = data.choices['model'] ?? const <CustomChoice>[];
  final custom = {for (final c in choices) c.value};
  final effective = effectiveField(field, choices) as SelectField;
  return [
    for (final o in effective.options)
      ChatModelOption(
        id: o.value,
        title: o.title,
        subtitle: o.subtitle,
        capabilities: spec.capabilitiesOf(o.value),
        isCustom:
            custom.contains(o.value) &&
            !field.options.any((own) => own.value == o.value),
      ),
  ];
}

/// Installed chat plugins, install order, each with its model list and
/// readiness. Loading while any plugin's settings load; a plugin whose
/// manifest no longer parses is left out.
final chatPluginsProvider = Provider<AsyncValue<List<ChatPluginInfo>>>((ref) {
  final installed = ref.watch(installedByKindProvider);
  if (installed.hasError) {
    return AsyncError(installed.error!, installed.stackTrace!);
  }
  final entries = installed.value?.of(PluginKind.aiChat);
  if (entries == null) return const AsyncLoading();
  final rows = ref.watch(pluginRowsProvider);
  final out = <ChatPluginInfo>[];
  for (final entry in entries) {
    final row = entry.row;
    final manifest = rows.manifestOf(row);
    final spec = manifest?.chat;
    if (manifest == null || spec == null) continue;
    final config = ref.watch(pluginConfigProvider(row.installId));
    if (config.hasError) return AsyncError(config.error!, config.stackTrace!);
    final data = config.value;
    if (data == null) return const AsyncLoading();
    final stored = resolveRunConfig(manifest.config, data);
    final model = stored['model'];
    out.add(
      ChatPluginInfo(
        installId: row.installId,
        installGeneration: row.installedAt,
        name: row.name,
        version: row.version,
        spec: spec,
        models: chatModelOptions(manifest.config, spec, data),
        defaultModel: model is String && model.trim().isNotEmpty ? model : null,
        readiness: chatReadiness(
          manifest: manifest,
          storedConfig: stored,
          conversationModel: null,
        ),
      ),
    );
  }
  return AsyncData(out);
});

/// Reads for the context chips (album, artist, genre, language, playlist),
/// on the library's public APIs. It captures its dependencies, not `ref`, so
/// a rebuild leaves no closure that fails later.
final chipScopeProvider = Provider<ChipScopePort>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ChipScopeAdapter(
    scopeIds: (scope) async => [
      for (final id in await songIds(
        db,
        scope,
        SortOrder.by(SortCriterion.title),
        '',
      ))
        id.value,
    ],
    lookup: ref.watch(trackLookupProvider),
    playlists: ref.watch(playlistStoreProvider),
  );
});
