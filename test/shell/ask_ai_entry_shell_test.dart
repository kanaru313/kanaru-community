import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/ai/ai_extension.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/state/chat_attachments.dart';
import 'package:kanaru/src/ai/state/chat_view/chat_view_state.dart';
import 'package:kanaru/src/ai/ui/chat_page_mobile.dart';
import 'package:kanaru/src/ai/ui/chat_surface.dart';
import 'package:kanaru/src/ai/ui/composer/composer.dart';
import 'package:kanaru/src/library/domain/ask_ai_target.dart';
import 'package:kanaru/src/library/ui/menus/ask_ai_entry.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/shell/state/right_panel.dart';
import 'package:material_ui/material_ui.dart';

import '../ai/ui/support/chat_ui_support.dart';
import '../support/app_harness.dart';
import '../support/nav_fixture.dart';

const _song = AskAiTarget.song(AskAiTrack(id: 5, title: 'So What'));

/// The whole app (router, shell) with the chat and the shell's Ask AI entry.
Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required double width,
}) => pumpKanaruApp(
  tester,
  extensions: [const NavFixture(), const AiExtension()],
  width: width,
  overrides: [
    ...chatUiOverrides(session: FakeChatSession()),
    chatHostOverride,
    askAiEntryOverride,
  ],
);

/// Locations of the router's stack, top last.
List<String> _stack(ProviderContainer c) => [
  for (final m
      in c.read(routerProvider).routerDelegate.currentConfiguration.matches)
    m.matchedLocation,
];

Future<void> _ask(
  WidgetTester tester,
  ProviderContainer container,
  AskAiTarget target, {
  Finder? from,
}) async {
  final context = tester.element(from ?? find.byType(Scaffold).first);
  await container.read(askAiEntryProvider)!.ask(context, target);
  await tester.pumpAndSettle();
}

bool _composerFocused(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byType(Composer),
        matching: find.byType(EditableText),
      ),
    )
    .focusNode
    .hasFocus;

void main() {
  testWidgets('desktop opens panel and attaches chip', (tester) async {
    final container = await _pumpApp(tester, width: 1280);
    expect(container.read(rightPanelProvider), RightPanelKind.closed);

    await _ask(tester, container, _song);

    expect(container.read(rightPanelProvider), RightPanelKind.chat);
    expect(find.byType(ChatSurface), findsOneWidget);
    final attached = container.read(chatAttachmentsProvider).attached;
    expect(attached.single.kind, ChipKind.song);
    expect(attached.single.tracks.single.trackId, 5);
    expect(_stack(container), isNot(contains('/chat')));
  });

  testWidgets('desktop swaps the queue panel to the chat', (tester) async {
    final container = await _pumpApp(tester, width: 1280);
    container.read(rightPanelProvider.notifier).show(RightPanelKind.queue);
    await tester.pumpAndSettle();

    await _ask(tester, container, const AskAiTarget.nowPlaying());

    expect(container.read(rightPanelProvider), RightPanelKind.chat);
    expect(
      container.read(chatAttachmentsProvider).attached.single.kind,
      ChipKind.nowPlaying,
    );
  });

  testWidgets('mobile pushes /chat and attaches chip', (tester) async {
    final container = await _pumpApp(tester, width: 400);
    expect(find.byType(ChatPageMobile), findsNothing);

    await _ask(tester, container, _song);

    expect(find.byType(ChatPageMobile), findsOneWidget);
    expect(_stack(container).where((l) => l == '/chat'), hasLength(1));
    expect(_stack(container).last, '/chat');
    expect(
      container.read(chatAttachmentsProvider).attached.single.kind,
      ChipKind.song,
    );
  });

  testWidgets('ask from a track row inside the chat does not push', (
    tester,
  ) async {
    final container = await _pumpApp(tester, width: 400);
    await _ask(tester, container, const AskAiTarget.nowPlaying());
    expect(_stack(container).where((l) => l == '/chat'), hasLength(1));

    // The song menu of a row in the chat asks from inside the chat page.
    await _ask(tester, container, _song, from: find.byType(ChatSurface));

    expect(_stack(container).where((l) => l == '/chat'), hasLength(1));
    expect(_stack(container).last, '/chat');
    expect(
      [
        for (final c in container.read(chatAttachmentsProvider).attached)
          c.kind,
      ],
      [ChipKind.nowPlaying, ChipKind.song],
    );
  });

  testWidgets('asking twice for the same thing attaches one chip', (
    tester,
  ) async {
    final container = await _pumpApp(tester, width: 1280);
    await _ask(tester, container, _song);
    await _ask(tester, container, _song);
    expect(container.read(chatAttachmentsProvider).attached, hasLength(1));
  });

  testWidgets('history gives way to the conversation', (tester) async {
    final container = await _pumpApp(tester, width: 1280);
    await _ask(tester, container, _song);
    container.read(chatViewProvider.notifier).openHistory();
    await tester.pumpAndSettle();

    await _ask(tester, container, const AskAiTarget.nowPlaying());

    expect(container.read(chatViewProvider).historyOpen, isFalse);
  });

  testWidgets('composer focused', (tester) async {
    final container = await _pumpApp(tester, width: 1280);
    await _ask(tester, container, _song);
    expect(_composerFocused(tester), isTrue);
  });
}
