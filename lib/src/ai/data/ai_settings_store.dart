import '../../platform/domain/setting.dart';
import '../domain/permission.dart';
import '../domain/settings/builtin_templates.dart';
import '../domain/settings/prompt_template.dart';
import '../domain/settings/tool_groups.dart';

/// The settings keys of the AI chat. One [Setting] per key; the providers are
/// in `state/ai_settings_providers.dart`.
///
/// Every `decode` throws [FormatException] on a value it does not know (the
/// default is used then); every `encode` throws [ArgumentError] on a value
/// that breaks a limit, so nothing invalid is ever written.

/// `ai.default_permission`: the permission a new conversation starts with.
final Setting<AiPermission> aiDefaultPermissionSetting = Setting<AiPermission>(
  'ai.default_permission',
  AiPermission.ask,
  decode: AiPermission.parse,
  encode: (v) => v.wire,
);

/// `ai.instructions`: the user's standing instructions, at most
/// [instructionsMaxChars] characters.
final Setting<String> aiInstructionsSetting = Setting<String>(
  'ai.instructions',
  '',
  decode: (json) {
    if (json is! String) throw FormatException('not a string: $json');
    if (json.runes.length > instructionsMaxChars) {
      throw const FormatException('instructions too long');
    }
    return json;
  },
  encode: (v) {
    if (v.runes.length > instructionsMaxChars) {
      throw ArgumentError.value(
        v.length,
        'length',
        'over $instructionsMaxChars',
      );
    }
    return v;
  },
);

Setting<bool> _boolSetting(String key, bool defaultValue) => Setting<bool>(
  key,
  defaultValue,
  decode: (json) {
    if (json is bool) return json;
    throw FormatException('not a bool: $json');
  },
  encode: (v) => v,
);

/// `ai.tools.<group>`, one per privacy group; on by default.
final Map<AiToolGroup, Setting<bool>> aiToolGroupSettings = {
  for (final g in AiToolGroup.values) g: _boolSetting(g.fullKey, true),
};

/// `ai.var_bypass`: a prompt variable may fill from a source whose tool group
/// is off.
final Setting<bool> aiVarBypassSetting = _boolSetting('ai.var_bypass', false);

/// `ai.auto_ask`: ask for confirmation before switching a conversation (or the
/// default) to the automatic permission. The confirm dialog's "show again"
/// check turns it off.
final Setting<bool> aiAutoAskSetting = _boolSetting('ai.auto_ask', true);

/// `ai.last_plugin`: install id of the chat plugin used last; null = none
/// yet. Whether it is still installed is `aiChatPluginProvider`'s job.
final Setting<String?> aiLastPluginSetting = Setting<String?>(
  'ai.last_plugin',
  null,
  decode: (json) {
    if (json == null || json is String) return json as String?;
    throw FormatException('not a string: $json');
  },
  encode: (v) => v,
);

/// `ai.prompts`: the prompt templates, in display order. An item this app
/// cannot read stays in the list as an unknown template; only a stored value
/// that is not a list at all resets to the builtin list.
final Setting<List<PromptTemplate>> aiPromptsSetting =
    Setting<List<PromptTemplate>>(
      'ai.prompts',
      List.unmodifiable(defaultPromptTemplates()),
      decode: (json) {
        if (json is! List<Object?>) {
          throw FormatException('templates are not a list: $json');
        }
        return List.unmodifiable([
          for (final item in json) _decodeTemplate(item),
        ]);
      },
      encode: (v) => [for (final t in v) t.toJson()],
    );

PromptTemplate _decodeTemplate(Object? item) {
  try {
    return PromptTemplate.fromJson(item);
  } on FormatException {
    return PromptTemplate.unknown(item ?? const <String, Object?>{});
  }
}
