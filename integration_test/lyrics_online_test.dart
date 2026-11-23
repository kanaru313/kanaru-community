import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart' show Navigator, Size, runApp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/kanaru_bootstrap.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/foundation/app_logger.dart';
import 'package:kanaru/src/lyrics/data/native_local_lyrics_reader.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/lyrics/state/lyrics_reader_provider.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_body.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_source_button.dart';
import 'package:kanaru/src/lyrics/ui/picker/picker_preview_page.dart';
import 'package:kanaru/src/lyrics/ui/song_lyrics_entry_impl.dart';
import 'package:kanaru/src/library/ui/menus/song_lyrics_entry.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/data/app_paths_factory.dart';
import 'package:kanaru/src/platform/data/file_device_id.dart';
import 'package:kanaru/src/platform/data/json_settings_store.dart';
import 'package:kanaru/src/platform/data/native_library.dart';
import 'package:kanaru/src/platform/state/device_id_provider.dart';
import 'package:kanaru/src/platform/state/media_permissions_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';
import 'package:kanaru/src/screens/first_run/state/first_run_gate.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/more_sheet.dart';
import 'package:kanaru_extensions/kanaru_extensions.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';

import '../test/lyrics/support/fake_plugin_runner.dart';
import 'support/fixtures.dart';
import 'support/harness.dart' show RunningApp;

/// Online lyrics on the real app, Linux or phone, with a scripted lyrics
/// plugin instead of a real one: the automatic lookup shows a result, "Không
/// đúng bài" moves to the next one, and the Chọn lời picker (search, choose,
/// "Dùng lời này") keeps a result as the song's own copy. One launch: the
/// window starts narrow (mobile shell: sheets, the preview page) and is
/// widened at the end (desktop shell: dialog with the preview beside the
/// list). Asserts state (providers, semantics, widget types), never pixels.
///
/// Run: `tool/integration_test.sh linux integration_test/lyrics_online_test.dart`
/// (through the main checkout's `main-build.sh`).

const _pluginId = 'fake-lrclib';

/// The song of the fixture without lyrics: tags "IT No Lyrics" by "Kanaru
/// Fixture". The scripted results carry no length, so only an exact title and
/// artist is believed; the three results below all have them.
const _title = 'IT No Lyrics';
const _artist = 'Kanaru Fixture';

Map<String, Object?> _item(String id, String title, String lyrics) => {
  'id': id,
  'title': title,
  'artist': _artist,
  'lyrics': lyrics,
};

/// The plugin: the automatic `search` (the song's tags) answers two copies,
/// the manual one (free text) answers a live and an acoustic version.
void _script(FakePluginRunner runner) {
  runner.on(_pluginId, 'search', (request, _) {
    final input = request.input;
    final manual = input is Map && input.containsKey('text');
    return searchAnswer(
      manual
          ? [
              _item('r3', '$_title (Live)', '[00:00.50]Live first line'),
              _item('r4', '$_title (Acoustic)', '[00:00.50]Acoustic line'),
            ]
          : [
              _item('r1', _title, '[00:00.50]Online first line'),
              _item('r2', _title, '[00:00.50]Second copy line'),
            ],
    );
  });
}

/// What `runKanaru` does, with [overrides] added: it has no hook for fakes
/// yet. Settings the harness needs (library minimum duration off) are written
/// first, as `startKanaru` does.
Future<RunningApp> _startWithFakes(
  WidgetTester tester,
  List<Override> overrides,
) async {
  final paths = await createAppPaths();
  final file = File('${paths.configDir.path}/settings.json');
  final values = <String, Object?>{};
  if (await file.exists()) {
    final json = jsonDecode(await file.readAsString());
    if (json is Map<String, Object?> && json['values'] is Map) {
      values.addAll((json['values'] as Map).cast<String, Object?>());
    }
  }
  values['library.min_duration_ms'] = 0;
  await file.writeAsString(
    jsonEncode({'format': 'kanaru-settings', 'version': 1, 'values': values}),
  );

  setupLogging();
  MediaKit.ensureInitialized();
  final started = await bootstrap(
    extensions: [...builtInExtensions, ...bundledExtensions],
    loadNative: loadNativeLibrary,
    createPaths: createAppPaths,
    openSettings: (paths) =>
        JsonSettingsStore.open(File('${paths.configDir.path}/settings.json')),
    loadDeviceId: (paths) =>
        FileDeviceId(File('${paths.dataDir.path}/device_id')).load(),
    openDatabase: (paths) =>
        AppDatabase.file(File('${paths.dataDir.path}/$databaseFileName')),
  );
  runApp(
    ProviderScope(
      overrides: [
        nativeVersionsProvider.overrideWithValue(started.nativeVersions),
        appPathsProvider.overrideWithValue(started.paths),
        settingsStoreProvider.overrideWithValue(started.settings),
        deviceIdProvider.overrideWithValue(started.deviceId),
        appDatabaseProvider.overrideWithValue(started.database),
        extensionRegistryProvider.overrideWithValue(started.registry),
        localLyricsReaderProvider.overrideWithValue(NativeLocalLyricsReader()),
        songLyricsEntryProvider.overrideWithValue(const LyricsSongEntry()),
        ...overrides,
      ],
      child: const KanaruApp(),
    ),
  );
  await tester.pump();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(KanaruApp)),
  );
  final app = RunningApp(tester, container);

  if (container.read(firstRunRequiredProvider)) {
    final next = find.byType(SetupNextButton);
    var lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);
    await app.pumpUntil(
      () {
        final now = DateTime.now();
        if (now.difference(lastRefresh) >= const Duration(seconds: 1)) {
          lastRefresh = now;
          unawaited(
            container
                .read(mediaPermissionStateProvider.notifier)
                .refresh()
                .then<void>(
                  (_) {},
                  onError: (Object e) =>
                      debugPrint('permission refresh failed: $e'),
                ),
          );
        }
        return next.hitTestable().evaluate().isNotEmpty &&
            tester.widget<SetupNextButton>(next).onPressed != null;
      },
      what:
          'first-run page with a default music folder (is XDG_MUSIC_DIR set?)',
    );
    await tester.tap(next);
    await app.pumpUntil(
      () => !container.read(firstRunRequiredProvider),
      what: 'setup to finish',
    );
  }
  container.read(routerProvider).go('/library/songs');
  await tester.pump();
  final wanted = {for (final t in fixtureTracks) t.title};
  await app.pumpUntil(
    () async => (await app.trackIdsByTitle()).keys.toSet().containsAll(wanted),
    what: 'every fixture track in the library (scan)',
    timeout: const Duration(seconds: 120),
  );
  return app;
}

Finder _iconButton(String tooltip) =>
    find.byWidgetPredicate((w) => w is KIconButton && w.tooltip == tooltip);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('online lyrics: lookup, wrong song, picker, keep', (
    tester,
  ) async {
    Logger.root.level = Level.WARNING;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 900);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    final runner = FakePluginRunner();
    _script(runner);
    final app = await _startWithFakes(tester, [
      pluginRunnerProvider.overrideWithValue(runner),
      lyricsSourcesLoadedProvider.overrideWithValue(true),
      lyricsSourcesProvider.overrideWithValue(const [
        LyricsSource(
          id: _pluginId,
          name: 'LRCLIB',
          version: 1,
          origin: LyricsSourceOrigin.repo,
          enabled: true,
        ),
      ]),
    ]);
    final container = app.container;
    final player = container.read(playerControllerProvider);
    container.read(lyricsAutoSearchProvider.notifier).set(true);
    final noneId = TrackId((await app.trackIdsByTitle())[_title]!);

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(Navigator).first));
    OnlineLyricsRef? shown() =>
        switch (container.read(trackLyricsProvider(noneId))) {
          LyricsShown(:final lyrics) => lyrics.online,
          _ => null,
        };
    Future<void> waitShown(String remoteId, OnlineHow how) => app.pumpUntil(
      () => shown()?.remoteId == remoteId && shown()?.how == how,
      what: 'online lyrics $remoteId ($how) to show',
      timeout: const Duration(seconds: 20),
    );
    final modal = find.byType(LyricsForTrackBody);
    Future<void> waitOpen(Finder f, String what) => app.pumpUntil(
      () => f.evaluate().isNotEmpty,
      what: what,
      timeout: const Duration(seconds: 15),
    );
    Future<void> waitGone(Finder f, String what) => app.pumpUntil(
      () => f.evaluate().isEmpty,
      what: what,
      timeout: const Duration(seconds: 15),
    );

    await player.playTracks([
      noneId,
    ], context: const PlayContext(PlayContextKind.songs));
    await app.pumpUntil(
      () => container.read(nowPlayingProvider).value?.trackId == noneId,
      what: 'the song without lyrics to be playing',
    );
    await player.pause();

    // The lookup found a result by itself: a copy of the cache, not kept.
    await waitShown('r1', OnlineHow.auto);
    expect(
      runner.calls.any(
        (c) => c.script == 'search' && (c.input as Map).containsKey('title'),
      ),
      isTrue,
    );

    // ============ mobile shell: the modal is a sheet, the picker a sheet ====
    await tester.tap(find.byType(MiniPlayer));
    await waitOpen(find.byType(MobileNowPlaying), 'mobile Now Playing');
    Future<void> openModalFromMore() async {
      await tester.tap(_iconButton(l10n().playbackMore));
      await waitOpen(find.byType(NowPlayingMoreSheet), 'the more sheet');
      await tester.tap(find.text(l10n().playbackLyricsSource));
      await waitOpen(modal, 'Lời cho bài này');
    }

    // "Không đúng bài": refuses r1, the lookup goes on to the next one.
    await openModalFromMore();
    expect(find.text(l10n().lyricsBarReject), findsOneWidget);
    await tester.tap(find.text(l10n().lyricsBarReject));
    await waitGone(modal, 'the modal to close after refusing');
    await waitShown('r2', OnlineHow.auto);

    // Picker: "Tìm lời trực tuyến…" switches the modal to it.
    await openModalFromMore();
    await tester.tap(find.text(l10n().lyricsFindOnline));
    await waitOpen(find.text(l10n().lyricsPickerTitle), 'the picker');
    expect(modal, findsNothing);
    await waitOpen(find.text('$_title (Live)'), 'the manual search results');
    expect(
      runner.calls.any(
        (c) =>
            c.script == 'search' &&
            (c.input as Map)['text'] == '$_title $_artist',
      ),
      isTrue,
      reason: 'the field starts as "title artist" and searches at once',
    );
    // A tap opens the preview page; Back goes to the list, a tap again and
    // "Dùng lời này" keeps it.
    await tester.tap(find.text('$_title (Live)'));
    await waitOpen(find.byType(PickerPreviewPage), 'the preview page');
    await tester.binding.handlePopRoute();
    await waitGone(find.byType(PickerPreviewPage), 'Back from the preview');
    expect(find.text(l10n().lyricsPickerTitle), findsOneWidget);
    await tester.tap(find.text('$_title (Live)'));
    await waitOpen(find.byType(PickerPreviewPage), 'the preview page again');
    final use = find.widgetWithText(KModalButton, l10n().lyricsPickerUse);
    await app.pumpUntil(
      () => isSemantics(isEnabled: true).matches(tester.getSemantics(use), {}),
      what: 'Dùng lời này to be enabled',
    );
    await tester.tap(use);
    await waitGone(find.text(l10n().lyricsPickerTitle), 'the picker to close');
    await waitShown('r3', OnlineHow.kept);
    expect(find.byType(MobileNowPlaying), findsOneWidget);

    // ============ desktop shell: widen the window ===========================
    tester.view.physicalSize = const Size(1400, 900);
    await app.pumpUntil(
      () => container.read(nowPlayingPanelProvider).covered,
      what: 'the desktop Now Playing panel after widening',
    );
    await waitOpen(find.byType(DesktopNowPlaying), 'desktop Now Playing');
    Future<void> openModalFromButton() async {
      await tester.tap(find.byType(LyricsSourceButton));
      await waitOpen(modal, 'Lời cho bài này (desktop)');
    }

    // Refusing the kept copy: the lookup shows the next result again.
    await openModalFromButton();
    await tester.tap(find.text(l10n().lyricsBarReject));
    await waitGone(modal, 'the modal to close after refusing (desktop)');
    await waitShown('r2', OnlineHow.auto);

    // The picker is a dialog: list on the left, the lyrics beside it.
    await openModalFromButton();
    await tester.tap(find.text(l10n().lyricsFindOnline));
    await waitOpen(find.text(l10n().lyricsPickerTitle), 'the picker (desktop)');
    await waitOpen(
      find.text('$_title (Acoustic)'),
      'the manual search results (desktop)',
    );
    await tester.tap(find.text('$_title (Acoustic)'));
    await waitOpen(find.text('Acoustic line'), 'the preview beside the list');
    final useDesktop = find.widgetWithText(
      KModalButton,
      l10n().lyricsPickerUse,
    );
    await app.pumpUntil(
      () =>
          isSemantics(isEnabled: true)
              .matches(tester.getSemantics(useDesktop), {}),
      what: 'Dùng lời này to be enabled (desktop)',
    );
    await tester.tap(useDesktop);
    await waitGone(
      find.text(l10n().lyricsPickerTitle),
      'the picker to close (desktop)',
    );
    await waitShown('r4', OnlineHow.kept);

    semantics.dispose();
  });
}
