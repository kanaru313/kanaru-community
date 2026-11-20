import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/playback/state/sleep_estimates.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_modal.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/ui_host.dart';

/// A sleep timer that only keeps its state: every command is logged in
/// [calls] and changes [state] the way the real one does, so the screens can
/// be driven without a clock. A test moves it with [set].
class FakeSleepTimer extends SleepTimer {
  final calls = <String>[];
  int _serial = 0;

  @override
  SleepTimerState build() => const SleepTimerState.off();

  void set(SleepTimerState next) => state = next;

  void _start(SleepTimerState s) {
    state = s.copyWith(startedAt: DateTime.now(), startSerial: ++_serial);
  }

  @override
  void startMinutes(int minutes) {
    calls.add('startMinutes:$minutes');
    final length = Duration(minutes: minutes);
    _start(
      SleepTimerState(
        mode: SleepTimerMode.minutes,
        remaining: length,
        setLength: length,
        endsAt: DateTime.now().add(length),
      ),
    );
  }

  @override
  void startTracks(int count) {
    calls.add('startTracks:$count');
    _start(
      SleepTimerState(
        mode: SleepTimerMode.tracks,
        tracksLeft: count,
        tracksAtStart: count,
      ),
    );
  }

  @override
  void startEndOfTrack() {
    calls.add('startEndOfTrack');
    _start(const SleepTimerState(mode: SleepTimerMode.endOfTrack));
  }

  @override
  void startEndOfAlbum() {
    calls.add('startEndOfAlbum');
    _start(const SleepTimerState(mode: SleepTimerMode.endOfAlbum));
  }

  @override
  void startEndOfQueue() {
    calls.add('startEndOfQueue');
    _start(const SleepTimerState(mode: SleepTimerMode.endOfQueue));
  }

  @override
  void addMinutes(int delta) {
    calls.add('addMinutes:$delta');
    final next = state.remaining + Duration(minutes: delta);
    state = state.copyWith(
      remaining: next,
      setLength: next > state.setLength ? next : state.setLength,
    );
  }

  @override
  void addTracks(int delta) {
    calls.add('addTracks:$delta');
    final left = state.tracksLeft + delta;
    state = state.copyWith(
      tracksLeft: left,
      tracksAtStart: left > state.tracksAtStart ? left : state.tracksAtStart,
    );
  }

  @override
  void pauseCounting() {
    calls.add('pauseCounting');
    state = state.copyWith(countingPaused: true, endsAt: null);
  }

  @override
  void resumeCounting() {
    calls.add('resumeCounting');
    state = state.copyWith(
      countingPaused: false,
      endsAt: DateTime.now().add(state.remaining),
    );
  }

  @override
  void cancel() {
    calls.add('cancel');
    state = const SleepTimerState.off();
  }
}

/// 23:41 left of 45 minutes, running.
SleepTimerState runningMinutes({
  Duration remaining = const Duration(minutes: 23, seconds: 41),
  bool held = false,
}) => SleepTimerState(
  mode: SleepTimerMode.minutes,
  remaining: remaining,
  setLength: const Duration(minutes: 45),
  endsAt: held ? null : DateTime.now().add(remaining),
  countingPaused: held,
  startedAt: DateTime.now(),
  startSerial: 1,
);

SleepTimerState runningTracks({int left = 3, int total = 5}) => SleepTimerState(
  mode: SleepTimerMode.tracks,
  tracksLeft: left,
  tracksAtStart: total,
  startedAt: DateTime.now(),
  startSerial: 1,
);

SleepTimerState runningEndOf(SleepTimerMode mode) => SleepTimerState(
  mode: mode,
  startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
  startSerial: 1,
);

/// The figures the tiles and the end-of rows show, without a database.
List<Override> sleepEstimates({bool noAlbum = false}) => [
  currentTrackLeftProvider.overrideWithValue(168),
  currentTrackPlayedProvider.overrideWithValue((played: 12, total: 180)),
  albumRunProvider.overrideWith(
    (ref) => Stream.value(
      AlbumRun(
        tracks: 4,
        restDuration: const Duration(minutes: 11, seconds: 12),
        noAlbum: noAlbum,
        capped: false,
      ),
    ),
  ),
  albumLeftProvider.overrideWithValue(const Duration(minutes: 14)),
  queueLeftProvider.overrideWithValue((
    tracks: 7,
    time: const Duration(minutes: 29),
  )),
];

/// A [NavigatorObserver] that counts pops.
class PopCounter extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => pops++;
}

/// The app around the sleep timer modal under test: Vietnamese, with an
/// opener button, a shell-like Escape handler above the navigator, a pop
/// counter, and the announcements the modal sends.
class SleepModalHost {
  SleepModalHost(this.ui, this.opener, this.pops, this.announced);

  final UiHost ui;
  final FocusNode opener;
  final PopCounter pops;

  /// Messages sent to the screen reader, in order.
  final List<String> announced;

  /// Times the Escape handler above the navigator ran.
  int shellEscapes = 0;

  FakeSleepTimer get timer =>
      ui.container.read(sleepTimerProvider.notifier) as FakeSleepTimer;

  static const openKey = ValueKey('open-sleep-timer');
}

/// Pumps the app and returns the host; the modal is not open yet ([open]).
Future<SleepModalHost> pumpSleepModal(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool reduceMotion = false,
  bool noAlbum = false,
  SleepTimerState? initial,
}) async {
  final ui = await pumpWithPlayer(
    tester,
    const SizedBox(),
    size: size,
    overrides: [
      sleepTimerProvider.overrideWith(FakeSleepTimer.new),
      ...sleepEstimates(noAlbum: noAlbum),
    ],
  );
  final announced = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
    SystemChannels.accessibility,
    (message) async {
      final map = message as Map<Object?, Object?>;
      if (map['type'] == 'announce') {
        announced.add((map['data']! as Map)['message']! as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
      SystemChannels.accessibility,
      null,
    ),
  );
  final opener = FocusNode(debugLabel: 'opener');
  addTearDown(opener.dispose);
  final pops = PopCounter();
  final host = SleepModalHost(ui, opener, pops, announced);
  if (initial != null) host.timer.set(initial);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: ui.container,
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: brightness),
        locale: const Locale('vi'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [pops],
        builder: (context, app) => CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                host.shellEscapes++,
          },
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              alwaysUse24HourFormat: true,
              disableAnimations: reduceMotion,
            ),
            child: app!,
          ),
        ),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => Focus(
                focusNode: opener,
                child: TextButton(
                  key: SleepModalHost.openKey,
                  onPressed: () => showSleepTimer(context, returnFocus: opener),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return host;
}

/// Opens the modal and lets it finish.
Future<void> openSleepModal(WidgetTester tester) async {
  await tester.tap(find.byKey(SleepModalHost.openKey));
  await tester.pumpAndSettle();
}

/// Whether keyboard focus is on [finder] or inside it.
bool focusedWithin(WidgetTester tester, Finder finder) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  return tester.any(
    find.descendant(
      of: finder,
      matching: find.byElementPredicate((e) => e == context),
      matchRoot: true,
    ),
  );
}

/// The row / tile / button that holds [text].
Finder holding(Type type, String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(type));

Finder get modalOpen => find.text('Hẹn giờ ngủ');

/// Taps [finder] after scrolling it into view (the modal scrolls when its
/// screen is taller than the window) and lets the frames finish.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The ← of the custom screen.
Finder get backButton =>
    find.byWidgetPredicate((w) => w is KIconButton && w.icon == KIcons.back);
