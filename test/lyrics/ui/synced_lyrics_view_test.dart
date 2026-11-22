import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_display_prefs.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_line.dart';
import 'package:kanaru/src/lyrics/ui/synced_lyrics_view.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart';

const _label = 'Back to current line';
final _back = find.byType(IconButton);
final _arrow = find.descendant(of: _back, matching: find.byType(Icon));

Widget _view(
  Lyrics lyrics, {
  double height = 800,
  LyricsAutoReturn autoReturn = LyricsAutoReturn.off,
  LyricsAlign align = LyricsAlign.start,
  LyricsDim dim = LyricsDim.light,
  double size = 25,
}) => SyncedLyricsView(
  lyrics: lyrics,
  lineSize: size,
  sidePadding: 24,
  viewportHeight: height,
  dim: dim,
  align: align,
  autoReturn: autoReturn,
);

double _offset(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

Future<void> _dragLyrics(WidgetTester tester) async {
  await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -150));
  await tester.pump();
}

void main() {
  late LyricsUiHost host;

  Future<void> open(
    WidgetTester tester,
    Lyrics lyrics, {
    int line = 4,
    LyricsAutoReturn autoReturn = LyricsAutoReturn.off,
    bool disableAnimations = false,
    double textScale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    host = LyricsUiHost(line: line);
    await host.pump(
      tester,
      _view(lyrics, autoReturn: autoReturn),
      disableAnimations: disableAnimations,
      textScale: textScale,
      brightness: brightness,
    );
    await settleScroll(tester);
  }

  testWidgets('the current line is the selected one and sits at the anchor', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, syncedLyrics(50));
    expect(isSelectedLine(tester, find.text('Line 4')), isTrue);
    expect(isSelectedLine(tester, find.text('Line 5')), isFalse);
    final y = tester.getCenter(find.text('Line 4')).dy;
    expect(y, closeTo(800 * 0.4, 40));
    handle.dispose();
  });

  testWidgets('a line change rebuilds exactly two lines, a repeat none', (
    tester,
  ) async {
    await open(tester, syncedLyrics(50));
    var rebuilds = 0;
    // Only rebuilds of existing lines are counted: nothing is mounted here.
    debugOnRebuildDirtyWidget = (element, _) {
      if (element.widget is ValueListenableBuilder<bool> &&
          element.findAncestorWidgetOfExactType<LyricsLine>() != null) {
        rebuilds++;
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    host.setLine(5);
    await settleScroll(tester);
    expect(rebuilds, 2);
    rebuilds = 0;
    host.setLine(5);
    await settleScroll(tester);
    expect(rebuilds, 0);
  });

  testWidgets('pressing a line seeks to it and makes it current at once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, syncedLyrics(50));
    await tester.tap(find.text('Line 7'));
    await tester.pump();
    expect(host.player.seekTargets, [const Duration(seconds: 28)]);
    expect(isSelectedLine(tester, find.text('Line 7')), isTrue);
    expect(isSelectedLine(tester, find.text('Line 4')), isFalse);
    handle.dispose();
  });

  testWidgets('a drag stops auto-scroll and shows the pill', (tester) async {
    await open(tester, syncedLyrics(50));
    expect(_back, findsNothing);
    await _dragLyrics(tester);
    expect(_back, findsOneWidget);
    final before = _offset(tester);
    host.setLine(10);
    await settleScroll(tester);
    expect(_offset(tester), before);
  });

  testWidgets('the mouse wheel does the same', (tester) async {
    await open(tester, syncedLyrics(50));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.byType(SingleChildScrollView))),
    );
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
    await tester.pump();
    expect(_back, findsOneWidget);
  });

  testWidgets('the button is icon only, labelled, at the bottom right', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, syncedLyrics(50));
    await _dragLyrics(tester);
    expect(find.text(_label), findsNothing);
    expect(find.byTooltip(_label), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    final area = tester.getRect(find.byType(SyncedLyricsView));
    final button = tester.getRect(find.byType(IconButton));
    expect(button.size, const Size.square(48));
    expect(area.right - button.right, closeTo(16, 0.5));
    expect(area.bottom - button.bottom, closeTo(16, 0.5));
    handle.dispose();
  });

  testWidgets('the arrow points to the current line and flips with scroll', (
    tester,
  ) async {
    await open(tester, syncedLyrics(50));
    IconData arrow() => tester.widgetList<Icon>(_arrow).last.icon!;
    // Content dragged up: the current line is now above the anchor.
    await _dragLyrics(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(arrow(), KIcons.arrowUp);
    // Dragged back down past where it was: the line is below.
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 400));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(arrow(), KIcons.arrowDown);
    expect(tester.widgetList(_arrow), hasLength(1));
  });

  testWidgets('the pill brings the line back and goes away', (tester) async {
    await open(tester, syncedLyrics(50));
    final anchored = _offset(tester);
    await _dragLyrics(tester);
    expect(_offset(tester), isNot(closeTo(anchored, 1)));
    await tester.tap(_back);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(_back, findsNothing);
    expect(_offset(tester), closeTo(anchored, 1));
  });

  testWidgets('auto-return 3 s: back after 3 s without input', (tester) async {
    await open(tester, syncedLyrics(50), autoReturn: LyricsAutoReturn.s3);
    final anchored = _offset(tester);
    await _dragLyrics(tester);
    await tester.pump(const Duration(milliseconds: 2900));
    expect(_back, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 1));
    expect(_back, findsNothing);
    expect(_offset(tester), closeTo(anchored, 1));
  });

  testWidgets('auto-return off: the pill stays however long we wait', (
    tester,
  ) async {
    await open(tester, syncedLyrics(50));
    await _dragLyrics(tester);
    await tester.pump(const Duration(seconds: 30));
    expect(_back, findsOneWidget);
  });

  testWidgets('two line changes 100 ms apart are not the user', (tester) async {
    await open(tester, syncedLyrics(50));
    host.setLine(5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    host.setLine(6);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(_back, findsNothing);
    expect(find.text('Line 6'), findsOneWidget);
  });

  testWidgets('an enclosing scrollable never moves', (tester) async {
    host = LyricsUiHost(line: 4);
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await host.pump(
      tester,
      ListView(
        controller: outer,
        children: [
          SizedBox(height: 500, child: _view(syncedLyrics(50), height: 500)),
          const SizedBox(height: 2000),
        ],
      ),
    );
    await settleScroll(tester);
    for (final line in [5, 6, 20]) {
      host.setLine(line);
      await settleScroll(tester);
    }
    expect(outer.offset, 0);
  });

  testWidgets('a resize puts the line back at once, without a glide', (
    tester,
  ) async {
    host = LyricsUiHost(line: 4);
    await host.pump(tester, _view(syncedLyrics(50)));
    await settleScroll(tester);
    final tall = _offset(tester);
    await host.pump(tester, _view(syncedLyrics(50), height: 400));
    // One frame for the layout and one for the post-frame reveal: no wait.
    await tester.pump();
    final short = _offset(tester);
    expect(short, isNot(closeTo(tall, 1)));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('animations off: the line jumps and nothing keeps running', (
    tester,
  ) async {
    await open(tester, syncedLyrics(50), disableAnimations: true);
    host.setLine(12);
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.getCenter(find.text('Line 12')).dy, closeTo(320, 40));
  });

  testWidgets('one line', (tester) async {
    await open(tester, syncedLyrics(1), line: 0);
    expect(find.text('Line 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1000 lines, scrolled to the last', (tester) async {
    host = LyricsUiHost(line: 0);
    await host.pump(tester, _view(syncedLyrics(1000)));
    await settleScroll(tester);
    host.setLine(999);
    await settleScroll(tester);
    expect(find.text('Line 999'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('200 % text, a 120-character line, ${brightness.name}', (
      tester,
    ) async {
      final long = 'Một dòng lời rất dài bằng tiếng Việt ' * 3;
      expect(long.length, greaterThan(110));
      await open(
        tester,
        syncedLyrics(6, text: (i) => i == 2 ? long.trim() : 'Line $i'),
        line: 2,
        textScale: 2,
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Một dòng lời'), findsOneWidget);
    });
  }

  testWidgets('a gap line is a pressable dot row that seeks', (tester) async {
    host = LyricsUiHost(line: 0);
    final lyrics = Lyrics(
      lines: const [
        LyricLine(Duration(seconds: 0), 'First'),
        LyricLine(Duration(seconds: 4), ''),
        LyricLine(Duration(seconds: 9), 'Second'),
      ],
      synced: true,
      origin: LyricsOrigin.lrc,
    );
    await host.pump(tester, _view(lyrics));
    await settleScroll(tester);
    await tester.tap(find.bySemanticsLabel('Instrumental break'));
    await tester.pump();
    expect(host.player.seekTargets, [const Duration(seconds: 4)]);
  });

  testWidgets('a failed seek puts the highlight back on the real line', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, syncedLyrics(50));
    host.player.seekError = StateError('engine gone');
    await tester.tap(find.text('Line 7'));
    await tester.pump();
    await tester.pump();
    expect(host.player.seekTargets, hasLength(1));
    expect(isSelectedLine(tester, find.text('Line 7')), isFalse);
    expect(isSelectedLine(tester, find.text('Line 4')), isTrue);
    handle.dispose();
  });

  testWidgets('with centred alignment the gap dots are centred too', (
    tester,
  ) async {
    host = LyricsUiHost(line: 0);
    final lyrics = Lyrics(
      lines: const [
        LyricLine(Duration.zero, 'First'),
        LyricLine(Duration(seconds: 4), ''),
        LyricLine(Duration(seconds: 9), 'Second'),
      ],
      synced: true,
      origin: LyricsOrigin.lrc,
    );
    Finder dots() => find.byWidgetPredicate(
      (w) => w is SizedBox && w.width == 10 && w.height == 10,
    );
    await host.pump(tester, _view(lyrics, align: LyricsAlign.center));
    await settleScroll(tester);
    final middle = dots().at(1);
    expect(tester.getCenter(middle).dx, closeTo(200, 2));
    await host.pump(tester, _view(lyrics));
    await settleScroll(tester);
    expect(tester.getCenter(dots().at(1)).dx, lessThan(100));
  });
}
