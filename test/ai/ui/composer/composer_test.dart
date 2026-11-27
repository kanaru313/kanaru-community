import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/domain/settings/prompt_template.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/variables/template_analysis.dart';
import 'package:kanaru/src/ai/domain/variables/variable_catalog.dart';
import 'package:kanaru/src/ai/domain/variables/variable_filler.dart';
import 'package:kanaru/src/ai/state/chat_attachments.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_draft.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_inputs.dart';
import 'package:kanaru/src/ai/ui/composer/composer_notice.dart';
import 'package:kanaru/src/ai/ui/composer/composer_text_controller.dart';
import 'package:kanaru/src/foundation/app_logger.dart';
import 'package:kanaru_ui/kanaru_ui.dart' show KChip;
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../../../support/kanaru_ui_finders.dart' show byEnabledState;
import '../support/chat_ui_support.dart';
import 'composer_harness.dart';

const _phone = Size(400, 800);

void main() {
  group('send', () {
    testWidgets('send disabled per readiness', (tester) async {
      final handle = tester.ensureSemantics();
      final setup = await pumpComposer(tester, readiness: const ChatNeedsKey());
      expect(byEnabledState('Send', enabled: false), findsOneWidget);

      setup.container
          .read(fakeChatReadinessProvider.notifier)
          .set(const ChatReady());
      await tester.pump();
      expect(byEnabledState('Send', enabled: true), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a sent message empties the field', (tester) async {
      final setup = await pumpComposer(tester);
      await typeInComposer(tester, 'hello');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(setup.sends, ['send hello']);
      expect(setup.controller.text, isEmpty);
    });

    testWidgets('Stop replaces Send while the model streams', (tester) async {
      final setup = await pumpComposer(tester);
      setup.session.setTurn(TurnState.streaming);
      await tester.pump();
      expect(find.byTooltip('Send'), findsNothing);
      await tester.tap(find.byTooltip('Stop'));
      await tester.pump();
      expect(setup.session.calls, contains('stop'));
    });

    testWidgets('permission control shows only its icon with the mode '
        'tooltip and semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpComposer(tester);
      expect(
        byIconButton('Permission: Ask first · Asks before changing anything'),
        findsOneWidget,
      );
      expect(find.text('Ask first'), findsNothing);
      expect(find.semantics.byLabel('Permission: Ask first'), findsOneWidget);
      handle.dispose();
    });
  });

  group('Enter', () {
    testWidgets('Enter sends on desktop, Shift+Enter is a new line', (
      tester,
    ) async {
      final desktop = await pumpComposer(tester);
      await typeInComposer(tester, 'hello');
      await pressEnter(tester, shift: true);
      expect(desktop.sends, isEmpty, reason: 'Shift+Enter is a new line');
      await pressEnter(tester);
      expect(desktop.sends, ['send hello']);
    });

    testWidgets('Enter is a new line on the phone', (tester) async {
      final phone = await pumpComposer(tester, size: _phone);
      await typeInComposer(tester, 'hello');
      await pressEnter(tester);
      expect(phone.sends, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField)).textInputAction,
        TextInputAction.newline,
      );
    });

    testWidgets('Enter while composing does not send', (tester) async {
      final setup = await pumpComposer(tester);
      await typeInComposer(tester, '');
      setup.controller.value = const TextEditingValue(
        text: 'xin',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      );
      await tester.pump();
      await pressEnter(tester);
      expect(setup.sends, isEmpty);

      // The input method commits: Enter sends again.
      setup.controller.value = setup.controller.value.copyWith(
        composing: TextRange.empty,
      );
      await tester.pump();
      await pressEnter(tester);
      expect(setup.sends, ['send xin']);
    });
  });

  group('variables', () {
    test('composing text keeps its underline inside a highlighted var', () {
      const text = 'see {{title}} now';
      final span = buildComposerSpan(
        text: text,
        composing: const TextRange(start: 6, end: 11),
        style: null,
        spans: analyzeTemplate(text, (_) => true).spans,
        styleOf: (_) => const TextStyle(color: Color(0xFF00AA00)),
      );
      final pieces = span.children!.cast<TextSpan>();
      expect(pieces.map((p) => p.text), ['see ', '{{', 'title', '}}', ' now']);
      TextSpan piece(String t) => pieces.firstWhere((p) => p.text == t);
      // Inside the variable and composing: coloured and underlined.
      expect(piece('title').style!.color, const Color(0xFF00AA00));
      expect(piece('title').style!.decoration, TextDecoration.underline);
      // Variable outside the composing range: coloured only.
      expect(piece('{{').style!.color, const Color(0xFF00AA00));
      expect(piece('{{').style!.decoration, isNull);
      // Plain text: untouched.
      expect(piece('see ').style, isNull);
    });

    testWidgets('typing {{ opens the list and a row inserts the variable', (
      tester,
    ) async {
      final setup = await pumpComposer(tester);
      await typeInComposer(tester, '');
      setup.controller.value = const TextEditingValue(
        text: 'ask {{no',
        selection: TextSelection.collapsed(offset: 8),
      );
      await tester.pump();
      expect(find.text('{{now_playing}}'), findsOneWidget);
      // The list is filtered by what follows the braces.
      expect(find.text('{{title}}'), findsNothing);

      await tester.tap(find.text('{{now_playing}}'));
      await tester.pump();
      expect(setup.controller.text, 'ask {{now_playing}}');
      expect(find.text('{{now_playing}}'), findsNothing);
    });

    testWidgets('{{ while composing does not open the list', (tester) async {
      final setup = await pumpComposer(tester);
      await typeInComposer(tester, '');
      setup.controller.value = const TextEditingValue(
        text: '{{',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      );
      await tester.pump();
      expect(find.text('{{title}}'), findsNothing);

      setup.controller.value = setup.controller.value.copyWith(
        composing: TextRange.empty,
      );
      await tester.pump();
      expect(find.text('{{title}}'), findsOneWidget);
    });
  });

  group('prompt chips', () {
    ComposerSettings prompts() => ComposerSettings(
      prompts: const [
        PromptTemplate(label: 'Say hi', body: 'Say hi'),
        PromptTemplate(label: 'Mood', body: 'Mood: {{input}}'),
        PromptTemplate(label: 'Lyrics', body: 'Explain {{lyrics}}'),
      ],
    );

    testWidgets('chip tap rules: send, fill above typed text, blank selected', (
      tester,
    ) async {
      final setup = await pumpComposer(tester, promptChips: true);
      setup.container
          .read(fakeComposerSettingsProvider.notifier)
          .set(prompts());
      await tester.pump();

      // Small prompt chips are outlined, like the empty-chat prompt buttons.
      expect(
        tester.widget<KChip>(find.widgetWithText(KChip, 'Say hi')).outlined,
        isTrue,
      );

      // An empty field sends at once.
      await tester.tap(find.text('Say hi'));
      await tester.pump();
      expect(setup.sends, ['send Say hi']);

      // Typed text goes under the prompt, nothing more is sent.
      setup.container
          .read(composerDraftProvider.notifier)
          .set(const TextEditingValue(text: 'abc'));
      await tester.pump();
      await tester.tap(find.text('Say hi'));
      await tester.pump();
      expect(setup.controller.text, 'Say hi\nabc');
      expect(setup.sends, hasLength(1));

      // A prompt with a blank is only filled in, the blank selected.
      setup.container
          .read(composerDraftProvider.notifier)
          .set(TextEditingValue.empty);
      await tester.pump();
      await tester.tap(find.text('Mood'));
      await tester.pump();
      expect(setup.controller.text, 'Mood: {{input}}');
      expect(
        setup.controller.selection.textInside(setup.controller.text),
        '{{input}}',
      );
      expect(setup.sends, hasLength(1));
    });

    testWidgets('a prompt that is not sent stays in the field', (tester) async {
      final setup = await pumpComposer(tester, promptChips: true);
      setup.container
          .read(fakeComposerSettingsProvider.notifier)
          .set(prompts());
      setup.session.sendResult = const SendFailed();
      await tester.pump();
      await tester.tap(find.text('Say hi'));
      await tester.pump();
      expect(setup.controller.text, 'Say hi');
    });

    testWidgets('a refused prompt keeps its note and the text', (tester) async {
      var searched = 0;
      final setup = await pumpComposer(
        tester,
        promptChips: true,
        overrides: [
          chatFindLyricsProvider.overrideWithValue((_) => searched++),
        ],
      );
      setup.container
          .read(fakeComposerSettingsProvider.notifier)
          .set(prompts());
      setup.session.sendResult = const SendMissingData([
        VariableIssue(FillMissing(AiVariable.lyrics, 'no lyrics')),
      ]);
      await tester.pump();
      await tester.tap(find.text('Lyrics'));
      await tester.pump();
      // The prompt is in the field, and the note says why it was not sent.
      expect(setup.controller.text, 'Explain {{lyrics}}');
      expect(
        find.textContaining('has no lyrics, so {{lyrics}} cannot be filled'),
        findsOneWidget,
      );
      await tester.tap(find.text('Find lyrics for this song'));
      expect(searched, 1);
    });

    testWidgets('chips lock while streaming and dim without data', (
      tester,
    ) async {
      final setup = await pumpComposer(tester, promptChips: true);
      setup.container
          .read(fakeComposerSettingsProvider.notifier)
          .set(prompts());
      setup.container
          .read(fakePromptDataProvider.notifier)
          .set(const ChatPromptData(hasPlaying: false));
      await tester.pump();
      // No playing song: the lyrics prompt does nothing.
      expect(
        tester.getSemantics(find.text('Lyrics')),
        isSemantics(isEnabled: false),
      );
      await tester.tap(find.text('Lyrics'), warnIfMissed: false);
      await tester.pump();
      expect(setup.sends, isEmpty);

      setup.session.setTurn(TurnState.streaming);
      await tester.pump();
      await tester.tap(find.text('Say hi'));
      await tester.pump();
      expect(setup.sends, isEmpty);
    });
  });

  group('notices', () {
    testWidgets('missing variable notice keeps the text', (tester) async {
      var searched = 0;
      final setup = await pumpComposer(
        tester,
        overrides: [
          chatFindLyricsProvider.overrideWithValue((_) => searched++),
        ],
      );
      setup.session.sendResult = const SendMissingData([
        VariableIssue(FillMissing(AiVariable.lyrics, 'no lyrics')),
      ]);
      await typeInComposer(tester, 'Explain {{lyrics}}');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();

      expect(
        find.textContaining('has no lyrics, so {{lyrics}} cannot be filled'),
        findsOneWidget,
      );
      expect(setup.controller.text, 'Explain {{lyrics}}');

      await tester.tap(find.text('Find lyrics for this song'));
      expect(searched, 1);

      await tester.tap(byIconButton('Dismiss'));
      await tester.pump();
      expect(find.textContaining('cannot be filled'), findsNothing);
      expect(setup.controller.text, 'Explain {{lyrics}}');
    });

    testWidgets('a leftover blank is selected for typing', (tester) async {
      final setup = await pumpComposer(tester);
      setup.session.sendResult = const SendMissingData([
        VariableIssue(FillLeftoverInput()),
      ]);
      await typeInComposer(tester, 'Mood: {{input}}');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(find.textContaining('is still in the message'), findsOneWidget);
      expect(
        setup.controller.selection.textInside(setup.controller.text),
        '{{input}}',
      );
    });

    testWidgets('a variable whose tool is off names the tool', (tester) async {
      final setup = await pumpComposer(tester);
      setup.session.sendResult = const SendMissingData([
        VariableIssue(FillGroupOff(AiVariable.nowPlaying)),
      ]);
      await typeInComposer(tester, 'Tell me about {{now_playing}}');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(
        find.text(
          'The “Now playing” tool is off, so {{now_playing}} cannot be '
          'filled. Nothing was sent.',
        ),
        findsOneWidget,
      );
      expect(find.text('AI settings'), findsOneWidget);
    });

    testWidgets('editing the text ends the note of a refused send', (
      tester,
    ) async {
      final setup = await pumpComposer(tester);
      setup.session.sendResult = const SendFailed();
      await typeInComposer(tester, 'one');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(find.textContaining('could not be saved'), findsOneWidget);
      await typeInComposer(tester, 'one two');
      expect(find.textContaining('could not be saved'), findsNothing);
    });

    testWidgets('a send that throws logs only the type in release', (
      tester,
    ) async {
      final before = Logger.root.level;
      Logger.root.level = Level.ALL;
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      addTearDown(() async {
        Logger.root.level = before;
        await sub.cancel();
      });
      final setup = await pumpComposer(tester);
      setup.session.sendError = StateError('SECRET-chat-text');
      await typeInComposer(tester, 'one');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      final warning = records.singleWhere(
        (r) => r.level == Level.WARNING && r.message.startsWith('send failed'),
      );
      final printed = formatLogLine(warning, release: true);
      expect(printed, contains('StateError'));
      expect(printed, isNot(contains('SECRET-chat-text')));
      expect(
        records.any(
          (r) =>
              r.level == Level.FINE && r.message.contains('SECRET-chat-text'),
        ),
        isTrue,
      );
      expect(find.textContaining('could not be saved'), findsOneWidget);
    });

    testWidgets('oversize queue shows the count and sends the short version', (
      tester,
    ) async {
      final setup = await pumpComposer(
        tester,
        overrides: [chatQueueLengthProvider.overrideWithValue(412)],
      );
      setup.session.sendResult = const SendOversize([AiVariable.queue]);
      await typeInComposer(tester, 'Clean {{queue}}');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(
        find.text('{{queue}} has 412 songs, over the limit m1 accepts.'),
        findsOneWidget,
      );

      setup.session.sendResult = null;
      await tester.tap(
        find.text('Send the short version: 50 songs around the playing one'),
      );
      await tester.pump();
      expect(setup.sends, [
        'send Clean {{queue}}',
        'send short Clean {{queue}}',
      ]);
      expect(setup.controller.text, isEmpty);
    });

    testWidgets('oversize without a known count uses the plain wording', (
      tester,
    ) async {
      final setup = await pumpComposer(tester);
      setup.session.sendResult = const SendOversize([AiVariable.lyrics]);
      await typeInComposer(tester, 'Explain {{lyrics}}');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(
        find.text('{{lyrics}} is too large to send to m1.'),
        findsOneWidget,
      );
      expect(find.text('Send the short version'), findsOneWidget);
    });

    testWidgets('cancel on the oversize note keeps the text', (tester) async {
      final setup = await pumpComposer(tester);
      setup.session.sendResult = const SendOversize([AiVariable.queue]);
      await typeInComposer(tester, 'Clean {{queue}}');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.textContaining('too large'), findsNothing);
      expect(setup.controller.text, 'Clean {{queue}}');
      expect(setup.sends, hasLength(1));
    });

    testWidgets('struck chip blocks send', (tester) async {
      final handle = tester.ensureSemantics();
      final setup = await pumpComposer(tester);
      setup.container
          .read(fakeComposerSettingsProvider.notifier)
          .set(
            ComposerSettings(
              enabledGroups: AiToolGroup.values.toSet()
                ..remove(AiToolGroup.nowPlaying),
            ),
          );
      setup.container
          .read(chatAttachmentsProvider.notifier)
          .attach(const ChipPart(kind: ChipKind.nowPlaying));
      await tester.pump();
      expect(find.textContaining('“Now playing” tool is off'), findsOneWidget);
      expect(byEnabledState('Send', enabled: false), findsOneWidget);

      await tester.tap(find.text('Remove chip'));
      await tester.pump();
      expect(find.textContaining('tool is off'), findsNothing);
      expect(byEnabledState('Send', enabled: true), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a missing key opens the plugin settings page', (tester) async {
      final setup = await pumpComposer(tester, readiness: const ChatNeedsKey());
      expect(
        find.text('Claude needs an API key before it can send.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Open plugin settings'));
      expect(setup.host.calls, ['openSettings /settings/plugins/p/p1']);
    });

    testWidgets('no model: the button reads Choose a model and the note offers '
        'the picker', (tester) async {
      await pumpComposer(tester, readiness: const ChatNeedsModel());
      expect(
        find.text('Claude has no model. Choose a model before sending.'),
        findsOneWidget,
      );
      // The model button and the note's button.
      expect(find.text('Choose a model'), findsNWidgets(2));
    });

    testWidgets('a reinstalled plugin locks the field and offers the picker', (
      tester,
    ) async {
      await pumpComposer(tester, readiness: const ChatPluginReinstalled());
      expect(
        find.textContaining('was removed and installed again'),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      await tester.tap(find.text('Choose a plugin'));
      await tester.pumpAndSettle();
      expect(find.text('Add an AI service…'), findsOneWidget);
    });

    testWidgets('a removed plugin keeps the text and offers the picker', (
      tester,
    ) async {
      await pumpComposer(tester, readiness: const ChatPluginRemoved());
      expect(find.textContaining('plugin was removed'), findsOneWidget);
      expect(find.text('Choose a plugin'), findsOneWidget);
    });

    testWidgets('a removed plugin is named when the chat switched to it', (
      tester,
    ) async {
      final setup = await pumpComposer(
        tester,
        readiness: const ChatPluginRemoved(),
      );
      setup.container.read(fakeChatMessagesProvider.notifier).set([
        chatMessage(
          1,
          role: AiMessageRole.event,
          parts: const [
            EventPart.pluginSwitch(fromName: 'Claude', toName: 'Grok'),
          ],
        ),
      ]);
      await tester.pump();
      await tester.pump();
      expect(
        find.text(
          'Plugin “Grok” was removed. Choose another plugin to continue.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a model without tools gets a gentle note and still sends', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpComposer(tester, plugins: [chatPlugin(tools: false)]);
      expect(find.textContaining('does not use tools'), findsOneWidget);
      expect(byEnabledState('Send', enabled: true), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a suggested chip attaches on tap and its × removes it', (
      tester,
    ) async {
      final setup = await pumpComposer(tester);
      const chip = ChipPart(kind: ChipKind.nowPlaying);
      final attachments = setup.container.read(
        chatAttachmentsProvider.notifier,
      );
      attachments.setSuggestions(const [chip]);
      await tester.pump();
      await tester.tap(find.text('+ Now playing'));
      await tester.pump();
      expect(setup.container.read(chatAttachmentsProvider).attached, const [
        chip,
      ]);
      await tester.tap(byIconButton('Remove chip Now playing'));
      await tester.pump();
      expect(setup.container.read(chatAttachmentsProvider).attached, isEmpty);
    });
  });

  group('draft', () {
    testWidgets('the draft never keeps the IME composing range', (
      tester,
    ) async {
      final setup = await pumpComposer(tester);
      await typeInComposer(tester, '');
      setup.controller.value = const TextEditingValue(
        text: 'xin',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      );
      await tester.pump();
      final draft = setup.container.read(composerDraftProvider);
      expect(draft.text, 'xin');
      expect(draft.composing, TextRange.empty);
      // The field itself keeps composing: the draft write did not undo it.
      expect(
        setup.controller.value.composing,
        const TextRange(start: 0, end: 3),
      );
    });

    testWidgets('a send that ends after the chat left still clears the text', (
      tester,
    ) async {
      final setup = await pumpComposer(tester);
      setup.session.sendGate = Completer<void>();
      await typeInComposer(tester, 'hello');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(setup.sends, ['send hello']);

      // The chat leaves the screen (a panel swap) while the send runs.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: setup.container,
          child: const MaterialApp(home: SizedBox()),
        ),
      );
      setup.session.sendGate!.complete();
      await tester.pump();
      await tester.pump();
      expect(setup.container.read(composerDraftProvider).text, isEmpty);
    });
  });
}
