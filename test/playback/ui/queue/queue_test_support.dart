import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/domain/queue_state.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/queue_row_infos.dart';
import 'package:kanaru/src/playback/state/queue_view_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A queue view of [n] entries (entry id i + 1, track id i) with [current].
QueueView fakeView(int n, {int? current}) => QueueView(
  items: [
    for (var i = 0; i < n; i++)
      QueueItem(entryId: i + 1, trackId: TrackId(i), sortKey: 'k$i'),
  ],
  current: current,
);

TrackInfo fakeInfo(TrackId id) => TrackInfo(
  id: id,
  title: 'Song ${id.value}',
  artist: 'Artist ${id.value}',
  album: 'Album',
  year: 2020,
  durationMs: 200000,
  status: TrackAvailability.present,
  relPath: 'a.mp3',
);

/// Counts the ids the rows asked to load.
class CountingLoader {
  final loaded = <TrackId>{};
  int calls = 0;

  Future<List<TrackInfo>> call(List<TrackId> ids) async {
    calls++;
    loaded.addAll(ids);
    return [for (final id in ids) fakeInfo(id)];
  }
}

/// Pumps [child] with a fake queue (no controller, no database): the view,
/// playing flag and info loader are overridden.
Future<ProviderContainer> pumpFakeQueue(
  WidgetTester tester,
  Widget child, {
  required QueueView view,
  CountingLoader? loader,
  bool playing = true,
  Size size = const Size(400, 800),

  /// System font scale; change its value to rescale while the list is open.
  ValueNotifier<double>? textScale,

  /// Later views (an advance, an edit); [view] is the first one.
  Stream<QueueView>? views,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final counting = loader ?? CountingLoader();
  final scale = textScale ?? ValueNotifier<double>(1);
  if (textScale == null) addTearDown(scale.dispose);
  final container = ProviderContainer(
    overrides: [
      queueViewProvider.overrideWith((ref) async* {
        yield view;
        if (views != null) yield* views;
      }),
      isPlayingProvider.overrideWithValue(playing),
      queueRowInfoLoaderProvider.overrideWithValue(counting.call),
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
        builder: (context, app) => ValueListenableBuilder<double>(
          valueListenable: scale,
          builder: (context, scale, _) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: app!,
          ),
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

/// Row height at the given font scale, as the list computes it.
double rowExtent([double scale = 1]) =>
    KMediaCard.extentOf(TextScaler.linear(scale));
