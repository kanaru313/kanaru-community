import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/settings/builtin_templates.dart';
import 'package:kanaru/src/ai/state/ai_settings_providers.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/state/ai_prompt_editor_guard.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show TextField;

import '../../../support/icon_button_finders.dart';
import '../support/settings_host.dart' show SettingsHarness;
import 'ai_settings_host.dart';

Finder get _labelField => find.byType(TextField).first;
Finder get _bodyField => find.byType(TextField).at(1);

TextEditingController _controller(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!;

/// Lưu is enabled, read from its semantics.
bool _saveOn(WidgetTester tester) => isSemantics(
  isEnabled: true,
).matches(tester.getSemantics(find.widgetWithText(KModalButton, 'Save')), {});

Future<SettingsHarness> _open(
  WidgetTester tester,
  String location, {
  Size size = const Size(400, 4000),
}) => openAiSettings(tester, location: location, size: size);

/// Types into the label field so the editor holds unsaved edits.
Future<void> _makeDirty(WidgetTester tester) async {
  await tester.enterText(_labelField, 'Changed label');
  await tester.pump();
}

void main() {
  testWidgets('insert variable at cursor', (tester) async {
    await _open(tester, SettingsPaths.aiPromptNew);
    await tester.enterText(_bodyField, 'abcdef');
    await tester.pump();
    _controller(tester, _bodyField).selection = const TextSelection.collapsed(
      offset: 3,
    );
    await tester.tap(find.text('{{title}}'));
    await tester.pump();
    final c = _controller(tester, _bodyField);
    expect(c.text, 'abc{{title}}def');
    expect(c.selection, const TextSelection.collapsed(offset: 3 + 9));
  });

  testWidgets('an unknown variable shows the error line and dims Save', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, SettingsPaths.aiPromptNew);
    await tester.enterText(_labelField, 'Weather');
    await tester.enterText(_bodyField, 'Is it {{weather}} now?');
    await tester.pump();
    expect(
      find.textContaining('Variable {{weather}} does not exist'),
      findsOneWidget,
    );
    expect(_saveOn(tester), isFalse);
    await tester.enterText(_bodyField, 'Is it {{title}} now?');
    await tester.pump();
    expect(_saveOn(tester), isTrue);
    // Disposed inside the test: the end-of-test check runs before teardowns.
    handle.dispose();
  });

  testWidgets('the preview shows the sample value', (tester) async {
    await _open(tester, SettingsPaths.aiPromptNew);
    await tester.enterText(_bodyField, 'Tell me about {{title}}');
    await tester.pump();
    expect(find.textContaining('Tell me about Lạc trôi'), findsOneWidget);
  });

  testWidgets('save writes the prompt and leaves with a toast', (tester) async {
    final host = await _open(tester, SettingsPaths.aiPromptNew);
    await tester.enterText(_labelField, 'Mine');
    await tester.enterText(_bodyField, 'Play {{now_playing}}');
    await tester.pump();
    await tester.tap(find.widgetWithText(KModalButton, 'Save'));
    await tester.pumpAndSettle();
    final list = host.container.read(aiPromptsProvider);
    expect(list.last.label, 'Mine');
    expect(find.text('New prompt'), findsNothing);
    expect(find.text('Saved “Mine”'), findsOneWidget);
  });

  group('discard', () {
    testWidgets('discard asks from the header back arrow', (tester) async {
      await _open(tester, SettingsPaths.aiPrompt(0));
      await _makeDirty(tester);
      await tester.tap(byIconButton('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      // Keep editing: still here, text kept.
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Edit prompt'), findsOneWidget);
      expect(_controller(tester, _labelField).text, 'Changed label');

      // Discard: back on the AI page.
      await tester.tap(byIconButton('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Edit prompt'), findsNothing);
      expect(find.text('Prompt templates'), findsOneWidget);
    });

    testWidgets('Cancel asks too', (tester) async {
      await _open(tester, SettingsPaths.aiPrompt(0));
      await _makeDirty(tester);
      await tester.tap(find.widgetWithText(KModalButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('nothing edited leaves without asking', (tester) async {
      await _open(tester, SettingsPaths.aiPrompt(0));
      await tester.tap(byIconButton('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Edit prompt'), findsNothing);
    });

    testWidgets('discard asks on system back', (tester) async {
      await _open(tester, SettingsPaths.aiPrompt(0));
      await _makeDirty(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Edit prompt'), findsNothing);
    });

    testWidgets('discard asks on desktop Esc', (tester) async {
      await _open(
        tester,
        SettingsPaths.aiPrompt(0),
        size: const Size(1400, 4000),
      );
      await _makeDirty(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('discard asks on go to another branch', (tester) async {
      final host = await _open(tester, SettingsPaths.aiPrompt(0));
      await _makeDirty(tester);
      host.router.go('/');
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Edit prompt'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      // Discard continues to where the user was going.
      expect(find.text('Edit prompt'), findsNothing);
    });

    testWidgets('Keep editing on a router jump stays on the editor', (
      tester,
    ) async {
      final host = await _open(tester, SettingsPaths.aiPrompt(0));
      await _makeDirty(tester);
      host.router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Edit prompt'), findsOneWidget);
    });
  });

  testWidgets('delete from editor then restore re-adds the builtin', (
    tester,
  ) async {
    final host = await _open(tester, SettingsPaths.aiPrompt(0));
    // A builtin names the way back.
    expect(
      find.text(
        'Built-in prompt: “Restore default prompts” adds the original back',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete prompt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Edit prompt'), findsNothing);
    expect(
      host.container.read(aiPromptsProvider).map((t) => t.key),
      isNot(contains(BuiltinTemplateKeys.explainLyrics)),
    );

    await tester.tap(find.text('Restore default prompts'));
    await tester.pumpAndSettle();
    expect(
      host.container.read(aiPromptsProvider).last.key,
      BuiltinTemplateKeys.explainLyrics,
    );
  });

  testWidgets('a double tap on Save adds one prompt and pops once', (
    tester,
  ) async {
    final host = await _open(tester, SettingsPaths.aiPromptNew);
    final before = host.container.read(aiPromptsProvider).length;
    await tester.enterText(_labelField, 'Mine');
    await tester.enterText(_bodyField, 'Play {{now_playing}}');
    await tester.pump();
    final save = find.widgetWithText(KModalButton, 'Save');
    await tester.tap(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(host.container.read(aiPromptsProvider), hasLength(before + 1));
    // One pop: back on the AI page, not on the Settings root.
    expect(find.text('New prompt'), findsNothing);
    expect(find.text('Prompt templates'), findsOneWidget);
  });

  testWidgets('Discard from the router resets the form and re-arms the guard', (
    tester,
  ) async {
    final host = await _open(tester, SettingsPaths.aiPrompt(0));
    final original = _controller(tester, _labelField).text;
    await _makeDirty(tester);
    final guard = host.container.read(promptEditorGuardProvider);

    // The router asks (as a branch switch does); the page stays alive.
    final first = guard.mayLeave();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await first, isTrue);
    expect(_controller(tester, _labelField).text, original);

    // Clean again: leaving needs no question.
    expect(await guard.mayLeave(), isTrue);

    // Edited again: the guard asks again.
    await _makeDirty(tester);
    final second = guard.mayLeave();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(await second, isFalse);
    expect(_controller(tester, _labelField).text, 'Changed label');
  });

  testWidgets('a new prompt has no delete block', (tester) async {
    await _open(tester, SettingsPaths.aiPromptNew);
    expect(find.text('Delete prompt'), findsNothing);
  });

  testWidgets('a link to a prompt that is not there leaves the editor', (
    tester,
  ) async {
    await _open(tester, SettingsPaths.aiPrompt(99));
    expect(find.text('Edit prompt'), findsNothing);
    expect(find.text('Prompt templates'), findsOneWidget);
  });
}
