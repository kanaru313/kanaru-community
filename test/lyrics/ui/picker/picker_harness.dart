import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_facts.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_candidate.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_match.dart';
import 'package:kanaru/src/lyrics/domain/online/online_search_state.dart';
import 'package:kanaru/src/lyrics/state/online/online_commands_provider.dart';
import 'package:kanaru/src/lyrics/state/online/online_search_provider.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_settings_link.dart';
import 'package:kanaru/src/lyrics/ui/picker/lyrics_picker.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/memory_settings_store.dart';
import '../online/modal_harness.dart' show RecordingOnlineCommands;

/// The song of the picker tests: 4:12 long.
const songLength = Duration(minutes: 4, seconds: 12);

LyricsFacts songFacts({Duration? duration = songLength}) => LyricsFacts(
  trackId: const TrackId(1),
  trackRevision: null,
  lrcLocator: null,
  lrcRevision: null,
  off: false,
  title: 'Song',
  artist: 'Singer',
  duration: duration,
);

const syncedBody = LyricsBody(
  syncedLrc: '[00:12.00]First line\n[00:30.00]\n[00:41.50]Second line',
);
const plainBody = LyricsBody(plain: 'Plain one\n\nPlain two');

/// A result of plugin [id]; [length] seconds long unless null.
LyricsCandidate candidate(
  String id,
  String remote, {
  String? title,
  int? length = 252,
  LyricsBody? body = syncedBody,
  String artist = 'Singer',
  String? album = 'Album',
}) => LyricsCandidate(
  providerId: id,
  remoteId: remote,
  title: title ?? 'Song $remote',
  artist: artist,
  album: album,
  duration: length == null ? null : Duration(seconds: length),
  body: body,
);

/// The ranked results of one source.
SourceSearch results(List<LyricsCandidate> list) => SourceSearch(
  SourceSearchPhase.results,
  matches: [
    for (final c in list)
      LyricsMatch(
        candidate: c,
        score: 1,
        delta: null,
        goodMatch: true,
        metadataGood: true,
      ),
  ],
);

/// The search the picker sees, driven by the test: it answers each text from
/// [answers] once its gate is open, and counts what was asked.
class FakeSearch extends OnlineSearchNotifier {
  FakeSearch(super.trackId, this.script);

  final SearchScript script;
  int _gen = 0;

  @override
  OnlineSearchState build() => const OnlineSearchState();

  @override
  Future<void> search(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;
    final gen = ++_gen;
    script.searches.add(query);
    state = OnlineSearchState(
      text: query,
      bySource: {for (final id in script.enabled) id: SourceSearch.loading},
    );
    await script.gates[query]?.future;
    if (!ref.mounted || gen != _gen) return;
    final answer = script.answers[query] ?? script.answers['*'] ?? const {};
    state = state.copyWith(
      bySource: {
        for (final id in script.enabled)
          id: answer[id] ?? const SourceSearch(SourceSearchPhase.empty),
      },
    );
  }

  @override
  Future<void> searchDisabled({Set<String>? ids}) async {
    script.askedOff.add(ids ?? {...script.disabledAnswers.keys});
    final todo = ids ?? script.disabledAnswers.keys.toSet();
    state = state.copyWith(
      onDemand: {...state.onDemand, ...todo},
      bySource: {
        ...state.bySource,
        for (final id in todo)
          id: script.disabledAnswers[id] ?? SourceSearch.loading,
      },
    );
  }

  @override
  Future<LyricsBody?> fetchLyrics(LyricsCandidate c) async {
    script.fetched.add(c.remoteId);
    final own = c.body;
    if (own != null && own.isUsable) return own;
    final gate = script.fetchGates[c.remoteId];
    state = state.copyWith(
      bodyFetches: {
        ...state.bodyFetches,
        c.ref: const BodyFetch(BodyFetchPhase.loading),
      },
    );
    await gate?.future;
    if (!ref.mounted) return null;
    final body = script.bodies[c.remoteId];
    final next = {...state.bodyFetches};
    if (body == null) {
      next[c.ref] = const BodyFetch(
        BodyFetchPhase.failed,
        failure: SourceSearchFailure.network,
      );
      state = state.copyWith(bodyFetches: next);
      return null;
    }
    next.remove(c.ref);
    final part = state.bySource[c.providerId]!;
    state = state.copyWith(
      bodyFetches: next,
      bySource: {
        ...state.bySource,
        c.providerId: SourceSearch(
          part.phase,
          matches: [
            for (final m in part.matches)
              m.candidate.ref == c.ref
                  ? LyricsMatch(
                      candidate: m.candidate.withBody(body),
                      score: m.score,
                      delta: m.delta,
                      goodMatch: m.goodMatch,
                      metadataGood: m.metadataGood,
                    )
                  : m,
          ],
        ),
      },
    );
    return body;
  }
}

/// What the fake search answers and what was asked of it.
class SearchScript {
  /// The ids of the sources that are on, in order.
  List<String> enabled = ['lrclib'];

  /// Text to per-source answers; `'*'` answers any other text.
  final Map<String, Map<String, SourceSearch>> answers = {};

  /// A text whose answer waits for its completer.
  final Map<String, Completer<void>> gates = {};

  /// The answers of sources that are off, by id.
  final Map<String, SourceSearch> disabledAnswers = {};

  /// A result whose lyrics are fetched: the body it gets (none: a failure).
  final Map<String, LyricsBody> bodies = {};
  final Map<String, Completer<void>> fetchGates = {};

  final searches = <String>[];
  final askedOff = <Set<String>>[];
  final fetched = <String>[];
}

/// What the picker reads: the song's facts and the [FakeSearch], for tests
/// that open it from another screen.
List<Override> pickerOverrides({
  SearchScript? script,
  LyricsFacts? facts,
  RecordingOnlineCommands? online,
  bool factsFail = false,
}) => [
  if (online != null) onlineLyricsCommandsProvider.overrideWithValue(online),
  lyricsFactsProvider.overrideWith(
    (ref, id) => factsFail
        ? Stream.error(StateError('facts are gone'))
        : Stream.value(facts ?? songFacts()),
  ),
  onlineSearchProvider.overrideWith2(
    (id) => FakeSearch(id, script ?? SearchScript()),
  ),
];

/// The playing entry, set by the test: null stops playback.
class _Playing extends Notifier<PlayingLyrics> {
  @override
  PlayingLyrics build() => const PlayingLyrics(
    entryId: 1,
    trackId: TrackId(1),
    lyrics: LyricsNone(),
  );

  void play(int? entry) => state = entry == null
      ? PlayingLyrics.none
      : PlayingLyrics(
          entryId: entry,
          trackId: TrackId(entry),
          lyrics: const LyricsNone(),
        );
}

final _playing = NotifierProvider<_Playing, PlayingLyrics>(_Playing.new);

/// What [openPicker] gives back.
class OpenedPicker {
  OpenedPicker(this.container, this.online, this.router, this.script, this.log);

  final ProviderContainer container;
  final RecordingOnlineCommands online;
  final GoRouter router;
  final SearchScript script;

  /// What the open button's callbacks recorded ("back", "use:...").
  final List<String> log;

  String get location =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  /// Makes track [entry] the playing one (null: stops).
  void play(int? entry) => container.read(_playing.notifier).play(entry);
}

/// Opens the picker of track 1 with a [FakeSearch] driven by [script].
/// [overrides] carry the plugin state (the sources).
Future<OpenedPicker> openPicker(
  WidgetTester tester, {
  required SearchScript script,
  List<Override> overrides = const [],
  Size size = const Size(400, 800),
  double textScale = 1,
  bool disableAnimations = false,
  LyricsFacts? facts,
  bool withBack = true,
  bool factsFail = false,
}) async {
  final online = RecordingOnlineCommands();
  final log = <String>[];
  final container = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      playingLyricsProvider.overrideWith((ref) => ref.watch(_playing)),
      ...pickerOverrides(
        script: script,
        facts: facts,
        online: online,
        factsFail: factsFail,
      ),
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
              onPressed: () => showLyricsPicker(
                context,
                const TrackId(1),
                followsPlaying: true,
                onBack: withBack ? () => log.add('back') : null,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/settings/plugins/p/:id',
        builder: (_, state) =>
            Scaffold(body: Text('plugin ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: lyricsSettingsLocation,
        builder: (_, _) => const Scaffold(body: Text('settings page')),
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
  return OpenedPicker(container, online, router, script, log);
}

/// Lets the search and the fetches the picker started finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const desktopSize = Size(1400, 900);

/// Types [text] into the picker's field and presses search.
Future<void> searchFor(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pump();
}
