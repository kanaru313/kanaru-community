import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/state/player_controller.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/memory_settings_store.dart';

/// `n` synced lines, 4 s apart: "Line 0", "Line 1", ...
Lyrics syncedLyrics(int n, {String Function(int i)? text}) => Lyrics(
  lines: [
    for (var i = 0; i < n; i++)
      LyricLine(Duration(seconds: i * 4), text?.call(i) ?? 'Line $i'),
  ],
  synced: true,
  origin: LyricsOrigin.tag,
);

/// `n` plain lines.
Lyrics plainLyrics(int n, {String Function(int i)? text}) => Lyrics(
  lines: [
    for (var i = 0; i < n; i++)
      LyricLine(Duration.zero, text?.call(i) ?? 'Plain $i'),
  ],
  synced: false,
  origin: LyricsOrigin.lrc,
);

/// A player that records seeks and nothing else.
class FakePlayer implements PlayerController {
  final seekTargets = <Duration>[];

  /// When set, every seek throws it.
  Object? seekError;

  @override
  Future<void> seek(Duration position) async {
    seekTargets.add(position);
    if (seekError != null) throw seekError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Source<T> extends Notifier<T> {
  _Source(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;
}

/// The providers the lyrics widgets read, driven by the test: the line being
/// sung, the playing lyrics and a recording player. Settings live in memory.
class LyricsUiHost {
  LyricsUiHost({
    TrackLyrics lyrics = const LyricsLoading(),
    int entryId = 1,
    int line = -1,
    List<Override> extra = const [],
  }) : _line = NotifierProvider<_Source<int>, int>(() => _Source(line)),
       _playing = NotifierProvider<_Source<PlayingLyrics>, PlayingLyrics>(
         () => _Source(
           PlayingLyrics(
             entryId: entryId,
             trackId: TrackId(entryId),
             lyrics: lyrics,
           ),
         ),
       ) {
    container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(settings),
        playerControllerProvider.overrideWithValue(player),
        playingLyricsLineProvider.overrideWith((ref) => ref.watch(_line)),
        playingLyricsProvider.overrideWith((ref) => ref.watch(_playing)),
        ...extra,
      ],
    );
  }

  final NotifierProvider<_Source<int>, int> _line;
  final NotifierProvider<_Source<PlayingLyrics>, PlayingLyrics> _playing;
  final settings = MemorySettingsStore();
  final player = FakePlayer();
  late final ProviderContainer container;

  void setLine(int index) => container.read(_line.notifier).set(index);

  void setLyrics(TrackLyrics lyrics, {int entryId = 1}) => container
      .read(_playing.notifier)
      .set(
        PlayingLyrics(
          entryId: entryId,
          trackId: TrackId(entryId),
          lyrics: lyrics,
        ),
      );

  /// Pumps [child] in a themed, localized app that reads this host.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(400, 800),
    double textScale = 1,
    Brightness brightness = Brightness.light,
    bool disableAnimations = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: brightness),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: disableAnimations,
            ),
            child: app!,
          ),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
  }
}

/// Whether the semantics node of the widget found by [finder] is selected.
bool isSelectedLine(WidgetTester tester, Finder finder) =>
    isSemantics(isSelected: true).matches(tester.getSemantics(finder), {});

/// Lets the glide of a line change and the post-frame reveal finish.
Future<void> settleScroll(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}
