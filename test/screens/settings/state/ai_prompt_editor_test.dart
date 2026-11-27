import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/settings/builtin_templates.dart';
import 'package:kanaru/src/ai/domain/settings/prompt_template.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/variables/variable_catalog.dart';
import 'package:kanaru/src/ai/state/ai_settings_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/screens/settings/state/ai_prompt_editor.dart';
import 'package:kanaru/src/screens/settings/state/ai_prompt_editor_guard.dart';
import 'package:kanaru/src/screens/settings/state/ai_prompt_preview.dart';

import '../../../support/memory_settings_store.dart';

ProviderContainer _container(List<PromptTemplate> list) {
  final store = MemorySettingsStore();
  store.write('ai.prompts', [for (final t in list) t.toJson()]);
  final c = ProviderContainer(
    overrides: [settingsStoreProvider.overrideWithValue(store)],
  );
  addTearDown(c.dispose);
  return c;
}

const _custom = PromptEditorTarget(index: 0, label: 'Mine', body: 'Play it');

void main() {
  test('invalid variable blocks save', () async {
    final c = _container([
      const PromptTemplate(label: 'Mine', body: 'Play it'),
    ]);
    final sub = c.listen(promptEditorProvider(_custom), (_, _) {});
    addTearDown(sub.close);
    final editor = c.read(promptEditorProvider(_custom).notifier);

    editor.setBody('Is it {{weather}} now?');
    final analysis = c.read(promptEditorAnalysisProvider(_custom));
    expect(analysis.invalidAsSaved, isTrue);
    expect(c.read(promptEditorProvider(_custom)).canSave(analysis), isFalse);
    expect(await editor.save(), isFalse);
    // Nothing was written.
    expect(c.read(aiPromptsProvider).single.body, 'Play it');
  });

  test('empty label or body blocks save', () async {
    final c = _container([
      const PromptTemplate(label: 'Mine', body: 'Play it'),
    ]);
    final sub = c.listen(promptEditorProvider(_custom), (_, _) {});
    addTearDown(sub.close);
    final editor = c.read(promptEditorProvider(_custom).notifier);

    editor.setLabel('   ');
    expect(await editor.save(), isFalse);
    editor.setLabel('Mine');
    editor.setBody('');
    expect(await editor.save(), isFalse);
  });

  test('disabled-group variable warns but saves', () async {
    final c = _container([
      const PromptTemplate(label: 'Mine', body: 'Play it'),
    ]);
    await c.read(aiToolGroupProvider(AiToolGroup.lyrics).notifier).set(false);
    final sub = c.listen(promptEditorProvider(_custom), (_, _) {});
    addTearDown(sub.close);
    final editor = c.read(promptEditorProvider(_custom).notifier);

    editor.setBody('Explain {{lyrics}}');
    final analysis = c.read(promptEditorAnalysisProvider(_custom));
    expect(analysis.invalidAsSaved, isFalse);
    expect(analysis.groupOff.map((s) => s.variable), [AiVariable.lyrics]);
    expect(c.read(promptEditorProvider(_custom)).canSave(analysis), isTrue);
    expect(await editor.save(), isTrue);
    expect(c.read(aiPromptsProvider).single.body, 'Explain {{lyrics}}');
  });

  test('preview fills sample values', () {
    final c = _container(const []);
    const target = PromptEditorTarget();
    final sub = c.listen(promptEditorProvider(target), (_, _) {});
    addTearDown(sub.close);
    c
        .read(promptEditorProvider(target).notifier)
        .setBody('Hi {{title}} {{input}} {{x}} {{queue}}!');
    final analysis = c.read(promptEditorAnalysisProvider(target));
    final segments = buildPreview(
      c.read(promptEditorProvider(target)).body,
      analysis,
      (v) => '<${v.name}>',
    );
    expect(
      [for (final s in segments) (s.kind, s.text)],
      [
        (PreviewKind.text, 'Hi '),
        (PreviewKind.value, '<title>'),
        (PreviewKind.text, ' '),
        (PreviewKind.input, '<input>'),
        (PreviewKind.text, ' '),
        (PreviewKind.unknown, '{{x}}'),
        (PreviewKind.text, ' '),
        (PreviewKind.value, '<queue>'),
        (PreviewKind.text, '!'),
      ],
    );
  });

  test('preview marks a variable of a switched-off group', () async {
    final c = _container(const []);
    await c.read(aiToolGroupProvider(AiToolGroup.queue).notifier).set(false);
    const target = PromptEditorTarget();
    final sub = c.listen(promptEditorProvider(target), (_, _) {});
    addTearDown(sub.close);
    c.read(promptEditorProvider(target).notifier).setBody('{{queue}}');
    final segments = buildPreview(
      '{{queue}}',
      c.read(promptEditorAnalysisProvider(target)),
      (v) => 'sample',
    );
    expect(segments.single.kind, PreviewKind.off);
    expect(segments.single.text, 'sample');
  });

  test('editing a builtin marks it edited', () async {
    final c = _container([
      for (final k in BuiltinTemplateKeys.all) PromptTemplate(key: k),
    ]);
    const target = PromptEditorTarget(
      index: 1,
      key: BuiltinTemplateKeys.similarSongs,
      label: 'Similar',
      body: 'Find songs like {{now_playing}}',
    );
    final sub = c.listen(promptEditorProvider(target), (_, _) {});
    addTearDown(sub.close);
    final editor = c.read(promptEditorProvider(target).notifier);

    // Opened and saved without a change: nothing is written.
    expect(c.read(promptEditorProvider(target)).dirty, isFalse);
    expect(await editor.save(), isTrue);
    expect(c.read(aiPromptsProvider)[1].edited, isFalse);

    editor.setBody('Find songs like {{now_playing}}, but older');
    expect(c.read(promptEditorProvider(target)).dirty, isTrue);
    expect(await editor.save(), isTrue);
    final saved = c.read(aiPromptsProvider)[1];
    expect(saved.edited, isTrue);
    expect(saved.key, BuiltinTemplateKeys.similarSongs);
    expect(saved.body, 'Find songs like {{now_playing}}, but older');
    expect(saved.label, 'Similar');
  });

  test('a whitespace-only change to a builtin is not an edit', () async {
    final c = _container([
      for (final k in BuiltinTemplateKeys.all) PromptTemplate(key: k),
    ]);
    const target = PromptEditorTarget(
      index: 0,
      key: BuiltinTemplateKeys.explainLyrics,
      label: 'Explain',
      body: 'Explain {{lyrics}}',
    );
    final sub = c.listen(promptEditorProvider(target), (_, _) {});
    addTearDown(sub.close);
    final editor = c.read(promptEditorProvider(target).notifier);
    editor.setBody('Explain {{lyrics}}  ');
    expect(await editor.save(), isTrue);
    expect(c.read(aiPromptsProvider)[0].edited, isFalse);
  });

  test('a new prompt is added at the end, on', () async {
    final c = _container([const PromptTemplate(label: 'A', body: 'a')]);
    const target = PromptEditorTarget();
    final sub = c.listen(promptEditorProvider(target), (_, _) {});
    addTearDown(sub.close);
    final editor = c.read(promptEditorProvider(target).notifier);
    editor
      ..setLabel(' New ')
      ..setBody('Hello');
    expect(await editor.save(), isTrue);
    final list = c.read(aiPromptsProvider);
    expect(list, hasLength(2));
    expect(list.last.label, 'New');
    expect(list.last.enabled, isTrue);
  });

  test('delete removes the prompt and a builtin can come back', () async {
    final c = _container([
      for (final k in BuiltinTemplateKeys.all) PromptTemplate(key: k),
    ]);
    const target = PromptEditorTarget(
      index: 0,
      key: BuiltinTemplateKeys.explainLyrics,
      label: 'Explain',
      body: 'x',
    );
    final sub = c.listen(promptEditorProvider(target), (_, _) {});
    addTearDown(sub.close);
    expect(
      await c.read(promptEditorProvider(target).notifier).delete(),
      isTrue,
    );
    expect(
      c.read(aiPromptsProvider).map((t) => t.key),
      isNot(contains(BuiltinTemplateKeys.explainLyrics)),
    );
  });

  test('save and delete refuse when the list moved under the editor', () async {
    final c = _container([
      const PromptTemplate(label: 'A', body: 'a'),
      const PromptTemplate(label: 'B', body: 'b'),
    ]);
    const target = PromptEditorTarget(index: 5, label: 'Z', body: 'z');
    final sub = c.listen(promptEditorProvider(target), (_, _) {});
    addTearDown(sub.close);
    final editor = c.read(promptEditorProvider(target).notifier);
    editor.setBody('zz');
    expect(await editor.save(), isFalse);
    expect(await editor.delete(), isFalse);
    expect(c.read(aiPromptsProvider), hasLength(2));
  });

  test('the guard asks only while a page is attached', () async {
    final guard = PromptEditorGuard();
    expect(await guard.mayLeave(), isTrue);
    Future<bool> no() async => false;
    guard.attach(no);
    expect(await guard.mayLeave(), isFalse);
    guard.detach(() async => true); // another page's callback: ignored
    expect(await guard.mayLeave(), isFalse);
    guard.detach(no);
    expect(await guard.mayLeave(), isTrue);
  });
}
