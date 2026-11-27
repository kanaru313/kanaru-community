import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/data/conversation_rows.dart' show AiChatStats;
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/domain/settings/prompt_template.dart';
import 'package:kanaru/src/ai/state/ai_chat_stats_provider.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/install_ops.dart';
import 'package:kanaru/src/plugins/state/store_filter.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';
import 'package:kanaru/src/screens/plugins/remove/remove_flow.dart';
import 'package:kanaru/src/screens/plugins/store/store_row.dart';
import 'package:kanaru/src/screens/settings/ui/ai/ai_history_section.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../test/screens/plugins/support/install_fixtures.dart';
import '../test/screens/plugins/support/page_fixtures.dart';
import '../test/screens/plugins/support/plugin_fixtures.dart';
import '../test/screens/settings/ai/ai_settings_host.dart';
import '../test/screens/settings/support/settings_host.dart'
    show SettingsHarness;
import '../test/support/memory_settings_store.dart';
import 'support/ai_settings_shots.dart';

/// Settings › Trò chuyện AI (D1) and the AI rows of the plugin screens, on
/// both shell sizes, in Vietnamese. The real Settings and plugin routes and
/// widgets with the engine providers faked (no network, keys, native library
/// or chat UI), so every state is reachable. Asserts state (finders), never
/// pixels; the screenshots are for comparing with `mockups/*/06-settings.html`
/// and `09-plugins` by eye. The prompt editor (D2) is in
/// `ai_prompt_editor_screens_test.dart`.
///
/// Screenshots `NN-<state>-<shell>.png` go to `$KANARU_IT_SHOTS` (default
/// `/tmp/kanaru-it/shots-ai-settings`).
///
/// Not covered here (needs the chat UI, a real plugin or the phone): auto ask
/// turned off from the chat, a real sideloaded chat plugin, Telex IME, the
/// soft warning of the instructions box near its limit (the section has none).

late AppLocalizations _l;

/// A session that only counts the delete.
class _FakeSession extends ChatSessionController {
  _FakeSession(this._turn);

  final TurnState _turn;

  @override
  ChatSessionState build() => ChatSessionState(turnState: _turn);

  @override
  Future<void> deleteAll() async {}
}

ChatPluginInfo _service(
  String id,
  String name,
  String model,
  ChatReadiness readiness,
) => ChatPluginInfo(
  installId: id,
  installGeneration: 1,
  name: name,
  version: 1,
  spec: const ChatSpec(),
  models: const [],
  defaultModel: model,
  readiness: readiness,
);

MemorySettingsStore _promptStore(List<PromptTemplate> list) {
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
      WidgetTester tester, {
      List<ChatPluginInfo>? services = const [],
      MemorySettingsStore? store,
      Map<String, String> removedNames = const {},
      Future<AiChatStats> Function()? stats,
      List<Override> overrides = const [],
      ThemeData? theme,
      double textScale = 1,
    }) => openAiSettings(
      tester,
      size: size,
      locale: aiSettingsLocale,
      services: services,
      store: store,
      removedNames: removedNames,
      stats: stats,
      overrides: overrides,
      theme: theme,
      textScale: textScale,
    );

    group('AI settings, $shell', () {
      testWidgets('01 services: empty', (tester) async {
        await open(tester);
        expect(find.text(_l.aiSetServicesEmpty), findsOneWidget);
        expect(find.text(_l.aiSetServiceAdd), findsOneWidget);
        await shot(tester, '01-services-empty');
      });

      testWidgets('02 services: ready (last used), needs key, needs model', (
        tester,
      ) async {
        final store = MemorySettingsStore();
        await store.write('ai.last_plugin', 'a');
        await open(
          tester,
          store: store,
          services: [
            _service('a', 'Gemini', 'gemini-2.5-flash', const ChatReady()),
            _service('k', 'OpenAI-compatible', 'gpt-x', const ChatNeedsKey()),
            _service('m', 'Claude', 'c-1', const ChatNeedsModel()),
          ],
        );
        expect(
          find.text(_l.aiSetServiceModelLastUsed('gemini-2.5-flash')),
          findsOneWidget,
        );
        final needsKey = find.text(_l.aiSetServiceNeedsKey);
        expect(needsKey, findsOneWidget);
        expect(
          tester.widget<Text>(needsKey).style?.color,
          Theme.of(tester.element(needsKey)).colorScheme.error,
        );
        expect(
          find.text(_l.aiSetServiceNeedsConfig(_l.lyricsTranslateModelTitle)),
          findsOneWidget,
        );
        await shot(tester, '02-services-states');
      });

      testWidgets('03 services: removed last-used line', (tester) async {
        final store = MemorySettingsStore();
        await store.write('ai.last_plugin', 'gone');
        await open(
          tester,
          store: store,
          removedNames: {'gone': 'Gemini'},
          services: [
            _service('x', 'OpenAI-compatible', 'm', const ChatReady()),
          ],
        );
        expect(
          find.text(_l.aiSetServicesGone('Gemini', 'OpenAI-compatible')),
          findsOneWidget,
        );
        await shot(tester, '03-removed-last-used');
      });

      testWidgets('04a permission picker open', (tester) async {
        final handle = tester.ensureSemantics();
        await open(tester);
        await aiSettingsReveal(tester, find.text(_l.aiSetPermRow));
        await tester.tap(find.text(_l.aiSetPermRow));
        await tester.pumpAndSettle();
        expect(find.text(_l.aiSetPermReadOnly), findsOneWidget);
        expect(find.text(_l.aiSetPermAuto), findsOneWidget);
        await shot(tester, '04a-permission-picker');
        handle.dispose();
      });

      testWidgets('04b permission: Tự động confirm, cancel keeps the value', (
        tester,
      ) async {
        final h = await open(tester);
        await aiSettingsReveal(tester, find.text(_l.aiSetPermRow));
        await tester.tap(find.text(_l.aiSetPermRow));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_l.aiSetPermAuto));
        await tester.pumpAndSettle();
        expect(find.text(_l.aiSetAutoTitleDefault), findsOneWidget);
        expect(find.text(_l.aiSetAutoBody), findsOneWidget);
        await shot(tester, '04b-permission-auto-confirm');
        // Cancel: the picker stays open and nothing is saved.
        await tester.tap(find.text(_l.aiSetEdCancel));
        await tester.pumpAndSettle();
        expect(find.text(_l.aiSetAutoTitleDefault), findsNothing);
        expect(h.store.read('ai.default_permission'), isNull);
        expect(find.text(_l.aiSetPermAutoDesc), findsOneWidget);
      });

      testWidgets('05 instructions: counter n / 2.000, over-limit refused', (
        tester,
      ) async {
        final h = await open(tester);
        final field = find.byType(TextField);
        await aiSettingsReveal(tester, field);
        expect(find.text('0 / 2.000'), findsOneWidget);
        // Text is set programmatically (no IME): a long Vietnamese line.
        await tester.enterText(field, 'Trả lời ngắn gọn ' * 100);
        await tester.pump();
        final saved = h.store.read('ai.instructions') as String;
        expect(saved.runes.length, lessThanOrEqualTo(2000));
        expect(find.textContaining(' / 2.000'), findsOneWidget);
        await shot(tester, '05a-instructions-long');

        // Emoji with a skin tone: one character, two code points. At the
        // limit it is whole; one more is refused and the text stays.
        final whole = '👍🏽' * 1000;
        await tester.enterText(field, whole);
        await tester.pump();
        expect(h.store.read('ai.instructions'), whole);
        await tester.enterText(field, '$whole👍🏽');
        await tester.pump();
        expect(tester.widget<TextField>(field).controller!.text, whole);
        expect(h.store.read('ai.instructions'), whole);
        expect(find.text('1.000 / 2.000'), findsOneWidget);
        await shot(tester, '05b-instructions-at-limit');
      });

      testWidgets('06 tools: groups and the locked Thống kê nghe row', (
        tester,
      ) async {
        final store = MemorySettingsStore();
        await store.write('playback.history_enabled', false);
        await open(tester, store: store);
        await aiSettingsReveal(tester, find.text(_l.aiSetToolsGroupRead));
        expect(find.text(_l.aiSetToolsGroupRead), findsOneWidget);
        expect(find.text(_l.aiSetToolsGroupWrite), findsOneWidget);
        await aiSettingsReveal(tester, find.text(_l.aiSetToolListeningStats));
        // The description stays, the locked reason is added under it.
        expect(find.text(_l.aiSetToolListeningStatsDesc), findsOneWidget);
        expect(find.text(_l.aiSetToolsStatsLocked), findsOneWidget);
        await tester.tap(find.text(_l.aiSetToolListeningStats));
        await tester.pumpAndSettle();
        expect(store.read('ai.tools.listening_stats'), isNull);
        await shot(tester, '06-tools-locked-stats');
      });

      testWidgets('07a prompts: the builtins in the order the app shows', (
        tester,
      ) async {
        await open(tester);
        await aiSettingsReveal(tester, find.text(_l.aiSetPromptAdd));
        final order = [
          _l.aiSetTemplateExplainLyricsLabel,
          _l.aiSetTemplateSimilarSongsLabel,
          _l.aiSetTemplateMoodPlaylistLabel,
          _l.aiSetTemplateSongStoryLabel,
          _l.aiSetTemplateTranslateLyricsLabel,
          _l.aiSetTemplateTasteSummaryLabel,
        ];
        final tops = [
          for (final t in order) tester.getTopLeft(find.text(t)).dy,
        ];
        expect(tops, orderedEquals([...tops]..sort()));
        expect(tops.toSet(), hasLength(6));
        await shot(tester, '07a-prompts-builtins');
      });

      testWidgets('07b prompts: Biến lỗi row', (tester) async {
        await open(
          tester,
          store: _promptStore(const [
            PromptTemplate(label: 'Weather', body: 'Is it {{weather}} now?'),
            PromptTemplate(label: 'Fine', body: 'Play {{now_playing}}'),
          ]),
        );
        await aiSettingsReveal(tester, find.text(_l.aiSetPromptBad));
        expect(find.text(_l.aiSetPromptBadLine('{{weather}}')), findsOneWidget);
        await shot(tester, '07b-prompts-broken-variable');
      });

      testWidgets('07c prompts: empty list, Khôi phục toast', (tester) async {
        final h = await open(tester, store: _promptStore([]));
        await aiSettingsReveal(tester, find.text(_l.aiSetPromptRestore));
        expect(find.text(_l.aiSetPromptsEmpty), findsOneWidget);
        await shot(tester, '07c-prompts-empty');
        await tester.tap(find.text(_l.aiSetPromptRestore));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Đã thêm lại 6 prompt có sẵn'), findsOneWidget);
        expect(h.store.read('ai.prompts'), isNotNull);
        await shot(tester, '07d-prompts-restored-toast');
        await tester.pumpAndSettle(const Duration(seconds: 6));
      });

      testWidgets('08a history: N conversations', (tester) async {
        await open(tester);
        await aiSettingsReveal(
          tester,
          find.textContaining('3 cuộc trò chuyện'),
        );
        await shot(tester, '08a-history-n');
      });

      testWidgets('08b history: none, Xoá disabled', (tester) async {
        await open(
          tester,
          stats: () async => const AiChatStats(conversations: 0, bytes: 0),
        );
        await aiSettingsReveal(tester, find.text(_l.aiSetHistNone));
        expect(
          tester
              .widget<TextButton>(
                find.widgetWithText(TextButton, _l.aiSetHistClearButton),
              )
              .onPressed,
          isNull,
        );
        await shot(tester, '08b-history-zero');
      });

      testWidgets('08c history: loading', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              aiChatStatsProvider.overrideWith(
                (ref) => Completer<AiChatStats>().future,
              ),
            ],
            child: MaterialApp(
              theme: buildKanaruTheme(brightness: Brightness.light),
              locale: aiSettingsLocale,
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SingleChildScrollView(child: AiHistorySection()),
              ),
            ),
          ),
        );
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        expect(find.text(_l.aiSetHistLoading), findsOneWidget);
        await shot(tester, '08c-history-loading');
      });

      testWidgets('08d history: error with Thử lại', (tester) async {
        await open(tester, stats: () async => throw StateError('no store'));
        await aiSettingsReveal(tester, find.text(_l.aiSetHistErrorTitle));
        expect(find.text(_l.aiSetHistRetry), findsOneWidget);
        await shot(tester, '08d-history-error');
      });

      for (final (label, turn, tag) in [
        ('idle', TurnState.idle, '09a-clear-all'),
        ('active turn', TurnState.streaming, '09b-clear-all-active-turn'),
      ]) {
        testWidgets('09 Xoá tất cả dialog ($label)', (tester) async {
          await open(
            tester,
            overrides: [
              chatSessionProvider.overrideWith(() => _FakeSession(turn)),
            ],
          );
          final button = find.widgetWithText(
            TextButton,
            _l.aiSetHistClearButton,
          );
          await aiSettingsReveal(tester, button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.text(_l.aiSetHistDialogTitle), findsOneWidget);
          expect(
            find.textContaining(_l.aiSetHistDialogStop),
            turn == TurnState.idle ? findsNothing : findsOneWidget,
          );
          await shot(tester, tag);
        });
      }

      testWidgets('10 Hộp xác nhận section (auto ask off)', (tester) async {
        final store = MemorySettingsStore();
        await store.write('ai.auto_ask', false);
        final h = await open(tester, store: store);
        await aiSettingsReveal(tester, find.text(_l.aiSetConfirmTitle));
        expect(find.text(_l.aiSetConfirmRow), findsOneWidget);
        await shot(tester, '10-confirm-box');
        await tester.tap(find.text(_l.aiSetConfirmOn));
        await tester.pumpAndSettle();
        expect(h.store.read('ai.auto_ask'), anyOf(isNull, isTrue));
      });

      testWidgets('11a text scale 2.0', (tester) async {
        await open(
          tester,
          textScale: 2,
          services: [
            _service('k', 'OpenAI-compatible', 'g', const ChatNeedsKey()),
          ],
        );
        expect(find.text(_l.aiSetServicesTitle), findsOneWidget);
        await shot(tester, '11a-text-scale-2');
      });

      testWidgets('11b dark theme', (tester) async {
        await open(
          tester,
          theme: buildKanaruTheme(brightness: Brightness.dark),
          services: [
            _service('a', 'Gemini', 'gemini-2.5-flash', const ChatReady()),
          ],
        );
        expect(find.text(_l.aiSetServicesTitle), findsOneWidget);
        await shot(tester, '11b-dark');
      });
    });

    group('AI rows on the plugin screens, $shell', () {
      testWidgets('12a plugin page: Dùng trong Trò chuyện AI row', (
        tester,
      ) async {
        await pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: size,
          locale: aiSettingsLocale,
          overrides: pageOverrides(
            AsyncData(pageData(row: pageRow(kind: 'ai-chat'))),
          ),
        );
        expect(find.text(_l.aiSetPluginUse), findsOneWidget);
        expect(find.text(_l.aiSetPluginUseAt), findsOneWidget);
        await shot(tester, '12a-plugin-page-ai-row');
      });

      testWidgets('12b remove dialog of an ai-chat plugin', (tester) async {
        final ops = FakeInstallOps()
          ..preview = const RemovePreview(
            installId: 'id-demo',
            name: 'Demo',
            author: 'someone',
            version: 3,
            kind: PluginKind.aiChat,
          );
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          locale: aiSettingsLocale,
          onTap: (c) => removePluginFlow(c, ops, 'id-demo'),
        );
        expect(find.text(_l.pluginsRemoveKeep), findsOneWidget);
        expect(find.text(_l.aiSetRemoveKeepChats), findsOneWidget);
        await shot(tester, '12b-remove-ai-chat');
      });

      testWidgets('12c store Installed row: Cần API key', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              chatPluginsProvider.overrideWithValue(
                AsyncData([
                  _service('id-ai', 'Chat', 'm', const ChatNeedsKey()),
                ]),
              ),
            ],
            child: MaterialApp(
              theme: buildKanaruTheme(brightness: Brightness.light),
              locale: aiSettingsLocale,
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: StoreRowFrame(
                  row: StoreRowView(
                    installId: 'id-ai',
                    name: 'Chat',
                    author: 'kanaru313',
                    kind: PluginKind.aiChat,
                    state: StoreItemState.installed,
                  ),
                  showSetupStatus: true,
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        expect(find.text(_l.aiSetServiceNeedsKey), findsOneWidget);
        await shot(tester, '12c-store-row-needs-key');
      });
    });
  }
}
