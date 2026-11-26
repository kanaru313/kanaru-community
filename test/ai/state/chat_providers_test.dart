import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/state/chat_attachments.dart';
import 'package:kanaru/src/ai/state/chat_conversation_providers.dart';
import 'package:kanaru/src/ai/state/chat_messages_provider.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/ai/state/live_text_provider.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_values.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';

import '../data/conversation_store_fixtures.dart';
import 'chat_harness.dart';

Future<T> settle<T>(T Function() read, bool Function(T) ready) async {
  for (var i = 0; i < 400; i++) {
    final v = read();
    if (ready(v)) return v;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('never settled');
}

void main() {
  late ChatHarness t;
  var created = false;

  Future<void> start({bool ready = true}) async {
    t = await ChatHarness.create(ready: ready);
    created = true;
  }

  tearDown(() async {
    if (!created) return;
    created = false;
    await t.dispose();
  });

  group('readiness', () {
    test('is ready once the key and the model are set', () async {
      await start();
      final chat = await t.session.newConversation();
      t.container.listen(chatReadinessProvider(chat), (_, _) {});

      final r = await settle(
        () => t.container.read(chatReadinessProvider(chat)),
        (v) => v.hasValue,
      );

      expect(r.requireValue, isA<ChatReady>());
    });

    test('needs a key while the key field is empty', () async {
      await start(ready: false);
      final chat = await t.session.newConversation();
      t.container.listen(chatReadinessProvider(chat), (_, _) {});

      final r = await settle(
        () => t.container.read(chatReadinessProvider(chat)),
        (v) => v.hasValue,
      );

      expect(r.requireValue, isA<ChatNeedsKey>());
    });

    test('reads removed once the plugin is gone', () async {
      await start();
      final chat = await t.session.newConversation();
      t.container.listen(chatReadinessProvider(chat), (_, _) {});
      await settle(
        () => t.container.read(chatReadinessProvider(chat)),
        (v) => v.value is ChatReady,
      );

      await t.h.actions.remover.remove(t.installId);

      await settle(
        () => t.container.read(chatReadinessProvider(chat)),
        (v) => v.value is ChatPluginRemoved,
      );
    });
  });

  group('messages', () {
    test('load a page, then older pages, and follow new messages', () async {
      await start();
      final chat = await newChat(t.store);
      for (var i = 1; i <= 60; i++) {
        await addUser(t.store, chat.id, 'm$i');
      }
      final sub = t.container.listen(chatMessagesProvider(chat.id), (_, _) {});
      addTearDown(sub.close);

      var page = await settle(
        () => t.container.read(chatMessagesProvider(chat.id)),
        (v) => v.hasValue,
      );
      expect(page.requireValue.messages, hasLength(chatMessagePage));
      expect(page.requireValue.hasMore, isTrue);
      expect(
        (page.requireValue.messages.last.parts.single as TextPart).text,
        'm60',
      );

      await t.container
          .read(chatMessagesProvider(chat.id).notifier)
          .loadOlder();
      page = t.container.read(chatMessagesProvider(chat.id));
      expect(page.requireValue.messages, hasLength(60));
      expect(page.requireValue.hasMore, isFalse);

      await addUser(t.store, chat.id, 'm61');
      await settle(
        () => t.container.read(chatMessagesProvider(chat.id)).value,
        (v) => v?.messages.length == 61,
      );
    });
  });

  test('the live text provider follows the streamed text', () async {
    await start();
    t.engine.rounds.add(
      const ScriptedRound(
        events: ['{"t":"text","d":"ab"}'],
        untilCancelled: true,
      ),
    );
    final seen = <String>[];
    t.session.liveText.listen((e) => seen.add(e.text));
    await t.session.send('go');
    await settle(() => seen.length, (n) => n == 1);
    final chat = t.session.state.conversationId!;
    final assistant = (await t.store.messages(chat)).last.message;
    expect(assistant.role, AiMessageRole.assistant);

    final sub = t.container.listen(liveTextProvider(assistant.id), (_, _) {});
    addTearDown(sub.close);
    expect(t.container.read(liveTextProvider(assistant.id)), 'ab');
    t.engine.lastOnEvent!('{"t":"text","d":"c"}');
    await settle(
      () => t.container.read(liveTextProvider(assistant.id)),
      (v) => v == 'abc',
    );
    expect(t.container.read(liveTextProvider(assistant.id + 1)), isNull);

    await t.session.stop();
  });

  group('model options', () {
    const spec = ChatSpec(
      models: [ChatModelSpec(id: 'a', title: 'A', tools: true, context: 4096)],
      custom: ChatCapabilities(context: 2048),
    );
    const field = SelectField(
      key: 'model',
      title: 'Model',
      custom: true,
      options: [
        ConfigOption(value: 'a', title: 'Model A'),
        ConfigOption(value: 'b', title: 'Model B'),
      ],
    );

    test('are the plugin options plus the user choices, with capabilities', () {
      final options = chatModelOptions(
        [field],
        spec,
        const PluginConfigData(
          choices: {
            'model': [CustomChoice('mine', 'my note')],
          },
        ),
      );

      expect([for (final o in options) o.id], ['a', 'b', 'mine']);
      expect([for (final o in options) o.isCustom], [false, false, true]);
      expect(options[0].capabilities.tools, isTrue);
      expect(options[0].capabilities.context, 4096);
      expect(options[1].capabilities.tools, isFalse);
      expect(options[2].capabilities.context, 2048);
      expect(options[2].subtitle, 'my note');
    });

    test('are empty when the plugin has no model select', () {
      expect(
        chatModelOptions(const [], spec, const PluginConfigData()),
        isEmpty,
      );
    });
  });

  group('attachments', () {
    const song = ChipPart(kind: ChipKind.genre, ref: 'pop', label: 'Pop');

    test('the same chip is attached once; detach removes it', () async {
      await start();
      final n = t.container.read(chatAttachmentsProvider.notifier);
      n.attach(song);
      n.attach(
        const ChipPart(kind: ChipKind.genre, ref: 'pop', label: 'Other'),
      );
      expect(t.container.read(chatAttachmentsProvider).attached, [song]);

      n.detach(song);
      expect(t.container.read(chatAttachmentsProvider).attached, isEmpty);
    });

    test('suggestions are kept apart from the attached chips', () async {
      await start();
      final n = t.container.read(chatAttachmentsProvider.notifier);
      n.setSuggestions([song]);
      n.clearAttached();
      expect(t.container.read(chatAttachmentsProvider).suggestions, [song]);
      expect(t.container.read(chatAttachmentsProvider).attached, isEmpty);
    });
  });

  test('new conversations take the default permission', () async {
    await start();
    final chat = await t.session.newConversation();
    expect((await t.store.conversation(chat))!.permission, AiPermission.ask);
  });
}
