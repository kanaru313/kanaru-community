import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_display_prefs.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_credit_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_line.dart';
import 'package:kanaru/src/lyrics/ui/synced_lyrics_view.dart';
import 'package:kanaru/src/lyrics/ui/translation/translation_placeholder.dart';
import 'package:material_ui/material_ui.dart';

import '../lyrics_ui_host.dart';
import 'translation_ui_host.dart';

const _size = 25.0;

Widget _view(Lyrics lyrics, {LyricsAlign align = LyricsAlign.start}) =>
    SyncedLyricsView(
      lyrics: lyrics,
      lineSize: _size,
      sidePadding: 24,
      viewportHeight: 800,
      dim: LyricsDim.light,
      align: align,
      autoReturn: LyricsAutoReturn.off,
      trackId: trackOne,
    );

TextStyle _styleOf(WidgetTester tester, String text) =>
    DefaultTextStyle.of(tester.element(find.text(text))).style;

void main() {
  late LyricsUiHost host;

  Future<void> open(
    WidgetTester tester,
    Lyrics lyrics, {
    TranslationView? view,
    int line = 2,
    bool on = true,
    bool replace = false,
    String target = 'vi',
    LyricsAlign align = LyricsAlign.start,
    double textScale = 1,
    bool disableAnimations = false,
    TranslationCredit? credit,
  }) async {
    host = LyricsUiHost(
      line: line,
      extra: translationOverrides(target: target),
    );
    if (on) await turnTranslationOn(host.container, replace: replace);
    host.container.read(viewBox.notifier).set(view ?? TranslationView.idle);
    host.container.read(creditBox.notifier).set(credit);
    await host.pump(
      tester,
      _view(lyrics, align: align),
      textScale: textScale,
      disableAnimations: disableAnimations,
    );
    await settleScroll(tester);
  }

  final lyrics = syncedLyrics(5);
  final map = {for (var i = 0; i < 5; i++) 'Line $i': 'Dòng $i'};

  testWidgets('under: the translation is 0.62 of the line, w500, 64 % on the '
      'sung line and dim on the others', (tester) async {
    await open(tester, lyrics, view: readyView(map));
    final sung = _styleOf(tester, 'Dòng 2');
    expect(sung.fontSize, closeTo(_size * 0.62, 1e-9));
    expect(sung.fontWeight, FontWeight.w500);
    expect(sung.color!.a, closeTo(0.64, 1e-3));
    expect(_styleOf(tester, 'Dòng 3').color!.a, closeTo(0.36, 1e-3));
    expect(find.text('Line 2'), findsOneWidget);
    expect(_styleOf(tester, 'Line 2').fontSize, _size);
  });

  testWidgets('a translated line reads as the original and its translation', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, lyrics, view: readyView(map));
    expect(find.bySemanticsLabel('Line 2, Dòng 2'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('replace: the translation is the line, the original a small '
      'dim line, and a line without one keeps its original', (tester) async {
    await open(
      tester,
      lyrics,
      view: readyView({'Line 2': 'Dòng 2'}),
      replace: true,
    );
    expect(_styleOf(tester, 'Dòng 2').fontSize, _size);
    final small = _styleOf(tester, 'Line 2');
    expect(small.fontSize, closeTo(_size * 0.5, 1e-9));
    expect(small.fontWeight, FontWeight.w500);
    // No translation for line 3: the original stays the main line.
    expect(_styleOf(tester, 'Line 3').fontSize, _size);
  });

  testWidgets('pending: a bar under each text line, none under a gap line', (
    tester,
  ) async {
    final withGap = Lyrics(
      lines: const [
        LyricLine(Duration(seconds: 0), 'Line 0'),
        LyricLine(Duration(seconds: 4), ''),
        LyricLine(Duration(seconds: 8), 'Line 2'),
      ],
      synced: true,
      origin: LyricsOrigin.tag,
    );
    await open(tester, withGap, view: pendingView, line: 0);
    expect(find.byKey(translationPlaceholderKey), findsNWidgets(2));
  });

  testWidgets('a finished translation has no bar', (tester) async {
    await open(tester, lyrics, view: readyView({'Line 0': 'Dòng 0'}));
    expect(find.byKey(translationPlaceholderKey), findsNothing);
  });

  testWidgets('a gap line and a translation equal to its source show nothing '
      'extra', (tester) async {
    final withGap = Lyrics(
      lines: const [
        LyricLine(Duration(seconds: 0), 'Line 0'),
        LyricLine(Duration(seconds: 4), ''),
        LyricLine(Duration(seconds: 8), 'Line 2'),
      ],
      synced: true,
      origin: LyricsOrigin.tag,
    );
    await open(
      tester,
      withGap,
      view: readyView({'': 'ghost', 'Line 0': ' line 0', 'Line 2': 'Dòng 2'}),
      line: 0,
    );
    expect(find.text('ghost'), findsNothing);
    expect(find.text(' line 0'), findsNothing);
    expect(find.text('line 0'), findsNothing);
    expect(find.text('Dòng 2'), findsOneWidget);
  });

  testWidgets('a target written right to left lays the translation out RTL', (
    tester,
  ) async {
    await open(tester, lyrics, view: readyView(map), target: 'ar');
    expect(
      tester.widget<Text>(find.text('Dòng 2')).textDirection,
      TextDirection.rtl,
    );
    expect(tester.widget<Text>(find.text('Line 2')).textDirection, isNull);
  });

  testWidgets('another language is laid out as usual', (tester) async {
    await open(tester, lyrics, view: readyView(map), target: 'ja');
    expect(tester.widget<Text>(find.text('Dòng 2')).textDirection, isNull);
  });

  testWidgets(
    'the credit comes after the last line and follows the alignment',
    (tester) async {
      await open(
        tester,
        lyrics,
        view: readyView(map),
        align: LyricsAlign.center,
        credit: const TranslationCredit(plugin: 'Gemini', target: 'vi'),
      );
      final credit = find.text('Translated by Gemini · Vietnamese');
      expect(credit, findsOneWidget);
      expect(tester.widget<Text>(credit).textAlign, TextAlign.center);
    },
  );

  testWidgets('credit of an existing translation and of a partial one', (
    tester,
  ) async {
    await open(
      tester,
      lyrics,
      view: readyView(map),
      credit: const TranslationCredit(
        plugin: 'Google',
        target: 'vi',
        other: true,
      ),
    );
    expect(find.text('Existing translation from Google'), findsOneWidget);
  });

  testWidgets('a partial translation says how many lines are done', (
    tester,
  ) async {
    await open(
      tester,
      lyrics,
      view: readyView(map),
      credit: const TranslationCredit(
        plugin: 'Gemini',
        target: 'en',
        model: 'Flash',
        style: 'Natural',
        linesDone: 6,
        linesTotal: 16,
      ),
    );
    expect(
      find.text(
        'Translated by Gemini · Flash · Natural · English · partial 6/16 lines',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no credit while none is made', (tester) async {
    await open(tester, lyrics, view: readyView(map));
    expect(find.textContaining('Translated by'), findsNothing);
  });

  testWidgets('translation off: lines are plain and nothing is asked for', (
    tester,
  ) async {
    await open(tester, lyrics, view: readyView(map), on: false);
    expect(find.text('Dòng 2'), findsNothing);
    expect(find.text('Line 2'), findsOneWidget);
    expect(translationAsks, 0);
  });

  testWidgets('translation on: showing the lyrics asks for the translation', (
    tester,
  ) async {
    await open(tester, lyrics, view: readyView(map));
    expect(translationAsks, greaterThan(0));
  });

  testWidgets('a status without a translation shows plain lines', (
    tester,
  ) async {
    await open(
      tester,
      lyrics,
      view: TranslationView(
        status: const TranslationStatus.same('vi'),
        map: map,
      ),
    );
    expect(find.text('Dòng 2'), findsNothing);
    expect(find.byKey(translationPlaceholderKey), findsNothing);
  });

  testWidgets('a chunk arriving rebuilds only the lines it covers', (
    tester,
  ) async {
    await open(tester, syncedLyrics(50), view: readyView({'Line 9': 'Dòng 9'}));
    final existing = find
        .byType(LyricsLine, skipOffstage: false)
        .evaluate()
        .toSet();
    var rebuilds = 0;
    debugOnRebuildDirtyWidget = (element, _) {
      if (element.widget is LyricsLine && existing.contains(element)) {
        rebuilds++;
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    host.container
        .read(viewBox.notifier)
        .set(readyView({'Line 9': 'Dòng 9', 'Line 3': 'Dòng 3'}));
    await tester.pump();
    expect(find.text('Dòng 3'), findsOneWidget);
    expect(rebuilds, 1);
  });

  testWidgets('a translation arriving mid-song keeps the sung line at the '
      'anchor', (tester) async {
    await open(tester, syncedLyrics(50), view: pendingView, line: 20);
    final sung = find
        .byType(LyricsLine)
        .evaluate()
        .firstWhere((e) => (e.widget as LyricsLine).index == 20);
    double centre() =>
        tester.getCenter(find.byElementPredicate((e) => e == sung)).dy;
    expect(centre(), closeTo(800 * 0.4, 40));
    host.container
        .read(viewBox.notifier)
        .set(readyView({for (var i = 0; i < 50; i++) 'Line $i': 'Dòng $i'}));
    await settleScroll(tester);
    expect(find.text('Dòng 20'), findsOneWidget);
    expect(centre(), closeTo(800 * 0.4, 40));
  });

  testWidgets('200 % text and animations off lay out without overflow', (
    tester,
  ) async {
    await open(
      tester,
      lyrics,
      view: readyView(map),
      textScale: 2,
      disableAnimations: true,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Dòng 2'), findsOneWidget);
  });

  testWidgets('the bar sweeps while animations are on', (tester) async {
    await open(tester, lyrics, view: pendingView);
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('animations off: the bar is still', (tester) async {
    await open(tester, lyrics, view: pendingView, disableAnimations: true);
    expect(find.byKey(translationPlaceholderKey), findsWidgets);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
