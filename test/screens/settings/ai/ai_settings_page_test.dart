import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/screens/plugins/store/store_page.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/kanaru_ui_finders.dart';
import '../../../support/memory_settings_store.dart';
import '../support/settings_host.dart';
import 'ai_settings_host.dart';

/// Where the top page is, also after a push.
String _location(SettingsHarness h) =>
    h.router.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('sections in order', (tester) async {
    await openAiSettings(tester, services: [service('a')]);
    final tops = [
      for (final t in [
        'AI services',
        'Permission',
        'General instructions',
        'Tools',
      ])
        tester.getTopLeft(find.text(t)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(tops.toSet(), hasLength(4));
    expect(find.text('AI chat'), findsOneWidget);
  });

  group('services', () {
    testWidgets('a ready service shows its model, the last used one says so', (
      tester,
    ) async {
      final store = MemorySettingsStore();
      await store.write('ai.last_plugin', 'a');
      await openAiSettings(
        tester,
        store: store,
        services: [
          service('a', name: 'Gemini', model: 'gemini-2.5-flash'),
          service('b', name: 'Other', model: 'm-2'),
        ],
      );
      expect(find.text('gemini-2.5-flash · last used'), findsOneWidget);
      expect(find.text('m-2'), findsOneWidget);
    });

    testWidgets('services list shows needs-key in error colour', (
      tester,
    ) async {
      final h = await openAiSettings(
        tester,
        services: [service('k', readiness: const ChatNeedsKey())],
      );
      final style = tester.widget<Text>(find.text('Needs API key')).style;
      expect(
        style?.color,
        Theme.of(tester.element(find.text('Needs API key'))).colorScheme.error,
      );
      expect(h.container, isNotNull);
    });

    testWidgets('other needs are told in words, in error colour', (
      tester,
    ) async {
      await openAiSettings(
        tester,
        services: [
          service('m', readiness: const ChatNeedsModel()),
          service(
            'c',
            readiness: const ChatNeedsConfig(['Endpoint', 'Region']),
          ),
        ],
      );
      expect(find.text('No model chosen'), findsOneWidget);
      expect(find.text('Needs setup: Endpoint, Region'), findsOneWidget);
    });

    testWidgets('a tap on a service opens its plugin page', (tester) async {
      final h = await openAiSettings(
        tester,
        services: [service('p 1', name: 'Gemini')],
      );
      await tester.tap(find.text('Gemini'));
      await tester.pumpAndSettle();
      expect(_location(h), '/settings/plugins/p/p%201');
    });

    testWidgets('add service opens the store filtered to AI', (tester) async {
      final h = await openAiSettings(tester);
      await tester.tap(find.text('Add AI service'));
      await tester.pumpAndSettle();
      expect(_location(h), '/settings/plugins');
      expect(tester.widget<StorePage>(find.byType(StorePage)).kind, 'aiChat');
    });

    testWidgets('no service: the empty note and the add row', (tester) async {
      await openAiSettings(tester);
      expect(find.textContaining('No AI service installed'), findsOneWidget);
      expect(find.text('Add AI service'), findsOneWidget);
    });

    testWidgets('while loading there is no empty note', (tester) async {
      await openAiSettings(tester, services: null);
      expect(find.textContaining('No AI service installed'), findsNothing);
      expect(find.text('Add AI service'), findsOneWidget);
    });

    testWidgets('removed last-used plugin shows the fallback line', (
      tester,
    ) async {
      final store = MemorySettingsStore();
      await store.write('ai.last_plugin', 'gone');
      await openAiSettings(
        tester,
        store: store,
        removedNames: {'gone': 'Gemini'},
        services: [service('x', name: 'OpenAI-compatible')],
      );
      expect(
        find.text(
          'The service you used last (Gemini) was removed. New chats use '
          'OpenAI-compatible until you pick another service in the chat.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('last used'), findsNothing);
    });

    testWidgets('an installed last-used plugin has no fallback line', (
      tester,
    ) async {
      final store = MemorySettingsStore();
      await store.write('ai.last_plugin', 'x');
      await openAiSettings(tester, store: store, services: [service('x')]);
      expect(find.textContaining('was removed'), findsNothing);
    });
  });

  group('permission', () {
    testWidgets('default permission selection via bySemanticsSelected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = await openAiSettings(tester);
      await tester.tap(find.text('Default permission for new chats'));
      await tester.pumpAndSettle();
      expect(bySemanticsSelected('Ask first'), findsWidgets);
      expect(bySemanticsSelected('Read only'), findsNothing);
      await tester.tap(find.text('Read only'));
      await tester.pumpAndSettle();
      expect(h.store.read('ai.default_permission'), 'readOnly');
      handle.dispose();
    });

    testWidgets('picking Tự động shows the default-scope confirm', (
      tester,
    ) async {
      final h = await openAiSettings(tester);
      await tester.tap(find.text('Default permission for new chats'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Automatic'));
      await tester.pumpAndSettle();
      expect(find.text('Turn on Automatic for new chats?'), findsOneWidget);
      // Cancel: the picker stays open and nothing is saved.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Makes changes without asking'), findsOneWidget);
      expect(h.store.read('ai.default_permission'), isNull);
      await tester.tap(find.text('Automatic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turn on Automatic'));
      await tester.pumpAndSettle();
      expect(h.store.read('ai.default_permission'), 'auto');
      expect(h.store.read('ai.auto_ask'), isNull);
      expect(find.text('New chats: Automatic'), findsOneWidget);
    });

    testWidgets('with the question turned off, Automatic applies at once', (
      tester,
    ) async {
      final store = MemorySettingsStore();
      await store.write('ai.auto_ask', false);
      await openAiSettings(tester, store: store);
      await tester.tap(find.text('Default permission for new chats'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Automatic'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(store.read('ai.default_permission'), 'auto');
    });
  });

  group('instructions', () {
    testWidgets('instructions counter and 2000 limit persist', (tester) async {
      final h = await openAiSettings(tester);
      final field = find.byType(TextField);
      expect(find.text('0 / 2,000'), findsOneWidget);
      await tester.enterText(field, 'Answer briefly');
      await tester.pump();
      expect(find.text('14 / 2,000'), findsOneWidget);
      expect(h.store.read('ai.instructions'), 'Answer briefly');
      await tester.enterText(field, 'x' * 2100);
      await tester.pump();
      expect((h.store.read('ai.instructions') as String).length, 2000);
      expect(find.text('2,000 / 2,000'), findsOneWidget);
    });

    testWidgets('a long text of multi-code-point characters is cut at 2000', (
      tester,
    ) async {
      final h = await openAiSettings(tester);
      // Thumbs-up with a skin tone: one character, two code points.
      await tester.enterText(find.byType(TextField), '👍🏽' * 1100);
      await tester.pump();
      final saved = h.store.read('ai.instructions') as String;
      expect(saved.runes.length, lessThanOrEqualTo(2000));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        saved,
      );
    });
  });

  group('tools', () {
    testWidgets('each tool switch writes its own key', (tester) async {
      final handle = tester.ensureSemantics();
      final h = await openAiSettings(tester);
      const titles = {
        AiToolGroup.nowPlaying: 'Now playing',
        AiToolGroup.queue: 'Queue',
        AiToolGroup.librarySearch: 'Search the library',
        AiToolGroup.lyrics: 'Lyrics',
        AiToolGroup.trackInfo: 'Song info',
        AiToolGroup.listeningStats: 'Listening stats',
        AiToolGroup.playlists: 'Playlist list',
        AiToolGroup.playControl: 'Playback control',
        AiToolGroup.queueEdit: 'Edit queue',
        AiToolGroup.playlistCreate: 'Create playlist',
        AiToolGroup.playlistEdit: 'Edit playlist',
      };
      expect(titles.keys, containsAll(AiToolGroup.values));
      var written = <String>{};
      for (final g in AiToolGroup.values) {
        expect(byToggledState(titles[g]!), findsOneWidget);
        await tester.tap(find.text(titles[g]!));
        await tester.pumpAndSettle();
        expect(h.store.read(g.fullKey), false, reason: g.fullKey);
        expect(byToggledState(titles[g]!, on: false), findsOneWidget);
        written.add(g.fullKey);
        // Only the keys tapped so far exist.
        for (final other in AiToolGroup.values) {
          expect(
            h.store.read(other.fullKey) != null,
            written.contains(other.fullKey),
            reason: other.fullKey,
          );
        }
      }
      handle.dispose();
    });

    testWidgets('read and write groups are headed', (tester) async {
      await openAiSettings(tester);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Changes · follow the chat permission'), findsOneWidget);
      expect(
        find.textContaining('variables {{now_playing}}, {{title}}'),
        findsOneWidget,
      );
      expect(find.text('Add, remove'), findsOneWidget);
      expect(
        find.text('Names, song counts and the songs in each playlist'),
        findsOneWidget,
      );
    });

    testWidgets('listening stats locked when history off', (tester) async {
      final store = MemorySettingsStore();
      await store.write('playback.history_enabled', false);
      await openAiSettings(tester, store: store);
      const reason = 'Turn on “Record listening history” in Playback first';
      expect(find.text(reason), findsOneWidget);
      await tester.tap(find.text('Listening stats'));
      await tester.pumpAndSettle();
      expect(store.read('ai.tools.listening_stats'), isNull);
    });

    testWidgets('with the history on, listening stats is a normal switch', (
      tester,
    ) async {
      await openAiSettings(tester);
      expect(find.textContaining('Record listening history'), findsNothing);
    });

    testWidgets('varBypass toggles without a dialog', (tester) async {
      final h = await openAiSettings(tester);
      await tester.tap(find.text('Send variables even when a tool is off'));
      await tester.pumpAndSettle();
      expect(h.store.read('ai.var_bypass'), true);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  testWidgets('root row opens /settings/ai', (tester) async {
    final h = await openAiSettings(
      tester,
      location: SettingsPaths.root,
      size: const Size(400, 1600),
    );
    expect(
      find.text('AI services, permissions, tools, prompts, history'),
      findsOneWidget,
    );
    await tester.tap(find.text('AI chat'));
    await tester.pumpAndSettle();
    expect(_location(h), '/settings/ai');
    expect(find.text('AI services'), findsOneWidget);
    expect(find.byType(SetupSection), findsWidgets);
  });
}
