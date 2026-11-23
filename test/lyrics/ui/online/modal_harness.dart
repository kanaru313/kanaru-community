import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/data/online/online_lyrics_commands.dart';
import 'package:kanaru/src/lyrics/data/online/store_result.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/lyrics_choice_commands.dart';
import 'package:kanaru/src/lyrics/state/online/online_commands_provider.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_modal.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_settings_link.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/memory_settings_store.dart';

/// Records the choice writes; nothing touches a database.
class RecordingChoiceCommands implements LyricsChoiceCommands {
  final calls = <String>[];

  @override
  Future<void> setOff(TrackId id) async => calls.add('off:${id.value}');

  @override
  Future<void> setFile(TrackId id) async => calls.add('file:${id.value}');

  @override
  Future<void> clear(TrackId id) async => calls.add('clear:${id.value}');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records keep / reject; the real commands need a database.
class RecordingOnlineCommands implements OnlineLyricsCommands {
  final calls = <String>[];

  /// When set, every write throws it after it was recorded.
  Object? error;

  /// What keepAuto answers.
  StoreResult keepResult = StoreResult.stored;

  @override
  Future<StoreResult> keepAuto(TrackId track) async {
    calls.add('keepAuto:${track.value}');
    if (error != null) throw error!;
    return keepResult;
  }

  @override
  Future<void> reject(TrackId track) async {
    calls.add('reject:${track.value}');
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What [openModal] gives back.
class OpenedModal {
  OpenedModal(this.container, this.choices, this.online, this.router);

  final ProviderContainer container;
  final RecordingChoiceCommands choices;
  final RecordingOnlineCommands online;
  final GoRouter router;

  String get location =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;
}

/// Opens "Lời cho bài này" for track 1 showing [lyrics], with the writes
/// recorded and [overrides] (the plugin state) applied.
Future<OpenedModal> openModal(
  WidgetTester tester,
  TrackLyrics lyrics, {
  List<Override> overrides = const [],
  Size size = const Size(400, 800),
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  final choices = RecordingChoiceCommands();
  final online = RecordingOnlineCommands();
  final container = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      trackLyricsProvider.overrideWith((ref, id) => lyrics),
      playingLyricsProvider.overrideWith(
        (ref) => PlayingLyrics(
          entryId: 1,
          trackId: const TrackId(1),
          lyrics: lyrics,
        ),
      ),
      lyricsChoiceCommandsProvider.overrideWithValue(choices),
      onlineLyricsCommandsProvider.overrideWithValue(online),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showLyricsForTrack(context, const TrackId(1)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: lyricsSettingsLocation,
        builder: (_, _) => const Scaffold(body: Text('settings page')),
      ),
      GoRoute(
        path: '/settings/plugins',
        builder: (_, state) =>
            Scaffold(body: Text('store ${state.uri.queryParameters['kind']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: app!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // Not pumpAndSettle: a running search draws a spinner that never settles.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return OpenedModal(container, choices, online, router);
}
