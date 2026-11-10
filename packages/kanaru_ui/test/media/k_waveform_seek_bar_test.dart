import 'dart:ui' show SemanticsAction;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

const _total = Duration(seconds: 100);
final _levels = Uint8List.fromList(List.generate(100, (i) => i * 2));
const _bars = ValueKey('waveform bars');

Widget _bar({
  Uint8List? levels,
  bool instant = false,
  Duration position = const Duration(seconds: 20),
  Duration? duration = _total,
  List<Duration>? seeks,
}) => SizedBox(
  width: 200,
  child: KWaveformSeekBar(
    position: position,
    duration: duration,
    levels: levels,
    instant: instant,
    onSeek: (d) => seeks?.add(d),
    semanticLabel: 'Position',
    semanticValue: '0:20 of 1:40',
  ),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('is 48 dp tall in $name', (tester) async {
      await tester.pumpWidget(
        host(
          Center(child: _bar(levels: _levels)),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(
        tester.getSize(find.byType(KWaveformSeekBar)).height,
        waveformTrackHeight,
      );
    });
  }

  testWidgets('without levels it shows the flat track only', (tester) async {
    await tester.pumpWidget(host(Center(child: _bar())));
    expect(find.byType(KFlatSeekTrack), findsOneWidget);
    expect(find.byKey(_bars), findsNothing);
  });

  testWidgets('an unknown duration is flat even with levels', (tester) async {
    await tester.pumpWidget(
      host(Center(child: _bar(levels: _levels, duration: null))),
    );
    expect(find.byKey(_bars), findsNothing);
  });

  testWidgets('levels there from the start show at once', (tester) async {
    await tester.pumpWidget(host(Center(child: _bar(levels: _levels))));
    expect(find.byKey(_bars), findsOneWidget);
    expect(find.byType(KFlatSeekTrack), findsNothing);
  });

  testWidgets('levels that arrive later fade in over 200 ms', (tester) async {
    await tester.pumpWidget(host(Center(child: _bar())));
    await tester.pumpWidget(host(Center(child: _bar(levels: _levels))));
    await tester.pump(const Duration(milliseconds: 100));
    // Halfway: both the flat track and the bars show.
    expect(find.byKey(_bars), findsOneWidget);
    expect(find.byType(KFlatSeekTrack), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(KFlatSeekTrack), findsNothing);
  });

  testWidgets('instant levels skip the fade', (tester) async {
    await tester.pumpWidget(host(Center(child: _bar())));
    await tester.pumpWidget(
      host(Center(child: _bar(levels: _levels, instant: true))),
    );
    await tester.pump();
    expect(find.byType(KFlatSeekTrack), findsNothing);
    expect(find.byKey(_bars), findsOneWidget);
  });

  testWidgets('losing the levels goes back to flat', (tester) async {
    await tester.pumpWidget(host(Center(child: _bar(levels: _levels))));
    await tester.pumpWidget(host(Center(child: _bar())));
    await tester.pump();
    expect(find.byKey(_bars), findsNothing);
    expect(find.byType(KFlatSeekTrack), findsOneWidget);
  });

  testWidgets('a position tick does not record the bars again', (tester) async {
    await tester.pumpWidget(host(Center(child: _bar(levels: _levels))));
    final before = WaveformPictures.recordings;
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(levels: _levels, position: const Duration(seconds: 21)),
        ),
      ),
    );
    expect(WaveformPictures.recordings, before);
  });

  testWidgets('narrower than the thumb it draws without throwing', (
    tester,
  ) async {
    for (final width in [0.0, 1.0, 3.0, 3.9, 4.0]) {
      await tester.pumpWidget(
        host(
          Center(
            child: SizedBox(
              width: width,
              child: KWaveformSeekBar(
                position: const Duration(seconds: 20),
                duration: _total,
                levels: _levels,
                onSeek: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });

  testWidgets('tap seeks to the tapped time of the duration', (tester) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(levels: _levels, seeks: seeks),
        ),
      ),
    );
    final box = tester.getRect(find.byType(KWaveformSeekBar));
    await tester.tapAt(Offset(box.left + 150, box.center.dy));
    expect(seeks, [const Duration(seconds: 75)]);
  });

  testWidgets('drag seeks once, on release', (tester) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(levels: _levels, seeks: seeks),
        ),
      ),
    );
    final box = tester.getRect(find.byType(KWaveformSeekBar));
    final g = await tester.startGesture(Offset(box.left + 20, box.center.dy));
    await g.moveTo(Offset(box.left + 100, box.center.dy));
    expect(seeks, isEmpty);
    await g.up();
    expect(seeks, [const Duration(seconds: 50)]);
  });

  testWidgets('left and right seek 5 s while focused', (tester) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(levels: _levels, seeks: seeks),
        ),
      ),
    );
    final box = tester.getRect(find.byType(KWaveformSeekBar));
    await tester.tapAt(Offset(box.left + 100, box.center.dy));
    seeks.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(seeks, [const Duration(seconds: 25), const Duration(seconds: 15)]);
  });

  testWidgets('no duration: taps and keys do nothing', (tester) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(levels: _levels, duration: null, seeks: seeks),
        ),
      ),
    );
    final box = tester.getRect(find.byType(KWaveformSeekBar));
    await tester.tapAt(Offset(box.left + 100, box.center.dy));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(seeks, isEmpty);
  });

  testWidgets('announces itself as a slider with its value', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(Center(child: _bar(levels: _levels))));
    final data = tester
        .getSemantics(find.byType(KWaveformSeekBar))
        .getSemanticsData();
    expect(data.label, 'Position');
    expect(data.value, '0:20 of 1:40');
    expect(data.flagsCollection.isSlider, isTrue);
    expect(data.hasAction(SemanticsAction.increase), isTrue);
    expect(data.hasAction(SemanticsAction.decrease), isTrue);
    handle.dispose();
  });
}
