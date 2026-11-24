import 'package:flutter/services.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'song_info_lyrics_host.dart';

void main() {
  testWidgets('Esc closes only the modal; the info page stays', (tester) async {
    await openFull(tester, synced(3));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(iconButton(showStamps), findsNothing);
    expect(find.text(openLabel), findsOneWidget);
  });

  testWidgets('menu > info > lyrics: Esc three times, one layer each', (
    tester,
  ) async {
    final host = SectionHost(LyricsShown(synced(3)));
    await host.pump(
      tester,
      wrap: (section) => Builder(
        builder: (context) => TextButton(
          onPressed: () => showKOverlayPage<void>(
            context,
            title: 'menu',
            builder: (menu) => TextButton(
              onPressed: () => showKOverlayPage<void>(
                menu,
                title: 'info',
                builder: (_) => ListView(children: [section]),
              ),
              child: const Text('go info'),
            ),
          ),
          child: const Text('go menu'),
        ),
      ),
    );
    await tester.tap(find.text('go menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('go info'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(openLabel));
    await tester.pumpAndSettle();
    expect(iconButton(showStamps), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(iconButton(showStamps), findsNothing);
    expect(find.text(openLabel), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(openLabel), findsNothing);
    expect(find.text('go info'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('go info'), findsNothing);
    expect(find.text('go menu'), findsOneWidget);
  });

  testWidgets('phone: a page with the song name under the title', (
    tester,
  ) async {
    await openFull(tester, synced(3), size: const Size(390, 800));
    expect(find.text('Song'), findsOneWidget);
    expect(find.text('Song · Artist'), findsNothing);
    expect(iconButton(showStamps), findsOneWidget);
    expect(iconButton('Copy lyrics'), findsOneWidget);
  });

  testWidgets('plain lyrics note has an info icon in front', (tester) async {
    await openFull(tester, plain(3));
    final note = find.ancestor(
      of: find.text('Plain lyrics, no timestamps'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(of: note.first, matching: find.byIcon(KIcons.info)),
      findsOneWidget,
    );
  });

  // Selection is a behaviour of the layout (no semantics of its own), so the
  // widget type is the proof.
  testWidgets('desktop lets the text be selected', (tester) async {
    await openFull(tester, synced(3), size: const Size(1400, 900));
    expect(find.byType(SelectionArea), findsOneWidget);
  });

  testWidgets('a phone does not make the text selectable', (tester) async {
    await openFull(tester, synced(3), size: const Size(390, 800));
    expect(find.byType(SelectionArea), findsNothing);
  });

  testWidgets('text at 200 % and animations off do not break it', (
    tester,
  ) async {
    await openFull(tester, synced(8), textScale: 2, still: true);
    await tester.tap(iconButton(showStamps));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(modalLine('Line 0'), findsOneWidget);
  });
}
