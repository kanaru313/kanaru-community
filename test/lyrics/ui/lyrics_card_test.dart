import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_intro_gap.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_gap_mark.dart';
import 'package:flutter/scheduler.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart';

Widget _card({VoidCallback? onOpen}) => Padding(
  padding: const EdgeInsets.all(16),
  child: LyricsCard(onOpen: onOpen),
);

double _y(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  testWidgets('synced: the line before, the current one and the next', (
    tester,
  ) async {
    final host = LyricsUiHost(lyrics: LyricsShown(syncedLyrics(10)), line: 3);
    await host.pump(tester, _card());
    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.text('In tag'), findsOneWidget);
    expect(find.text('Line 3'), findsOneWidget);
    expect(find.text('Line 2'), findsOneWidget);
    expect(find.text('Line 4'), findsOneWidget);
    expect(find.text('Line 1'), findsNothing);
    expect(find.text('Line 5'), findsNothing);
    expect(_y(tester, 'Line 2'), lessThan(_y(tester, 'Line 3')));
    expect(_y(tester, 'Line 3'), lessThan(_y(tester, 'Line 4')));
    final current = tester.widget<Text>(find.text('Line 3')).style!;
    final other = tester.widget<Text>(find.text('Line 2')).style!;
    expect(current.fontSize, 18);
    expect(current.color!.a, 1);
    expect(other.color!.a, closeTo(0.36, 1e-6));
    host.setLine(4);
    await tester.pump();
    expect(find.text('Line 5'), findsOneWidget);
    expect(find.text('Line 2'), findsNothing);
  });

  testWidgets('before the first line the first line is the next one', (
    tester,
  ) async {
    final host = LyricsUiHost(lyrics: LyricsShown(syncedLyrics(4)), line: -1);
    await host.pump(tester, _card());
    expect(find.text('Line 0'), findsOneWidget);
    expect(find.byType(LyricsGapMark), findsOneWidget);
  });

  testWidgets('a gap reads as a note', (tester) async {
    final lyrics = Lyrics(
      lines: const [
        LyricLine(Duration.zero, 'A'),
        LyricLine(Duration(seconds: 4), ''),
        LyricLine(Duration(seconds: 8), 'B'),
      ],
      synced: true,
      origin: LyricsOrigin.lrc,
    );
    final host = LyricsUiHost(lyrics: LyricsShown(lyrics), line: 1);
    await host.pump(tester, _card());
    expect(find.byType(LyricsGapMark), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('during an intro gap the card shows the gap as current', (
    tester,
  ) async {
    final lyrics = withIntroGap(
      const Lyrics(
        lines: [LyricLine(Duration(seconds: 30), 'First')],
        synced: true,
        origin: LyricsOrigin.tag,
      ),
    );
    final host = LyricsUiHost(lyrics: LyricsShown(lyrics), line: 0);
    await host.pump(tester, _card());
    expect(find.byType(LyricsGapMark), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(LyricsGapMark)).dy,
      lessThan(_y(tester, 'First')),
    );
  });

  testWidgets(
    'gaps: static as previous or next, pulsing as current, edges empty',
    (tester) async {
      final lyrics = Lyrics(
        lines: const [
          LyricLine(Duration.zero, ''),
          LyricLine(Duration(seconds: 4), 'A'),
          LyricLine(Duration(seconds: 8), ''),
        ],
        synced: true,
        origin: LyricsOrigin.lrc,
      );
      final host = LyricsUiHost(lyrics: LyricsShown(lyrics), line: 1);
      await host.pump(tester, _card());
      expect(find.byType(LyricsGapMark), findsNWidgets(2));
      expect(
        tester
            .widgetList<LyricsGapMark>(find.byType(LyricsGapMark))
            .map((m) => m.active),
        [false, false],
      );
      await tester.pump(const Duration(seconds: 1));
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      host.setLine(0);
      await tester.pump();
      // Current gap pulses; the slot before the first line is empty.
      expect(find.byType(LyricsGapMark), findsOneWidget);
      expect(
        tester.widget<LyricsGapMark>(find.byType(LyricsGapMark)).active,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
      host.setLine(2);
      await tester.pump();
      expect(find.byType(LyricsGapMark), findsNWidgets(1));
      expect(find.text('A'), findsOneWidget);
    },
  );

  testWidgets('plain: the first three lines at 15', (tester) async {
    final host = LyricsUiHost(lyrics: LyricsShown(plainLyrics(8)));
    await host.pump(tester, _card());
    for (final i in [0, 1, 2]) {
      expect(find.text('Plain $i'), findsOneWidget);
    }
    expect(find.text('Plain 3'), findsNothing);
    expect(tester.widget<Text>(find.text('Plain 0')).style!.fontSize, 15);
    expect(find.text('LRC file'), findsOneWidget);
  });

  for (final (lyrics, text) in [
    (const LyricsNone(), 'No lyrics for this song'),
    (const LyricsOff(null), 'Lyrics are off for this song'),
  ]) {
    testWidgets('${lyrics.runtimeType}: one status line', (tester) async {
      final host = LyricsUiHost(lyrics: lyrics);
      await host.pump(tester, _card());
      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('loading: only the title, no line of the last track', (
    tester,
  ) async {
    final host = LyricsUiHost(lyrics: const LyricsLoading());
    await host.pump(tester, _card());
    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.textContaining('No lyrics'), findsNothing);
  });

  testWidgets('the whole card is one button named by title and source', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var opened = 0;
    final host = LyricsUiHost(lyrics: LyricsShown(syncedLyrics(5)), line: 1);
    await host.pump(tester, _card(onOpen: () => opened++));
    expect(
      tester.getSemantics(find.byType(LyricsCard)),
      isSemantics(
        label: 'Lyrics · In tag',
        isButton: true,
        hasTapAction: true,
        isEnabled: true,
      ),
    );
    await tester.tap(find.byType(LyricsCard));
    expect(opened, 1);
    handle.dispose();
  });

  testWidgets('without a callback the card is inert', (tester) async {
    final host = LyricsUiHost(lyrics: LyricsShown(syncedLyrics(5)), line: 1);
    await host.pump(tester, _card());
    await tester.tap(find.byType(LyricsCard));
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('200 % text with a long line, ${brightness.name}', (
      tester,
    ) async {
      final long = 'Một dòng lời rất dài bằng tiếng Việt ' * 4;
      final host = LyricsUiHost(
        lyrics: LyricsShown(syncedLyrics(5, text: (_) => long)),
        line: 2,
      );
      await host.pump(
        tester,
        _card(),
        textScale: 2,
        brightness: brightness,
        size: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the card sits on surfaceContainerHigh with radius 20', (
    tester,
  ) async {
    final host = LyricsUiHost(lyrics: const LyricsNone());
    await host.pump(tester, _card());
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(LyricsCard),
        matching: find.byType(Material),
      ),
    );
    expect(material.borderRadius, KRadius.lg);
    expect(
      material.color,
      buildKanaruTheme(brightness: Brightness.light)
          .colorScheme
          .surfaceContainerHigh,
    );
  });

  testWidgets('10 000 synced lines: three rows, following line 9000', (
    tester,
  ) async {
    final host = LyricsUiHost(
      lyrics: LyricsShown(syncedLyrics(10000)),
      line: 9000,
    );
    await host.pump(tester, _card());
    expect(find.textContaining('Line ', skipOffstage: false), findsNWidgets(3));
    expect(find.text('Line 9000'), findsOneWidget);
    host.setLine(9001);
    await tester.pump();
    expect(find.text('Line 9002'), findsOneWidget);
    expect(find.textContaining('Line ', skipOffstage: false), findsNWidgets(3));
  });
}
