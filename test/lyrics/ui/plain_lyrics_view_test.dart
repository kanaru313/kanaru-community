import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_display_prefs.dart';
import 'package:kanaru/src/lyrics/ui/plain_lyrics_view.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart';

Widget _view(Lyrics lyrics, {LyricsAlign align = LyricsAlign.start}) =>
    PlainLyricsView(
      lyrics: lyrics,
      lineSize: 25,
      sidePadding: 24,
      align: align,
    );

void main() {
  testWidgets('the note comes first and the text is 0.7 of the line size', (
    tester,
  ) async {
    final host = LyricsUiHost();
    await host.pump(tester, _view(plainLyrics(5)));
    expect(
      find.text(
        'Plain lyrics, no time marks: they do not scroll by themselves.',
      ),
      findsOneWidget,
    );
    final style = tester.widget<Text>(find.text('Plain 0')).style!;
    expect(style.fontSize, closeTo(25 * KLyricsMetrics.plainScale, 1e-9));
    final note = tester.getTopLeft(
      find.textContaining('Plain lyrics, no time marks'),
    );
    expect(note.dy, lessThan(tester.getTopLeft(find.text('Plain 0')).dy));
  });

  testWidgets('a press does nothing: no highlight, no seek', (tester) async {
    final host = LyricsUiHost();
    await host.pump(tester, _view(plainLyrics(5)));
    expect(find.byType(InkWell), findsNothing);
    await tester.tap(find.text('Plain 1'));
    await tester.pump();
    expect(host.player.seekTargets, isEmpty);
  });

  testWidgets('10 000 lines build lazily', (tester) async {
    final host = LyricsUiHost();
    await host.pump(tester, _view(plainLyrics(10000)));
    expect(find.byType(Text).evaluate().length, lessThan(60));
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    expect(find.byType(Text).evaluate().length, lessThan(60));
  });

  testWidgets('centred alignment is applied', (tester) async {
    final host = LyricsUiHost();
    await host.pump(tester, _view(plainLyrics(3), align: LyricsAlign.center));
    expect(
      tester.widget<Text>(find.text('Plain 0')).textAlign,
      TextAlign.center,
    );
  });

  testWidgets('a blank line is a break, and 200 % text does not overflow', (
    tester,
  ) async {
    final host = LyricsUiHost();
    final lyrics = plainLyrics(
      4,
      text: (i) => i == 1 ? '' : 'Một dòng lời rất dài bằng tiếng Việt ' * 3,
    );
    await host.pump(tester, _view(lyrics), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
