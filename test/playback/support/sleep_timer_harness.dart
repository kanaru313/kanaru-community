import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/platform/domain/media_controls.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/state/media_session_bridge.dart';
import 'package:kanaru/src/playback/state/playback_data_providers.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/player_ready.dart';
import 'package:kanaru/src/playback/state/queue_row_infos.dart';
import 'package:kanaru/src/playback/state/sleep_ticker_provider.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';

import 'controller_harness.dart';

/// Makes the sleep timer and the sleep fade of [h]'s player tick by hand
/// (`h.ticker.fire()`), so a test never leaves a real periodic timer behind.
/// One override for every host that mounts the timer.
Override sleepTickerOverride(Harness h) =>
    sleepTickerProvider.overrideWithValue(h.ticker.call);

/// System controls that only count `cancelPendingResume`.
class CountingControls implements MediaControls {
  int cancelledResumes = 0;
  final _commands = StreamController<MediaCommand>.broadcast();

  @override
  void cancelPendingResume() => cancelledResumes++;

  @override
  Stream<MediaCommand> get commands => _commands.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> update(
    MediaControlsItem? item,
    MediaControlsState state,
  ) async {}

  @override
  void updatePosition(Duration position) {}

  @override
  void seeked(Duration position) {}

  @override
  Future<bool> activate() async => true;

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dispose() => _commands.close();
}

/// The sleep timer on a real controller (in-memory database, fake engine,
/// manual ticker) inside a container with fake album loading and a counting
/// bridge. Time is `h.now`; [pass] moves it and fires the tickers.
class SleepHarness {
  SleepHarness._(this.h) {
    bridge = MediaSessionBridge(
      controls: controls,
      infoOf: (_) async => null,
      artPathOf: (_) => null,
    );
    container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWith((ref) {
          controllerReads++;
          return h.c;
        }),
        sleepTickerOverride(h),
        appDatabaseProvider.overrideWithValue(h.db),
        mediaSessionBridgeProvider.overrideWithValue(bridge),
        queueRowInfoLoaderProvider.overrideWithValue(_load),
        queueTracksChangedProvider.overrideWith((ref) {
          var n = 0;
          return tracksChanged.stream.map((_) => ++n);
        }),
      ],
    );
    container.listen(sleepTimerProvider, (_, next) => states.add(next));
  }

  final Harness h;
  final controls = CountingControls();
  late final MediaSessionBridge bridge;
  late final ProviderContainer container;
  final tracksChanged = StreamController<void>.broadcast();
  final states = <SleepTimerState>[];

  /// The token of the entry the engine plays (the last one we drove).
  EngineToken? _token;

  /// How often the container built the controller provider.
  int controllerReads = 0;

  /// Album key per track (a null key is a track without an album); a track
  /// that is not here is not in the database.
  final albums = <TrackId, AlbumKey?>{};

  /// Length in milliseconds per track the loader reports; none = unknown.
  final durations = <TrackId, int>{};

  /// Every id list the database loader was asked for.
  final loads = <List<TrackId>>[];

  /// When set, loads wait for it; when [loadError] is set they fail.
  Completer<void>? loadGate;
  Object? loadError;

  static Future<SleepHarness> create({
    int tracks = 6,
    bool playerCreated = true,
  }) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final sh = SleepHarness._(await Harness.create(tracks: tracks));
    if (playerCreated) await sh.attachPlayer();
    return sh;
  }

  /// What the shell does after its first frame.
  Future<void> attachPlayer() async {
    await container.read(playerPhaseProvider.notifier).attach(h.c);
    await h.settle();
  }

  SleepTimer get timer => container.read(sleepTimerProvider.notifier);
  SleepTimerState get state => container.read(sleepTimerProvider);

  /// Track [i] (index into the harness tracks) in album [artist]/[title].
  void albumOf(int i, String? title, {String artist = 'x'}) =>
      albums[h.tracks[i]] = title == null ? null : AlbumKey(artist, title);

  Future<List<TrackInfo>> _load(List<TrackId> ids) async {
    loads.add(ids);
    await loadGate?.future;
    final error = loadError;
    if (error != null) throw error;
    return [
      for (final id in ids)
        if (albums.containsKey(id))
          TrackInfo(
            id: id,
            title: 't${id.value}',
            status: TrackAvailability.present,
            relPath: 't${id.value}.mp3',
            albumKey: albums[id],
            durationMs: durations[id],
          ),
    ];
  }

  /// Plays from [start] and loads the entry (the engine reports it loaded).
  Future<void> play({int start = 0}) async {
    await h.play(start: start);
    await h.settle();
    _token = h.loadedToken;
    h.engine.emit(EngineLoaded(_token!, const Duration(minutes: 3)));
    await h.settle();
    h.engine.commands.clear();
  }

  /// The user pauses; the engine log starts afresh after it.
  Future<void> userPause() async {
    await h.c.pause();
    await h.settle();
    h.engine.commands.clear();
  }

  /// The user plays again; the engine log starts afresh after it.
  Future<void> userPlay() async {
    await h.c.play();
    await h.settle();
    h.engine.commands.clear();
  }

  /// Moves the clock by [d] and fires one tick of every ticker.
  Future<void> pass(Duration d) async {
    h.now += d.inMilliseconds;
    h.ticker.fire();
    await h.settle();
  }

  /// The engine gaplessly moved on to the entry it was handed.
  Future<void> advance() async {
    final t = h.engine.nexts.last!.token;
    _token = t;
    h.engine.emit(EngineAdvanced(t));
    h.engine.emit(EngineLoaded(t, const Duration(seconds: 10)));
    await h.settle();
  }

  /// The loaded entry ended with nothing handed over.
  Future<void> end() async {
    final t = _token ?? h.loadedToken;
    h.engine.emit(EngineLoaded(t, const Duration(seconds: 10)));
    await h.settle();
    h.engine.emit(EngineEnded(t));
    await h.settle();
  }

  /// The levels the engine was given, in order.
  List<int> volumes() => [
    for (final c in h.engine.commands)
      if (c.startsWith('volume:')) int.parse(c.substring(7)),
  ];

  /// The app comes back to the foreground.
  void resumeApp() {
    final binding = WidgetsBinding.instance;
    // The binding only follows the real chain of states.
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
  }

  bool _containerDisposed = false;

  /// Disposes the container, as the app does on exit.
  void disposeContainer() {
    if (_containerDisposed) return;
    _containerDisposed = true;
    container.dispose();
  }

  Future<void> close() async {
    disposeContainer();
    bridge.dispose();
    await controls.dispose();
    await tracksChanged.close();
    await h.close();
  }
}
