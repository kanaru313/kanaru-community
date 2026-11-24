import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_display_prefs.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_line.dart';
import 'package:kanaru/src/lyrics/ui/synced_lyrics_view.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart';

// A file of 10 000 synced lines: only the lines near the viewport may exist,
// whatever the position, the jumps or the scrolling.

const _count = 10000;
const _height = 800.0;

/// Far below the 10 000 lines; a screen holds about 15.
const _maxBuilt = 100;

final _back = find.byType(IconButton);
final _arrow = find.descendant(of: _back, matching: find.byType(Icon));
final _list = find.byType(Scrollable);

Widget _view(Lyrics lyrics) => SyncedLyricsView(
  lyrics: lyrics,
  lineSize: 25,
  sidePadding: 24,
  viewportHeight: _height,
  dim: LyricsDim.light,
  align: LyricsAlign.start,
  autoReturn: LyricsAutoReturn.off,
);

int _builtLines() =>
    find.byType(LyricsLine, skipOffstage: false).evaluate().length;

Finder _line(int i) => find.text('Line $i', skipOffstage: false);

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(_list).position;

/// The line's top where the anchor puts it: 40 % of the room the line leaves.
void _expectAtAnchor(WidgetTester tester, Finder line) {
  final rect = tester.getRect(
    find.ancestor(of: line, matching: find.byType(LyricsLine)).first,
  );
  expect(rect.top, closeTo(lyricsAnchorTop(rect.height), 2));
}

double lyricsAnchorTop(double lineHeight) => 0.4 * (_height - lineHeight);

IconData _arrowIcon(WidgetTester tester) =>
    tester.widgetList<Icon>(_arrow).last.icon!;

void main() {
  late LyricsUiHost host;

  Future<void> open(
    WidgetTester tester,
    Lyrics lyrics, {
    int line = 0,
    double textScale = 1,
  }) async {
    host = LyricsUiHost(line: line);
    await host.pump(tester, _view(lyrics), textScale: textScale);
    await settleScroll(tester);
  }

  testWidgets('opening builds only the lines near the viewport', (
    tester,
  ) async {
    await open(tester, syncedLyrics(_count), line: 3);
    expect(_builtLines(), lessThan(_maxBuilt));
    expect(_line(3), findsOneWidget);
    _expectAtAnchor(tester, _line(3));
  });

  testWidgets('opening at line 9000 shows it at the anchor without a glide', (
    tester,
  ) async {
    host = LyricsUiHost(line: 9000);
    await host.pump(tester, _view(syncedLyrics(_count)));
    // The first frame and the post-frame reveal, then one frame for the
    // list's height corrections: no waiting on an animation.
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(_builtLines(), lessThan(_maxBuilt));
    _expectAtAnchor(tester, _line(9000));
    expect(_back, findsNothing);
  });

  testWidgets('the position jumping to line 9000 follows it, lazily', (
    tester,
  ) async {
    await open(tester, syncedLyrics(_count), line: 2);
    host.setLine(9000);
    await settleScroll(tester);
    await settleScroll(tester);
    expect(_builtLines(), lessThan(_maxBuilt));
    _expectAtAnchor(tester, _line(9000));
    expect(_line(2), findsNothing);
    // The song keeps going: the next line glides in like any other.
    host.setLine(9001);
    await settleScroll(tester);
    _expectAtAnchor(tester, _line(9001));
    expect(_back, findsNothing);
  });

  testWidgets('a tick at line 9000 rebuilds only the old and new lines', (
    tester,
  ) async {
    await open(tester, syncedLyrics(_count), line: 9000);
    final rebuilt = <int>[];
    // A line the glide brings into the cache area is built for the first
    // time; only lines that existed before the tick count.
    final existing = find
        .byType(LyricsLine, skipOffstage: false)
        .evaluate()
        .toSet();
    debugOnRebuildDirtyWidget = (element, _) {
      final widget = element.widget;
      if (widget is LyricsLine && existing.contains(element)) {
        rebuilt.add(widget.index);
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    host.setLine(9001);
    await settleScroll(tester);
    expect(rebuilt..sort(), [9000, 9001]);
  });

  testWidgets('scrolling by hand far through the file stays lazy', (
    tester,
  ) async {
    await open(tester, syncedLyrics(_count), line: 5000);
    for (var i = 0; i < 6; i++) {
      await tester.fling(_list, const Offset(0, -600), 4000);
      await tester.pump();
      expect(_builtLines(), lessThan(_maxBuilt));
    }
    await tester.pumpAndSettle();
    expect(_builtLines(), lessThan(_maxBuilt));
    expect(_back, findsOneWidget);
  });

  testWidgets('the arrow points down to a current line far below, unbuilt', (
    tester,
  ) async {
    await open(tester, syncedLyrics(_count), line: 9000);
    // Not a glide of the view's own: the user's.
    _position(tester).jumpTo(0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_line(9000), findsNothing);
    expect(_back, findsOneWidget);
    expect(_arrowIcon(tester), KIcons.arrowDown);
    // A line change while away: still unbuilt, still below.
    host.setLine(9001);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_line(9001), findsNothing);
    expect(_arrowIcon(tester), KIcons.arrowDown);
    expect(_builtLines(), lessThan(_maxBuilt));
  });

  testWidgets('the arrow points up to a current line far above, unbuilt', (
    tester,
  ) async {
    await open(tester, syncedLyrics(_count), line: 5);
    final position = _position(tester);
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_line(5), findsNothing);
    expect(_arrowIcon(tester), KIcons.arrowUp);
    expect(_builtLines(), lessThan(_maxBuilt));
  });

  testWidgets('the back button brings back a line thousands of lines away', (
    tester,
  ) async {
    await open(tester, syncedLyrics(_count), line: 9000);
    _position(tester).jumpTo(0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(_back);
    await settleScroll(tester);
    await settleScroll(tester);
    expect(_back, findsNothing);
    expect(_builtLines(), lessThan(_maxBuilt));
    _expectAtAnchor(tester, _line(9000));
  });

  testWidgets('wrapping lines at 200 % text land exactly at the anchor', (
    tester,
  ) async {
    // Every third line wraps over several rows: estimated heights are wrong
    // until the lines are measured, and the jump must still be exact.
    final long = 'Một dòng lời rất dài bằng tiếng Việt ' * 3;
    final lyrics = syncedLyrics(
      _count,
      text: (i) => i % 3 == 0 ? 'Line $i ${long.trim()}' : 'Line $i',
    );
    await open(tester, lyrics, line: 10, textScale: 2);
    for (final target in [7000, 7001, 300, 9999]) {
      host.setLine(target);
      await settleScroll(tester);
      await settleScroll(tester);
      final line = target % 3 == 0
          ? find.textContaining('Line $target ', skipOffstage: false)
          : _line(target);
      expect(line, findsOneWidget, reason: 'line $target');
      _expectAtAnchor(tester, line);
      expect(_builtLines(), lessThan(_maxBuilt));
    }
    expect(_back, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
