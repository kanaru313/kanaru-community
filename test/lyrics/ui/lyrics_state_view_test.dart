import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_state_view.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart';

void main() {
  testWidgets('none: the title and sentence, and no button', (tester) async {
    await LyricsUiHost().pump(
      tester,
      const LyricsStateView(kind: LyricsStateKind.none, desktop: false),
    );
    expect(find.text('No lyrics'), findsOneWidget);
    expect(
      find.text('No lyrics in the file or in an .lrc file next to the song.'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('off: desktop and mobile say different things', (tester) async {
    final host = LyricsUiHost();
    await host.pump(
      tester,
      const LyricsStateView(kind: LyricsStateKind.off, desktop: true),
    );
    expect(find.text('Lyrics are off for this song'), findsOneWidget);
    expect(
      find.text('Right-click the lyrics button to turn them back on.'),
      findsOneWidget,
    );
    await host.pump(
      tester,
      const LyricsStateView(kind: LyricsStateKind.off, desktop: false),
    );
    expect(
      find.text('You chose “Don’t show lyrics” in Lyrics for this song.'),
      findsOneWidget,
    );
  });

  testWidgets('off: the button shows only when the owner gives one', (
    tester,
  ) async {
    final host = LyricsUiHost();
    await host.pump(
      tester,
      const LyricsStateView(kind: LyricsStateKind.off, desktop: false),
    );
    expect(find.text('Lyrics for this song'), findsNothing);
    var opened = 0;
    await host.pump(
      tester,
      LyricsStateView(
        kind: LyricsStateKind.off,
        desktop: false,
        onOpenChoice: () => opened++,
      ),
    );
    await tester.tap(find.text('Lyrics for this song'));
    expect(opened, 1);
  });

  testWidgets('200 % text on a short screen scrolls instead of overflowing', (
    tester,
  ) async {
    await LyricsUiHost().pump(
      tester,
      SizedBox(
        height: 200,
        child: LyricsStateView(
          kind: LyricsStateKind.off,
          desktop: false,
          onOpenChoice: () {},
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
