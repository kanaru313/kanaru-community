import 'json_read.dart';

const chatMaxModels = 50;
const chatContextRange = (min: 1024, max: 10000000);
const chatDefaultContext = 32768;
const chatIdleTimeoutCapSec = 90;
const chatDefaultIdleTimeoutSec = 90;

final _modelId = RegExp(r'^[A-Za-z0-9._:/@-]{1,120}$');

/// What a chat model can do. Shared by the per-model overlay and the
/// fallback `custom` capabilities.
class ChatCapabilities {
  const ChatCapabilities({
    this.tools = false,
    this.vision = false,
    this.context = chatDefaultContext,
  });

  /// The model may be offered `tools[]`.
  final bool tools;

  /// The model accepts image parts.
  final bool vision;

  /// Context window in tokens.
  final int context;
}

/// Capability overlay of one model id (not the model list itself: that is the
/// `model` config field).
class ChatModelSpec extends ChatCapabilities {
  const ChatModelSpec({
    required this.id,
    required this.title,
    super.tools,
    super.vision,
    super.context,
  });

  final String id;

  /// Display title; the id when the manifest gives none.
  final String title;
}

/// The `chat` block of an `ai-chat` plugin's `plugin.json`.
class ChatSpec {
  const ChatSpec({
    this.models = const [],
    this.custom = const ChatCapabilities(),
    this.keyField,
    this.idleTimeoutSec = chatDefaultIdleTimeoutSec,
  });

  /// Capability overlays, unique by id.
  final List<ChatModelSpec> models;

  /// Capabilities of any model without an overlay entry.
  final ChatCapabilities custom;

  /// Key of the config field holding the API key(s); null when none. Checked
  /// against the config by `requireChatFields`.
  final String? keyField;

  /// Longest silence between emits before a run is cut, 1..90 s.
  final int idleTimeoutSec;

  /// Capabilities of [modelId]: its overlay, else [custom].
  ChatCapabilities capabilitiesOf(String modelId) {
    for (final model in models) {
      if (model.id == modelId) return model;
    }
    return custom;
  }
}

/// Parses the `chat` block; stops with `InvalidManifest('chat.<field>')`.
ChatSpec readChatSpec(Object? value) {
  final block = asObject(value);
  if (block == null) invalid('chat');
  final rawModels = block['models'];
  final models = <ChatModelSpec>[];
  if (rawModels != null) {
    if (rawModels is! List || rawModels.length > chatMaxModels) {
      invalid('chat.models');
    }
    final seen = <String>{};
    for (final item in rawModels) {
      final model = _readModel(item);
      if (!seen.add(model.id)) invalid('chat.models.id');
      models.add(model);
    }
  }
  final keyField = block['keyField'];
  if (keyField != null &&
      (keyField is! String || keyField.isEmpty)) {
    invalid('chat.keyField');
  }
  return ChatSpec(
    models: List.unmodifiable(models),
    custom: _readCustom(block['custom']),
    keyField: keyField as String?,
    idleTimeoutSec:
        readInt(
          block,
          'idleTimeoutSec',
          'chat',
          min: 1,
          max: chatIdleTimeoutCapSec,
        ) ??
        chatDefaultIdleTimeoutSec,
  );
}

ChatModelSpec _readModel(Object? item) {
  final raw = asObject(item);
  if (raw == null) invalid('chat.models');
  final id = raw['id'];
  if (id is! String || !_modelId.hasMatch(id)) invalid('chat.models.id');
  return ChatModelSpec(
    id: id,
    title: raw['title'] == null
        ? id
        : readText(raw['title'], 'chat.models.title', min: 1, max: 80),
    tools: readBool(raw, 'tools', 'chat.models'),
    vision: readBool(raw, 'vision', 'chat.models'),
    context: _readContext(raw, 'chat.models'),
  );
}

ChatCapabilities _readCustom(Object? value) {
  if (value == null) return const ChatCapabilities();
  final raw = asObject(value);
  if (raw == null) invalid('chat.custom');
  return ChatCapabilities(
    tools: readBool(raw, 'tools', 'chat.custom'),
    vision: readBool(raw, 'vision', 'chat.custom'),
    context: _readContext(raw, 'chat.custom'),
  );
}

int _readContext(JsonObject raw, String path) =>
    readInt(
      raw,
      'context',
      path,
      min: chatContextRange.min,
      max: chatContextRange.max,
    ) ??
    chatDefaultContext;
