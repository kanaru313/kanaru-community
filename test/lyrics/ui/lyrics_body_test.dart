import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_display_prefs.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_body.dart';
import 'package:kanaru/src/lyrics/ui/plain_lyrics_view.dart';
import 'package:kanaru/src/lyrics/ui/synced_lyrics_view.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart';

LyricsBody _body({
  KLyricsSurface surface = KLyricsSurface.screen,
  VoidCallback? onOpenChoice,
  bool cover = true,
}) => LyricsBody(
  surface: surface,
  coverColumnShown: cover,
  onOpenChoice: onOpenChoice,
);

void main() {
  testWidgets('loading is blank', (tester) async {
    final host = LyricsUiHost();
    await host.pump(tester, _body());
    expect(find.byType(Text), findsNothing);
    expect(find.byType(SyncedLyricsView), findsNothing);
  });

  testWidgets('synced and plain lyrics pick their views', (tester) async {
    final host = LyricsUiHost(lyrics: LyricsShown(syncedLyrics(5)), line: 1);
    await host.pump(tester, _body());
    expect(find.byType(SyncedLyricsView), findsOneWidget);
    host.setLyrics(LyricsShown(plainLyrics(5)));
    await tester.pump();
    expect(find.byType(PlainLyricsView), findsOneWidget);
    expect(find.byType(SyncedLyricsView), findsNothing);
  });

  testWidgets('the next track never shows the last track lines', (
    tester,
  ) async {
    final host = LyricsUiHost(lyrics: LyricsShown(syncedLyrics(5)), line: 1);
    await host.pump(tester, _body());
    expect(find.text('Line 1'), findsOneWidget);
    host.setLyrics(const LyricsLoading(), entryId: 2);
    await tester.pump();
    expect(find.text('Line 1'), findsNothing);
    host.setLyrics(LyricsShown(plainLyrics(3)), entryId: 2);
    await tester.pump();
    expect(find.text('Plain 0'), findsOneWidget);
  });

  testWidgets('none and unavailable say no lyrics, off offers the choice', (
    tester,
  ) async {
    var opened = 0;
    final host = LyricsUiHost(lyrics: const LyricsNone());
    await host.pump(tester, _body(onOpenChoice: () => opened++));
    expect(find.text('No lyrics'), findsOneWidget);
    host.setLyrics(const LyricsOff(null));
    await tester.pump();
    expect(find.text('Lyrics are off for this song'), findsOneWidget);
    await tester.tap(find.text('Lyrics for this song'));
    expect(opened, 1);
  });

  testWidgets('the off sentence follows the surface', (tester) async {
    final host = LyricsUiHost(lyrics: const LyricsOff(null));
    await host.pump(tester, _body(surface: KLyricsSurface.tab));
    expect(
      find.text('Right-click the lyrics button to turn them back on.'),
      findsOneWidget,
    );
    // Without an owner callback there is no button yet.
    expect(find.text('Lyrics for this song'), findsNothing);
  });

  testWidgets('sizes come from the surface and the font scale setting', (
    tester,
  ) async {
    final host = LyricsUiHost(lyrics: LyricsShown(plainLyrics(3)));
    await host.pump(tester, _body());
    double size() => tester.widget<Text>(find.text('Plain 0')).style!.fontSize!;
    expect(size(), closeTo(25 * 0.7, 1e-9));
    await host.container
        .read(lyricsFontScaleProvider.notifier)
        .set(LyricsFontScale.large);
    await tester.pump();
    expect(size(), closeTo(25 * 1.2 * 0.7, 1e-9));
  });

  testWidgets('the tab at 1000 dp with the cover hidden uses 36', (
    tester,
  ) async {
    final host = LyricsUiHost(lyrics: LyricsShown(plainLyrics(3)));
    await host.pump(
      tester,
      _body(surface: KLyricsSurface.tab, cover: false),
      size: const Size(1000, 800),
    );
    expect(
      tester.widget<Text>(find.text('Plain 0')).style!.fontSize,
      closeTo(36 * 0.7, 1e-9),
    );
    expect(tester.getTopLeft(find.text('Plain 0')).dx, closeTo(120, 0.01));
  });

  testWidgets('the dim setting reaches the lines', (tester) async {
    final host = LyricsUiHost(lyrics: LyricsShown(syncedLyrics(5)), line: 1);
    await host.container.read(lyricsDimProvider.notifier).set(LyricsDim.strong);
    await host.pump(tester, _body());
    await tester.pump(const Duration(seconds: 1));
    final style = tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Line 3'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style;
    expect(style.color!.a, closeTo(0.20, 1e-6));
  });
}
