import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/settings/builtin_templates.dart';
import 'package:kanaru/src/ai/domain/settings/prompt_template.dart';
import 'package:kanaru/src/ai/state/prompt_template_ops.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../support/memory_settings_store.dart';
import 'ai_settings_host.dart';

/// Records the call instead of editing the list.
class _FakeOps extends PromptTemplateOps {
  _FakeOps() : super(read: () => const [], write: (_) async {});

  final calls = <String>[];

  @override
  Future<void> reorder(int oldIndex, int newIndex) async =>
      calls.add('reorder $oldIndex $newIndex');

  @override
  Future<void> toggle(int index, {required bool enabled}) async =>
      calls.add('toggle $index $enabled');

  @override
  Future<void> restoreDefaults() async => calls.add('restore');
}

MemorySettingsStore _storeWith(List<PromptTemplate> list) {
  final store = MemorySettingsStore();
  store.write('ai.prompts', [for (final t in list) t.toJson()]);
  return store;
}

ReorderableToggleList<int> _list(WidgetTester tester) =>
    tester.widget<ReorderableToggleList<int>>(
      find.byType(ReorderableToggleList<int>),
    );

void main() {
  testWidgets('shows the builtin prompts in order with their text', (
    tester,
  ) async {
    await openAiSettings(tester);
    final list = _list(tester);
    expect(list.items, hasLength(BuiltinTemplateKeys.all.length));
    expect(list.items.first.value, 0);
    expect(find.text('Prompt templates'), findsOneWidget);
  });

  testWidgets('reorder calls ops.reorder', (tester) async {
    final ops = _FakeOps();
    await openAiSettings(
      tester,
      overrides: [promptTemplateOpsProvider.overrideWithValue(ops)],
    );
    _list(tester).onReorder(0, 2);
    // Moving down: the list form is one past the row it goes after.
    _list(tester).onReorder(3, 1);
    expect(ops.calls, ['reorder 0 3', 'reorder 3 1']);
  });

  testWidgets('reorder maps shown rows to list indices past a hidden item', (
    tester,
  ) async {
    final ops = _FakeOps();
    final store = _storeWith([
      const PromptTemplate(label: 'A', body: 'a'),
      const PromptTemplate.unknown(<String, Object?>{'x': 1}),
      const PromptTemplate(label: 'B', body: 'b'),
    ]);
    await openAiSettings(
      tester,
      store: store,
      overrides: [promptTemplateOpsProvider.overrideWithValue(ops)],
    );
    expect(_list(tester).items.map((i) => i.value), [0, 2]);
    _list(tester).onReorder(0, 1);
    expect(ops.calls, ['reorder 0 3']);
  });

  testWidgets('toggle calls ops.toggle', (tester) async {
    final ops = _FakeOps();
    await openAiSettings(
      tester,
      overrides: [promptTemplateOpsProvider.overrideWithValue(ops)],
    );
    _list(tester).onToggle(1, false);
    expect(ops.calls, ['toggle 1 false']);
  });

  testWidgets('restore calls ops.restoreDefaults and shows the count', (
    tester,
  ) async {
    final ops = _FakeOps();
    final store = _storeWith([
      for (final k in BuiltinTemplateKeys.all.skip(2)) PromptTemplate(key: k),
    ]);
    await openAiSettings(
      tester,
      store: store,
      overrides: [promptTemplateOpsProvider.overrideWithValue(ops)],
    );
    await tester.tap(find.text('Restore default prompts'));
    await tester.pump();
    expect(ops.calls, ['restore']);
    expect(find.text('Added back 2 built-in prompts'), findsOneWidget);
  });

  testWidgets('restore with nothing deleted says so', (tester) async {
    final ops = _FakeOps();
    await openAiSettings(
      tester,
      overrides: [promptTemplateOpsProvider.overrideWithValue(ops)],
    );
    await tester.tap(find.text('Restore default prompts'));
    await tester.pump();
    expect(find.text('No built-in prompt was deleted'), findsOneWidget);
  });

  testWidgets('bad-variable row shows Biến lỗi', (tester) async {
    final store = _storeWith([
      const PromptTemplate(label: 'Weather', body: 'Is it {{weather}} now?'),
      const PromptTemplate(label: 'Fine', body: 'Play {{now_playing}}'),
    ]);
    await openAiSettings(tester, store: store);
    expect(find.text('Broken variable'), findsOneWidget);
    expect(
      find.text('Variable {{weather}} no longer exists · tap to edit'),
      findsOneWidget,
    );
    // The problem replaces the line.
    expect(find.text('Is it {{weather}} now?'), findsNothing);
    expect(find.text('Play {{now_playing}}'), findsOneWidget);
  });

  testWidgets('row tap shows Sắp có before the editor ships', (tester) async {
    await openAiSettings(tester);
    await tester.tap(find.text('Explain the lyrics'));
    await tester.pump();
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('Add prompt shows Sắp có', (tester) async {
    await openAiSettings(tester);
    await tester.tap(find.text('Add prompt'));
    await tester.pump();
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('empty list state', (tester) async {
    await openAiSettings(tester, store: _storeWith(const []));
    expect(find.byType(ReorderableToggleList<int>), findsNothing);
    expect(
      find.text(
        'No prompts yet: the chat input has no prompt chips. Add a prompt, or restore the built-in ones.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add prompt'), findsOneWidget);
    expect(find.text('Restore default prompts'), findsOneWidget);
  });
}
