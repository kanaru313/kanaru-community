import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/lyrics_choice_commands.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_choice_rows.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_body.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_modal.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_settings_link.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart' show plainLyrics, syncedLyrics;

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

Finder _closeButton() => find.byWidgetPredicate(
  (w) => w is KIconButton && w.tooltip == 'Close',
  description: 'close button',
);

Finder _settingsButton() => find.byWidgetPredicate(
  (w) => w is KIconButton && w.tooltip == 'Lyrics settings',
  description: 'settings button',
);

/// Records the writes; nothing touches a database.
class _Commands implements LyricsChoiceCommands {
  final calls = <String>[];

  @override
  Future<void> setOff(TrackId id) async => calls.add('off:${id.value}');

  @override
  Future<void> clear(TrackId id) async => calls.add('clear:${id.value}');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _mobile = Size(400, 800);
const _desktop = Size(1400, 900);

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SelectionRow));

bool _selected(WidgetTester tester, String title) =>
    isSemantics(isSelected: true).matches(tester.getSemantics(_row(title)), {});

bool _enabled(WidgetTester tester, String title) =>
    isSemantics(isEnabled: true).matches(tester.getSemantics(_row(title)), {});

class _Setup {
  _Setup(this.container, this.commands, this.router);
  final ProviderContainer container;
  final _Commands commands;
  final GoRouter router;

  String get location =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  void play(int? entry) => container.read(_playing.notifier).play(entry);
}

/// Pumps an app with a button that opens the modal for track 1 and opens it.
Future<_Setup> _open(
  WidgetTester tester,
  TrackLyrics lyrics, {
  Size size = _mobile,
  bool followsPlaying = false,
  double textScale = 1,
}) async {
  final commands = _Commands();
  final container = ProviderContainer(
    overrides: [
      trackLyricsProvider.overrideWith((ref, id) => lyrics),
      playingLyricsProvider.overrideWith((ref) => ref.watch(_playing)),
      lyricsChoiceCommandsProvider.overrideWithValue(commands),
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
              onPressed: () => showLyricsForTrack(
                context,
                const TrackId(1),
                followsPlaying: followsPlaying,
              ),
              child: const Text('open'),
            ),
          ),
        ),
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
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return _Setup(container, commands, router);
}

void main() {
  for (final (name, size) in [('mobile', _mobile), ('desktop', _desktop)]) {
    group(name, () {
      testWidgets('file lyrics: row described, chosen and enabled', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, LyricsShown(syncedLyrics(2)), size: size);
        expect(find.text('Lyrics for this song'), findsOneWidget);
        expect(find.text('In tag · Synced'), findsOneWidget);
        expect(_selected(tester, 'Lyrics in file'), isTrue);
        expect(_enabled(tester, 'Lyrics in file'), isTrue);
        expect(_selected(tester, 'Don’t show lyrics'), isFalse);
        expect(find.text('No lyrics on this device'), findsNothing);
        handle.dispose();
      });

      testWidgets('plain .lrc lyrics say so', (tester) async {
        await _open(tester, LyricsShown(plainLyrics(2)), size: size);
        expect(find.text('LRC file · Plain'), findsOneWidget);
      });

      testWidgets('off: the off row is chosen, the file row can be picked', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, LyricsOff(syncedLyrics(2)), size: size);
        expect(_selected(tester, 'Don’t show lyrics'), isTrue);
        expect(_selected(tester, 'Lyrics in file'), isFalse);
        expect(_enabled(tester, 'Lyrics in file'), isTrue);
        expect(find.text('In tag · Synced'), findsOneWidget);
        expect(find.text('No lyrics on this device'), findsNothing);
        handle.dispose();
      });

      testWidgets('no lyrics: file row disabled, status line shown', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, const LyricsNone(), size: size);
        expect(_enabled(tester, 'Lyrics in file'), isFalse);
        expect(find.text('No lyrics in the file'), findsOneWidget);
        expect(
          find.text('No lyrics on this device · automatic search is off'),
          findsOneWidget,
        );
        expect(_enabled(tester, 'Don’t show lyrics'), isTrue);
        handle.dispose();
      });

      testWidgets('loading: file row disabled, off row enabled and works', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final setup = await _open(tester, const LyricsLoading(), size: size);
        expect(_enabled(tester, 'Lyrics in file'), isFalse);
        expect(_enabled(tester, 'Don’t show lyrics'), isTrue);
        expect(find.text('No lyrics on this device'), findsNothing);
        await tester.tap(find.text('Don’t show lyrics'));
        await tester.pumpAndSettle();
        expect(setup.commands.calls, ['off:1']);
        expect(find.byType(LyricsForTrackBody), findsNothing);
        handle.dispose();
      });

      testWidgets('choosing off writes once and closes', (tester) async {
        final setup = await _open(
          tester,
          LyricsShown(syncedLyrics(2)),
          size: size,
        );
        await tester.tap(find.text('Don’t show lyrics'));
        await tester.pumpAndSettle();
        expect(setup.commands.calls, ['off:1']);
        expect(find.byType(LyricsForTrackBody), findsNothing);
      });

      testWidgets('choosing the file when off clears the choice once', (
        tester,
      ) async {
        final setup = await _open(
          tester,
          LyricsOff(syncedLyrics(2)),
          size: size,
        );
        await tester.tap(find.text('Lyrics in file'));
        await tester.pumpAndSettle();
        expect(setup.commands.calls, ['clear:1']);
        expect(find.byType(LyricsForTrackBody), findsNothing);
      });

      testWidgets('the chosen row only closes', (tester) async {
        final setup = await _open(
          tester,
          LyricsShown(syncedLyrics(2)),
          size: size,
        );
        await tester.tap(find.text('Lyrics in file'));
        await tester.pumpAndSettle();
        expect(setup.commands.calls, isEmpty);
        expect(find.byType(LyricsForTrackBody), findsNothing);
      });

      testWidgets('a double tap writes once', (tester) async {
        final setup = await _open(
          tester,
          LyricsShown(syncedLyrics(2)),
          size: size,
        );
        final off = find.text('Don’t show lyrics');
        await tester.tap(off);
        await tester.tap(off, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(setup.commands.calls, ['off:1']);
      });

      testWidgets('soon rows are dimmed and inert', (tester) async {
        final handle = tester.ensureSemantics();
        final setup = await _open(tester, const LyricsNone(), size: size);
        expect(find.text('Coming soon'), findsNWidgets(2));
        expect(find.text('Groq Whisper'), findsOneWidget);
        for (final title in ['Create lyrics from audio…', 'Save lyrics…']) {
          await tester.tap(find.text(title));
          await tester.pumpAndSettle();
          expect(find.byType(LyricsForTrackBody), findsOneWidget);
        }
        expect(setup.commands.calls, isEmpty);
        expect(_closeButton(), findsOneWidget);
        expect(_settingsButton(), findsOneWidget);
        expect(find.byType(KIconButton), findsNWidgets(2));
        handle.dispose();
      });

      testWidgets('the close button closes', (tester) async {
        await _open(tester, const LyricsNone(), size: size);
        await tester.tap(_closeButton());
        await tester.pumpAndSettle();
        expect(find.byType(LyricsForTrackBody), findsNothing);
      });

      testWidgets('200 % text and a short window do not overflow', (
        tester,
      ) async {
        await _open(
          tester,
          const LyricsNone(),
          size: Size(size.width, 480),
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(LyricsForTrackBody), findsOneWidget);
      });
    });
  }

  testWidgets('mobile Back closes the modal', (tester) async {
    await _open(tester, const LyricsNone());
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('desktop Esc closes the modal', (tester) async {
    await _open(tester, const LyricsNone(), size: _desktop);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsNothing);
  });

  testWidgets('following the playing song: a track change closes it once', (
    tester,
  ) async {
    final setup = await _open(tester, const LyricsNone(), followsPlaying: true);
    setup.play(2);
    await tester.pump();
    // A second change while it animates out must not pop another route.
    setup.play(3);
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('following the playing song: stopping closes it', (tester) async {
    final setup = await _open(tester, const LyricsNone(), followsPlaying: true);
    setup.play(null);
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsNothing);
  });

  testWidgets('opened for a song, it stays when another one plays', (
    tester,
  ) async {
    final setup = await _open(tester, const LyricsNone());
    setup.play(2);
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsOneWidget);
  });

  for (final (name, size) in [('mobile', _mobile), ('desktop', _desktop)]) {
    testWidgets('$name: the settings button closes the modal and opens '
        'Settings › Lyrics', (tester) async {
      final setup = await _open(tester, const LyricsNone(), size: size);
      setup.container.read(nowPlayingPanelProvider.notifier).open();
      await tester.tap(_settingsButton());
      await tester.pumpAndSettle();
      expect(find.byType(LyricsForTrackBody), findsNothing);
      expect(setup.location, lyricsSettingsLocation);
      expect(find.text('settings page'), findsOneWidget);
      expect(setup.container.read(nowPlayingPanelProvider).open, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  test('fileLyricsSummary reads the file even while lyrics are off', () {
    expect(fileLyricsSummary(const LyricsNone()), isNull);
    expect(fileLyricsSummary(const LyricsLoading()), isNull);
    expect(fileLyricsSummary(const LyricsOff(null)), isNull);
    expect(fileLyricsSummary(LyricsOff(plainLyrics(1))), isNotNull);
  });
}
