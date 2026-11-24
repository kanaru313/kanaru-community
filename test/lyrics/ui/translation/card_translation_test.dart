import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru/src/lyrics/ui/translation/translation_placeholder.dart';
import 'package:material_ui/material_ui.dart';

import '../lyrics_ui_host.dart';
import 'translation_ui_host.dart';

void main() {
  Future<LyricsUiHost> open(
    WidgetTester tester, {
    TranslationView? view,
    bool on = true,
    int line = 3,
    bool plain = false,
    String target = 'vi',
  }) async {
    final host = LyricsUiHost(
      lyrics: LyricsShown(plain ? plainLyrics(5) : syncedLyrics(10)),
      line: line,
      extra: translationOverrides(target: target),
    );
    if (on) await turnTranslationOn(host.container);
    host.container.read(viewBox.notifier).set(view ?? TranslationView.idle);
    await host.pump(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: LyricsCard(onOpen: null),
      ),
    );
    return host;
  }

  final map = {for (var i = 0; i < 10; i++) 'Line $i': 'Dòng $i'};

  testWidgets('the sung line has its translation at 13, 64 %, under it', (
    tester,
  ) async {
    await open(tester, view: readyView(map));
    final style = tester.widget<Text>(find.text('Dòng 3')).style!;
    expect(style.fontSize, 13);
    expect(style.fontWeight, FontWeight.w500);
    expect(style.color!.a, closeTo(0.64, 1e-3));
    expect(
      tester.getTopLeft(find.text('Dòng 3')).dy,
      greaterThan(tester.getBottomLeft(find.text('Line 3')).dy - 1),
    );
    // The lines before and after have none.
    expect(find.text('Dòng 2'), findsNothing);
    expect(find.text('Dòng 4'), findsNothing);
  });

  testWidgets('it follows the song', (tester) async {
    final host = await open(tester, view: readyView(map));
    host.setLine(4);
    await tester.pump();
    expect(find.text('Dòng 4'), findsOneWidget);
    expect(find.text('Dòng 3'), findsNothing);
  });

  testWidgets('pending: a bar stands where it will be', (tester) async {
    await open(tester, view: pendingView);
    expect(find.byKey(translationPlaceholderKey), findsOneWidget);
  });

  testWidgets('a right to left target is laid out right to left', (
    tester,
  ) async {
    await open(tester, view: readyView(map), target: 'he');
    expect(
      tester.widget<Text>(find.text('Dòng 3')).textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('the card keeps its height whatever the line has', (
    tester,
  ) async {
    final host = await open(tester, view: readyView({'Line 3': 'Dòng 3'}));
    final withText = tester.getSize(find.byType(LyricsCard)).height;
    host.setLine(4);
    await tester.pump();
    expect(tester.getSize(find.byType(LyricsCard)).height, withText);
  });

  testWidgets('translation off: nothing is added or asked for', (tester) async {
    await open(tester, view: readyView(map), on: false);
    expect(find.text('Dòng 3'), findsNothing);
    expect(translationAsks, 0);
  });

  testWidgets('plain lyrics on the card get no translation line', (
    tester,
  ) async {
    await open(tester, view: readyView({'Plain 0': 'Bản 0'}), plain: true);
    expect(find.text('Bản 0'), findsNothing);
    expect(find.text('Plain 0'), findsOneWidget);
  });
}
