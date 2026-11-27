import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/settings/builtin_templates.dart';
import 'package:kanaru/src/ai/domain/settings/prompt_template.dart';
import 'package:kanaru/src/ai/state/ai_settings_providers.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show TextField;

import '../test/screens/settings/ai/ai_settings_host.dart';
import '../test/screens/settings/support/settings_host.dart'
    show SettingsHarness;
import '../test/support/memory_settings_store.dart';
import 'support/ai_settings_shots.dart';

/// The prompt editor of Settings › Trò chuyện AI (D2: "Prompt mới" / "Sửa
/// prompt"), on both shell sizes, in Vietnamese. The real Settings routes
/// over an in-memory store. Asserts state (finders), never pixels; the
/// screenshots (`NN-<state>-<shell>.png` in `$KANARU_IT_SHOTS`, default
/// `/tmp/kanaru-it/shots-ai-settings`) are for comparing with
/// `mockups/screens/06-settings.md` § Trình sửa prompt by eye.
///
/// Not covered here (phone only): Vietnamese Telex composition in both fields.

late AppLocalizations _l;

Finder get _labelField => find.byType(TextField).first;
Finder get _bodyField => find.byType(TextField).at(1);

TextEditingController _controller(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!;

MemorySettingsStore _prompts(List<PromptTemplate> list) {
  final store = MemorySettingsStore();
  store.write('ai.prompts', [for (final t in list) t.toJson()]);
  return store;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => _l = await loadViStrings());

  for (final MapEntry(key: shell, value: size) in aiSettingsShells.entries) {
    Future<void> shot(WidgetTester t, String name) =>
        aiSettingsShot(t, name, shell);

    Future<SettingsHarness> open(
      WidgetTester tester,
      String location, {
      MemorySettingsStore? store,
    }) => openAiSettings(
      tester,
      location: location,
      size: size,
      locale: aiSettingsLocale,
      store: store,
    );

    /// Types into the label field so the editor holds unsaved edits.
    Future<void> makeDirty(WidgetTester tester) async {
      await tester.enterText(_labelField, 'Changed label');
      await tester.pump();
    }

    group('Prompt editor, $shell', () {
      testWidgets('01 new prompt: fields, counters, chips insert at cursor', (
        tester,
      ) async {
        await open(tester, SettingsPaths.aiPromptNew);
        expect(find.text(_l.aiSetEdTitleNew), findsOneWidget);
        expect(find.text('0 / 40'), findsOneWidget);
        expect(find.text('0 / 2.000'), findsOneWidget);
        expect(find.text(_l.aiSetEdLabelHelp), findsOneWidget);
        expect(find.text(_l.aiSetEdBodyHelp), findsOneWidget);
        for (final v in [
          'now_playing',
          'title',
          'artist',
          'album',
          'lyrics',
          'queue',
          'input',
        ]) {
          expect(find.text('{{$v}}'), findsOneWidget, reason: v);
        }
        expect(find.text(_l.aiSetEdPreviewEmpty), findsOneWidget);
        await shot(tester, '01a-new-prompt');

        await tester.enterText(_labelField, 'Giải nghĩa');
        await tester.enterText(_bodyField, 'abcdef');
        await tester.pump();
        expect(find.text('10 / 40'), findsOneWidget);
        expect(find.text('6 / 2.000'), findsOneWidget);
        _controller(tester, _bodyField).selection =
            const TextSelection.collapsed(offset: 3);
        await tester.tap(find.text('{{title}}'));
        await tester.pump();
        final c = _controller(tester, _bodyField);
        expect(c.text, 'abc{{title}}def');
        expect(c.selection, const TextSelection.collapsed(offset: 12));
        await shot(tester, '01b-chip-inserted');
      });

      testWidgets('02 preview fills the sample data', (tester) async {
        await open(tester, SettingsPaths.aiPromptNew);
        await tester.enterText(
          _bodyField,
          'Kể về {{title}} của {{artist}}: {{lyrics}} {{queue}} {{input}}',
        );
        await tester.pump();
        expect(find.text(_l.aiSetEdPreviewTitle), findsOneWidget);
        expect(
          find.textContaining('Kể về Lạc trôi của Sơn Tùng M-TP'),
          findsOneWidget,
        );
        expect(find.textContaining(_l.aiSetEdSampleLyrics), findsOneWidget);
        expect(find.textContaining(_l.aiSetEdSampleQueue), findsOneWidget);
        expect(find.textContaining(_l.aiSetEdSampleInput), findsOneWidget);
        await shot(tester, '02-preview');
      });

      testWidgets('03 edit a builtin: delete block line, delete, restore', (
        tester,
      ) async {
        final h = await open(tester, SettingsPaths.aiPrompt(0));
        expect(find.text(_l.aiSetEdTitleEdit), findsOneWidget);
        final line = _l.aiSetEdDeleteBuiltinDesc(_l.aiSetPromptRestore);
        await aiSettingsReveal(tester, find.text(line));
        expect(line, startsWith('Prompt có sẵn: '));
        await shot(tester, '03a-edit-builtin');
        await tester.tap(find.text(_l.aiSetEdDeleteRow));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_l.aiSetEdDeleteConfirm));
        await tester.pumpAndSettle();
        expect(find.text(_l.aiSetEdTitleEdit), findsNothing);
        expect(
          h.container.read(aiPromptsProvider).map((t) => t.key),
          isNot(contains(BuiltinTemplateKeys.explainLyrics)),
        );
        await aiSettingsReveal(tester, find.text(_l.aiSetPromptRestore));
        await tester.tap(find.text(_l.aiSetPromptRestore));
        await tester.pumpAndSettle();
        expect(
          h.container.read(aiPromptsProvider).last.key,
          BuiltinTemplateKeys.explainLyrics,
        );
        await shot(tester, '03b-restored');
        await tester.pumpAndSettle(const Duration(seconds: 6));
      });

      testWidgets('04 unknown {{weather}}: error line, Lưu dimmed', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await open(tester, SettingsPaths.aiPromptNew);
        await tester.enterText(_labelField, 'Weather');
        await tester.enterText(_bodyField, 'Is it {{weather}} now?');
        await tester.pump();
        expect(
          find.textContaining('Biến {{weather}} không có'),
          findsOneWidget,
        );
        bool saveOn() => isSemantics(isEnabled: true).matches(
          tester.getSemantics(
            find.widgetWithText(KModalButton, _l.aiSetEdSave),
          ),
          {},
        );
        expect(saveOn(), isFalse);
        await shot(tester, '04-unknown-variable');
        await tester.enterText(_bodyField, 'Is it {{title}} now?');
        await tester.pump();
        expect(saveOn(), isTrue);
        handle.dispose();
      });

      testWidgets('05 warning when the tool group of a variable is off', (
        tester,
      ) async {
        final store = MemorySettingsStore();
        await store.write('ai.tools.lyrics', false);
        await open(tester, SettingsPaths.aiPromptNew, store: store);
        await tester.enterText(_labelField, 'Lời');
        await tester.enterText(_bodyField, 'Giải nghĩa {{lyrics}}');
        await tester.pump();
        expect(find.textContaining('Vẫn lưu được'), findsOneWidget);
        expect(find.textContaining('{{lyrics}}'), findsWidgets);
        await shot(tester, '05-group-off-warning');
      });

      testWidgets('06 Huỷ with changes asks, Keep editing / Bỏ', (
        tester,
      ) async {
        await open(tester, SettingsPaths.aiPrompt(0));
        await makeDirty(tester);
        await tester.tap(find.widgetWithText(KModalButton, _l.aiSetEdCancel));
        await tester.pumpAndSettle();
        expect(find.text(_l.aiSetEdDiscardTitle), findsOneWidget);
        expect(find.text(_l.aiSetEdDiscardBody), findsOneWidget);
        await shot(tester, '06-discard-dialog');
        await tester.tap(find.text(_l.aiSetEdDiscardKeep));
        await tester.pumpAndSettle();
        expect(find.text(_l.aiSetEdDiscardTitle), findsNothing);
        expect(_controller(tester, _labelField).text, 'Changed label');

        // System back takes the same path.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text(_l.aiSetEdDiscardTitle), findsOneWidget);
        await tester.tap(find.text(_l.aiSetEdDiscardConfirm));
        await tester.pumpAndSettle();
        expect(find.text(_l.aiSetEdTitleEdit), findsNothing);
        await aiSettingsReveal(tester, find.text(_l.aiSetPromptsTitle));
        expect(find.text(_l.aiSetPromptsTitle), findsOneWidget);
      });

      if (shell == 'desktop') {
        testWidgets('06b Esc asks too (desktop)', (tester) async {
          await open(tester, SettingsPaths.aiPrompt(0));
          await makeDirty(tester);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(find.text(_l.aiSetEdDiscardTitle), findsOneWidget);
        });
      }

      testWidgets('07a Xoá prompt: builtin dialog and toast', (tester) async {
        await open(tester, SettingsPaths.aiPrompt(0));
        await aiSettingsReveal(tester, find.text(_l.aiSetEdDeleteRow));
        await tester.tap(find.text(_l.aiSetEdDeleteRow));
        await tester.pumpAndSettle();
        final label = _l.aiSetTemplateExplainLyricsLabel;
        expect(find.text(_l.aiSetEdDeleteTitle(label)), findsOneWidget);
        expect(
          find.text(_l.aiSetEdDeleteBodyBuiltin(_l.aiSetPromptRestore)),
          findsOneWidget,
        );
        await shot(tester, '07a-delete-builtin-dialog');
        await tester.tap(find.text(_l.aiSetEdDeleteConfirm));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Đã xoá “$label”'), findsOneWidget);
        await shot(tester, '07b-delete-toast');
        await tester.pumpAndSettle(const Duration(seconds: 6));
      });

      testWidgets('07c Xoá prompt: own prompt dialog', (tester) async {
        await open(
          tester,
          SettingsPaths.aiPrompt(0),
          store: _prompts(const [
            PromptTemplate(label: 'Mine', body: 'Play {{now_playing}}'),
          ]),
        );
        await aiSettingsReveal(tester, find.text(_l.aiSetEdDeleteRow));
        expect(find.textContaining('Prompt có sẵn'), findsNothing);
        await tester.tap(find.text(_l.aiSetEdDeleteRow));
        await tester.pumpAndSettle();
        expect(find.text(_l.aiSetEdDeleteTitle('Mine')), findsOneWidget);
        expect(find.text(_l.aiSetEdDeleteBodyCustom), findsOneWidget);
        await shot(tester, '07c-delete-own-dialog');
        await tester.tap(find.text(_l.aiSetEdDeleteConfirm));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Đã xoá “Mine”'), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 6));
      });
    });
  }
}
