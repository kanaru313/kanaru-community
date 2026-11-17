import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/playback/ui/mini_seek_band.dart';
import 'package:material_ui/material_ui.dart';

import '../support/ui_host.dart';

const _total = Duration(seconds: 200);

Widget _player(List<String> events) => Align(
  alignment: Alignment.bottomCenter,
  child: MiniPlayer(
    onOpen: () => events.add('open'),
    onOpenQueue: () => events.add('queue'),
  ),
);

/// The loaded track reports its duration, so the band can seek.
Future<void> _loaded(WidgetTester tester, UiHost host) async {
  await host.run(
    tester,
    () async => host.h.engine.emit(EngineLoaded(host.h.loadedToken, _total)),
  );
  await host.letStreamsArrive(tester);
}

Rect _band(WidgetTester tester) => tester.getRect(find.byType(MiniSeekBand));

/// The coloured line (the one clipped to the card corners).
Rect _line(WidgetTester tester) => tester.getRect(
  find.descendant(
    of: find.descendant(
      of: find.byType(MiniSeekBand),
      matching: find.byType(ClipRRect),
    ),
    matching: find.byType(Container),
  ),
);

Finder _thumb() => find.descendant(
  of: find.byType(MiniSeekBand),
  matching: find.byType(AnimatedScale),
);

bool _thumbShown(WidgetTester tester) =>
    tester.widget<AnimatedScale>(_thumb()).scale == 1;

/// A change of state starts the animation on the next frame; run it out.
Future<void> _settleLook(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<TestGesture> _hover(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: _band(tester).center);
  await _settleLook(tester);
  return mouse;
}

void main() {
  testWidgets('at rest the line is 2 dp on the card edge, no thumb', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _player([]));
    await _loaded(tester, host);
    final band = _band(tester);
    expect(band.height, MiniSeekBand.height);
    expect(_line(tester).height, 2);
    expect(_line(tester).bottom, band.bottom);
    expect(_thumbShown(tester), isFalse);
  });

  testWidgets('hovering grows the line to 4 and shows a thumb on its centre', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _player([]));
    await _loaded(tester, host);
    await _hover(tester);
    final line = _line(tester);
    expect(line.height, 4);
    expect(line.bottom, _band(tester).bottom);
    expect(_thumbShown(tester), isTrue);
    final thumb = tester.getRect(_thumb());
    expect(thumb.size, const Size.square(12));
    expect(thumb.center.dy, line.center.dy);
    // Hangs below the card edge, within the 8 dp margin of the dock.
    expect(thumb.bottom - _band(tester).bottom, lessThanOrEqualTo(5));
  });

  testWidgets('dragging: line 6, thumb under the finger, time bubble up', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _player([]));
    await _loaded(tester, host);
    final band = _band(tester);
    final g = await tester.startGesture(Offset(band.left + 96, band.center.dy));
    await g.moveBy(const Offset(60, 0));
    await _settleLook(tester);
    expect(_line(tester).height, 6);
    expect(tester.getRect(_thumb()).center.dx, closeTo(band.left + 156, 0.5));
    expect(tester.getRect(_thumb()).center.dy, _line(tester).center.dy);
    // 156 / 384 of 3:20 = 1:21.
    final bubble = find.textContaining('1:21 / 3:20');
    expect(bubble, findsOneWidget);
    final card = tester.getRect(find.byType(MiniPlayer)).deflate(8);
    expect(tester.getRect(bubble).bottom, lessThanOrEqualTo(card.top - 8));
    await host.run(tester, g.up);
    await _settleLook(tester);
    expect(find.textContaining('/ 3:20'), findsNothing);
    expect(_line(tester).height, 2);
  });

  testWidgets('the bubble keeps 8 dp from the card edges at both ends', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _player([]));
    await _loaded(tester, host);
    final band = _band(tester);
    final g = await tester.startGesture(Offset(band.left + 40, band.center.dy));
    await g.moveBy(const Offset(-40, 0));
    await g.moveBy(const Offset(-20, 0));
    await tester.pump();
    var bubble = tester.getRect(find.textContaining('0:00 / 3:20'));
    expect(bubble.left, greaterThanOrEqualTo(band.left + 8));
    await g.moveTo(Offset(band.right + 30, band.center.dy));
    await tester.pump();
    await tester.pump();
    bubble = tester.getRect(find.textContaining('3:20 / 3:20'));
    expect(bubble.right, lessThanOrEqualTo(band.right - 8));
    await host.run(tester, g.up);
  });

  testWidgets('the thumb centre stays inside the card at 0 and at the end', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _player([]));
    await _loaded(tester, host);
    await _hover(tester);
    final band = _band(tester);
    expect(tester.getRect(_thumb()).left, band.left, reason: 'progress 0');
    await host.run(tester, () async => host.h.engine.tickPosition(_total));
    await host.letStreamsArrive(tester);
    expect(tester.getRect(_thumb()).right, band.right, reason: 'progress 1');
  });

  testWidgets('a track that cannot seek has no fill and no thumb', (
    tester,
  ) async {
    await pumpWithPlayer(tester, _player([]));
    // No duration reported yet.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: _band(tester).center);
    await _settleLook(tester);
    expect(_thumb(), findsNothing);
    expect(_line(tester).height, 2, reason: 'no growth on hover');
  });

  testWidgets('keyboard focus shows the thumb with a ring', (tester) async {
    final host = await pumpWithPlayer(tester, _player([]));
    await _loaded(tester, host);
    // Tab through the card and the buttons to the band.
    for (var i = 0; i < 8 && !_thumbShown(tester); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await _settleLook(tester);
    }
    expect(_thumbShown(tester), isTrue);
    expect(_line(tester).height, 4);
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: _thumb(),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.boxShadow, isNotEmpty, reason: 'focus ring');
  });

  testWidgets('semantics: slider with value, ±5 s, disabled without duration', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final host = await pumpWithPlayer(tester, _player([]));
    SemanticsFinder slider() => find.semantics.byLabel('Playback position');
    expect(
      slider().evaluate().single,
      isSemantics(isSlider: true, hasEnabledState: true, isEnabled: false),
    );
    await _loaded(tester, host);
    expect(slider().evaluate().single.value, '0:00 of 3:20');
    await host.run(tester, () async => tester.semantics.increase(slider()));
    expect(
      (await tester.runAsync(() => host.h.c.position.first))!.position,
      const Duration(seconds: 5),
    );
    handle.dispose();
  });
}
