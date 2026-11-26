import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/state/ai_conversation_store_provider.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool_registry.dart';
import 'package:kanaru/src/ai/domain/tools/read_tools.dart';
import 'package:kanaru/src/ai/domain/tools/write_tools.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/ai/state/tool_env_provider.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_log_reader.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/state/plugin_actions_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../../plugins/data/install_test_support.dart';
import '../../plugins/domain/chat_test_support.dart';
import '../../plugins/run/support/runner_support.dart';
import '../../support/memory_settings_store.dart';
import '../domain/tools/fake_tool_env.dart';
import 'scripted_chat_engine.dart';

export 'scripted_chat_engine.dart';

/// A log reader that records the clears.
class RecordingLogReader extends PluginLogReader {
  RecordingLogReader(super.log);

  final cleared = <String>[];

  @override
  Future<void> clearLog(String installId) async => cleared.add(installId);
}

/// The chat session over an in-memory database, a real plugin runner and a
/// scripted streaming engine, with one `ai-chat` plugin installed and ready.
class ChatHarness {
  ChatHarness._();

  late final InstallHarness h;
  late final RunnerHarness r;
  late final ScriptedChatEngine engine;
  late final RecordingLogReader logs;
  late final ProviderContainer container;
  late final FakePlaybackWrite playbackWrite;
  final settings = MemorySettingsStore();
  final installId = fileInstallId('Chat', 'someone');

  static Future<ChatHarness> create({
    bool ready = true,
    Duration streamWait = const Duration(seconds: 10),
    List<AiTool> tools = const [],
    FakePlaybackWrite? playbackWrite,
  }) async {
    final c = ChatHarness._();
    c.playbackWrite = playbackWrite ?? FakePlaybackWrite();
    c.h = InstallHarness();
    c.engine = ScriptedChatEngine();
    c.r = RunnerHarness(c.h, engine: c.engine, streamWait: streamWait);
    await c.r.install(
      manifest: chatManifest((m) {
        (m['metadata']! as Map<String, Object?>)['author'] = 'someone';
      }),
      extra: {'src/chat.js': 'function execute(req) { return req; }'},
    );
    if (ready) await c.configure();
    c.logs = RecordingLogReader(c.h.logs);
    c.container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(c.h.db),
        settingsStoreProvider.overrideWithValue(c.settings),
        pluginRowsProvider.overrideWithValue(c.h.rows),
        pluginConfigStoreProvider.overrideWithValue(c.h.config),
        pluginRunnerProvider.overrideWithValue(c.r.runner),
        pluginPausesProvider.overrideWithValue(c.r.pauses),
        pluginLogReaderProvider.overrideWithValue(c.logs),
        toolEnvFactoryProvider.overrideWithValue(
          (_) => fakeEnv(playbackWrite: c.playbackWrite),
        ),
        aiToolRegistryProvider.overrideWithValue(
          AiToolRegistry([
            readToolProvider,
            writeToolProvider,
            BuiltinToolProvider(tools),
          ]),
        ),
      ],
    );
    // Keep the session alive like the app does.
    c.container.listen(chatSessionProvider, (_, _) {});
    await c.container.read(installedPluginsProvider.future);
    return c;
  }

  /// Gives the plugin a key and a model.
  Future<void> configure() async {
    await h.config.setValue(installId, 'apiKeys', 'k');
    await h.config.setValue(installId, 'model', 'gemini-2.5-flash');
  }

  ChatSessionController get session =>
      container.read(chatSessionProvider.notifier);
  ConversationStore get store => container.read(aiConversationStoreProvider);

  /// Sends [text] and waits until the turn parks or ends.
  Future<SendSent> sendAndWait(String text) async {
    final result = await session.send(text);
    if (result is! SendSent) throw StateError('send was $result');
    await result.done;
    return result;
  }

  var _containerDisposed = false;

  /// Disposes the container (the app closing) without the database.
  void disposeContainer() {
    if (_containerDisposed) return;
    _containerDisposed = true;
    container.dispose();
  }

  Future<void> dispose() async {
    disposeContainer();
    r.dispose();
    await h.dispose();
  }
}
