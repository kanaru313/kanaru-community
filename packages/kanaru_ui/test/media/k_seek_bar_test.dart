import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../support/host.dart';

const _total = Duration(seconds: 100);

Widget _bar({
  Duration position = const Duration(seconds: 20),
  Duration? duration = _total,
  required List<Duration> seeks,
  List<String>? events,
}) => SizedBox(
  width: 200,
  child: KSeekBar(
    position: position,
    duration: duration,
    onSeek: seeks.add,
    onSeekStart: () => events?.add('start'),
    onSeekEnd: () => events?.add('end'),
    semanticLabel: 'Position',
    semanticValue: '0:20 of 1:40',
  ),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders in $name', (tester) async {
      await tester.pumpWidget(
        host(
          Center(child: _bar(seeks: [])),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(find.byType(KSeekBar), findsOneWidget);
      expect(tester.getSize(find.byType(KSeekBar)).height, KSeekBar.hitHeight);
    });
  }

  testWidgets('tap seeks to the tapped fraction', (tester) async {
    final seeks = <Duration>[];
    final events = <String>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(seeks: seeks, events: events),
        ),
      ),
    );
    final box = tester.getRect(find.byType(KSeekBar));
    await tester.tapAt(Offset(box.left + 150, box.center.dy));
    expect(seeks, [const Duration(seconds: 75)]);
    expect(events, ['start', 'end']);
  });

  testWidgets('drag follows the finger and seeks once on release', (
    tester,
  ) async {
    final seeks = <Duration>[];
    final events = <String>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(seeks: seeks, events: events),
        ),
      ),
    );
    final box = tester.getRect(find.byType(KSeekBar));
    final gesture = await tester.startGesture(
      Offset(box.left + 40, box.center.dy),
    );
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(seeks, isEmpty);
    expect(events, ['start']);
    await gesture.up();
    await tester.pump();
    expect(seeks, hasLength(1));
    expect(seeks.single.inSeconds, inInclusiveRange(48, 52));
    expect(events, ['start', 'end']);
  });

  testWidgets('arrow keys step 5 s and clamp at both ends', (tester) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(position: const Duration(seconds: 3), seeks: seeks),
        ),
      ),
    );
    await tester.tap(find.byType(KSeekBar));
    await tester.pump();
    seeks.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(seeks, [const Duration(seconds: 8), Duration.zero]);
  });

  testWidgets('without a duration it ignores input and shows no thumb', (
    tester,
  ) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      host(Center(child: _bar(duration: null, seeks: seeks))),
    );
    await tester.tap(find.byType(KSeekBar));
    await tester.pump();
    expect(seeks, isEmpty);
  });

  testWidgets('semantics: slider with label, value and actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final seeks = <Duration>[];
    await tester.pumpWidget(host(Center(child: _bar(seeks: seeks))));
    final node = tester.getSemantics(find.byType(KSeekBar));
    expect(node.label, 'Position');
    expect(node.value, '0:20 of 1:40');
    tester.semantics.increase(find.semantics.byLabel('Position'));
    expect(seeks, [const Duration(seconds: 25)]);
    handle.dispose();
  });

  testWidgets('hover grows the track', (tester) async {
    await tester.pumpWidget(host(Center(child: _bar(seeks: []))));
    double trackHeight() => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .first
        .constraints!
        .maxHeight;
    expect(trackHeight(), KSeekBar.trackHeight);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byType(KSeekBar)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(trackHeight(), KSeekBar.trackHeightActive);
  });
}
