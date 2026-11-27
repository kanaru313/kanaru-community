import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/conversation/track_ref_snapshot.dart';
import 'package:kanaru/src/ai/domain/output/chat_outcome.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/ai/state/chat_view/card_view.dart';
import 'package:kanaru/src/ai/ui/cards/chat_cards.dart';
import 'package:kanaru/src/ai/ui/cards/playlist_link.dart';
import 'package:kanaru/src/ai/ui/chat_host.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart'
    show trackRowLoaderProvider;
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/chat_ui_support.dart';

/// The installed plugin of the cards' messages ([chatMessage] has none; the
/// card tests set it on the message).
const cardPluginId = 'plugin-1';

/// A call of a write tool.
ToolCallPart writeCall(
  String name,
  Map<String, Object?> args, {
  String id = 't1-r1-1',
}) => ToolCallPart.parsed(id: id, name: name, args: args);

/// A tool row (a confirmation, a result, a skipped call) of the card tests.
AiMessage toolRow(
  int id, {
  required AiMessageState state,
  required List<AiPart> parts,
}) => chatMessage(id, role: AiMessageRole.tool, state: state, parts: parts);

/// A user message, to make the rows before it an older turn.
AiMessage userRow(int id) =>
    chatMessage(id, role: AiMessageRole.user, parts: [const TextPart('hi')]);

/// A failed assistant message with its stored error.
AiMessage failedRow(
  int id, {
  String code = 'server',
  String kind = 'server',
  DateTime? retryAt,
  AiMessageState state = AiMessageState.error,
  String installId = cardPluginId,
}) => AiMessage(
  id: id,
  conversationId: 1,
  seq: id,
  role: AiMessageRole.assistant,
  parts: [
    const TextPart('Mình đã chọn 6 bài'),
    ErrorPart(code: code, kind: kind, retryAt: retryAt),
  ],
  state: state,
  createdAt: DateTime(2026, 11, 27, 14, 32),
  installId: installId,
  model: 'claude-sonnet-4-5',
);

/// [count] songs with the titles "Bài 0", "Bài 1", ...
List<TrackRefSnapshot> songsOf(int count) => [
  for (var i = 0; i < count; i++)
    TrackRefSnapshot(trackId: 100 + i, title: 'Bài $i', artist: 'Nghệ sĩ $i'),
];

/// What a card test sees: the container, the fake session and host.
class CardSetup {
  CardSetup(this.container, this.session, this.host, this.shown);

  final ProviderContainer container;
  final FakeChatSession session;
  final RecordingChatHost host;
  final ValueNotifier<AiMessage> shown;

  /// Shows [message] in the card's place and lets the frames settle.
  Future<void> show(WidgetTester tester, AiMessage message) async {
    shown.value = message;
    await settle(tester);
  }
}

/// A few frames: providers resolve, then the card rebuilds.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
}

/// Pumps the card of [message] (through the same builder the message list
/// uses) over fake engine providers, in Vietnamese. [messages] are the rows of
/// the conversation (default: only [message], so it is the newest of the
/// latest turn); [size] picks the shell.
Future<CardSetup> pumpCard(
  WidgetTester tester,
  AiMessage message, {
  List<AiMessage>? messages,
  Size size = const Size(400, 900),
  ChatOutcomeView? view,
  DateTime Function()? clock,
  ToolPreview? preview,
  Map<int, TrackInfo> library = const {},
  String? pluginHost = 'api.anthropic.com',
  List<Override> extra = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final session = FakeChatSession();
  final host = RecordingChatHost();
  final container = ProviderContainer(
    overrides: [
      ...chatUiOverrides(session: session),
      chatHostProvider.overrideWithValue(host),
      trackInfoProvider.overrideWith(
        (ref, id) => Stream.value(library[id.value]),
      ),
      trackRowLoaderProvider.overrideWithValue(
        (ids) async => [for (final id in ids) ?library[id.value]],
      ),
      chatConfirmPreviewProvider.overrideWith((ref, call) async => preview),
      chatCardHostProvider.overrideWith((ref, installId) async => pluginHost),
      chatPlaylistLocationProvider.overrideWithValue(
        (id) async => id == null ? '/playlists' : '/playlists/p$id',
      ),
      if (clock != null) chatCardClockProvider.overrideWithValue(clock),
      ...extra,
    ],
  );
  addTearDown(container.dispose);
  container.read(fakeChatMessagesProvider.notifier).set(messages ?? [message]);
  // Build the session so a live outcome can be set on it.
  container.read(chatSessionProvider);
  session.setView(view);
  final shown = ValueNotifier(message);
  addTearDown(shown.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('vi'),
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder<AiMessage>(
              valueListenable: shown,
              builder: (context, m, _) =>
                  buildChatCard(context, m) ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ),
  );
  await settle(tester);
  return CardSetup(container, session, host, shown);
}

/// No action button on the card (the text buttons of a song list are not
/// actions).
void expectNoButtons() {
  expect(find.byType(OutlinedButton), findsNothing);
  expect(find.byType(FilledButton), findsNothing);
}

/// The button labelled [label] is the card's only action: on a row of its own
/// and, like every one-button card, at the end of it.
void expectButtonAtEnd(WidgetTester tester, String label) {
  final card = tester.getRect(find.byType(KActionCard));
  final button = tester.getRect(find.widgetWithText(OutlinedButton, label));
  expect(button.width, lessThan(card.width / 2));
  expect(card.right - button.right, closeTo(KSpace.x3, 0.01));
}
