import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/ai/ui/chat_host.dart';
import 'package:kanaru/src/ai/ui/composer/composer.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/chat_ui_support.dart';

/// An installed chat plugin with two models (one of them added by the user).
ChatPluginInfo chatPlugin({
  String id = 'p1',
  String name = 'Claude',
  ChatReadiness readiness = const ChatReady(),
  bool keyed = true,
  bool tools = true,
}) {
  final caps = ChatCapabilities(tools: tools, vision: true, context: 200000);
  return ChatPluginInfo(
    installId: id,
    installGeneration: 1,
    name: name,
    version: 1,
    spec: ChatSpec(keyField: keyed ? 'apiKey' : null, custom: caps),
    models: [
      ChatModelOption(id: 'm1', title: 'Model 1', capabilities: caps),
      const ChatModelOption(
        id: 'm2',
        title: 'Model 2',
        capabilities: ChatCapabilities(context: 32000),
        isCustom: true,
      ),
    ],
    defaultModel: 'm1',
    readiness: readiness,
  );
}

class ComposerSetup {
  ComposerSetup(this.tester, this.container, this.session, this.host);

  final WidgetTester tester;
  final ProviderContainer container;
  final FakeChatSession session;
  final RecordingChatHost host;

  /// The `send` calls the session recorded.
  List<String> get sends =>
      session.calls.where((c) => c.startsWith('send')).toList();

  TextEditingController get controller =>
      tester.widget<TextField>(find.byType(TextField)).controller!;
}

/// The composer alone at the bottom of a window of [size] (desktop shell at
/// 1280, phone shell below 1200), over a fake session bound to the plugin
/// `p1` and its model `m1`.
Future<ComposerSetup> pumpComposer(
  WidgetTester tester, {
  Size size = const Size(1280, 800),
  ChatReadiness readiness = const ChatReady(),
  List<ChatPluginInfo>? plugins,
  bool promptChips = false,
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final session = FakeChatSession();
  final host = RecordingChatHost();
  final container = ProviderContainer(
    overrides: [
      ...chatUiOverrides(session: session, plugins: plugins ?? [chatPlugin()]),
      chatHostProvider.overrideWithValue(host),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  container
      .read(fakeChatBindingProvider.notifier)
      .set(installId: 'p1', model: 'm1');
  container.read(fakeChatReadinessProvider.notifier).set(readiness);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Composer(showPromptChips: promptChips)],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return ComposerSetup(tester, container, session, host);
}

/// Types [text] into the field (the field takes focus).
Future<void> typeInComposer(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

/// Presses Enter with the field focused.
Future<void> pressEnter(WidgetTester tester, {bool shift = false}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pump();
}
