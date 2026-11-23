import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_outcome.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_state_view.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart';
import 'lyrics_spinner_finders.dart';

const _instrumental = LyricsInstrumental(
  OnlineLyricsRef(
    providerId: 'lrclib',
    providerName: 'LRCLIB',
    remoteId: 'r',
    how: OnlineHow.auto,
  ),
);

/// Pumps the state view for [lyrics] with every button wired; the callbacks
/// record which one was pressed.
Future<List<String>> _pump(
  WidgetTester tester,
  TrackLyrics lyrics, {
  bool desktop = false,
  bool wired = true,
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  final pressed = <String>[];
  await LyricsUiHost().pump(
    tester,
    LyricsStateView(
      lyrics: lyrics,
      desktop: desktop,
      onOpenChoice: wired ? () => pressed.add('choice') : null,
      onFindOnline: wired ? () => pressed.add('find') : null,
      onAddSource: wired ? () => pressed.add('add') : null,
    ),
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
  return pressed;
}

Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.bySubtype<ButtonStyleButton>(),
);

void main() {
  testWidgets('none (not searchable): title and sentence, no button', (
    tester,
  ) async {
    await _pump(
      tester,
      const LyricsNone(reason: LyricsNoneReason.notSearchable),
    );
    expect(find.text('No lyrics'), findsOneWidget);
    expect(
      find.text('No lyrics in the file or in an .lrc file next to the song.'),
      findsOneWidget,
    );
    expect(find.bySubtype<ButtonStyleButton>(), findsNothing);
  });

  testWidgets('a track without a file says the same, with no button', (
    tester,
  ) async {
    await _pump(tester, const LyricsNone(reason: LyricsNoneReason.notPlaying));
    expect(find.text('No lyrics'), findsOneWidget);
    expect(find.bySubtype<ButtonStyleButton>(), findsNothing);
  });

  testWidgets('none with automatic search off: "Search manually…" finds', (
    tester,
  ) async {
    final pressed = await _pump(tester, const LyricsNone());
    expect(
      find.text(
        'No lyrics in the file or in an .lrc file next to the song. '
        'Automatic search is off.',
      ),
      findsOneWidget,
    );
    await tester.tap(_button('Search manually…'));
    expect(pressed, ['find']);
  });

  testWidgets('searching: spinner, title and the number of sources', (
    tester,
  ) async {
    await _pump(tester, const LyricsSearching(2));
    expect(find.text('Searching for lyrics…'), findsOneWidget);
    expect(
      find.text('No lyrics on this device yet · searching 2 enabled sources.'),
      findsOneWidget,
    );
    expect(byLyricsSpinner(), findsOneWidget);
    expect(find.bySubtype<ButtonStyleButton>(), findsNothing);
  });

  testWidgets('searching with animations off: a still arc', (tester) async {
    await _pump(tester, const LyricsSearching(1), disableAnimations: true);
    expect(byLyricsSpinner(), findsOneWidget);
    await expectStill(tester);
    expect(
      find.text('No lyrics on this device yet · searching 1 enabled source.'),
      findsOneWidget,
    );
  });

  testWidgets('not found: sources asked and off, and the find button', (
    tester,
  ) async {
    final pressed = await _pump(tester, const LyricsNotFound(asked: 2, off: 2));
    expect(find.text('Lyrics not found'), findsOneWidget);
    expect(
      find.text('Searched 2 enabled sources. 2 other sources are off.'),
      findsOneWidget,
    );
    await tester.tap(_button('Find lyrics online…'));
    expect(pressed, ['find']);
  });

  testWidgets('not found with no source off drops the second sentence', (
    tester,
  ) async {
    await _pump(tester, const LyricsNotFound(asked: 1, off: 0));
    expect(find.text('Searched 1 enabled source.'), findsOneWidget);
  });

  testWidgets('not found with every source off says so', (tester) async {
    await _pump(tester, const LyricsNotFound(asked: 0, off: 3));
    expect(
      find.text(
        'No lyrics on this device · every online lyrics source is off.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no lyrics plugin: "Add an online lyrics source"', (
    tester,
  ) async {
    final pressed = await _pump(tester, const LyricsNoSource());
    expect(
      find.text('No lyrics on this device and no online lyrics source yet.'),
      findsOneWidget,
    );
    await tester.tap(_button('Add an online lyrics source'));
    expect(pressed, ['add']);
  });

  testWidgets('instrumental: the button searches again', (tester) async {
    final pressed = await _pump(tester, _instrumental);
    expect(find.text('Instrumental'), findsOneWidget);
    await tester.tap(_button('Not right? Find lyrics online…'));
    expect(pressed, ['find']);
  });

  group('lookup failed', () {
    final retry = DateTime(2030, 1, 1, 21, 5);

    testWidgets('network: the reason and the retry time', (tester) async {
      final pressed = await _pump(
        tester,
        LyricsLookupFailed(
          reason: LookupFailReason.network,
          asked: 2,
          retryAt: retry,
        ),
      );
      expect(find.text('Couldn’t find lyrics'), findsOneWidget);
      expect(
        find.text(
          'Network error searching 2 enabled sources · trying again at '
          '9:05 PM.',
        ),
        findsOneWidget,
      );
      // The spinner has stopped: a failed state shows no progress.
      expect(byLyricsSpinner(), findsNothing);
      await tester.tap(_button('Find lyrics online…'));
      expect(pressed, ['find']);
    });

    testWidgets('needs configuration, nothing scheduled: no retry time', (
      tester,
    ) async {
      await _pump(
        tester,
        const LyricsLookupFailed(
          reason: LookupFailReason.needsConfig,
          asked: 1,
        ),
      );
      expect(find.text('The sources need setting up.'), findsOneWidget);
    });

    testWidgets('sources that do not answer', (tester) async {
      await _pump(
        tester,
        LyricsLookupFailed(
          reason: LookupFailReason.noAnswer,
          asked: 1,
          retryAt: retry,
        ),
      );
      expect(
        find.text(
          'The lyrics sources did not answer · trying again at 9:05 PM.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('paused: until when, and the find button stays', (tester) async {
    final pressed = await _pump(
      tester,
      LyricsLookupPaused(DateTime(2030, 1, 1, 21, 5)),
    );
    expect(find.text('Lyrics sources are paused'), findsOneWidget);
    expect(
      find.text(
        'The lyrics sources are paused until 9:05 PM: the server reported '
        'too many requests. Kanaru searches again then.',
      ),
      findsOneWidget,
    );
    await tester.tap(_button('Find lyrics online…'));
    expect(pressed, ['find']);
  });

  testWidgets('a button without its callback is not drawn', (tester) async {
    await _pump(tester, const LyricsNotFound(asked: 1, off: 0), wired: false);
    expect(find.bySubtype<ButtonStyleButton>(), findsNothing);
    await _pump(tester, const LyricsNoSource(), wired: false);
    expect(find.bySubtype<ButtonStyleButton>(), findsNothing);
  });

  testWidgets('off: desktop and mobile say different things', (tester) async {
    await _pump(tester, const LyricsOff(null), desktop: true);
    expect(find.text('Lyrics are off for this song'), findsOneWidget);
    expect(
      find.text('Right-click the lyrics button to turn them back on.'),
      findsOneWidget,
    );
    await _pump(tester, const LyricsOff(null));
    expect(
      find.text('You chose “Don’t show lyrics” in Lyrics for this song.'),
      findsOneWidget,
    );
  });

  testWidgets('off: the button shows only when the owner gives one', (
    tester,
  ) async {
    await _pump(tester, const LyricsOff(null), wired: false);
    expect(find.text('Lyrics for this song'), findsNothing);
    final pressed = await _pump(tester, const LyricsOff(null));
    await tester.tap(find.text('Lyrics for this song'));
    expect(pressed, ['choice']);
  });

  testWidgets('loading stays blank', (tester) async {
    await _pump(tester, const LyricsLoading());
    expect(find.byType(Text), findsNothing);
  });

  for (final (name, lyrics) in <(String, TrackLyrics)>[
    ('searching', const LyricsSearching(3)),
    ('not found', const LyricsNotFound(asked: 2, off: 2)),
    (
      'failed',
      LyricsLookupFailed(
        reason: LookupFailReason.network,
        asked: 2,
        retryAt: DateTime(2030, 1, 1, 21, 5),
      ),
    ),
    ('paused', LyricsLookupPaused(DateTime(2030, 1, 1, 21, 5))),
    ('instrumental', _instrumental),
    ('no source', const LyricsNoSource()),
  ]) {
    testWidgets('$name: 200 % text on a short screen scrolls, no overflow', (
      tester,
    ) async {
      await LyricsUiHost().pump(
        tester,
        SizedBox(
          height: 200,
          child: LyricsStateView(
            lyrics: lyrics,
            desktop: false,
            onFindOnline: () {},
            onAddSource: () {},
          ),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
