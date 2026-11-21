import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/domain/history/history_days.dart';
import 'package:kanaru/src/library/state/history/history_providers.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';
import 'package:kanaru/src/library/ui/history/history_page.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/data/play_log_writer.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/state/listen_recorder.dart';
import 'package:kanaru/src/playback/state/listen_recorder_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../database/support/test_db.dart';
import '../../../support/fake_playback_commands.dart';
import '../../../support/memory_settings_store.dart';
import '../../history/state/fake_history_store.dart';
import '../menus/menu_pump.dart';

/// The day the History page tests run on.
final testToday = DateTime(2026, 11, 20, 10);

/// A play of [id] (a song) at [when].
HistoryPlay playAt(
  int id,
  DateTime when, {
  TrackInfo? track,
  int ordinal = 1,
  String? uid,
  int listenedMs = 60000,
}) => HistoryPlay(
  id: id,
  uid: uid ?? 'p$id',
  track: track ?? info(id, title: 'Song $id'),
  playedAt: when.millisecondsSinceEpoch,
  listenedMs: listenedMs,
  ordinal: ordinal,
);

/// Everything a History page test drives.
class HistoryHarness {
  HistoryHarness(this.container, this.store, this.playback, this._now);

  final ProviderContainer container;
  final FakeHistoryStore store;
  final FakePlaybackCommands playback;
  final StreamController<NowPlaying> _now;

  void setNowPlaying(NowPlaying value) => _now.add(value);
}

/// Pumps the History page on a window of [width] x [height] (device pixel
/// ratio 1, text scale [textScale]) over a scripted [store].
///
/// [years] and [overview] default from [byYear] (every play counted).
/// With [pushed] the page is opened from a home page (tap "open history").
/// [recorder] replaces the listen recorder the clear goes through,
/// [playbackCommands] the fake player, [page] the page under test. With
/// [routes] the page is the `/` route of a router that also has them (for a
/// test of where a menu row goes).
Future<HistoryHarness> pumpHistoryPage(
  WidgetTester tester, {
  required Map<int, List<HistoryPlay>> byYear,
  double width = 400,
  double height = 800,
  double textScale = 1,
  bool recording = true,
  bool animations = true,
  Locale locale = const Locale('vi'),
  List<Override> overrides = const [],
  FakeHistoryStore? store,
  bool settle = true,
  bool pushed = false,
  ListenRecorder? recorder,
  FakePlaybackCommands? playbackCommands,
  Widget page = const HistoryPage(),
  List<RouteBase>? routes,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  final fake = store ?? FakeHistoryStore();
  fake.byYear = byYear;
  final all = [for (final y in byYear.values) ...y];
  fake.yearsAnswer = (byYear.keys.where((y) => byYear[y]!.isNotEmpty).toList()
    ..sort((a, b) => b.compareTo(a)));
  fake.overviewAnswer = HistoryOverview(
    plays: all.length,
    songs: {for (final p in all) p.track.id.value}.length,
    since: all.isEmpty
        ? null
        : all.map((p) => p.playedAt).reduce((a, b) => a < b ? a : b),
  );
  final settings = MemorySettingsStore();
  final db = openTestDb();
  addTearDown(db.close);
  final playback = playbackCommands ?? FakePlaybackCommands();
  final now = StreamController<NowPlaying>()..add(NowPlaying.none);
  addTearDown(() => unawaited(now.close()));
  final container = ProviderContainer(
    overrides: [
      historyStoreProvider.overrideWithValue(fake),
      appDatabaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(settings),
      playbackCommandsProvider.overrideWithValue(playback),
      nowPlayingProvider.overrideWith((ref) => now.stream),
      localDayProvider.overrideWith(_FixedDay.new),
      listenRecorderProvider.overrideWithValue(recorder ?? _recorder(db)),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  if (!recording) {
    await container.read(historyEnabledProvider.notifier).set(false);
  }
  Widget app(Widget? home) {
    final delegates = [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];
    Widget scale(BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: !animations,
      ),
      child: child!,
    );
    final theme = buildKanaruTheme(brightness: Brightness.light);
    return UncontrolledProviderScope(
      container: container,
      child: routes == null
          ? MaterialApp(
              theme: theme,
              locale: locale,
              localizationsDelegates: delegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: scale,
              home: home,
            )
          : MaterialApp.router(
              theme: theme,
              locale: locale,
              localizationsDelegates: delegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: scale,
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => Scaffold(body: page),
                  ),
                  ...routes,
                ],
              ),
            ),
    );
  }

  await tester.pumpWidget(
    app(
      pushed
          ? Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: HistoryPage()),
                    ),
                  ),
                  child: const Text('open history'),
                ),
              ),
            )
          : Scaffold(body: page),
    ),
  );
  if (pushed) {
    await tester.tap(find.text('open history'));
    await tester.pumpAndSettle();
  }
  if (settle) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
  return HistoryHarness(container, fake, playback, now);
}

/// A local day that never ticks (no midnight timer to leave pending).
class _FixedDay extends LocalDayNotifier {
  @override
  DateTime build() => localDay(testToday);
}

ListenRecorder _recorder(AppDatabase db) =>
    ListenRecorder(writer: PlayLogWriter(db), deviceId: () => 'dev');

/// The l10n of the pumped page (Vietnamese by default).
AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(HistoryPage)));

/// Plays over consecutive days, newest first: perDay[0] plays today
/// (2026-11-20), `perDay[1]` yesterday, and so on. Ids count up from [first],
/// each song has its own id, so every row has a distinct title "Song 7" for id 7.
List<HistoryPlay> playsOverDays(List<int> perDay, {int first = 1}) {
  final out = <HistoryPlay>[];
  var id = first;
  for (var d = 0; d < perDay.length; d++) {
    for (var i = 0; i < perDay[d]; i++) {
      out.add(playAt(id, DateTime(2026, 11, 20 - d, 20 - i), uid: 'p$id'));
      id++;
    }
  }
  return out;
}

/// Gives the row of [title] keyboard focus, as Tab would (a click on a row
/// plays it and does not focus it).
Future<void> focusRow(WidgetTester tester, String title) async {
  Focus.of(tester.element(find.text(title))).requestFocus();
  await tester.pump();
}

/// Opens the menu of the day whose bar reads [label] (a long press on it);
/// the first bar with that text, so the pinned bar when it is the same day.
Future<void> openDayMenu(WidgetTester tester, String label) async {
  await tester.longPress(find.text(label).first);
  await pumpMenu(tester);
}
