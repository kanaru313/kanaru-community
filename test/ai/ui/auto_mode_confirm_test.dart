import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/ui/auto_mode_confirm.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/kanaru_ui_finders.dart';
import '../../support/memory_settings_store.dart';

/// A button that opens the box for [scope] and keeps what it answered.
class _Host {
  _Host(this.store);

  final MemorySettingsStore store;
  bool? answer;

  Future<void> pump(WidgetTester tester, AutoModeScope scope) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async =>
                    answer = await confirmAutoMode(context, ref, scope: scope),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('cancel returns false and keeps the flag', (tester) async {
    final host = _Host(MemorySettingsStore());
    await host.pump(tester, AutoModeScope.conversation);
    await host.open(tester);
    await tester.tap(find.text('Show this again next time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(host.answer, false);
    expect(host.store.read('ai.auto_ask'), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('confirming with the check ticked keeps asking', (tester) async {
    final host = _Host(MemorySettingsStore());
    await host.pump(tester, AutoModeScope.conversation);
    await host.open(tester);
    expect(byCheckState(KCheckState.on), findsOneWidget);
    await tester.tap(find.text('Turn on Automatic'));
    await tester.pumpAndSettle();
    expect(host.answer, true);
    expect(host.store.read('ai.auto_ask'), isNull);
    expect(find.text('This chat: Automatic'), findsOneWidget);
  });

  testWidgets('unticking writes ai.auto_ask false', (tester) async {
    final host = _Host(MemorySettingsStore());
    await host.pump(tester, AutoModeScope.defaultForNew);
    await host.open(tester);
    await tester.tap(find.text('Show this again next time'));
    await tester.pumpAndSettle();
    expect(byCheckState(KCheckState.on), findsNothing);
    await tester.tap(find.text('Turn on Automatic'));
    await tester.pumpAndSettle();
    expect(host.answer, true);
    expect(host.store.read('ai.auto_ask'), false);
    expect(find.textContaining('will not ask next time'), findsOneWidget);
  });

  testWidgets('conversation and default scopes show their titles', (
    tester,
  ) async {
    final conversation = _Host(MemorySettingsStore());
    await conversation.pump(tester, AutoModeScope.conversation);
    await conversation.open(tester);
    expect(find.text('Turn on Automatic for this chat?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final fresh = _Host(MemorySettingsStore());
    await fresh.pump(tester, AutoModeScope.defaultForNew);
    await fresh.open(tester);
    expect(find.text('Turn on Automatic for new chats?'), findsOneWidget);
  });

  testWidgets('with the question turned off nothing is asked', (tester) async {
    final store = MemorySettingsStore();
    await store.write('ai.auto_ask', false);
    final host = _Host(store);
    await host.pump(tester, AutoModeScope.conversation);
    await host.open(tester);
    expect(host.answer, true);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
