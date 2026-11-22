import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/lyrics_choice_commands.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_source_button.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/playable.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart' show plainLyrics, syncedLyrics;

class _Commands implements LyricsChoiceCommands {
  final toggles = <(int, bool)>[];

  @override
  Future<void> toggle(TrackId id, {required bool currentlyOff}) async =>
      toggles.add((id.value, currentlyOff));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PlayingLyrics _playing(TrackLyrics lyrics) =>
    PlayingLyrics(entryId: 1, trackId: const TrackId(1), lyrics: lyrics);

class _Harness {
  _Harness(this.opened, this.commands);
  final List<int> opened;
  final _Commands commands;
}

Future<_Harness> _pump(
  WidgetTester tester,
  PlayingLyrics playing, {
  bool desktop = false,
  bool withToggle = true,
}) async {
  final commands = _Commands();
  final opened = <int>[];
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = desktop
      ? const Size(1400, 900)
      : const Size(400, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playingLyricsProvider.overrideWithValue(playing),
        lyricsChoiceCommandsProvider.overrideWithValue(commands),
      ],
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Consumer(
              builder: (context, ref, _) => LyricsSourceButton(
                onOpen: () => opened.add(1),
                onToggle: withToggle ? toggleLyricsOfPlaying(ref) : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return _Harness(opened, commands);
}

SemanticsNode _node(WidgetTester tester) =>
    tester.getSemantics(find.byType(KIconButton));

bool _enabled(WidgetTester tester) =>
    isSemantics(isEnabled: true).matches(_node(tester), {});

void main() {
  final labels = <(String, TrackLyrics)>[
    ('Lyrics in tag · Synced', LyricsShown(syncedLyrics(2))),
    ('LRC file · Plain', LyricsShown(plainLyrics(2))),
    ('No lyrics', const LyricsNone()),
    ('Lyrics off', const LyricsOff(null)),
    // Nothing is known yet: the button names its modal.
    ('Lyrics for this song', const LyricsLoading()),
  ];
  for (final (label, lyrics) in labels) {
    testWidgets('$label: named by its state and tappable', (tester) async {
      final handle = tester.ensureSemantics();
      final h = await _pump(tester, _playing(lyrics));
      expect(_node(tester).label, label);
      expect(_enabled(tester), isTrue);
      await tester.tap(find.byType(KIconButton));
      expect(h.opened, hasLength(1));
      handle.dispose();
    });
  }

  testWidgets('no track: disabled and inert', (tester) async {
    final handle = tester.ensureSemantics();
    final h = await _pump(tester, PlayingLyrics.none, desktop: true);
    expect(_enabled(tester), isFalse);
    await tester.tap(find.byType(KIconButton), warnIfMissed: false);
    await tester.tap(
      find.byType(KIconButton),
      buttons: kSecondaryButton,
      warnIfMissed: false,
    );
    expect(h.opened, isEmpty);
    expect(h.commands.toggles, isEmpty);
    handle.dispose();
  });

  testWidgets('a track without a readable file: still opens the modal', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = await _pump(
      tester,
      _playing(const LyricsUnavailable(UnplayableReason.unknownTrack)),
    );
    expect(_enabled(tester), isTrue);
    await tester.tap(find.byType(KIconButton));
    expect(h.opened, hasLength(1));
    handle.dispose();
  });

  testWidgets('desktop right-click turns lyrics off', (tester) async {
    final h = await _pump(
      tester,
      _playing(LyricsShown(syncedLyrics(2))),
      desktop: true,
    );
    await tester.tap(find.byType(KIconButton), buttons: kSecondaryButton);
    await tester.pump();
    expect(h.commands.toggles, [(1, false)]);
    expect(h.opened, isEmpty);
  });

  testWidgets('desktop right-click turns lyrics back on when off', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      _playing(const LyricsOff(null)),
      desktop: true,
    );
    await tester.tap(find.byType(KIconButton), buttons: kSecondaryButton);
    await tester.pump();
    expect(h.commands.toggles, [(1, true)]);
  });

  testWidgets('mobile has no right-click toggle', (tester) async {
    final h = await _pump(tester, _playing(LyricsShown(syncedLyrics(2))));
    await tester.tap(find.byType(KIconButton), buttons: kSecondaryButton);
    await tester.pump();
    expect(h.commands.toggles, isEmpty);
  });

  testWidgets('tooltip: desktop names the key and the right-click', (
    tester,
  ) async {
    await _pump(tester, _playing(LyricsShown(syncedLyrics(2))), desktop: true);
    expect(
      tester.widget<KIconButton>(find.byType(KIconButton)).tooltip,
      'Lyrics in tag · Synced (L)\nRight-click: turn this song’s lyrics on or off',
    );
  });

  testWidgets('tooltip: no right-click line without a toggle; mobile plain', (
    tester,
  ) async {
    await _pump(
      tester,
      _playing(const LyricsNone()),
      desktop: true,
      withToggle: false,
    );
    expect(
      tester.widget<KIconButton>(find.byType(KIconButton)).tooltip,
      'No lyrics (L)',
    );
    await _pump(tester, _playing(const LyricsNone()));
    await tester.pump();
    expect(
      tester.widget<KIconButton>(find.byType(KIconButton)).tooltip,
      'No lyrics',
    );
  });
}
