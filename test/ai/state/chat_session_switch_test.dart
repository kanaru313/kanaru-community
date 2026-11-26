import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../../plugins/domain/chat_test_support.dart';
import 'chat_harness.dart';

/// A store whose `bind` waits for [hold]: the rebind of a switch is stuck
/// there while the test acts.
class _HoldingStore extends ConversationStore {
  _HoldingStore(super.db);

  Completer<void>? hold;
  final reached = Completer<void>();

  @override
  Future<void> bind(
    int id, {
    required String? installId,
    required int? installGeneration,
    String? model,
  }) async {
    final h = hold;
    if (h != null && !reached.isCompleted) {
      reached.complete();
      await h.future;
    }
    return super.bind(
      id,
      installId: installId,
      installGeneration: installGeneration,
      model: model,
    );
  }
}

void main() {
  late ChatHarness t;
  late _HoldingStore store;

  setUp(() async {
    t = await ChatHarness.create(makeStore: (db) => store = _HoldingStore(db));
  });
  tearDown(() async => t.dispose());

  int openId() => t.session.state.conversationId!;

  test(
    'a send during switchModel is refused, then uses the new model',
    () async {
      await t.session.newConversation();
      store.hold = Completer<void>();
      final switching = t.session.switchModel('other-model');
      await store.reached.future;

      final during = await t.session.send('too early');

      expect(during, isA<SendBusy>());
      expect(t.engine.inputs, isEmpty);
      expect(await t.store.latestSeq(openId()), 0);

      store.hold!.complete();
      await switching;
      await t.sendAndWait('now');

      expect(t.engine.inputs.single['model'], 'other-model');
      final rows = await t.store.messages(openId());
      expect(rows.map((m) => m.message.role), [
        AiMessageRole.user,
        AiMessageRole.assistant,
      ]);
      expect(rows.last.message.state, AiMessageState.complete);
    },
  );

  test(
    'a send during switchPlugin is refused, then uses the new plugin',
    () async {
      await t.r.install(
        manifest: chatManifest((m) {
          (m['metadata']! as Map<String, Object?>)['author'] = 'other';
        }),
        extra: {'src/chat.js': 'function execute(req) { return req; }'},
      );
      final otherId = fileInstallId('Chat', 'other');
      await t.h.config.setValue(otherId, 'apiKeys', 'k');
      await t.h.config.setValue(otherId, 'model', 'gemini-2.5-flash');
      t.container.invalidate(installedPluginsProvider);
      await t.container.read(installedPluginsProvider.future);
      await t.session.newConversation();
      store.hold = Completer<void>();
      final switching = t.session.switchPlugin(otherId);
      await store.reached.future;

      final during = await t.session.send('too early');

      expect(during, isA<SendBusy>());
      expect(t.engine.inputs, isEmpty);

      store.hold!.complete();
      expect(await switching, isTrue);
      await t.sendAndWait('now');

      final conversation = (await t.store.conversation(openId()))!;
      expect(conversation.installId, otherId);
      final rows = await t.store.messages(openId());
      expect(rows.last.message.role, AiMessageRole.assistant);
      expect(rows.last.message.installId, otherId);
      expect(rows.last.message.state, AiMessageState.complete);
    },
  );
}
