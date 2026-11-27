import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_inputs.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_view.dart';
import 'package:kanaru/src/ai/state/chat_view/prompt_apply.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';

ChatPluginInfo _plugin({bool tools = true}) => ChatPluginInfo(
  installId: 'p1',
  installGeneration: 1,
  name: 'Claude',
  version: 1,
  spec: ChatSpec(custom: ChatCapabilities(tools: tools)),
  models: const [],
  defaultModel: 'm1',
  readiness: const ChatReady(),
);

ComposerView _derive(
  TurnState turn, {
  ChatReadiness? readiness = const ChatReady(),
  List<ChipPart> struck = const [],
  ComposerNotice? sendNotice,
  bool tools = true,
}) => deriveComposerView(
  turn: turn,
  readiness: readiness,
  permission: AiPermission.ask,
  plugin: _plugin(tools: tools),
  model: 'm1',
  struckChips: struck,
  sendNotice: sendNotice,
);

void main() {
  group('lock table', () {
    for (final turn in [TurnState.idle, TurnState.error]) {
      test('$turn: Send, field and every picker and prompt chip on', () {
        final v = _derive(turn);
        expect(v.action, ComposerAction.send);
        expect(v.canSend, isTrue);
        expect(v.fieldEditable, isTrue);
        expect(v.pluginPickerEnabled, isTrue);
        expect(v.modelPickerEnabled, isTrue);
        expect(v.permissionPickerEnabled, isTrue);
        expect(v.promptChipsEnabled, isTrue);
      });
    }

    test(
      'streaming: Stop, field editable, pickers and prompt chips locked',
      () {
        final v = _derive(TurnState.streaming);
        expect(v.action, ComposerAction.stop);
        expect(v.canSend, isFalse);
        expect(v.toolsRunning, isFalse);
        expect(v.fieldEditable, isTrue);
        expect(v.pluginPickerEnabled, isFalse);
        expect(v.modelPickerEnabled, isFalse);
        expect(v.permissionPickerEnabled, isFalse);
        expect(v.promptChipsEnabled, isFalse);
      },
    );

    test(
      'runningTools: Stop that says the later calls will not run, locked',
      () {
        final v = _derive(TurnState.runningTools);
        expect(v.action, ComposerAction.stop);
        expect(v.toolsRunning, isTrue);
        expect(v.fieldEditable, isTrue);
        expect(v.pluginPickerEnabled, isFalse);
        expect(v.modelPickerEnabled, isFalse);
        expect(v.permissionPickerEnabled, isFalse);
        expect(v.promptChipsEnabled, isFalse);
      },
    );

    test('awaitingConfirm: Send and every control stay on', () {
      final v = _derive(TurnState.awaitingConfirm);
      expect(v.action, ComposerAction.send);
      expect(v.canSend, isTrue);
      expect(v.fieldEditable, isTrue);
      expect(v.pluginPickerEnabled, isTrue);
      expect(v.modelPickerEnabled, isTrue);
      expect(v.permissionPickerEnabled, isTrue);
      expect(v.promptChipsEnabled, isTrue);
    });
  });

  group('send needs a ready plugin and no struck chip', () {
    test('readiness still loading: nothing to send, no notice', () {
      final v = _derive(TurnState.idle, readiness: null);
      expect(v.canSend, isFalse);
      expect(v.notice, isNull);
    });

    test('needs key / model / config give their note and block Send', () {
      var v = _derive(TurnState.idle, readiness: const ChatNeedsKey());
      expect(v.canSend, isFalse);
      expect(v.notice, isA<NoticeNeedsKey>());
      v = _derive(TurnState.idle, readiness: const ChatNeedsModel());
      expect(v.notice, isA<NoticeNeedsModel>());
      expect(v.modelNeeded, isTrue);
      v = _derive(
        TurnState.idle,
        readiness: const ChatNeedsConfig(['Preset', 'Base URL']),
      );
      expect((v.notice! as NoticeNeedsConfig).titles, ['Preset', 'Base URL']);
    });

    test('removed and reinstalled plugins lock the field and the model', () {
      for (final r in [
        const ChatPluginRemoved(),
        const ChatPluginReinstalled(),
      ]) {
        final v = _derive(TurnState.idle, readiness: r);
        expect(v.canSend, isFalse);
        expect(v.fieldEditable, isFalse);
        expect(v.modelPickerEnabled, isFalse);
        // Choosing another plugin is the way out.
        expect(v.pluginPickerEnabled, isTrue);
      }
      expect(
        _derive(TurnState.idle, readiness: const ChatPluginRemoved()).notice,
        isA<NoticeRemoved>(),
      );
      expect(
        _derive(
          TurnState.idle,
          readiness: const ChatPluginReinstalled(),
        ).notice,
        isA<NoticeReinstalled>(),
      );
    });

    test('a struck chip blocks Send and shows its note', () {
      const chip = ChipPart(kind: ChipKind.nowPlaying);
      final v = _derive(TurnState.idle, struck: const [chip]);
      expect(v.canSend, isFalse);
      expect((v.notice! as NoticeStruckChip).chip, chip);
    });
  });

  group('the one note', () {
    test('a readiness note wins over a send note', () {
      final v = _derive(
        TurnState.idle,
        readiness: const ChatNeedsKey(),
        sendNotice: const NoticeSendFailed(),
      );
      expect(v.notice, isA<NoticeNeedsKey>());
    });

    test('a send note shows while the plugin is ready', () {
      final v = _derive(TurnState.idle, sendNotice: const NoticeSendFailed());
      expect(v.notice, isA<NoticeSendFailed>());
    });

    test('a model without tools only gets the gentle note and still sends', () {
      final v = _derive(TurnState.idle, tools: false);
      expect(v.notice, isA<NoticeNoTools>());
      expect(v.canSend, isTrue);
    });
  });

  group('prompt data', () {
    test('a variable without data names what is lacking', () {
      const none = ChatPromptData(hasPlaying: false, hasQueue: false);
      expect(promptLack('Explain {{lyrics}}', none), PromptLack.noPlaying);
      expect(promptLack('Clean {{queue}}', none), PromptLack.emptyQueue);
      expect(promptLack('Mood: {{input}}', none), isNull);
      expect(promptLack('No variables', none), isNull);
      expect(promptLack('{{queue}}', const ChatPromptData()), isNull);
    });
  });

  group('prompt chip rules', () {
    test('an empty field sends a prompt without a blank', () {
      final a = applyPrompt('Tell me', TextEditingValue.empty);
      expect((a as PromptSendNow).text, 'Tell me');
    });

    test('typed text goes under the prompt, nothing is sent', () {
      final a = applyPrompt(
        'Tell me',
        const TextEditingValue(text: 'my words'),
      );
      expect((a as PromptFill).value.text, 'Tell me\nmy words');
    });

    test('a blank is only filled in and selected', () {
      final a = applyPrompt('Mood: {{input}}', TextEditingValue.empty);
      final value = (a as PromptFill).value;
      expect(value.text, 'Mood: {{input}}');
      expect(value.selection.textInside(value.text), '{{input}}');
    });

    test('blank and typed text together: prompt on top, blank selected', () {
      final a = applyPrompt(
        'Mood: {{input}}',
        const TextEditingValue(text: 'extra'),
      );
      final value = (a as PromptFill).value;
      expect(value.text, 'Mood: {{input}}\nextra');
      expect(value.selection.textInside(value.text), '{{input}}');
    });
  });
}
