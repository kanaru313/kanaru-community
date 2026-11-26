import '../../../plugins/domain/config/config_field.dart';
import '../../../plugins/domain/package/plugin_manifest.dart';

/// Whether a conversation can send through its plugin right now.
sealed class ChatReadiness {
  const ChatReadiness();
}

final class ChatReady extends ChatReadiness {
  const ChatReady();
}

/// The key field (`chat.keyField`) has no value.
final class ChatNeedsKey extends ChatReadiness {
  const ChatNeedsKey();
}

/// Neither the conversation nor the plugin settings name a model.
final class ChatNeedsModel extends ChatReadiness {
  const ChatNeedsModel();
}

/// Other required settings are empty; [titles] are their form titles.
final class ChatNeedsConfig extends ChatReadiness {
  const ChatNeedsConfig(this.titles);

  final List<String> titles;
}

/// The conversation's plugin is not installed any more.
final class ChatPluginRemoved extends ChatReadiness {
  const ChatPluginRemoved();
}

/// The plugin was removed and installed again: another install generation.
final class ChatPluginReinstalled extends ChatReadiness {
  const ChatPluginReinstalled();
}

const _modelKey = 'model';

/// The one answer the composer, the settings page and the send path use.
///
/// [manifest] is null when the plugin row is gone. [storedConfig] holds what
/// a run would read (defaults merged in). [conversationModel] wins over the
/// plugin's own `model` value, so it satisfies a required `model` field.
/// [reinstalled] is true when the conversation's install generation differs
/// from the plugin row's. Order of checks: removed, reinstalled, key, model,
/// other required fields.
ChatReadiness chatReadiness({
  required PluginManifest? manifest,
  required Map<String, Object?> storedConfig,
  required String? conversationModel,
  bool reinstalled = false,
}) {
  if (manifest == null) return const ChatPluginRemoved();
  if (reinstalled) return const ChatPluginReinstalled();
  final keyField = manifest.chat?.keyField;
  if (keyField != null && _isEmpty(storedConfig[keyField])) {
    return const ChatNeedsKey();
  }
  final hasModel =
      !_isEmpty(conversationModel) || !_isEmpty(storedConfig[_modelKey]);
  if (!hasModel) return const ChatNeedsModel();
  final missing = [
    for (final field in manifest.config)
      if (field.required &&
          field is! ToggleField &&
          field.key != keyField &&
          field.key != _modelKey &&
          _isEmpty(storedConfig[field.key]))
        field.title,
  ];
  if (missing.isNotEmpty) return ChatNeedsConfig(missing);
  return const ChatReady();
}

bool _isEmpty(Object? value) => switch (value) {
  null => true,
  String s => s.trim().isEmpty,
  List<Object?> l => l.isEmpty,
  Map<Object?, Object?> m => m.isEmpty,
  _ => false,
};
