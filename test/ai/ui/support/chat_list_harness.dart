import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/ui/chat_host.dart';
import 'package:kanaru/src/ai/ui/chat_surface.dart';
import 'package:kanaru/src/ai/ui/track_actions.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'chat_ui_support.dart';

/// Records what a song row of an answer asked of the app.
class RecordingTrackActions implements ChatTrackActions {
  final calls = <String>[];

  @override
  Future<void> play(TrackId id) async => calls.add('play ${id.value}');

  @override
  Future<void> openMenu(
    BuildContext context,
    TrackInfo info, {
    required bool viaKeyboard,
  }) async => calls.add('menu ${info.id.value}');
}

TrackInfo fakeTrack(int id, {String title = 'Lac troi', String? artist}) =>
    TrackInfo(
      id: TrackId(id),
      title: title,
      artist: artist ?? 'Son Tung',
      status: TrackAvailability.present,
      relPath: 'a.flac',
    );

class ListSetup {
  ListSetup(this.container, this.session, this.tracks);

  final ProviderContainer container;
  final FakeChatSession session;
  final RecordingTrackActions tracks;

  FakeChatMessagesData get data =>
      container.read(fakeChatMessagesProvider.notifier);

  /// Sets the stored messages and lets the list follow.
  Future<void> setMessages(
    WidgetTester tester,
    List<AiMessage> messages, {
    bool hasMore = false,
  }) async {
    data.set(messages, hasMore: hasMore);
    // A few frames: the list measures, jumps to the end, measures again.
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }
}

/// Pumps the chat surface (the message list inside it) over fake engine
/// providers. [size] picks the shell: 1280 wide is desktop, 400 the phone.
Future<ListSetup> pumpChatList(
  WidgetTester tester, {
  Size size = const Size(1280, 800),
  bool disableAnimations = false,
  Map<int, TrackInfo> library = const {},
  bool failMessages = false,
  List<Override> extra = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final session = FakeChatSession();
  final tracks = RecordingTrackActions();
  final container = ProviderContainer(
    overrides: [
      ...chatUiOverrides(session: session),
      chatHostProvider.overrideWithValue(RecordingChatHost()),
      chatTrackActionsProvider.overrideWithValue(tracks),
      trackInfoProvider.overrideWith(
        (ref, id) => Stream.value(library[id.value]),
      ),
      if (failMessages) fakeMessagesFailProvider.overrideWithValue(true),
      ...extra,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: const Scaffold(body: ChatSurface()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return ListSetup(container, session, tracks);
}
