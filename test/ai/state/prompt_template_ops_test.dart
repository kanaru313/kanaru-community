import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/settings/builtin_templates.dart';
import 'package:kanaru/src/ai/domain/settings/prompt_template.dart';
import 'package:kanaru/src/ai/state/ai_settings_providers.dart';
import 'package:kanaru/src/ai/state/prompt_template_ops.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import '../../support/memory_settings_store.dart';

List<String?> _keys(List<PromptTemplate> l) => [for (final t in l) t.key];

void main() {
  late MemorySettingsStore store;
  late ProviderContainer c;

  ProviderContainer make() {
    final container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    store = MemorySettingsStore();
    c = make();
  });

  PromptTemplateOps ops() => c.read(promptTemplateOpsProvider);
  List<PromptTemplate> list() => c.read(aiPromptsProvider);

  test('restore re-adds only deleted builtins', () async {
    await ops().delete(1);
    await ops().delete(3);
    await ops().add(label: 'Mine', body: 'Do it');
    expect(list(), hasLength(5));

    await ops().restoreDefaults();
    final keys = _keys(list());
    expect(
      keys.where((k) => k != null).toSet(),
      BuiltinTemplateKeys.all.toSet(),
    );
    expect(keys, hasLength(7));
    // Present items keep their place; the two missing ones come at the end in
    // default order.
    expect(keys.sublist(0, 5), [
      BuiltinTemplateKeys.explainLyrics,
      BuiltinTemplateKeys.moodPlaylist,
      BuiltinTemplateKeys.songStory,
      BuiltinTemplateKeys.tasteSummary,
      null,
    ]);
    expect(keys.sublist(5), [
      BuiltinTemplateKeys.similarSongs,
      BuiltinTemplateKeys.translateLyrics,
    ]);

    // Nothing missing: nothing is written.
    final before = store.read('ai.prompts');
    await ops().restoreDefaults();
    expect(store.read('ai.prompts'), before);
  });

  test('edited builtin is not overwritten by restore', () async {
    await ops().edit(0, label: 'Giải nghĩa', body: 'Giải nghĩa lời bài này');
    await ops().toggle(2, enabled: false);
    await ops().restoreDefaults();
    expect(list(), hasLength(6));
    expect(list()[0].label, 'Giải nghĩa');
    expect(list()[0].edited, isTrue);
    expect(list()[0].key, BuiltinTemplateKeys.explainLyrics);
    expect(list()[2].enabled, isFalse);
  });

  test('reorder persists', () async {
    await ops().reorder(
      0,
      3,
    ); // down: index before removal, as the list reports it
    expect(_keys(list()).take(3), [
      BuiltinTemplateKeys.similarSongs,
      BuiltinTemplateKeys.moodPlaylist,
      BuiltinTemplateKeys.explainLyrics,
    ]);
    await ops().reorder(5, 0); // up
    expect(list().first.key, BuiltinTemplateKeys.tasteSummary);

    final reopened = make();
    expect(_keys(reopened.read(aiPromptsProvider)), _keys(list()));
  });

  test('delete then restore re-adds the builtin', () async {
    await ops().delete(0);
    expect(
      list().any((t) => t.key == BuiltinTemplateKeys.explainLyrics),
      isFalse,
    );
    await ops().restoreDefaults();
    final back = list().last;
    expect(back.key, BuiltinTemplateKeys.explainLyrics);
    expect(back.edited, isFalse);
    expect(back.enabled, isTrue);
  });

  test('an invalid add or edit throws and writes nothing', () async {
    final before = store.read('ai.prompts');
    await expectLater(ops().add(label: '', body: 'x'), throwsArgumentError);
    await expectLater(
      ops().add(label: 'a' * 41, body: 'x'),
      throwsArgumentError,
    );
    await expectLater(
      ops().edit(0, label: 'ok', body: 'x' * 2001),
      throwsArgumentError,
    );
    await expectLater(ops().delete(99), throwsRangeError);
    await expectLater(ops().reorder(0, 99), throwsRangeError);
    expect(store.read('ai.prompts'), before);
    expect(list(), defaultPromptTemplates());
  });

  test('an unreadable item can be moved and deleted but not edited', () async {
    await store.write('ai.prompts', [
      'junk',
      {'key': BuiltinTemplateKeys.songStory},
    ]);
    c = make();
    await expectLater(
      ops().edit(0, label: 'a', body: 'b'),
      throwsArgumentError,
    );
    await expectLater(ops().toggle(0, enabled: false), throwsArgumentError);
    await ops().reorder(0, 2);
    expect(list().last.isUnknown, isTrue);
    await ops().delete(1);
    expect(_keys(list()), [BuiltinTemplateKeys.songStory]);
  });

  test('toggle changes only the enabled flag', () async {
    await ops().toggle(1, enabled: false);
    expect(list()[1].enabled, isFalse);
    expect(list()[1].edited, isFalse);
    expect(list()[0].enabled, isTrue);
  });
}
