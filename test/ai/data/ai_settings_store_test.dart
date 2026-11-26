import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/ai_settings_store.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/domain/settings/builtin_templates.dart';
import 'package:kanaru/src/ai/domain/settings/chat_plugin_choice.dart';
import 'package:kanaru/src/ai/domain/settings/prompt_template.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/state/ai_settings_providers.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/plugin_page_provider.dart';

import '../../support/memory_settings_store.dart';

PluginRow _row(String id, {String kind = 'ai-chat', int? removedAt}) =>
    PluginRow(
      installId: id,
      kind: kind,
      name: id,
      version: 1,
      apiVersion: 1,
      manifestJson: '{}',
      packageSha256: 'a' * 64,
      origin: 'file',
      consentedHostsJson: '[]',
      installedAt: 1,
      updatedAt: 1,
      removedAt: removedAt,
    );

InstalledByKind _installed(List<PluginRow> rows) {
  final byKind = <PluginKind, List<InstalledEntry>>{};
  for (final r in rows) {
    byKind
        .putIfAbsent(PluginKind.fromWire(r.kind)!, () => [])
        .add(InstalledEntry(row: r, updating: false, missing: null));
  }
  return InstalledByKind(byKind, const []);
}

void main() {
  late MemorySettingsStore store;

  ProviderContainer container([
    AsyncValue<InstalledByKind> installed = const AsyncLoading(),
  ]) {
    final c = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        installedByKindProvider.overrideWithValue(installed),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => store = MemorySettingsStore());

  test('defaults per key', () {
    final c = container();
    expect(c.read(aiDefaultPermissionProvider), AiPermission.ask);
    expect(c.read(aiInstructionsProvider), '');
    expect(c.read(aiVarBypassProvider), isFalse);
    expect(c.read(aiAutoAskProvider), isTrue);
    expect(c.read(aiLastPluginProvider), isNull);
    expect(c.read(aiPromptsProvider), defaultPromptTemplates());
    expect(c.read(aiPromptsProvider), hasLength(6));
    expect(AiToolGroup.values, hasLength(11));
    for (final g in AiToolGroup.values) {
      expect(c.read(aiToolGroupProvider(g)), isTrue, reason: g.name);
    }
  });

  test('keys are the documented ones, one per setting', () {
    final keys = [
      aiDefaultPermissionSetting.key,
      aiInstructionsSetting.key,
      aiVarBypassSetting.key,
      aiAutoAskSetting.key,
      aiLastPluginSetting.key,
      aiPromptsSetting.key,
      for (final s in aiToolGroupSettings.values) s.key,
    ];
    expect(keys.toSet(), hasLength(keys.length));
    expect(aiDefaultPermissionSetting.key, 'ai.default_permission');
    expect(
      aiToolGroupSettings[AiToolGroup.nowPlaying]!.key,
      'ai.tools.now_playing',
    );
    expect(keys.every((k) => k.startsWith('ai.')), isTrue);
  });

  test(
    'stored values are read back and bad ones fall back to the default',
    () async {
      await store.write('ai.default_permission', 'auto');
      await store.write('ai.var_bypass', 'yes');
      await store.write('ai.tools.queue', false);
      final c = container();
      expect(c.read(aiDefaultPermissionProvider), AiPermission.auto);
      expect(c.read(aiVarBypassProvider), isFalse);
      expect(c.read(aiToolGroupProvider(AiToolGroup.queue)), isFalse);
      await store.write('ai.default_permission', 'root');
      expect(c.read(aiDefaultPermissionProvider), AiPermission.ask);
    },
  );

  test('instructions over 2000 chars refused', () async {
    final c = container();
    final ok = 'a' * 2000;
    await c.read(aiInstructionsProvider.notifier).set(ok);
    expect(store.read('ai.instructions'), ok);

    expect(() => aiInstructionsSetting.encode('a' * 2001), throwsArgumentError);
    await store.write('ai.instructions', 'a' * 2001);
    expect(container().read(aiInstructionsProvider), '');
  });

  test('template label over 40 or body over 2000 refused', () {
    expect(
      () => PromptTemplate(label: 'a' * 41, body: 'x').toJson(),
      throwsArgumentError,
    );
    expect(
      () => PromptTemplate(label: 'a', body: 'x' * 2001).toJson(),
      throwsArgumentError,
    );
    expect(
      () =>
          aiPromptsSetting.encode([PromptTemplate(label: 'a' * 41, body: 'x')]),
      throwsArgumentError,
    );
    expect(
      PromptTemplate(label: 'a' * 40, body: 'x' * 2000).toJson(),
      isA<Map<String, Object?>>(),
    );
    expect(
      () => PromptTemplate.fromJson({'label': 'a' * 41, 'body': 'x'}),
      throwsFormatException,
    );
    // A custom template without label and body, and an empty body, are not valid.
    expect(() => const PromptTemplate().validate(), throwsArgumentError);
    expect(
      () => const PromptTemplate(label: 'a', body: '  ').validate(),
      throwsArgumentError,
    );
  });

  test('removed last plugin falls back to the first installed', () async {
    expect(resolveChatPlugin(stored: 'gone', installedIds: ['a', 'b']), 'a');
    expect(resolveChatPlugin(stored: 'b', installedIds: ['a', 'b']), 'b');
    expect(resolveChatPlugin(stored: null, installedIds: ['a', 'b']), 'a');
    expect(resolveChatPlugin(stored: 'b', installedIds: []), isNull);

    await store.write('ai.last_plugin', 'b');
    final live = container(
      AsyncData(
        _installed([_row('a'), _row('b'), _row('t', kind: 'translate')]),
      ),
    );
    expect(live.read(aiChatPluginProvider).value, 'b');

    final removed = container(
      AsyncData(_installed([_row('a'), _row('b', removedAt: 5)])),
    );
    expect(removed.read(aiChatPluginProvider).value, 'a');

    // A plugin of another kind with the stored id is not a chat plugin.
    await store.write('ai.last_plugin', 't');
    final otherKind = container(
      AsyncData(_installed([_row('a'), _row('t', kind: 'translate')])),
    );
    expect(otherKind.read(aiChatPluginProvider).value, 'a');

    final none = container(
      AsyncData(_installed([_row('t', kind: 'translate')])),
    );
    expect(none.read(aiChatPluginProvider).value, isNull);
  });

  test('the chat plugin is loading while the installed list loads', () {
    expect(container().read(aiChatPluginProvider).isLoading, isTrue);
  });

  test('writing one key does not reset another', () async {
    final c = container();
    await c.read(aiInstructionsProvider.notifier).set('Trả lời ngắn');
    await c
        .read(aiDefaultPermissionProvider.notifier)
        .set(AiPermission.readOnly);
    await c.read(aiToolGroupProvider(AiToolGroup.lyrics).notifier).set(false);
    await c.read(aiLastPluginProvider.notifier).set('p1');

    final fresh = container();
    expect(fresh.read(aiInstructionsProvider), 'Trả lời ngắn');
    expect(fresh.read(aiDefaultPermissionProvider), AiPermission.readOnly);
    expect(fresh.read(aiToolGroupProvider(AiToolGroup.lyrics)), isFalse);
    expect(fresh.read(aiToolGroupProvider(AiToolGroup.queue)), isTrue);
    expect(fresh.read(aiLastPluginProvider), 'p1');
    expect(fresh.read(aiPromptsProvider), defaultPromptTemplates());

    await c.read(aiLastPluginProvider.notifier).set(null);
    expect(store.read('ai.last_plugin'), isNull);
    expect(store.read('ai.instructions'), 'Trả lời ngắn');
  });

  test('one bad template keeps the others', () async {
    await store.write('ai.prompts', [
      {'key': BuiltinTemplateKeys.explainLyrics, 'enabled': false},
      {'label': 'a' * 41, 'body': 'x'},
      'junk',
      {'label': 'Của tôi', 'body': 'Nội dung', 'enabled': true},
    ]);
    final c = container();
    final list = c.read(aiPromptsProvider);
    expect(list, hasLength(4));
    expect(list[0].key, BuiltinTemplateKeys.explainLyrics);
    expect(list[0].enabled, isFalse);
    expect(list[1].isUnknown, isTrue);
    expect(list[2].isUnknown, isTrue);
    expect(list[3].label, 'Của tôi');

    // Writing the list back keeps the unreadable items as they were.
    await c.read(aiPromptsProvider.notifier).set(list);
    expect(store.read('ai.prompts'), [
      {
        'key': BuiltinTemplateKeys.explainLyrics,
        'enabled': false,
        'edited': false,
      },
      {'label': 'a' * 41, 'body': 'x'},
      'junk',
      {
        'label': 'Của tôi',
        'body': 'Nội dung',
        'enabled': true,
        'edited': false,
      },
    ]);
  });

  test('a prompts value that is not a list resets to the builtins', () async {
    await store.write('ai.prompts', 'oops');
    expect(container().read(aiPromptsProvider), defaultPromptTemplates());
  });
}
