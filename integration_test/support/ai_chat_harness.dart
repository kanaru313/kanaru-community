import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/ai/ai_extension.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/ai/state/chat_view/card_view.dart';
import 'package:kanaru/src/ai/state/chat_view/chat_view_state.dart';
import 'package:kanaru/src/ai/ui/cards/playlist_link.dart';
import 'package:kanaru/src/ai/ui/track_actions.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart'
    show trackRowLoaderProvider;
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';
import 'package:kanaru/src/shell/state/right_panel.dart';
import 'package:material_ui/material_ui.dart';

import '../../test/ai/ui/composer/composer_harness.dart' show chatPlugin;
import '../../test/ai/ui/support/chat_list_harness.dart'
    show RecordingTrackActions;
import '../../test/ai/ui/support/chat_ui_support.dart';
import '../../test/support/app_harness.dart';
import '../../test/support/icon_button_finders.dart';
import '../../test/support/nav_fixture.dart';

enum ChatShell { phone, desktop }

const phoneSize = Size(412, 915);
const desktopSize = Size(1400, 1000);
const chatPluginId = 'plugin-1';

/// Writes a screenshot of the root layer to the shots folder. For the eye
/// only: a failure is logged, never fails the test.
Future<void> chatShot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(() async {
    try {
      final view = tester.binding.renderViews.first;
      final layer = view.debugLayer! as OffsetLayer;
      final image = await layer.toImage(Offset.zero & view.size);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final dir = Directory(
        Platform.environment['KANARU_IT_SHOTS'] ??
            '/tmp/kanaru-it/shots-ai-chat',
      )..createSync(recursive: true);
      File('${dir.path}/$name.png')
          .writeAsBytesSync(bytes.buffer.asUint8List());
    } on Object catch (e) {
      debugPrint('screenshot $name failed: $e');
    }
  });
}

/// The chat under test, on one shell.
class ChatUnderTest {
  ChatUnderTest(
    this.tester,
    this.shell,
    this.container,
    this.session,
    this.tracks,
  );

  final WidgetTester tester;
  final ChatShell shell;
  final ProviderContainer container;
  final FakeChatSession session;
  final RecordingTrackActions tracks;

  bool get isPhone => shell == ChatShell.phone;

  /// A few frames, so lists measure and providers resolve. Never settles: a
  /// streaming answer animates forever.
  Future<void> pump([int frames = 6]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> messages(List<AiMessage> list) async {
    container.read(fakeChatMessagesProvider.notifier).set(list);
    await pump();
  }

  Future<void> shot(String name) => chatShot(tester, '$name-${shell.name}');

  Future<void> openHistory() async {
    container.read(chatViewProvider.notifier).openHistory();
    await pump();
  }
}

/// Fixed "now" of the countdown cards.
final chatNow = DateTime(2026, 11, 27, 19, 5);

/// Opens the chat on [shell]: a plugin bound to the conversation, ready
/// unless [readiness] says otherwise.
Future<ChatUnderTest> openChat(
  WidgetTester tester,
  ChatShell shell, {
  List<ChatPluginInfo>? plugins,
  ChatReadiness readiness = const ChatReady(),
  String? model = 'm1',
  bool bind = true,
  Map<int, TrackInfo> library = const {},
  ToolPreview? preview,
  List<Override> extra = const [],
}) async {
  tester.platformDispatcher.localesTestValue = const [Locale('vi')];
  tester.platformDispatcher.localeTestValue = const Locale('vi');
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final list = plugins ?? [chatPlugin(id: chatPluginId, readiness: readiness)];
  final tracks = RecordingTrackActions();
  final common = <Override>[
    chatTrackActionsProvider.overrideWithValue(tracks),
    trackInfoProvider.overrideWith(
      (ref, id) => Stream.value(library[id.value]),
    ),
    trackRowLoaderProvider.overrideWithValue(
      (ids) async => [for (final id in ids) ?library[id.value]],
    ),
    chatConfirmPreviewProvider.overrideWith((ref, call) async => preview),
    chatCardHostProvider.overrideWith((ref, id) async => 'api.anthropic.com'),
    chatPlaylistLocationProvider.overrideWithValue(
      (id) async => id == null ? '/playlists' : '/playlists/p$id',
    ),
    chatCardClockProvider.overrideWithValue(() => chatNow),
    ...extra,
  ];
  final session = FakeChatSession();
  final container = await pumpKanaruApp(
    tester,
    extensions: [const NavFixture(), const AiExtension()],
    width: shell == ChatShell.phone ? phoneSize.width : desktopSize.width,
    height: shell == ChatShell.phone ? phoneSize.height : desktopSize.height,
    overrides: [
      ...chatUiOverrides(session: session),
      chatHostOverride,
      ...common,
    ],
  );
  if (shell == ChatShell.phone) {
    await tester.tap(byIconButton('Trò chuyện AI'));
  } else {
    container.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
  }
  await tester.pumpAndSettle();
  container.read(fakeChatPluginsProvider.notifier).set(list);
  container.read(fakeChatReadinessProvider.notifier).set(readiness);
  if (bind) {
    container
        .read(fakeChatBindingProvider.notifier)
        .set(installId: chatPluginId, model: model);
  }
  final chat = ChatUnderTest(tester, shell, container, session, tracks);
  await chat.pump();
  return chat;
}

void perShell(
  String name,
  Future<void> Function(WidgetTester tester, ChatShell shell) body,
) {
  for (final shell in ChatShell.values) {
    testWidgets('$name [${shell.name}]', (tester) => body(tester, shell));
  }
}
