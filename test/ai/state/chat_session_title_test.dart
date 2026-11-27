import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../../plugins/domain/chat_test_support.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/state/chat_conversation_providers.dart';
import 'package:kanaru/src/ai/ui/chat_header_title.dart';
import 'package:material_ui/material_ui.dart';

import 'chat_harness.dart';

const _question = 'How many songs are in my library';

void main() {
  late ChatHarness t;
  setUp(() async => t = await ChatHarness.create());
  tearDown(() async => t.dispose());

  test('a conversation opened by newConversation is titled by its first '
      'message, and the header provider shows it', () async {
    t.engine.rounds.add(ScriptedRound.reply('Four'));
    final id = await t.session.newConversation();
    final titles = <String?>[];
    final sub = t.container.listen(
      chatConversationProvider(id),
      (_, next) => titles.add(next.value?.title),
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await t.sendAndWait(_question);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect((await t.store.conversation(id))!.title, _question);
    expect(
      t.container.read(chatConversationProvider(id)).value?.title,
      _question,
    );
    expect(titles.last, _question);
  });

  test('a plugin switch before the first message still lets it title the '
      'conversation', () async {
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
    t.engine.rounds.add(ScriptedRound.reply('Four'));
    final id = await t.session.newConversation();
    expect(await t.session.switchPlugin(otherId), isTrue);

    await t.sendAndWait(_question);

    expect((await t.store.conversation(id))!.title, _question);
  });

  testWidgets('the header title changes from the empty name to the first '
      'message', (tester) async {
    await tester.runAsync(() async {
      t.engine.rounds.add(ScriptedRound.reply('Four'));
      await t.session.newConversation();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: t.container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ChatHeaderTitle(style: TextStyle())),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.text('New conversation'), findsOneWidget);

    await tester.runAsync(() async {
      await t.sendAndWait(_question);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump();

    expect(find.text(_question), findsOneWidget);
  });
}
