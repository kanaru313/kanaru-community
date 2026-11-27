import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/store_filter.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';
import 'package:kanaru/src/screens/plugins/store/store_row.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

ChatPluginInfo _info(ChatReadiness readiness) => ChatPluginInfo(
  installId: 'id-ai',
  installGeneration: 1,
  name: 'Chat',
  version: 1,
  spec: const ChatSpec(),
  models: const [],
  defaultModel: 'm',
  readiness: readiness,
);

Future<void> _pump(
  WidgetTester tester, {
  required ChatReadiness readiness,
  PluginKind kind = PluginKind.aiChat,
  StoreItemState state = StoreItemState.installed,
  bool showSetupStatus = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatPluginsProvider.overrideWithValue(AsyncData([_info(readiness)])),
      ],
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StoreRowFrame(
            row: StoreRowView(
              installId: 'id-ai',
              name: 'Chat',
              author: 'kanaru313',
              kind: kind,
              state: state,
            ),
            showSetupStatus: showSetupStatus,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('ai-chat row without key shows Cần API key', (tester) async {
    await _pump(tester, readiness: const ChatNeedsKey());
    expect(find.text('Needs API key'), findsOneWidget);
  });

  testWidgets('a ready ai-chat row shows no status', (tester) async {
    await _pump(tester, readiness: const ChatReady());
    expect(find.text('Needs API key'), findsNothing);
  });

  testWidgets('a not installed or other kind row shows no status', (
    tester,
  ) async {
    await _pump(
      tester,
      readiness: const ChatNeedsKey(),
      state: StoreItemState.notInstalled,
    );
    expect(find.text('Needs API key'), findsNothing);
    await _pump(
      tester,
      readiness: const ChatNeedsKey(),
      kind: PluginKind.lyrics,
    );
    expect(find.text('Needs API key'), findsNothing);
  });

  testWidgets('an update row with an empty key shows no status', (
    tester,
  ) async {
    await _pump(
      tester,
      readiness: const ChatNeedsKey(),
      state: StoreItemState.updateAvailable,
      showSetupStatus: false,
    );
    expect(find.text('Needs API key'), findsNothing);
  });
}
